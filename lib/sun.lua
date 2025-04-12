-- lib/sun.lua
-- note: this class operates in different "modes" 
--     and achieves this using a "strategy" design pattern
--     see: https://en.wikipedia.org/wiki/Strategy_pattern


local Ray = include "lib/ray"
local sun_mode_1 = include "lib/sun_mode_1"
local sun_mode_2 = include "lib/sun_mode_2"
local sun_mode_3 = include "lib/sun_mode_3"
local sun_mode_4 = include "lib/sun_mode_4"

local Sun = {}
Sun.__index = Sun

-- class-level constants 
-- these typically won't change while using the script
-- these are set as global (without local before the name)
--    so they are available everywhere (e.g. sun_mode_3.lua uses photons_per_ray)
sun1_x = 32
sun2_x = 96
num_rays = 16
photons_per_ray = 8
sun_radius = 6
min_level = 2
max_level = 15
active_ray_brightness = 10

function Sun:new(index, mode, ray_callback, photon_callback)
  local obj = {
    index = index,
    mode = mode,
    ray_callback = ray_callback,
    photon_callback = photon_callback,
    rays = {},
    velocity = 0,
    motion_clock = nil,
    direction = 0,
    sun_level = 10,    
  }
  setmetatable(obj, Sun)
  
  -- Instantiate the rays.
  for r = 1, num_rays do
    obj.rays[r] = Ray:new(index, r)
  end

  -- init the sun modes.
  print("init sun mode: ", mode)
  if mode == 1 then sun_mode_1.init(obj)
  elseif mode == 2 then sun_mode_2.init(obj)
  elseif mode == 3 then sun_mode_3.init(obj)
  elseif mode == 4 then sun_mode_4.init(obj) end
  
  return obj
end

-- Delegate encoder (enc) handling to the mode-specific functions.
function Sun:enc(n, delta)
  if self.mode == 1 then
    sun_mode_1.enc(self, n, delta)
  elseif self.mode == 2 then
    sun_mode_2.enc(self, n, delta)
  elseif self.mode == 3 then
    sun_mode_3.enc(self, n, delta)
  elseif self.mode == 4 then
    sun_mode_4.enc(self, n, delta)
  end
end

function Sun:key(n, z)
    if self.mode == 1 then
        -- sun_mode_1.key(self, n, z)
      elseif self.mode == 2 then
        -- sun_mode_2.key(self, n, z)
      elseif self.mode == 3 then
        sun_mode_3.key(self, n, z)
      elseif self.mode == 4 then
        -- sun_mode_4.key(self, n, z)
      end      
end

function Sun:get_ray_photon(ix)
  local photon_ix = ix - 1
  local ray = math.floor(photon_ix / photons_per_ray) + 1
  local photon = (photon_ix % photons_per_ray) + 1
  return ray, photon
end

function Sun:get_photon(ray, photon)
  return self.rays[ray]:get_photon(photon)
end

-- note: update_state only used in modes 1 & 2
function Sun:update_state()
  for _, ray in ipairs(self.rays) do
    ray:clear_state(min_level)
  end

  for _, index in ipairs(self.active_photons) do
    local ray, photon = self:get_ray_photon(index)
    
    -- is this needed???
    -- local p = self:get_photon(ray, photon)
    -- -- update the brightness
    -- p:set_brightness(max_level)

    -- callback code: notify on ray or photon change
    if ray ~= self.last_selected_ray then
      self.ray_callback(self.index, ray, photon)
    elseif photon ~= self.last_selected_photon then
      self.photon_callback(self.index, ray, photon)
    end

    self.last_selected_photon = photon
    self.last_selected_ray = ray

    -- highlight non-active photons on the same ray
    local brightness_fn = function(photon)
        local flat_index = (ray - 1) * photons_per_ray + photon
        local has_active_photons = not table_contains(self.active_photons, flat_index)
        if has_active_photons then return active_ray_brightness else  return nil end
    end
    self:set_ray_brightness(ray,brightness_fn)
  end
end

-- set active photons by an array of {ray_id, photon_id} pairs
function Sun:set_active_photons(ids)
  self.active_photons = {}
  for i = 1, #ids do
    local ray = ids[i][1]
    local photon = ids[i][2]
    local sun_photon_id = ((ray - 1) * photons_per_ray) + photon
    self.active_photons[i] = sun_photon_id
  end
  self:update_state()
end

--change the active photons relative to the delta value
function Sun:set_active_photons_rel(delta)
  
  local new_active = {}
  if #self.active_photons == 0 then
    new_active[1] = util.wrap(1 + delta, 1, num_rays * photons_per_ray)
  else
    for i, ix in ipairs(self.active_photons) do
      new_active[i] = util.wrap(ix + delta, 1, num_rays * photons_per_ray)
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
    for photon = 1, photons_per_ray do
        local p = self:get_photon(ray, photon)

        -- if brightness is a function: 
        --    call it and redefine brightness as the function's return value
        --    otherwise, assume it is a number and set it back to itself
        brightness_level = brightness_is_fn and brightness(photon,p) or brightness

        -- safety check: before setting brightness, make sure it is now a number
        if type(brightness_level) == "number" then p:set_brightness(brightness_level) end
    end
end

function Sun:redraw(force)
  for _, ray in ipairs(self.rays) do
    ray:redraw(force)
  end
  local cx = (self.index == 1) and sun1_x or sun2_x

  screen.level(math.floor(self.sun_level))
  screen.circle(cx, 32, sun_radius)
  screen.fill()

  if self.mode == 1 then
    sun_mode_1.redraw(self)
  elseif self.mode == 2 then    
    sun_mode_2.redraw(self)
  elseif self.mode == 3 then
    sun_mode_3.redraw(self)
  elseif self.mode == 4 then
    sun_mode_4.redraw(self)
  end
end

return Sun
