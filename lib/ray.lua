local Photon = include "lib/photon"

local Ray = {}
Ray.__index = Ray

-- Constants for photon placement (these could be adjusted as needed)
local PHOTON_OFFSET = 3
local PHOTON_SPACING = 2

function Ray:new(sun_index, ray_index)
  local ray_obj = {
    sun_index = sun_index,
    ray_index = ray_index,
    photons = {},
  }
  setmetatable(ray_obj, Ray)

  -- Instantiate the photons using the new Photon class (only id is passed)
  for i=1, PHOTONS_PER_RAY do
    ray_obj.photons[i] = Photon:new(i)
    ray_obj.photons[i]:set_brightness(min_level)  -- default brightness (min_level)
  end

  return ray_obj
end

-- Helper: calculate photon position based on the ray’s parameters and photon id.
function Ray:calc_photon_position(photon)
  local center_x = (self.sun_index == 1) and 32 or 96
  local center_y = 32
  local angle = -math.pi/2 + (self.ray_index - 1) * (2 * math.pi / NUM_RAYS)
  local distance = SUN_RADIUS + PHOTON_OFFSET + (photon.id - 1) * (PHOTON_SPACING + 1)
  local x = util.round(center_x + distance * math.cos(angle))
  local y = util.round(center_y + distance * math.sin(angle))
  return x, y
end

function Ray:get_photon(i)
  return self.photons[i]
end

-- Morph a photon's brightness over time 
function Ray:morph_photon(photon_id, s_val, f_val, duration, steps, shape, callback, caller_id)
  local ph = self:get_photon(photon_id)
  -- print("start morph",photon_id, s_val, f_val, duration, steps, shape, callback, caller_id)
  ph:morph_photon(s_val, f_val, duration, steps, shape, callback, caller_id)
end 

function Ray:set_photon_brightness(i, level)
  local p = self.photons[i]
  p:set_brightness(level)
end

function Ray:clear_state(min_level)
  for _, p in ipairs(self.photons) do
    p:set_brightness(min_level)
  end
end

function Ray:redraw(force_redraw)
  for _, p in ipairs(self.photons) do
    p.x, p.y = self:calc_photon_position(p)
    p:redraw(force_redraw)
  end
end

return Ray
