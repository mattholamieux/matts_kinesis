# notes for testing 
## installation
* install the script: `;install https://github.com/jaseknighter/kinesis`
* restart the norns
* load kinesis

## quick start
by default:
* the left sun (1) is set to granulate audio from norns input (using the new sunshine engine)
* the right sun (2) does softcut stuff 

## granulate audio from norns inputs with sun 1 (in mode 2)
on load, the sunshine engine immediately starts granulating audio input. each ray controls a different grain synth param (aka engine command). note, we aren't actually using norns params for this, just rolling our own system for now...

the name of the grain synth param and its value are shown on the screen to the right of the sun at the top and bottom. the param names are abbreviated:

* "sp": engine.speed (default: 1)
* "dn": engine.density (rate of grain generation. default: 1 grain per second)
* "ps": engine.pos (scrub the grain player's playhead)
* "sz": engine.size (default: 0.1)
* "jt": engine.jitter (default: 0)
<!-- * "we": engine.buf_win_end (size of the window that can be granulated. default: 1) -->
* "es": engine.env_shape (the shape of the grain envelope. default: 6)
* "rl": engine.rec_level (recording level. default: 1)
* "pl": engine.pre_level (prerecording level. default: 0)

grain envelope shapes are:
* exponential
* squared
* linear
* sine
* cubed
* welches

### switch between grain synth params
* (sun1) k1+e2

### record and play param modulations
* select a param
* press k2 (notice the `-` changes to `+`)
* turn e2 to record some param changes
* press k2 (notice the `+` changes back to `-`)
* select a different param and repeat the steps

### freeze and scrub grains with a static buffer
* reload script to get back to default params
* let the grains emit for about 10 seconds to fill the recording buffer
* set speed (sp) to 0
* set pre-record level to 1 (pl)
* set record level to 0 (rl)
* change positions (pos) to scrub the play head 

alternatively, use the `freeze grains` trigger in the params menu. 

### reset grain phase
the `reset grain phase` trigger in the params menu regenerates the supercollider grain player. it is meant to be used to sync the beat of the grains with other music (e.g. when playing in an ensemble)

### switch to play an audio file
* select an audio file with the `sample` param file selector
* set mode to `recorded` with the `set mode` param


## modulate softcut with sun 2 (in mode 1)
* turn e2. currently, this causes the softcut rate to switch bewtween 1 and 2. it is triggered when the lighted photon arrives at every other ray

## switching modes
* k1 + k2/k3 to switch modes
* the other modes don't do anything musical yet
* mode 4, has no interactivity built in

## todo
* fix bugs (see comments in main `kinesis.lua` file for details on known bugs)
* update code comments
* consider having two grain voices (one per sun) so they aren't clobbering each other when both suns are set to mode 2
* finish coding a mode to granulate an audio file
* finish coding ability to swich between modes
* add ability to reset the phase of the density trigger so multiple players can manually sync up with each other
* add code/comments for workshop attendees to add pitch control

# (in progress) notes for the class
important notes
* if adding additional sun modes
  * create a new sun_mode_[num].lua file in the lib folder
  * add an include for the new mode file created in the prior step in the `sun.lua` file. for example:
  `local sun_mode_5 = include "lib/sun_mode_5"`
  * update `num_sun_modes` in the `sun.lua` file
* warning if you are calling a function with `.` instead of `:` (warning is like: `attempt to index a number value (local 'self')`). if you get this warning, ask about `syntactic sugar`

things to try
note: you may want to duplicate a line of code and comment it out before making changes so it is easier to return to the original code.

* change number of rays
* change number of photons per ray
* change photon size
* morphing function
* set brightness
* set mode to 2 and run `set_velocity_manual`
* morph a photon:
suns[1].rays[1]:morph_photon(4,0,15,0.25,15,nil,function(next_val, done, id) print("extcb",next_val, done, id) end,123)
* set multiple photons active: 
suns[1]:set_active_photons ({{1,4},{3,4},{5,4},{7,4},{9,4},{11,4},{13,4},{15,4}})


suns[1]:set_active_photons ({{1,1},{3,2},{5,3},{7,4},{9,5},{11,6},{13,7},{15,8}})
