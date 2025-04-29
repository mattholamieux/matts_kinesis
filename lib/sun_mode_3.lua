-- lib/sun_mode_3.lua
-- softcut
-- this mode uses the softcut module
-- Reference: https://monome.org/docs/norns/softcut/ 

local sun_mode_3 = {}

function sun_mode_3.init(self)
  -- create state variables 
  self.active_photons = {3,22}

  -- assign callbacks (defined below) to handle events when a photon or ray changes
  self.photon_changed_callback  = sun_mode_3.photon_changed
  self.ray_changed_callback     = sun_mode_3.ray_changed

  -- call update state (defined in sun.lua) to
  self:update_state()

  ------------------------------------------
  -- deinit
  -- remove any variables or tables that might stick around
  -- after switching to a different sun mode
  -- for example: a lattice or reflection instance
  ------------------------------------------
  self.deinit = function()
    print("deinit sun mode: 3")
    self.photon_changed_callback  = nil
    self.ray_changed_callback     = nil
  end  

end

function sun_mode_3.photon_changed(self,ray_id,photon_id)
  -- do something when the photon changes
  -- print("photon changed",self.index,ray_id,photon_id)
end

function sun_mode_3.ray_changed(self,ray_id,photon_id)
  -- do something when the ray changes
  -- print("ray changed",self.index,ray_id,photon_id)
end

function sun_mode_3.enc(self, n, delta)
  if n==1 then return end
  self:set_active_photons_rel(delta)
end

function sun_mode_3.key(self, n, z)
  -- do something when a key is pressed
end


function sun_mode_3.redraw(self)
  -- draw something here
end

return sun_mode_3
