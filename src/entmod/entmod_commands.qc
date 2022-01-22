__accumulate void() Entmod_CreateAliases =
{
    localcmd("alias \"entmod\" \"scratch1 0;impulse 80\"\n");
}



void() Entmod_Command_PrintEntity =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    eprint(entmod.selectedEntity);
}
DEFINE_ENTMOD_COMMAND(ent_print,Entmod_Command_PrintEntity)


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
        sprint(self,Entmod_GetOperationName(entmod.mode));
        sprint(self," operation already in progress\n");
    }
}
DEFINE_ENTMOD_COMMAND(ent_grab,Entmod_Command_GrabEntity)


void() Entmod_Command_Copy_Brush =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    if(entmod.selectedEntity.model != "" && Entmod_IsEntityBrushModel(entmod.selectedEntity))
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

        sprint(self,"Brush entity copied into a func_wall (");
        sprint(self,newEnt.model);
        sprint(self,")\n");
    }
}
DEFINE_ENTMOD_COMMAND(ent_copybrush,Entmod_Command_Copy_Brush)


void() Entmod_Command_Copy =
{
    if(!entmod.selectedEntity)
    return Entmod_Error_NoEntitySelected();

    if(entmod.mode == ENTMOD_MODE_NONE) {
        entmod.mode = ENTMOD_MODE_COPYING;
        sprint(self,"Started copying entity\n");

        entmod.moveeStartOrigin = entmod.selectedEntity.origin;
        entmod.moverStartOrigin = self.origin;

        local entity ghost = spawn();
        ghost.owner = entmod.selectedEntity;
        ghost.origin = ghost.owner.origin;
        setmodel(ghost,ghost.owner.model);
        ghost.skin = ghost.owner.skin;
        ghost.solid = SOLID_NOT;
        ghost.alpha = 0.5;
        ghost.angles = ghost.owner.angles;

        entmod.selectedEntity = ghost;
    }
    else if(entmod.mode == ENTMOD_MODE_COPYING) {
        entmod.mode = ENTMOD_MODE_NONE;

        local entity ghost = entmod.selectedEntity;
        local entity original = ghost.owner;

        ghost.alpha = 1;
        ghost.solid = original.solid;
        ghost.classname = original.classname;
        ghost.message = original.message;
        ghost.spawnflags = original.spawnflags;
        ghost.target = original.target;
        ghost.targetname = original.targetname;
        ghost.lip = original.lip;
        ghost.wait = original.wait;
        ghost.angles = original.angles;
        ghost.mangle = original.mangle;
        ghost.sounds = original.sounds;
        ghost.owner = original.owner;
        ghost.speed = original.speed;

        local entity oself = self;
        self = ghost;

        if(!Entmod_InitializeEntitySelf()) {
            self = oself;

            sprint(self,"Stoped copying entity. NOTE: No entity initializer found for: ");
            sprint(self,ghost.classname);
            sprint(self,"\n");
        }
        else {
            self = oself;

            sprint(self,"Stopped copying entity.\n");
        }

        entmod.selectedEntity = ghost;
    }
    else {
        sprint(self,Entmod_GetOperationName(entmod.mode));
        sprint(self," operation already in progress\n");
    }
}
DEFINE_ENTMOD_COMMAND(ent_copy,Entmod_Command_Copy)


void() Entmod_Command_Rotate_X =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.selectedEntity.angles_x += 15;

    sprint(self,"Entity rotated in X\n");
}
DEFINE_ENTMOD_COMMAND(ent_rotate_x,Entmod_Command_Rotate_X)


void() Entmod_Command_Rotate_Y =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.selectedEntity.angles_y += 15;

    sprint(self,"Entity rotated in Y\n");
}
DEFINE_ENTMOD_COMMAND(ent_rotate_y,Entmod_Command_Rotate_Y)


void() Entmod_Command_Rotate_Z =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.selectedEntity.angles_z += 15;

    sprint(self,"Entity rotated in Z\n");
}
DEFINE_ENTMOD_COMMAND(ent_rotate_z,Entmod_Command_Rotate_Z)


void() Entmod_Command_Remove =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    sprint(self,"Entity removed\n");

    remove(entmod.selectedEntity);

    entmod.selectedEntity = world;
}
DEFINE_ENTMOD_COMMAND(ent_remove,Entmod_Command_Remove)


void() Entmod_Command_Mark =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.markedEntity = entmod.selectedEntity;

    sprint(self,"Entity marked\n");
}
DEFINE_ENTMOD_COMMAND(ent_mark,Entmod_Command_Mark)


void() Entmod_Command_UnMark =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.markedEntity = entmod.selectedEntity;

    sprint(self,"Entity un-marked\n");
}
DEFINE_ENTMOD_COMMAND(ent_unmark,Entmod_Command_UnMark)


void() Entmod_Command_ClearMarked =
{
    entmod.markedEntity = world;

    sprint(self,"Cleared marked entities\n");
}
DEFINE_ENTMOD_COMMAND(ent_clearmarked,Entmod_Command_ClearMarked)


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
DEFINE_ENTMOD_COMMAND(ent_gridalign,Entmod_Command_GridAlign)


void() Entmod_Command_Set_Alpha =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.selectedEntity.alpha = Entmod_Get_Command_Argument1();

    sprint(self,"Set entity alpha to: ");
    sprint(self,ftos(entmod.selectedEntity.alpha));
    sprint(self,"\n");
}
DEFINE_ENTMOD_COMMAND(ent_set_alpha,Entmod_Command_Set_Alpha)


void() Entmod_Command_Set_Effects =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    entmod.selectedEntity.effects = Entmod_Get_Command_Argument1();

    sprint(self,"Set entity effects to: ");
    sprint(self,ftos(entmod.selectedEntity.effects));
    sprint(self,"\n");
}
DEFINE_ENTMOD_COMMAND(ent_set_effects,Entmod_Command_Set_Effects)


void() Entmod_Command_Set_BrushModel_Think =
{
    setmodel(entmod.selectedEntity,self.netname);

    sprint(self,"Set entity model to: ");
    sprint(self,entmod.selectedEntity.model);
    sprint(self,"\n");
}

void() Entmod_Command_Set_BrushModel =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    local float modelId = Entmod_Get_Command_Argument1();

    if(!modelId) {
        sprint(self,"Error: No model set. Set the model number in scratch2 cvar\n");
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
DEFINE_ENTMOD_COMMAND(ent_set_brushmodel,Entmod_Command_Set_BrushModel)



#define EXPORT_KV_STRING(key,value) {\
    dprint("\t\""#key"\"\t\t\"");\
    dprint(value);\
    dprint("\"\n");\
}(void)__NULL__

#define EXPORT_KV_FLOAT(key,value) {\
    dprint("\t\""#key"\"\t\t\"");\
    dprint(ftos(value));\
    dprint("\"\n");\
}(void)__NULL__

#define EXPORT_KV_VECTOR(key,value) {\
    local vector v = value;\
    dprint("\t\""#key"\"\t\t\"");\
    dprint(ftos(v_x));\
    dprint(" ");\
    dprint(ftos(v_y));\
    dprint(" ");\
    dprint(ftos(v_z));\
    dprint("\"\n");\
}(void)__NULL__

void() Entmod_Command_Export =
{
    if(!entmod.selectedEntity)
        return Entmod_Error_NoEntitySelected();

    local entity ent = entmod.selectedEntity;

    dprint("{\n");
    EXPORT_KV_STRING(classname,ent.classname);

    if(ent.origin != '0 0 0') EXPORT_KV_VECTOR(origin,ent.origin);
    if(ent.angles != '0 0 0') EXPORT_KV_VECTOR(angles,ent.angles);
    if(ent.spawnflags != 0) EXPORT_KV_FLOAT(light,ent.spawnflags);
    if(ent.wait != 0) EXPORT_KV_FLOAT(wait,ent.wait);
    if(ent.sounds != 0) EXPORT_KV_FLOAT(sounds,ent.sounds);
    if(ent.health != 0) EXPORT_KV_FLOAT(health,ent.health);
    if(ent.lip != 0) EXPORT_KV_FLOAT(lip,ent.lip);
    if(ent.speed != 0) EXPORT_KV_FLOAT(speed,ent.speed);
    if(ent.targetname != "") EXPORT_KV_STRING(targetname,ent.targetname);
    if(ent.message != "") EXPORT_KV_STRING(message,ent.message);
    if(ent.target != "") EXPORT_KV_STRING(target,ent.target);
    if(ent.model != "") EXPORT_KV_STRING(model,ent.model);

    dprint("}\n");
}
DEFINE_ENTMOD_COMMAND(ent_export,Entmod_Command_Export)