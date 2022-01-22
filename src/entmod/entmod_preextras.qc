/*
Prevent game from crashing if attempting to precache a model or sound after the precaching is already done
*/
#define precache_model(s) if(framecount == 0) { precache_model_actual(s); }(void)__NULL__
#define precache_sound(s) if(framecount == 0) { precache_sound_actual(s); }(void)__NULL__

