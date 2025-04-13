-- lib/photon.lua
local Photon = {}
Photon.__index = Photon

local photon_length = 2    -- used for drawing

---------------------------------------------------------------------
-- constructor
---------------------------------------------------------------------
function Photon:new(id)
  local obj = {
    id = id,                       -- identifier (e.g., photon index)
    brightness = 2,                -- current brightness
    last_drawn_brightness = nil,   -- for change detection
    x = 0,
    y = 0,
    external_callback = nil,       -- the callback provided by the caller
    morphing = false,              -- whether a morph is active
    cancel_morph = false,          -- flag to cancel/accelerate an active morph
    active_morph_caller = nil      -- stores the caller_id for the active morph
  }
  setmetatable(obj, Photon)
  return obj
end

---------------------------------------------------------------------
-- basic drawing methods
---------------------------------------------------------------------
function Photon:set_brightness(level)
  self.brightness = math.floor(level)
end

function Photon:has_changed(force)
  return force or (self.last_drawn_brightness == nil or self.last_drawn_brightness ~= self.brightness)
end

function Photon:redraw(force)
  if not self:has_changed(force) then return end  
  screen.level(self.brightness)
  screen.move(self.x, self.y)
  screen.circle(self.x, self.y, photon_length / 2)
  screen.fill()
  self.last_drawn_brightness = self.brightness
end

function Photon:cancel_morphing()
  self.cancel_morph = true
end

---------------------------------------------------------------------
-- Public wrapper: morph_photon
--
-- This method begins a morph operation on the photon. If a morph is already
-- in progress and the new morph's caller_id is different, the current morph is
-- accelerated (by canceling it) and the new morph starts with a shorter duration.
--
-- Parameters:
--   s_val, f_val  - start and finish brightness values
--   duration      - total time (seconds) for the morph
--   steps         - total number of steps
--   shape         - "exp", "log", or linear interpolation
--   callback      - (optional) function(next_val, done, photon_id)
--   caller_id     - (optional) identifier for the morph context (default 1)
---------------------------------------------------------------------
function Photon:morph_photon(s_val, f_val, duration, steps, shape, callback, caller_id)
  caller_id = caller_id or 1
  if self.morphing then -- IS THIS CODE ACTUALLY NECESSARY???
    if self.active_morph_caller ~= caller_id then
      print("Photon " .. self.id .. ": new morph (caller " .. caller_id .. ") differs from active context (" .. tostring(self.active_morph_caller) .. "), cancelling current morph.")
      self:cancel_morphing()
      local new_duration = duration * 0.3  -- accelerate the morph (30% of original time)
      local new_steps = math.max(1, math.ceil(steps * 0.3))
      clock.run(function()
        self:morph_photon(s_val, f_val, new_duration, new_steps, shape, callback, caller_id)
      end)
      return
    else
      -- print("Photon " .. self.id .. ": new morph has same context (" .. caller_id .. "); ignoring new request.")
      return
    end
  end

  self.active_morph_caller = caller_id
  self.morphing = true
  self.cancel_morph = false
  self.external_callback = callback

  local function morph_photon_callback(next_val, done)
    self:set_brightness(util.round(next_val))
    if self.external_callback then
      self.external_callback(next_val, done, self.id)
    end
    if done then
      self.external_callback = nil
      self.morphing = false
      self.active_morph_caller = nil
    end
  end

  clock.run(function()
    morph(self, s_val, f_val, duration, steps, shape, morph_photon_callback, caller_id)
  end)
end

return Photon
