-- Utility function: get sign
function sign(x)
  local direction
  if x > 0 then 
    direction = 1 
  elseif x < 0 then 
    direction = -1
  else 
    direction = 0     
  end
  return direction
end

-- Utility function: get integer quotient and remainder
function quotient_remainder(numerator,denominator)
  local integer_quotient = math.floor(numerator/denominator)
  local remainder = (numerator-(integer_quotient*denominator))/denominator
  return integer_quotient, remainder
end

-- Utility function: returns whether a value exists in a table.
function table_contains(t, val)
  for _, v in ipairs(t) do
  if v == val then return true end
  end
  return false
end


---------------------------------------------------------------------
-- Internal morph function
--
-- This recursively interpolates between s_val and f_val over the given duration/steps,
-- using the provided shape mapping (e.g., "exp", "log", or linear).
--
-- Parameters:
--   self      - the instance of whatever is calling the morphing function
--   s_val, f_val  - start and finish brightness values
--   duration    - total time (in seconds) for the morph
--   steps       - total number of steps
--   shape       - string: "exp", "log", or any other value for linear interpolation
--   callback    - function to call each step: callback(next_val, done, caller_id)
--   caller_id     - an identifier for the morphing context
--   steps_remaining (optional) - steps remaining (internal use)
--   current_val   (optional) - current brightness value (internal use)
---------------------------------------------------------------------
-- Revised internal morph function.
-- Now "self" is passed so that we can check self.cancel_morph and, if true, speed up the morph.
function morph(self, s_val, f_val, duration, steps, shape, callback, caller_id, steps_remaining, current_val)
  -- Instead of immediately canceling, check for cancellation and accelerate the process.
  local accel_factor = 0.5  -- adjust this factor to increase speed when cancelled.
  if self.cancel_morph then
    -- Scale down the remaining duration and steps.
    duration = duration * accel_factor
    steps = math.floor(math.max(1, math.ceil(steps * accel_factor)))
    if steps_remaining then
    steps_remaining = math.max(1, math.ceil(steps_remaining * accel_factor))
    end
  end
  
  if steps <= 0 then
    if callback then callback(f_val, true, caller_id) end
    return
  end
  
  if steps_remaining == nil or current_val == nil then
    steps_remaining = steps
    current_val = s_val
  end
  
  local delay = duration / steps
  clock.sleep(delay)
  
  local step_number = steps - steps_remaining + 1
  local progress = step_number / steps
  local interpolated = s_val + progress * (f_val - s_val)
  local next_val
  
  -- Handle reversed range (if s_val > f_val)
  local reversed = false
  local in_low, in_high = s_val, f_val
  if s_val > f_val then
    reversed = true
    in_low, in_high = f_val, s_val
    interpolated = s_val + progress * (f_val - s_val)
  end
  
  if shape == "exp" then
    next_val = util.linexp(in_low, in_high, in_low, in_high, interpolated)
  elseif shape == "log" then
    next_val = util.explin(in_low, in_high, in_low, in_high, interpolated)
  else
    next_val = util.linlin(in_low, in_high, in_low, in_high, interpolated)
  end
  
  if reversed then
    next_val = s_val - (next_val - f_val)
  end
  
  local done = false
  if steps_remaining <= 1 then
    next_val = f_val  -- force_redraw final value.
    done = true
  end
  
  if callback then
    callback(next_val, done, caller_id)
  end
  
  if not done then
    steps_remaining = steps_remaining - 1
    clock.run(function()
    morph(self, s_val, f_val, duration, steps, shape, callback, caller_id, steps_remaining, next_val)
    end)
  end
  end
  