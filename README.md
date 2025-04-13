# notes for testing 
## installation
* install the script: `;install https://github.com/jaseknighter/kinesis`
* restart the norns
* load kinesis

## quick start
at the moment, the script loads into sun mode #3, which uses the moonshine engine (renamed `Engine_Kinesis`)

## play notes with sun mode 2
### start notes playing
* turn e3 to change the second sun's notes

### record and play note changes
* press k3 (notice the `1r-` changes to `1r+`)
* turn e3 to record some note changes
* press k3 (notice the `1r+` changes back to `1r-`)

a notes about notes
* after recording, each note will randomply play itself at 1 octave below, 1 above, 2 above, or at its defined frequency regular
* when sun 2 is playing recorded notes, its division will switch between 1/16 and 1/32 at the end of its loop

### start the filter
* k1+e3 to rotate sun1 to face the next ray (`1r-` should now say `5r-`)
* turn e3 change the filter (same as for notes)
* press k3, record filter changes, and press k2 again (same as for notes)

a note about the filters
* when sun 2 is playing recorded filter changes, the swing of its notes will switch between 0 and 10 at the end of its loop

## modulate softcut
* turn e2. currently, this causes the softcut rate to switch bewtween 1 and 2. it is triggered when the lighted photon arrives at every other ray


## switching modes
* k1 + k2/k3 to switch modes
* the other modes don't do anything musical yet
* mode 4, has no interactivity built in



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
