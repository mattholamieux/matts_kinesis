'tho musical out of the box, the kinesis script was written for the habitus workshop and is meant to be tinkered with by folks at a beginning-intermediate level of norns-scripting comfort...for example, folks who have completed the [norns studies](https://monome.org/docs/norns/studies/) but aren't quite ready to create a whole script from scratch.

the notes below cover installation, quick start (for making sounds) and ideas for modifying the script.

also, extensive comments have been added to the code to help explain how it works and provide suggestions for further modification/exploration.

########################################
# installation
########################################
* install the script: `;install https://github.com/jaseknighter/kinesis`
* restart the norns
* load kinesis

########################################
# quick start
########################################
by default:
* the left sun is set to granulate audio from norns input (using a new SuperCollider engine called `sunshine`)
* the right sun processes audio with softcut

## granulate audio (sun1)
on load, the sunshine engine immediately starts granulating audio input. each ray controls a different grain synth param (aka `engine command`). 

switch between grain synth params with k1+e2.

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

### grain envelope
the ray controlling the grain envelopes (`ge`), provides six envelope shapes. they are:
* exponential (1.0)
* squared (2.0)
* linear (3.0)
* sine (4.0)
* cubed (5.0)
* welches (6.0)

### record and play param modulations
* select a param (using k1+e2)
* press k2 (notice the `-` changes to `+`) to start recording
* turn e2 to record some param changes
* press k2 (notice the `+` changes back to `-`) to end recording

### stop/erase param modulations
* press k2 twice

### freeze grains
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


## audio mangling with softcut (sun 2)
by default, the 2nd sun is configured to switch the softcut rate between 1 and 2. it is triggered when the lighted photon arrives at every other ray.

to start softcut rate switching, turn e3 until you see the sun pulsating. the velocity at which you turn e3 gets translated into the speed at which softcut switches between 1 and 2.

to stop rate switching, turn e3 in the opposite direction.


## switching modes
* k1 + k2/k3 to switch modes of the two suns

########################################
# modifying and exploring the script
########################################
## about the code
conceptually, the script is made up two "suns" and each sun operates independently in one of four modes:

* mode 1
  * ui behavior: turning an encoder moves photons around the sun
  * sound behavior: softcut
* mode 2 
  * ui behavior:   the movement of photons in each ray gets recorded  and played back (using the reflection library)
  * sound behavior: softcut
* mode 3
  * ui behavior: encoders activate a photon moving around its sun
  * sound behavior: nothing by default. up to you to define
* mode 4
  * ui behavior: same as mode 1
  * sound behavior: nothing by default. up to you to define

the code is organized hierarcically like so:

* kinesis.lua: the main file for the script (containing the `init` function norns will run when the script is first loaded)
* sun.lua: sets the visual elements of the sun (e.g., number of rays) and handles the switching between the different modes (see the `Sun:enc` function)
* sun_mode_X.lua: the ui and sound behavior is defined in these four files
* ray.lua: code for setting the size and position of each of the sun's rays.
* photon.lua: code for each of the sun's "photons."  

## simple modifications/explorations
### sun.lua modifications
* switch to a different "sun mode" (see the `sun_modes` varialbe in the kinesis.lua file)
* change number of rays 
* change number of photons per ray
* change photon size
* ADD ADDITIONAL SIMPLE MODIFICATIONS
### sun_mode 1 (softcut)
* photon velocity
  * in the REPL, run `suns[2]:set_velocity_manual(1)`
  * what happens when different values are passed to the function (e.g., `suns[2]:set_velocity_manual(10)`)?
  * why do you get an error message when you run `suns[2].set_velocity_manual(1)`?
  * review the code in sun.lua to understand how the `set_velocity_manual` function works
* softcut rate
  * find the code at the bottom of the sun_mode_1.lua file that changes softcut rate and modify the values.
### photon modifications
  * set multiple photons active: 
`suns[1]:set_active_photons ({{1,4},{3,4},{5,4},{7,4},{9,4},{11,4},{13,4},{15,4}})`
* ADD ADDITIONAL MODIFICATIONS/EXPLORATIONs

## more advanced stuff
### add an additional sun mode
* create a new sun_mode_[num].lua file in the lib folder (e.g. sun_mode5.lua)
* add an include for the new mode file created in the prior step in the sun.lua file. for example:
  `local sun_mode_5 = include "lib/sun_mode_5"`
* update `num_sun_modes` in the sun.lua file
### ADD MORE ADVANCED STUFF
