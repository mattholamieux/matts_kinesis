-- lib/sun.lua
-- note: this class operates in different "modes" 
--   and uses a "strategy" design pattern to run the code 
--   required for each mode.
--
--   this separates the implementation details for each mode
--     from one another so modes can change and new modes can 
--     be developed with minimal changes required in 
--     in the main sun.lua codebase
--
--   see: https://en.wikipedia.org/wiki/Strategy_pattern
--

local Ray = include "lib/ray"
local sun_mode_1 = include "lib/sun_mode_1"
local sun_mode_2 = include "lib/sun_mode_2"
local sun_mode_3 = include "lib/sun_mode_3"
local sun_mode_4 = include "lib/sun_mode_4"

local Sun = {}
Sun.__index = Sun

-- constants 
--   constants are written in all caps. they never change.
--   constants are global, written without `local` before the name, 
--     and are accessible throughout the codebase.
SUN1_X = 32
SUN2_X = 96
NUM_RAYS = 16
PHOTONS_PER_RAY = 8
SUN_RADIUS = 4
MIN_LEVEL = 2
MAX_LEVEL = 15
ACTIVE_RAY_BRIGHTNESS = 7--10

function Sun:new(index, mode, ray_changed_callback, photon_changed_callback)
  local obj = {
    index = index,
    mode = mode,
    ray_changed_callback = ray_changed_callback,
    photon_changed_callback = photon_changed_callback,
    rays = {},
    velocity = 0,
    motion_clock = nil,
    direction = 0,
    sun_level = 10,
    last_selected_rays = {},
    last_selected_photons = {}
  }
  setmetatable(obj, Sun)
  
  -- instantiate each ray
  for r = 1, NUM_RAYS do obj.rays[r] = Ray:new(index, r) end

  -- initialize the sun modes
  print("init sun mode: ", mode)
  if      mode == 1 then sun_mode_1.init(obj)
  elseif  mode == 2 then sun_mode_2.init(obj)
  elseif  mode == 3 then sun_mode_3.init(obj)
  elseif  mode == 4 then sun_mode_4.init(obj)     
  end
  
  return obj
end

-- Delegate encoder (enc) handling to the mode-specific functions.
function Sun:enc(n, delta)
  if self.mode == 1 then       sun_mode_1.enc(self, n, delta)
  elseif self.mode == 2 then   sun_mode_2.enc(self, n, delta)
  elseif self.mode == 3 then   sun_mode_3.enc(self, n, delta)
  elseif self.mode == 4 then   sun_mode_4.enc(self, n, delta)
  end
end

function Sun:key(n, z)
  if self.mode == 1 then       sun_mode_1.key(self, n, z)
  elseif self.mode == 2 then   sun_mode_2.key(self, n, z)
  elseif self.mode == 3 then   sun_mode_3.key(self, n, z)
  elseif self.mode == 4 then   sun_mode_4.key(self, n, z)
  end  
end

function Sun:get_ray_photon(ix)
  local photon_ix = ix - 1
  local ray = math.floor(photon_ix / PHOTONS_PER_RAY) + 1
  local photon = (photon_ix % PHOTONS_PER_RAY) + 1
  return ray, photon
end

function Sun:get_photon(ray, photon)
  return self.rays[ray]:get_photon(photon)
end

-- note: update_state and self.last_selected_photon is not used in mode 3
function Sun:update_state()
  for _, ray in ipairs(self.rays) do
    ray:clear_state(MIN_LEVEL)
  end

  for ix, photon_index in ipairs(self.active_photons) do
    local ray, photon = self:get_ray_photon(photon_index)
    
    ------------------------------------------------
    -- callback code: notify on ray or photon change
    ------------------------------------------------
    
    -- >>>>first, check if a ray or photon has changed
    --   BUT ONLY IF THERE IS A CALLBACK DEFINED 
    
    local ray_changed = ray ~= self.last_selected_rays[ix] and 
                        self.ray_changed_callback ~= nil
                               
    local photon_changed = photon ~= self.last_selected_photons[ix]  and 
                           self.photon_changed_callback ~= nil
                                     
    -- print("photon changed",self.photon_changed_callback and self.last_selected_photon and photon ~= self.last_selected_photon )
    
    -- >>>>>then, call the callbacks
    if ray_changed then
      self.ray_changed_callback(self, ray, photon)
      -- print("ray changed",ix, photon_changed, ray, self.last_selected_rays[ix])
    elseif photon_changed then
      -- print("photon changed",ix, photon_changed, photon, self.active_photons[ix], self.last_selected_photons[ix])
      self.photon_changed_callback(self, ray, photon)
    end

    --
    self.last_selected_photons[ix] = photon
    self.last_selected_rays[ix] = ray
    
    -- highlight non-active photons on the same ray
    local brightness_fn = function(photon)
      local flat_index = (ray - 1) * PHOTONS_PER_RAY + photon
      local has_active_photons = not table_contains(self.active_photons, flat_index)
      if has_active_photons then return ACTIVE_RAY_BRIGHTNESS else  return nil end
    end

    self:set_ray_brightness(ray,brightness_fn)
  end
end

-- set active photons by an array of {ray_id, photon_id} pairs
function Sun:set_active_photons(ids)
  self.active_photons = {}
  for i=1, #ids do
  local ray = ids[i][1]
  local photon = ids[i][2]
  local sun_photon_id = ((ray - 1) * PHOTONS_PER_RAY) + photon
  self.active_photons[i] = sun_photon_id
  end
  self:update_state()
end

--change the active photons relative to the delta value
function Sun:set_active_photons_rel(delta) 
  local new_active = {}
  if #self.active_photons == 0 then
    new_active[1] = util.wrap(1 + delta, 1, NUM_RAYS * PHOTONS_PER_RAY)
  else
    for ix, photon_ix in ipairs(self.active_photons) do
      new_active[ix] = util.wrap(photon_ix + delta, 1, NUM_RAYS * PHOTONS_PER_RAY)
      -- print("new active photon", ix, new_active[ix])
    end
  end
  self.active_photons = new_active
  self:update_state()
end

function Sun:set_velocity_manual(new_velocity)
  self.velocity = new_velocity
  self.direction = sign(new_velocity)

  if math.abs(new_velocity) < 0.01 then
    self.velocity = 0
    self.direction = 0
  return
  end

  self.motion_clock = clock.run(function()
    while true do
      clock.sleep(1 / math.abs(self.velocity))
      self:set_active_photons_rel(self.direction)
    end
  end)
end

function Sun:set_ray_brightness(ray, brightness)
  local brightness_is_fn = type(brightness) == "function" 
  for photon = 1, PHOTONS_PER_RAY do
    local p = self:get_photon(ray, photon)

    -- if brightness is a function: 
    --  call it and redefine brightness as the function's return value
    --  otherwise, assume it is a number and set it back to itself
    brightness_level = brightness_is_fn and brightness(photon,p) or brightness

    -- safety check: before setting brightness, make sure it is now a number
    if type(brightness_level) == "number" then p:set_brightness(brightness_level) end
  end
end

function Sun:redraw(force_redraw)
  for ix, ray in ipairs(self.rays) do
    -- if force_redraw then print("redraw ray",ix) end
    ray:redraw(force_redraw)
  end

  local cx = (self.index == 1) and SUN1_X or SUN2_X
  screen.level(math.floor(self.sun_level))
  screen.circle(cx, 32, SUN_RADIUS)
  screen.fill()

  if self.mode == 1 then sun_mode_1.redraw(self)
  elseif self.mode == 2 then sun_mode_2.redraw(self)
  elseif self.mode == 3 then sun_mode_3.redraw(self)
  elseif self.mode == 4 then sun_mode_4.redraw(self)
  end
end

return Sun
