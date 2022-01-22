#define ENTMOD_COMMAND_ID 1

#define INCREMENT_ENTMOD_COMMAND_ID \
#append ENTMOD_COMMAND_ID +1

#define DEFINE_ENTMOD_COMMAND(command,handler) __accumulate void() Entmod_CreateAliases =\
{\
    localcmd("alias \""#command"\" \"scratch1 ");\
    localcmd(ftos(ENTMOD_COMMAND_ID));\
    localcmd(";impulse ");\
    localcmd(ftos(ENTMOD_IMPULSE));\
    localcmd("\"\n");\
}\
__wrap float(float cmdId) Entmod_HandleCommand_Execute =\
{\
    if(cmdId == ENTMOD_COMMAND_ID) { ##handler(); return 1; }\
    return prior(cmdId);\
}\
INCREMENT_ENTMOD_COMMAND_ID


#define ENTMOD_REGISTER_ENTITY(entityClassname) __accumulate float() Entmod_InitializeEntitySelf =\
{\
    if(self.classname == #entityClassname) { entityClassname(); return 1; }\
}
