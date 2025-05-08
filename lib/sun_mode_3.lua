local sun_mode_3 = {}

------------------------------------------
-- Initialization and deinitialization
------------------------------------------
function sun_mode_3.init(self)
  -- [[ 0_0 ]] --
  -- Create state variables 
  self.active_photons = {3,22}

  -- Assign callbacks (defined below) to handle events when a photon or ray changes
  self.photon_changed_callback  = sun_mode_3.photon_changed
  self.ray_changed_callback     = sun_mode_3.ray_changed

  -- Call update state (defined in sun.lua) to
  self:update_state()


  -- Deinit (cleanup) function
  self.deinit = function()
    print("deinit sun mode: 3")
    self.photon_changed_callback  = nil
    self.ray_changed_callback     = nil
  end  

end

function sun_mode_3.enc(self, n, delta)
  if n==1 then return end
  self:set_active_photons_rel(delta)
end

-- [[ 0_0 ]] --
function sun_mode_3.key(self, n, z)
  -- Do something when a key is pressed
end

-- [[ 0_0 ]] --
function sun_mode_3.photon_changed(self,ray_id,photon_id)
  -- Do something when the photon changes
  -- print("photon changed: sun/ray/photon: ",self.index,ray_id,photon_id)
end

-- [[ 0_0 ]] --
function sun_mode_3.ray_changed(self,ray_id,photon_id)
  -- Do something when the ray changes
  -- print(">>>ray changed: sun/ray/photon: ",self.index,ray_id,photon_id)
end



-- [[ 0_0 ]] --
function sun_mode_3.redraw(self)
  -- Draw something here specific to sun mode 3
end

return sun_mode_3
