# QEEntmod
A Quake Enhanced mod to manipulate entities. Inspired by the Half-Life metamod plugin 'Entmod'
Can be used standalone or easily implemented into another mod.

**Note that the mod is very much not polished. Some commands don't work properly and there can be crashes if you don't know what you're doing**

## How to use
* Install the mod as you would any other mod
* Start a map and type in the console `entmod`
* Use shotgun weapon to select and move entities
* Use other commands to do more advanced operations


## Commands
### entmod
Activates or disables the mod. Only the host can do it.

### ent_grab
Starts and stops moving the selected entity in relation to the player position.

### ent_copybrush
Copies the brush model of the selected entity into a new func_wall entity.

### ent_copy
Starts copying procedure, acting like ent_grab. When called again, will stop the copying procedure and attempt to initialize the entity at the new location.

### ent_rotate_x
Rotates the entity angle X in 15 degrees.

### ent_rotate_y
Rotates the entity angle Y in 15 degrees.

### ent_rotate_z
Rotates the entity angle Z in 15 degrees.

### ent_remove
Deletes the currently selected entity.

### ent_mark
Marks an entity for bulk operations.

### ent_unmark
Unmarks an entity for bulk operation.

### ent_clearmarked
Clears all marked entities

### ent_gridalign
Sets grid snapping for entities when moving them. Specify the grid units in `scratch2` cvar. Example: `scratch2 8` - Snaps entities every 8 units

### ent_set_alpha
Sets the alpha (specified in `scratch2` cvar) of the currently selected entity. 

### ent_set_brushmodel
Sets the model of the currently selected entity to a specific brush model. For example, set it to brush model 5. `scratch2 5` `ent_set_brushmodel`

### ent_set_effects
Sets the effects of the currently selected entity to the value from `scratch2` cvar.

### ent_export
Outputs the selected entity into the console in .map entity format