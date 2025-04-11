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
