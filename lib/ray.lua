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
        -- num_rays = num_rays,
        -- photons_per_ray = photons_per_ray,
        -- sun_radius = sun_radius,
    }
    setmetatable(obj, Ray)

    -- instantiate the photons using the new Photon class (only id is passed)
    for i = 1, photons_per_ray do
        obj.photons[i] = Photon:new(i)
        obj.photons[i]:set_brightness(min_level)    -- default brightness (min_level)
    end

    return obj
end

-- helper: calculate photon position based on the ray’s parameters and photon id.
function Ray:calc_photon_position(photon)
    local center_x = (self.sun_index == 1) and 32 or 96
    local center_y = 32
    local angle = -math.pi/2 + (self.ray_index - 1) * (2 * math.pi / num_rays)
    local distance = sun_radius + photon_offset_from_center + (photon.id - 1) * (photon_length + 1)
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
function Ray:clear_state(min_level)
    for _, p in ipairs(self.photons) do
        p:set_brightness(min_level)
    end
end

function Ray:redraw(force)
    for _, p in ipairs(self.photons) do
        p.x, p.y = self:calc_photon_position(p)
        p:redraw(force)
    end
end

return Ray
