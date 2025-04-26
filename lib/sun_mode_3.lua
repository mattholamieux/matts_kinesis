-- lib/sun_mode_3.lua
local sun_mode_3 = {}

function sun_mode_3.init(self)
  -- add code here to do create state variables 
  -- required for sun mode 1  
  self.active_photons = {1,9}
  self.photon_changed_callback  = sun_mode_3.photon_changed
  self.ray_changed_callback     = sun_mode_3.ray_changed

  self:update_state()

  ------------------------------------------
  -- deinit
  -- remove any variables or tables that might stick around
  -- after switching to a different sun mode
  -- for example: a lattice or reflection instance
  ------------------------------------------
  self.deinit = function()
    print("deinit sun mode: 4")
    self.photon_changed_callback  = nil
    self.ray_changed_callback     = nil
  end  

end

function sun_mode_3.photon_changed(self,ray_id,photon_id)
  print("photon_changed",self.index,ray_id,photon_id)
end

function sun_mode_3.ray_changed(self,ray_id,photon_id)
  print("ray_changed",self.index,ray_id,photon_id)
end

function sun_mode_3.enc(self, n, delta)
  if n==1 then return end
  self:set_active_photons_rel(delta)
end

function sun_mode_3.key(self, n, z)

end


function sun_mode_3.redraw(self)
  -- add code here to draw something only when sun mode == 4
end

return sun_mode_3
