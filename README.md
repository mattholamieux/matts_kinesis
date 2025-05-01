'tho musical out of the box, the kinesis script was written for the 2025 habitus workshops and is meant to be tinkered with by folks with a beginning-intermediate level of norns-scripting  experience...for example, folks who have completed the [norns studies](https://monome.org/docs/norns/studies/) but aren't quite ready to create a whole script from scratch.

the notes below cover installation, quick start (for making sounds) and some ideas for modifying the script.

also, extensive comments have been added to the code that help explain how it works and provide suggestions for further modification/exploration.

########################################
# installation
########################################
* `;install https://github.com/jaseknighter/kinesis`
* restart norns 
* load the script

########################################
# quick start
########################################
by default:
* the left sun is set to granulate audio from norns input (using a new SuperCollider engine called `sunshine`)
* the right sun processes audio with softcut

## sun 1: granulate audio
on load, the sunshine engine immediately starts granulating the norns' audio input. each ray controls a different grain synth param (aka `engine command`). 

k1+e2: switch between grain synth params.

the name of the grain synth param and its value are shown on the screen to the right of the sun at the top and bottom. the param names are abbreviated:

* "sp": `engine.speed` (default: 1)
* "dn": `engine.density` (rate of grain generation. default: 1 grain per second)
* "ps": `engine.pos` (scrub the grain player's playhead)
* "sz": `engine.size` (default: 0.1)
* "jt": `engine.jitter` (default: 0)
<!-- * "we": `engine.buf_win_end` (size of the window that can be granulated. default: 1) -->
* "ge": `engine.env_shape` (the shape of the grain envelope. default: 6)
* "rl": `engine.rec_level` (recording level. default: 1)
* "pl": `engine.pre_level` (prerecording level. default: 0)

### grain envelopes
the ray controlling the grain envelopes (`ge`), switches between six shapes:
* exponential (ray value: 1.0)
* squared (ray value: 2.0)
* linear (ray value: 3.0)
* sine (ray value: 4.0)
* cubed (ray value: 5.0)
* welches (ray value: 6.0)

### play and record engine command modulations
* select a param (using k1+e2)
* press k2 (notice the `-` changes to `+`) to start recording
* turn e2 to record some param changes
* press k2 (notice the `+` changes back to `-`) to end recording

### stop/erase engine command modulations
* press k2 twice to clear the recording of the selected engine command

### freeze grains
* let the grains emit for about 10 seconds to fill the recording buffer
* set speed (sp) to 0
* set pre-record level to 1 (pl)
* set record level to 0 (rl)
* change positions (pos) to scrub the play head 

alternatively, use the `freeze grains` trigger in the params menu. 

### reset grain phase
the `reset grain phase` trigger in the params menu regenerates the supercollider grain player. it is meant to be used to sync the beat of the grains with other music (e.g. when playing in an ensemble.)

### switch to play an audio file
* select an audio file with the `sample` param file selector
* set mode to `recorded` with the `set mode` param

## sun 2: audio mangling with softcut
by default, the 2nd sun is configured to switch the softcut rate between 1 and 2. it is triggered when the lighted photon arrives at every other ray.

to start softcut rate switching, turn e3 until you see the sun pulsating. the velocity at which you turn e3 gets translated into the speed at which the softcut rate switches between 1 and 2.

to stop rate switching, turn e3 in the opposite direction.


## switching sun modes
k1 + k2: switch the mode of the sun 1
k1 + k3: switch the mode of the sun 2

each sun can operate in one of four modes

* mode 1
  * ui behavior: turning e2 or e3 moves photons around the sun
  * sound behavior: softcut rate switching
* mode 2 
  * ui behavior: the movement of photons in each ray controls the value of the SuperCollider engine command mapped to the ray
  * sound behavior: live/recorded granular synthesis
* mode 3
  * ui behavior: encoders activate a photon moving around its sun
  * sound behavior: nothing by default. up to you to define
* mode 4
  * ui behavior: same as mode 1
  * sound behavior: nothing by default. up to you to define

########################################
# modifying and exploring the script
########################################
## about the code
conceptually, the script is made up two "suns" and each sun operates independently in one of four modes:

the code is organized hierarcically like so:

* kinesis.lua: the main file for the script (containing the `init` function norns will run when the script is first loaded)
  * sun.lua: sets the visual elements of the sun (e.g., number of rays) and handles the switching between the different modes (see the `Sun:enc` function)
  * sun_mode_X.lua: the ui and sound behavior is defined in these four files
  * ray.lua: code for setting the size and position of each of the sun's rays.
  * photon.lua: code for each of the sun's "photons."  
* Engine_sunshine.sc: SuperCollider granular synth engine
* utilities.lua: misc lua functions used by multiple files

## simple modifications/explorations
note: restart the script before trying each of the modifications below.
### sun.lua
* change the number of rays (`NUM_RAYS`)
* change the number of photons per ray (`PHOTONS_PER_RAY`)
* change the value of the `sun_modes` variable in the kinesis.lua file so the suns start up with a different sun mode (use values `1`,`2`,`3`, or `4`) 
### sun_mode_1.lua (softcut)
* softcut rate
  * find the code at the bottom of the sun_mode_1.lua file that changes softcut rate and modify the values.
* other things to try:
  * softcut.position(2,0)
  * softcut.rate_slew_time (2,5)
  * softcut.rec_level (2,0.5);softcut.pre_level(2,0.5)
  * softcut.loop_end(2,1)

### sun_mode_2.lua (sunshine granular synth, lua code)
* engine initialization
  * find the `init_engine_commands` function
  * change the default value for `engine.density`
  * change the default values for other engine commands
  * replace one of the commands in the engine_commands table with the `engine.buf_win_end` command
* change default grain mode from live to recorded
  * find the comment in sun_mode_2.lua "switch to granulate an audio file by default"
  * uncomment the two lines that set the `sample` and `grain_mode` params
  * be sure to add a file path to a file on your norns (see the note in the code)

### sun_mode_3.lua
* with k1+k3: switch the 2nd sun to mode 3
* photon velocity
  * in the REPL, run `suns[2]:set_velocity_manual(1)`
  * what happens when different values are passed to the function (e.g., `suns[2]:set_velocity_manual(-10)`)?
  * review the `set_velocity_manual` function in sun.lua to understand how it works
  * review the `sign` function in utilities.lua to understand how it gets used by `set_velocity_manual`.
* active photons
  * play with the `active_photons` variable. what happens if the initial values are changed? what happens if there are fewer or additional values in the `active_photons` table?
* callbacks
  * uncomment the print statements in the `sun_mode_3.photon_changed` and `sun_mode_3.ray_changed` functions. restart the script and move the photons around with e3 to understand the conditions when these print statements trigger?
## intermediate/advanced modifications/explorations
### sun_mode_.lua (softcut)