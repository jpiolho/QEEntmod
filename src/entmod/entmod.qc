/*
====
Defs
====
*/
enum {
    ENTMOD_MODE_NONE,
    ENTMOD_MODE_MOVING
};

enum {
    ENTMOD_ATTACKINGMODE_NONE,
    ENTMOD_ATTACKINGMODE_SELECT,
    ENTMOD_ATTACKINGMODE_DRAG
};

enum {
    ENTMOD_ENTITY_NORMAL,
    ENTMOD_ENTITY_SUBENTITY,
    ENTMOD_ENTITY_MARKED,
};

typedef struct {
    float active;

    float mode;
    float attackingMode;
    entity selectedEntity;
    entity markedEntity;

    float attacking;
    float attackTime;
    entity attackingOldOwner;

    void() killOverride;
    string killOverrideStringArgument;
    float killOverrideFloatArgument;

    vector lastSelectedPosition;

    vector moverStartOrigin;
    vector moveeStartOrigin;

    float gridAligned;
} entmod_t;

entmod_t entmod;


.entity entchain;


float() Entmod_Get_Command_Argument1 =
{
    local float v = cvar("scratch2");
    cvar_set("scratch2",0);

    return v;
}

float(float n1,float n2) Entmod_math_min =
{
    return n1 < n2 ? n1 : n2;
}

float(float n1,float n2) Entmod_math_max =
{
    return n1 > n2 ? n1 : n2;
}

float(float nValue,float nMin,float nMax) Entmod_math_clamp =
{
    return Entmod_math_max(Entmod_math_min(nValue,nMax),nMin);
}


vector() Entmod_GetEyesPosition =
{
    return self.origin + '0 0 16';
}

vector() Entmod_GetAimTargetVector =
{
    makevectors (self.v_angle);

    return Entmod_GetEyesPosition() + v_forward * 10000;
}

vector(entity ent) Entmod_GetBoundsCenter =
{
    local float sx = fabs(ent.absmin_x - ent.absmax_x);
    local float sy = fabs(ent.absmin_y - ent.absmax_y);
    local float sz = fabs(ent.absmin_z - ent.absmax_z);

    local vector result = ent.absmin;

    result_x += sx / 2;
    result_y += sy / 2;
    result_z += sz / 2;

    return result;
}

entity() Entmod_TraceForward =
{
    traceline (Entmod_GetEyesPosition(), Entmod_GetAimTargetVector(), FALSE, self);

    if (trace_fraction == 1.0)
		return FALSE;

    if(trace_ent != world)
        return trace_ent;

    return FALSE;
}

vector(entity ignored) Entmod_GetAim =
{
    traceline (Entmod_GetEyesPosition() + aim(self,10000) * 2, Entmod_GetAimTargetVector(), FALSE, self);

    return trace_endpos;
}

void(entity ent,float entityStyle) Entmod_RenderEntity =
{
    local vector size = ent.absmax - ent.absmin;
    local vector center = ent.absmax - (size / 2);
    local vector eyes = self.origin + '0 0 16';

    local vector playerHeightAdjustedCenter = center;
    playerHeightAdjustedCenter_z = Entmod_math_clamp(eyes_z,ent.absmin_z,ent.absmax_z);


    local float boundsColor;

    switch(entityStyle) {
        default:
        case ENTMOD_ENTITY_NORMAL: boundsColor = 192; break;
        case ENTMOD_ENTITY_SUBENTITY: boundsColor = 231; break;
        case ENTMOD_ENTITY_MARKED: boundsColor = 184; break;
    }
    draw_bounds(ent.absmin,ent.absmax,boundsColor,0,FALSE);

    local vector textPlacement = playerHeightAdjustedCenter;
    draw_worldtext(ent.classname,textPlacement,0.1,FALSE,FALSE);

    if(ent.targetname) {
        textPlacement -= '0 0 4';
        draw_worldtext(ent.targetname,textPlacement,0.1,FALSE,FALSE);
    }

    if(ent.model) {
        textPlacement -= '0 0 4';
        draw_worldtext(ent.model,textPlacement,0.1,FALSE,FALSE);
    }

    // Draw targetting arrows
    if(entityStyle == ENTMOD_ENTITY_NORMAL && ent.target) {
        local vector myCenter = Entmod_GetBoundsCenter(entmod.selectedEntity);
        local entity targetEnt;
        while((targetEnt = find(targetEnt,targetname,ent.target)))
        {
            draw_arrow(myCenter,Entmod_GetBoundsCenter(targetEnt), 231,5, FALSE, FALSE);
            Entmod_RenderEntity(targetEnt, ENTMOD_ENTITY_SUBENTITY);
        }
    }
}

void() Entmod_RenderSelectionMarker =
{
    local entity targetEnt = Entmod_TraceForward();
    local float markerColor = 254;

    if(targetEnt)
        markerColor = 95;

    draw_sphere(trace_endpos,5.0,markerColor,0.001,TRUE);
}

float() Entmod_PlayerPreThink =
{
    if(entmod.selectedEntity)
        Entmod_RenderEntity(entmod.selectedEntity,ENTMOD_ENTITY_NORMAL);

    if(entmod.markedEntity)
        Entmod_RenderEntity(entmod.markedEntity,ENTMOD_ENTITY_MARKED);


    if(self.weapon == IT_SHOTGUN) {
        Entmod_RenderSelectionMarker();
    }


    // Handle moving mode
    if(entmod.mode == ENTMOD_MODE_MOVING) {
        local vector offset = self.origin - entmod.moverStartOrigin;

        local vector newOrigin = entmod.moveeStartOrigin + offset;

        if(entmod.gridAligned) {
            newOrigin_x = entmod.gridAligned * floor(newOrigin_x / entmod.gridAligned);
            newOrigin_y = entmod.gridAligned * floor(newOrigin_y / entmod.gridAligned);
            newOrigin_z = entmod.gridAligned * floor(newOrigin_z / entmod.gridAligned);
        }

        setorigin(entmod.selectedEntity,newOrigin);
    }

    return TRUE;
}

// Returns FALSE if overriding
float() Entmod_PlayerPostThink =
{
    if(self.weapon != IT_SHOTGUN)
        return TRUE;

    return FALSE;
}


void() Entmod_Attack_EntitySelect =
{
    // Effects
    player_shot1 ();
    sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);
    self.attack_finished = time + 0.5;

    // Try to select new entity
    local entity targetEnt = Entmod_TraceForward();

    // Deselect the entity
    if(entmod.selectedEntity) {
        entmod.selectedEntity = FALSE;
    }


    if(!targetEnt)
    {
        local entity foundEnt = world;

        local entity closestEnt = world;
        local float closestDist = 99999;

        while((foundEnt = nextent(foundEnt)))
        {
            local float dist = vlen(trace_endpos - Entmod_GetBoundsCenter(foundEnt));
            if(!closestEnt || dist < closestDist) {
                closestEnt = foundEnt;
                closestDist = dist;
            }
        }

        targetEnt = closestEnt;
    }

    if(targetEnt)
        entmod.selectedEntity = targetEnt;


}


void() Entmod_PlayerAttack_Think =
{
    if(!self.button0) {
        if(entmod.attackingMode == ENTMOD_ATTACKINGMODE_SELECT) {
            Entmod_Attack_EntitySelect();
        }
        else if(entmod.attackingMode == ENTMOD_ATTACKINGMODE_DRAG) {
            entmod.selectedEntity.owner = entmod.attackingOldOwner;
        }

        entmod.attackingMode = ENTMOD_ATTACKINGMODE_NONE;
        return;
    }

    dprint("Think\n");

    // Switch to drag mode
    if(entmod.attackingMode == ENTMOD_ATTACKINGMODE_SELECT && time >= entmod.attackTime + 0.25) {
        dprint("Now dragging\n");
        entmod.attackingMode = ENTMOD_ATTACKINGMODE_DRAG;

        entmod.attackingOldOwner = entmod.selectedEntity.owner;
        entmod.selectedEntity.owner = self;
    }

    if(entmod.attackingMode == ENTMOD_ATTACKINGMODE_DRAG) {
        local vector offset = Entmod_GetAim(entmod.selectedEntity) - entmod.moverStartOrigin;

        local vector newOrigin = entmod.moveeStartOrigin + offset;

        if(entmod.gridAligned) {
            newOrigin_x = entmod.gridAligned * floor(newOrigin_x / entmod.gridAligned);
            newOrigin_y = entmod.gridAligned * floor(newOrigin_y / entmod.gridAligned);
            newOrigin_z = entmod.gridAligned * floor(newOrigin_z / entmod.gridAligned);
        }

        setorigin(entmod.selectedEntity,newOrigin);
    }

    self.think = Entmod_PlayerAttack_Think;
    self.nextthink = time;
}

float() Entmod_PlayerAttack =
{
    if(self.weapon != IT_SHOTGUN)
        return TRUE;

    if(entmod.attackingMode == ENTMOD_ATTACKINGMODE_NONE)
    {
        self.think = Entmod_PlayerAttack_Think;
        self.nextthink = time;

        entmod.moverStartOrigin = Entmod_GetAim(self);
        entmod.moveeStartOrigin = entmod.selectedEntity.origin;

        entmod.attackingMode = ENTMOD_ATTACKINGMODE_SELECT;
        entmod.attackTime = time;
    }

    return FALSE;
}





void() Entmod_Error_NoEntitySelected =
{
    sprint(self,"No entity is selected\n");
}





void() Entmod_Command_Activate =
{
    entmod.active = TRUE;
    entmod.mode = ENTMOD_MODE_NONE;


    sprint(self,"Entmod activated\n");
    self.weapon = IT_SHOTGUN;
}

void() Entmod_Command_Deactivate =
{
    entmod.active = FALSE;
    sprint(self,"Entmod deactivated\n");
}

void() Entmod_Command_PrintEntity =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    eprint(entmod.selectedEntity);
}


void() Entmod_Command_GrabEntity =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    if(entmod.mode == ENTMOD_MODE_NONE) {
        entmod.mode = ENTMOD_MODE_MOVING;
        sprint(self,"Started moving entity\n");

        entmod.moverStartOrigin = self.origin;
        entmod.moveeStartOrigin = entmod.selectedEntity.origin;
    }
    else if(entmod.mode == ENTMOD_MODE_MOVING) {
        entmod.mode = ENTMOD_MODE_NONE;
        sprint(self,"Stopped moving entity\n");
    }
    else {
        sprint(self,"Invalid mode\n");
    }
}

void() Entmod_Command_Copy =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();


    local string targetClass = entmod.selectedEntity.classname;
    if(targetClass == "func_wall" || targetClass == "func_plat" || targetClass == "func_door" || targetClass == "func_button" || targetClass == "train")
    {
        local entity newEnt = spawn();
        newEnt.origin = entmod.selectedEntity.origin;
        newEnt.model = entmod.selectedEntity.model;
        newEnt.classname = "func_wall";

        local entity oself = self;
        self = newEnt;
        func_wall();
        self = oself;

        entmod.selectedEntity = newEnt;

        sprint(self,"Entity copied into func_wall\n");
    }
}

void() Entmod_Command_Rotate =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.selectedEntity.angles_y += 90;

    sprint(self,"Entity rotated\n");
}


void() Entmod_Command_Remove =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    sprint(self,"Entity removed\n");

    remove(entmod.selectedEntity);

    entmod.selectedEntity = world;
}

void() Entmod_Command_Set_Alpha =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.selectedEntity.alpha = Entmod_Get_Command_Argument1();

    sprint(self,"Entity toggled\n");
}

void() Entmod_Command_Mark =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.markedEntity = entmod.selectedEntity;

    sprint(self,"Entity marked\n");
}

void() Entmod_Command_UnMark =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.markedEntity = entmod.selectedEntity;

    sprint(self,"Entity un-marked\n");
}

void() Entmod_Command_ClearMarked =
{
    entmod.markedEntity = world;

    sprint(self,"Cleared marked entities\n");
}

void() Entmod_Command_GridAlign =
{
    local float s2 = Entmod_Get_Command_Argument1();

    if(entmod.gridAligned || !s2) {
        entmod.gridAligned = 0;
        sprint(self,"Removed grid alignment\n");
    }
    else {

        entmod.gridAligned = s2;

        sprint(self,"Set grid alignment to: ");
        sprint(self,ftos(entmod.gridAligned));
        sprint(self,"\n");
    }
}

void() Entmod_Command_Set_Effects =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.selectedEntity.effects = Entmod_Get_Command_Argument1();

    sprint(self,"Set effects to: ");
    sprint(self,ftos(entmod.selectedEntity.effects));
    sprint(self,"\n");
}



void() Entmod_Command_Set_BrushModel_Think =
{
    setmodel(entmod.selectedEntity,self.netname);
}

void() Entmod_Command_Set_BrushModel =
{


    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    local float modelId = Entmod_Get_Command_Argument1();

    if(!modelId) {
        sprint(self,"No model set. Set the model number in scratch2\n");
        return;
    }

    local string oldnetname = self.netname;


    entmod.killOverride = Entmod_Command_Set_BrushModel_Think;

    // Dynamic string
    localcmd("cl_name *");
    localcmd(ftos(modelId));
    localcmd(";name *");
    localcmd(ftos(modelId));
    localcmd(";kill\n");
}
void() Entmod_HandleCommand =
{
    // Only the host can do it
    if(self != find(world,classname,"player"))
        return;

    if(!entmod.active)
    {
        Entmod_Command_Activate();
        return;
    }

    local float scratch = cvar("scratch1");
    switch(scratch) {
        default: sprint(self,"Unknown entmod command\n"); break;
        case 0: Entmod_Command_Deactivate(); break;
        case 1: Entmod_Command_PrintEntity(); break;
        case 2: Entmod_Command_Copy(); break;
        case 3: Entmod_Command_GrabEntity(); break;
        case 4: Entmod_Command_Rotate(); break;
        case 5: Entmod_Command_Remove(); break;
        case 6: Entmod_Command_Set_Alpha(); break;
        case 7: Entmod_Command_Mark(); break;
        case 8: Entmod_Command_UnMark(); break;
        case 9: Entmod_Command_ClearMarked(); break;
        case 10: Entmod_Command_GridAlign(); break;
        case 11: Entmod_Command_Set_BrushModel(); break;
        // case 12: break;
        case 13: Entmod_Command_Set_Effects(); break;
    }

}

float() Entmod_HandleImpulse =
{
    if(self.impulse == 80) {
		Entmod_HandleCommand();
        return FALSE;
    }


    return TRUE;
}


/*
===========================
Hooks into regular mod code
===========================
*/
#pragma warning disable F321
__accumulate void() worldspawn =
{
    localcmd("alias \"entmod\" \"scratch1 0;impulse 80\"\n");
    localcmd("alias \"ent_print\" \"scratch1 1;impulse 80\"\n");
    localcmd("alias \"ent_copy\" \"scratch1 2;impulse 80\"\n");
    localcmd("alias \"ent_move\" \"scratch1 3;impulse 80\"\n");
    localcmd("alias \"ent_rotate\" \"scratch1 4;impulse 80\"\n");
    localcmd("alias \"ent_remove\" \"scratch1 5;impulse 80\"\n");
    localcmd("alias \"ent_set_alpha\" \"scratch1 6;impulse 80\"\n");
    localcmd("alias \"ent_mark\" \"scratch1 7;impulse 80\"\n");
    localcmd("alias \"ent_unmark\" \"scratch1 8;impulse 80\"\n");
    localcmd("alias \"ent_clearmarked\" \"scratch1 9;impulse 80\"\n");
    localcmd("alias \"ent_gridalign\" \"scratch1 10;impulse 80\"\n");
    localcmd("alias \"ent_apply_brushmodel\" \"scratch1 11;impulse 80\"\n");
    //localcmd("alias \"ent_apply_message\" \"scratch1 12;impulse 80\"\n");
    localcmd("alias \"ent_apply_effects\" \"scratch1 13;impulse 80\"\n");

    localcmd("sv_cheats 1\n");


    entmod.attackingMode = ENTMOD_ATTACKINGMODE_NONE;
}
#pragma warning enable F321

__wrap void() PlayerPreThink =
{
    prior();

    if(entmod.active) {
        Entmod_PlayerPreThink();
    }
}

__wrap void() PlayerPostThink =
{
    prior();

    W_WeaponFrame();
}

__wrap void() ImpulseCommands =
{
    if(!Entmod_HandleImpulse()) {
        self.impulse = 0;
        return;
    }

    prior();
}

__wrap void() W_Attack =
{
    if(entmod.active && !Entmod_PlayerAttack())
        return;

    prior();
}

__wrap void() ClientKill =
{
    if(entmod.killOverride)
    {
        entmod.killOverride();
        entmod.killOverride = __NULL__;

        return;
    }

    prior();
}