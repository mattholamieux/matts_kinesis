-- lib/ray.lua
local Photon = include "lib/photon"
local Ray = {}
Ray.__index = Ray

-- constants for photon placement (these could be adjusted as needed)
local photon_offset_from_center = 3
local photon_length = 2

function Ray:new(sun_index, ray_index)
  local obj = {
    sun_index = sun_index,
    ray_index = ray_index,
    photons = {},
    -- NUM_RAYS = NUM_RAYS,
    -- PHOTONS_PER_RAY = PHOTONS_PER_RAY,
    -- SUN_RADIUS = SUN_RADIUS,
  }
  setmetatable(obj, Ray)

  -- instantiate the photons using the new Photon class (only id is passed)
  for i=1, PHOTONS_PER_RAY do
    obj.photons[i] = Photon:new(i)
    obj.photons[i]:set_brightness(MIN_LEVEL)  -- default brightness (MIN_LEVEL)
  end

  return obj
end

-- helper: calculate photon position based on the ray’s parameters and photon id.
function Ray:calc_photon_position(photon)
  local center_x = (self.sun_index == 1) and 32 or 96
  local center_y = 32
  local angle = -math.pi/2 + (self.ray_index - 1) * (2 * math.pi / NUM_RAYS)
  local distance = SUN_RADIUS + photon_offset_from_center + (photon.id - 1) * (photon_length + 1)
  local x = util.round(center_x + distance * math.cos(angle))
  local y = util.round(center_y + distance * math.sin(angle))
  return x, y
end

function Ray:get_photon(i)
  return self.photons[i]
end

-- morph a photon's brightness over time 
-- (see Photon:morph_photon for details)
function Ray:morph_photon(photon_id, s_val, f_val, duration, steps, shape, callback, caller_id)
  local ph = self:get_photon(photon_id)
  print("start morph",photon_id, s_val, f_val, duration, steps, shape, callback, caller_id)
  ph:morph_photon(s_val, f_val, duration, steps, shape, callback, caller_id)
end 

-- Adjusted to simply set brightness on the photon
function Ray:set_photon(i, level)
  local p = self.photons[i]
  p:set_brightness(level)
end

-- Clear the state (only brightness now; removed activation flags)
function Ray:clear_state(MIN_LEVEL)
  for _, p in ipairs(self.photons) do
    p:set_brightness(MIN_LEVEL)
  end
end

function Ray:redraw(force_redraw)
  for _, p in ipairs(self.photons) do
    p.x, p.y = self:calc_photon_position(p)
    p:redraw(force_redraw)
  end
end

return Ray
