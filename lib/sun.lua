-- Note: this class operates in different "modes" 
--   and uses a "strategy" design pattern to run the code 
--   required for each mode.
--
--   This separates the implementation details for each mode
--     from one another so modes can change and new modes can 
--     be developed with minimal changes required in 
--     in the main sun.lua codebase
--
--   See: https://en.wikipedia.org/wiki/Strategy_pattern
--

local Ray = include "lib/ray"

local Sun = {}
Sun.__index = Sun

local sun_modes = {
  -- [1] = include "lib/sun_mode_1",
  [2] = include "lib/sun_mode_2",
  [3] = include "lib/sun_mode_3"
}

-- NOTE: CONSTANT VARIABLES
--   The following variables are written in all caps. 
--   Writing a variable in all caps indicates that they never change.
--   Writing these variables without `local` before the name makes them global.
--   Global variables are accessible globally.
SUN1_X = 32
SUN2_X = 96
NUM_RAYS = 16               -- [[ 0_0 ]] --
PHOTONS_PER_RAY = 8         -- [[ 0_0 ]] --
SUN_RADIUS = 4              -- [[ 0_0 ]] --
min_level = 2               -- [[ 0_0 ]] --
MAX_LEVEL = 15              -- [[ 0_0 ]] --
ACTIVE_RAY_BRIGHTNESS = 7   -- [[ 0_0 ]] --

function Sun:new(index, mode, ray_changed_callback, photon_changed_callback)
  local sun_obj = {
    index = index,
    mode = mode,
    sun_level = 10,
    ray_changed_callback = ray_changed_callback,
    photon_changed_callback = photon_changed_callback,
    rays = {},
    velocity = 0,
    motion_clock = nil,
    direction = 0,
    last_selected_rays = {},
    last_selected_photons = {}
  }
  setmetatable(sun_obj, Sun)
  
  -- Instantiate each ray
  for r = 1, NUM_RAYS do sun_obj.rays[r] = Ray:new(index, r) end

  -- initialize the sun modes
  sun_modes[mode].init(sun_obj)
  print("init sun mode: ", mode)
  
  return sun_obj
end

-- Delegate encoder (enc) handling to the mode-specific functions.
function Sun:enc(n, delta)
  -- print("enc", self.mode,sun_modes[self.mode].enc, n, delta)
  sun_modes[self.mode].enc(self, n, delta)
end

function Sun:key(n, z)
  sun_modes[self.mode].key(self, n, z)
end

function Sun:grid(x,y,z)
  sun_modes[self.mode].grid(self,x,y,z)
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

function Sun:update_state()
  for _, ray in ipairs(self.rays) do
    ray:clear_state(min_level)
  end

  for ix, photon_index in ipairs(self.active_photons) do
    local ray, photon = self:get_ray_photon(photon_index)
    
    ------------------------------------------------
    -- Callback code: notify on ray or photon change
    ------------------------------------------------
    
    -- First, check if a ray or photon has changed
    --   BUT ONLY IF THERE IS A CALLBACK DEFINED 
    
    local ray_changed = ray ~= self.last_selected_rays[ix] and 
                        self.ray_changed_callback ~= nil
                               
    local photon_changed = photon ~= self.last_selected_photons[ix]  and 
                           self.photon_changed_callback ~= nil
                                     
    -- print("photon changed",self.photon_changed_callback and self.last_selected_photon and photon ~= self.last_selected_photon )
    
    -- Then, call the callbacks
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
    
    -- Highlight non-active photons on the same ray
    local brightness_fn = function(photon)
      local flat_index = (ray - 1) * PHOTONS_PER_RAY + photon
      local has_active_photons = not table_contains(self.active_photons, flat_index)
      if has_active_photons then return ACTIVE_RAY_BRIGHTNESS else  return nil end
    end

    self:set_ray_brightness(ray,brightness_fn)
  end
end

-- Set active photons by an array of {ray_id, photon_id} pairs
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

-- Change the active photons relative to the delta value
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

    -- If brightness is a function: 
    --  call it and redefine brightness as the function's return value
    --  otherwise, assume it is a number and set it back to itself
    brightness_level = brightness_is_fn and brightness(photon,p) or brightness

    -- Safety check: before setting brightness, make sure it is now a number
    if type(brightness_level) == "number" then p:set_brightness(brightness_level) end
  end
end

function Sun:redraw(force_redraw)
  for ix, ray in ipairs(self.rays) do
    ray:redraw(force_redraw)
  end

  local cx = (self.index == 1) and SUN1_X or SUN2_X
  screen.level(math.floor(self.sun_level))
  screen.circle(cx, 32, SUN_RADIUS)
  screen.fill()

  sun_modes[self.mode].redraw(self)
end

return Sun
