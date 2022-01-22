#include "entmod_defs.qc"
#include "entmod_macros.qc"

#define ENTMOD_IMPULSE 80

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
    sprint(self,"Error: No entity is selected\n");
}



float(float commandId) Entmod_HandleCommand_Execute =
{
    return 0;
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

    if(!Entmod_HandleCommand_Execute(scratch))
        sprint(self,"Unknown entmod command\n");
}

float() Entmod_HandleImpulse =
{
    if(self.impulse == ENTMOD_IMPULSE) {
		Entmod_HandleCommand();
        return FALSE;
    }

    return TRUE;
}


#include "entmod_commands.qc"

/*
===========================
Hooks into regular mod code
===========================
*/
#pragma warning disable F321
__accumulate void() worldspawn =
{
    Entmod_CreateAliases();

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

