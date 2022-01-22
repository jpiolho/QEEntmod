/*
====
Defs
====
*/
enum {
    ENTMOD_MODE_NONE,
    ENTMOD_MODE_MOVING,
    ENTMOD_MODE_COPYING
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
    float moveeDistance;

    entity copyingGhost;

    float gridAligned;
} entmod_t;

entmod_t entmod;

.entity entchain;