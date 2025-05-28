-- Sun mode 2: granular synthesis using the GrainBuf UGen, controlled with the reflection library
-- References: 
--   https://monome.org/docs/norns/reference/lib/reflection
--   https://doc.sccode.org/Classes/GrainBuf.html 

sun_mode_2 = {}

-- define state names.
local states = {'r','p','l'}  -- record, play, loop

------------------------------------------
-- Initialization and deinitialization
------------------------------------------
function sun_mode_2.init(self)
  print("grain_params_created",self.index,grain_params_created)
  -- If sun mode 2 is being inited for the first time, create a global variable called `grain_params_created`  
  if grain_params_created == nil then grain_params_created = false end
  
  self.reflection_indices = {}
  self.max_cursor = 8 * 16
  self.state = 1  -- States: 1 = record, 2 = play, 3 = loop
  self.grain_mode = 1 -- Grain modes: 1 = granulate live audio, 2 = granulate an audio file
  
  -- Set which rays have reflectors
  if self.index == 1 then
    self.reflector_locations = {1,3,5,7,9,11,13,15}
  else
    self.reflector_locations = {1,3,5,7,9,11,13,15}
  end

  -- Initialize state tables
  self.record       = {}
  self.play         = {}
  self.loop         = {}
  self.engine_vals  = {}

  for i=1, #self.reflector_locations do
    local reflector_id = self.reflector_locations[i]
    self.record[reflector_id]  = 0
    self.play[reflector_id]    = 1
    self.loop[reflector_id]    = 1
    sun_mode_2.deselect_reflector(self, reflector_id)
  end

  sun_mode_2.init_reflectors(self)
  sun_mode_2.hide_non_reflector_rays(self)

  -- 0_0 -- Make the 2nd reflector selected by default
  self.selected_ray = self.reflector_locations[2]

  sun_mode_2.select_reflector(self, self.selected_ray)

  -- Initialize the engine commands
  sun_mode_2.init_engine_commands(self)

  -- Initialize sounds
  sun_mode_2.init_sounds(self)

  ------------------------------------------
  -- Add params, but only if they haven't yet been created
  ------------------------------------------
  if not grain_params_created then
    for sun_ix=1,2 do
      params:add_separator("grain_params_sun_"..sun_ix,"grain params: sun "..sun_ix)
      -- select between live and recorded audio granulation
      params:add_option("grain_mode"..sun_ix,"set grain mode",{"live","recorded"})
      params:set_action("grain_mode"..sun_ix,function(mode) 
        if mode == 2 then -- Granulate an audio file
          local file = params:get("sample"..sun_ix)
          if file ~= "-" then
            self.grain_mode = mode
            engine.sample(sun_ix,file)
          else
            print("select a file before setting mode to 'recorded'")
            params:set("grain_mode"..sun_ix,1)
          end
        elseif mode == 1 then -- Granulate live audio
          self.grain_mode = mode
          engine.live(sun_ix)
        end

      end)
      
      -- File selector for recorded audio granulation
      params:add_file("sample"..sun_ix,"sample")
      params:set_action("sample"..sun_ix,function(file)
        if params:get("grain_mode"..sun_ix) == 2 then
          print("new sample "..sun_ix,file)
          if file~="-" then
            engine.sample(sun_ix,file)
            print("playing sample", file)
          end
        else 
          print("loading sample. set grain mode to `live` to play.", file)
        end
      end)

      -- Trigger to freeze grains
      params:add_trigger("freeze_grains"..sun_ix,"freeze grains")
      params:set_action("freeze_grains"..sun_ix, function()
        -- To freeze grains we need to:
        --   Set speed and jitter to 0
        --   For live granulation set pre_level to 1 and rec_level to 0 
        --   Note: if there are reflection recordings running for these, freezing might not exactly happen
        local speed_reflector            =  sun_mode_2.get_reflector_id_by_engine_command_name(self,"sp")
        local jitter_reflector           =  sun_mode_2.get_reflector_id_by_engine_command_name(self,"jt")
        local prerecord_level_reflector  =  sun_mode_2.get_reflector_id_by_engine_command_name(self,"pl")
        local record_level_reflector     =  sun_mode_2.get_reflector_id_by_engine_command_name(self,"rl")
        sun_mode_2.update_engine(self, sun_ix, "sp", 64)
        sun_mode_2.update_engine(self, sun_ix, "jt", 0)
        sun_mode_2.update_engine(self, sun_ix, "pl", 128) 
        sun_mode_2.update_engine(self, sun_ix, "rl", 0)
        clock.run(function() 
          clock.sleep(0.1)
          sun_mode_2.set_reflector_cursor(self, speed_reflector           , 64)
          sun_mode_2.set_reflector_cursor(self, jitter_reflector          , 0)
          sun_mode_2.set_reflector_cursor(self, prerecord_level_reflector , 128)
          sun_mode_2.set_reflector_cursor(self, record_level_reflector    , 0)
        end)
      end)

      -- Trigger to reset the phase of the grain emitter (for syncing with other sounds)
      params:add_trigger("reset_grain_phase"..sun_ix,"reset grain phase")
      params:set_action("reset_grain_phase"..sun_ix, function()
        engine_params = {}
        local voice = sun_ix 
        for reflector_location_ix=1,#engine_commands do
          local reflector_id = self.reflector_locations[reflector_location_ix]
          local engine_command_data = sun_mode_2.get_engine_command_data(self,reflector_id) 
          local engine_val = self.engine_vals[reflector_id]
          local engine_command_name = engine_command_data[1]
          engine_params[engine_command_name]=engine_val
        end
        engine.reload_grain_player(
          voice,
          engine_params["sp"], -- speed
          engine_params["dn"],
          engine_params["ps"],
          engine_params["sz"],
          engine_params["jt"],
          engine_params["ge"]
        )
      end)
    end

    -- Hide the params for the other sun
    local other_sun = 3-self.index
    params:hide("grain_params_sun_"..other_sun)
    params:hide("grain_mode"..other_sun)
    params:hide("sample"..other_sun)
    params:hide("freeze_grains"..other_sun)
    params:hide("reset_grain_phase"..other_sun)
    engine.gate(other_sun,0) -- Set gate to 0 so grains can't play
    grain_params_created = true 
  else 
    print("unhide grain params",self.index)
    params:show("grain_params_sun_"..self.index)
    params:show("grain_mode"..self.index)
    params:show("sample"..self.index)
    params:show("freeze_grains"..self.index)
    params:show("reset_grain_phase"..self.index)
    engine.gate(self.index,1) -- Set gate to 1 so grains can play
    _menu:rebuild_params()
  end

  -- Switch to granulate an audio file by default
  -- Note: a file path will look something like: `/home/we/dust/audio/my_file.wav`
  -- params:set("sample"..self.index, "<insert file path>")
  -- params:set("grain_mode"..self.index, 2)


  -- Deinit (cleanup) function
  self.deinit = function(self)
    print("deinit sun "..self.index .. " mode 2")
    engine.gate(self.index,0) -- set gate to 1 so grains can play
    self.lattice:stop()
    self.lattice = nil
    for reflector=1,#self.reflectors do
      self.reflectors[reflector]:stop()
      self.reflectors[reflector]:clear()
    end
    params:hide("grain_params_sun_"..self.index)
    params:hide("grain_mode"..self.index)
    params:hide("sample"..self.index)
    params:hide("freeze_grains"..self.index)
    params:hide("reset_grain_phase"..self.index)
    _menu:rebuild_params()
    self.deinit = nil
  end  
end

------------------------------------------
-- Helpers
------------------------------------------
function sun_mode_2.hide_non_reflector_rays(self)
  for ray = 1, NUM_RAYS do
    if not table_contains(self.reflector_locations, ray) then
      self:set_ray_brightness(ray, 0)
    end
  end
end

------------------------------------------
-- Get minimum brightness for a reflector
------------------------------------------
function sun_mode_2.get_min_level(self, reflector_id)
  local min_l = 0
  for i=1, #self.reflector_locations do
    if reflector_id == self.reflector_locations[i] then
      min_l = 3
      break
    end
  end
  return min_l
end

------------------------------------------
-- Get the next reflector from reflector_locations
------------------------------------------
function sun_mode_2.get_next_ray(self, delta)
  local current_index = nil
  for i=1, #self.reflector_locations do
    if self.selected_ray == self.reflector_locations[i] then
      current_index = i
      break
    end
  end
  if not current_index then current_index = 1 end
  local next_index = util.wrap(current_index + delta, 1, #self.reflector_locations)
  return self.reflector_locations[next_index]
end

------------------------------------------
-- Grid handler
------------------------------------------
function sun_mode_2.grid(self, x, y, z)
  -- Adjust reflector cursor for the relevant reflector.
  self.selected_ray = (x*2)-1
  sun_mode_2.set_reflector_cursor_grid(self, self.selected_ray, y)
  sun_mode_2.draw_reflector_cursor(self, self.selected_ray)
end

------------------------------------------
-- Encoder handler
------------------------------------------
function sun_mode_2.enc(self, n, delta)
  if n == 1 then
    self.state = util.clamp(self.state + delta, 1, #states)
  else
    if alt_key == true then
      -- Change the selected reflector
      --   But first, if the curent reflector is recording, stop the recording
      for i=1,#self.reflector_locations do
        local reflector_id = self.reflector_locations[i]  
        if self.record[reflector_id] == 1 then                  -- If the reflector is recording then
          print("stop recording in progress...",reflector_id)
          self.record[reflector_id] = 0                         -- Set the recording flag to 0
          self.reflectors[reflector_id]:set_rec(0)              -- Stop recording
          self.reflectors[reflector_id]:clear()                 -- Clear the reflector
        end
      end
      self.selected_ray = sun_mode_2.get_next_ray(self, delta)
      sun_mode_2.select_reflector(self, self.selected_ray)
      sun_mode_2.draw_reflector_cursor(self, self.selected_ray)
    else
      print('sun 2 encoder '..self.selected_ray, delta)
      -- Adjust reflector cursor for the selected reflector.
      sun_mode_2.set_reflector_cursor_rel(self, self.selected_ray, delta)
      sun_mode_2.draw_reflector_cursor(self, self.selected_ray)
    end
  end
end

------------------------------------------
-- Key handler
------------------------------------------

function sun_mode_2.key(self, n, z)
  -- local reflector_id = self.selected_ray
  if alt_key == true then
    for i=1, 15, 2 do
      local reflector_id = i
      self.reflectors[reflector_id]:clear()
    end
  else
    for i=1, 15 do
      local reflector_id = i
      if self.state == 1 then  -- Record state
        if self.record[reflector_id] == 1 and z == 0 then
          self.record[reflector_id] = 0
          self.reflectors[reflector_id]:set_rec(0)
          print("key: stop reflector recording")    
        elseif self.record[reflector_id] == 0 and z == 0 then
          print("key: start reflector recording",reflector_id,self.reflectors[reflector_id])
          self.record[reflector_id] = 1
          if self.reflectors[reflector_id].count < 1 then
            self.reflectors[reflector_id]:clear()
          end
          -- self.reflectors[reflector_id]:clear()
          self.reflectors[reflector_id]:set_rec(1)
       end
      elseif self.state == 2 then -- Play state
        if z == 0 then
          if n == 2 then
            if self.play[reflector_id] == 1 then
              self.play[reflector_id] = 0
             print("toggle_play: stop reflector playing", reflector_id)
             if self.reflectors[reflector_id] and self.reflectors[reflector_id].stop then
               self.reflectors[reflector_id]:stop()
             end
           else
             self.play[reflector_id] = 1
             print("toggle_play: start reflector playing", reflector_id)
             if self.reflectors[reflector_id] and self.reflectors[reflector_id].start then
               self.reflectors[reflector_id]:start()
             end
           end
         end
        end
      elseif self.state == 3 then  -- Loop state
       if self.loop[reflector_id] == 1 and z == 0 then
         self.loop[reflector_id] = 0
          print("key: stop reflector looping")
          self.reflectors[reflector_id]:set_loop(0)
        elseif self.loop[reflector_id] == 0 and z == 0 then
          self.loop[reflector_id] = 1
          print("key: start reflector looping")
          self.reflectors[reflector_id]:set_loop(1)
        end
      end
    end
  end
end

-- function sun_mode_2.key(self, n, z)
--   local reflector_id = self.selected_ray
--   if self.state == 1 then  -- Record state
--     if self.record[reflector_id] == 1 and z == 0 then
      
--       self.record[reflector_id] = 0
--       self.reflectors[reflector_id]:set_rec(0)
--       print("key: stop reflector recording")    
--     elseif self.record[reflector_id] == 0 and z == 0 then
--       print("key: start reflector recording",reflector_id,self.reflectors[reflector_id])
--       self.record[reflector_id] = 1
--       self.reflectors[reflector_id]:clear()
--       self.reflectors[reflector_id]:set_rec(1)
--     end
--   elseif self.state == 2 then -- Play state
--     if z == 0 then
--       if n == 2 then
--         if self.play[reflector_id] == 1 then
--           self.play[reflector_id] = 0
--           print("toggle_play: stop reflector playing", reflector_id)
--           if self.reflectors[reflector_id] and self.reflectors[reflector_id].stop then
--             self.reflectors[reflector_id]:stop()
--           end
--         else
--           self.play[reflector_id] = 1
--           print("toggle_play: start reflector playing", reflector_id)
--           if self.reflectors[reflector_id] and self.reflectors[reflector_id].start then
--             self.reflectors[reflector_id]:start()
--           end
--         end
--       end
--     end
--   elseif self.state == 3 then  -- Loop state
--     if self.loop[reflector_id] == 1 and z == 0 then
--       self.loop[reflector_id] = 0
--       print("key: stop reflector looping")
--       self.reflectors[reflector_id]:set_loop(0)
--     elseif self.loop[reflector_id] == 0 and z == 0 then
--       self.loop[reflector_id] = 1
--       print("key: start reflector looping")
--       self.reflectors[reflector_id]:set_loop(1)
--     end
--   end
-- end

------------------------------------------
-- Get last selected photon for a reflector
------------------------------------------
function sun_mode_2.get_last_selected_photon(self, reflector_id)
  local last_ph, last_ph_brightness
  if self.reflection_indices[reflector_id] then
    local cursor = self.reflection_indices[reflector_id].reflection_cursor
    local q, r = quotient_remainder(cursor, NUM_RAYS)
    last_ph = q + 1
    last_ph_brightness = r * NUM_RAYS
    if last_ph_brightness == 1 then last_ph_brightness = 0 end
  end
  return last_ph, last_ph_brightness
end

------------------------------------------
-- Calculate photon brightness for a reflector
------------------------------------------
function sun_mode_2.get_photon_brightness(self, reflector_id, photon)
  local brightness, last_ph, last_ph_brightness
  if self.reflection_indices[reflector_id] then
    last_ph, last_ph_brightness = sun_mode_2.get_last_selected_photon(self, reflector_id)
    if photon < last_ph then
      brightness = MAX_LEVEL
    elseif photon == last_ph then
      brightness = last_ph_brightness
    else
      brightness = sun_mode_2.get_min_level(self, reflector_id)
    end
  else
    brightness = sun_mode_2.get_min_level(self, reflector_id)
  end
  return brightness, last_ph
end

------------------------------------------
-- Draw the reflector cursor for a given reflector
------------------------------------------
function sun_mode_2.draw_reflector_cursor(self, reflector_id)
  local brightness_fn = function(photon_id,photon)
    local brightness = sun_mode_2.get_photon_brightness(self, reflector_id, photon_id)
    photon:set_brightness(brightness)
    return nil
  end
  self:set_ray_brightness(reflector_id,brightness_fn)
end

------------------------------------------
-- Set reflector cursor (absolute)
------------------------------------------
function sun_mode_2.set_reflector_cursor(self, reflector_id, val)
  if not self.reflection_indices[reflector_id] then
    self.reflection_indices[reflector_id] = { reflection_cursor = 1 }
  end
  
  self.reflection_indices[reflector_id].reflection_cursor = val
  print("set_reflector_cursor", reflector_id, val)
  sun_mode_2.draw_reflector_cursor(self, reflector_id)
end

------------------------------------------
-- Set reflector cursor (relative)
------------------------------------------
function sun_mode_2.set_reflector_cursor_rel(self, reflector_id, delta)
  print("set_reflector_cursor", reflector_id, delta)
  if not self.reflection_indices[reflector_id] then
    self.reflection_indices[reflector_id] = { reflection_cursor = 1 }
  end
  local cursor = self.reflection_indices[reflector_id].reflection_cursor
  local new_cursor = util.clamp(cursor + delta, 1, self.max_cursor)
  self.reflection_indices[reflector_id].reflection_cursor = new_cursor
  -- Store reflector data.
  local new_data = { reflector = reflector_id, value = new_cursor }
  sun_mode_2.store_reflector_data(self, reflector_id, new_data)

  -- pass the event value to the router
  sun_mode_2.event_router(self, reflector_id, "process", new_data.value)

end

------------------------------------------
-- Set reflector cursor (GRID)
------------------------------------------
function sun_mode_2.set_reflector_cursor_grid(self, reflector_id, val)
  if not self.reflection_indices[reflector_id] then
    self.reflection_indices[reflector_id] = { reflection_cursor = 1 }
  end
  local new_val = 9-val
  local cursor = self.reflection_indices[reflector_id].reflection_cursor
  local new_cursor = util.linlin(1,8, 1, self.max_cursor,new_val)
  self.reflection_indices[reflector_id].reflection_cursor = new_cursor
  -- Store reflector data.
  local new_data = { reflector = reflector_id, value = new_cursor } -- IS THIS THE KEY?
  sun_mode_2.store_reflector_data(self, reflector_id, new_data)

  -- pass the event value to the router
  sun_mode_2.event_router(self, reflector_id, "process", new_data.value)
end

------------------------------------------
-- Deselect a reflector
------------------------------------------
function sun_mode_2.deselect_reflector(self, reflector_id)
  self:set_ray_brightness(reflector_id,function() 
    return sun_mode_2.get_min_level(self, reflector_id)
  end)
end

------------------------------------------
-- Select a reflector
------------------------------------------
function sun_mode_2.select_reflector(self, reflector_id)
  -- First, hide all non-reflector rays.
  sun_mode_2.hide_non_reflector_rays(self)
  -- Then update the display for the selected reflector.
  local set_reflector_brightness = function(photon_id, photon)
    if sun_mode_2.ray_has_cursor(self) then
      sun_mode_2.draw_reflector_cursor(self, reflector_id)
    end
    if photon_id < PHOTONS_PER_RAY then
      return min_level
    else
      local brightness = sun_mode_2.get_photon_brightness(self, reflector_id, photon_id)
      photon:morph_photon(MAX_LEVEL, brightness, 1, 15, 'lin', nil, reflector_id)
      return nil
    end
  end
  self:set_ray_brightness(reflector_id,set_reflector_brightness)
end

------------------------------------------
-- Check if the currently selected reflector has cursor data
------------------------------------------
function sun_mode_2.ray_has_cursor(self)
  return self.reflection_indices[self.selected_ray] ~= nil
end

------------------------------------------
-- Calculate pointer position (for display)
------------------------------------------
function sun_mode_2.calc_pointer_position(self)
  local center_x = (self.index == 1) and 32 or 96
  local center_y = 32
  local angle = -math.pi/2 + (self.selected_ray - 1) * (2 * math.pi / NUM_RAYS)
  local distance = SUN_RADIUS - 1
  local x = util.round(center_x + distance * math.cos(angle))
  local y = util.round(center_y + distance * math.sin(angle))
  return x, y
end

------------------------------------------
-- Redraw routine.
------------------------------------------
function sun_mode_2.redraw(self)
  local bottom_left_x = (self.index == 1) and 1 or 65
  local bottom_left_y = 62
  screen.move(bottom_left_x, bottom_left_y)
  screen.rect(bottom_left_x, bottom_left_y-5, 18, 8)
  screen.level(0)
  screen.fill()
  
  screen.move(bottom_left_x, bottom_left_y)
  screen.level(3)
  local state_text = tostring(self.selected_ray)
  -- update lower left labels for record/play/loop
  if self.state == 1 then
    local rec = (self.record[self.selected_ray] == 0) and "-" or "+"
    state_text = state_text .. states[self.state] .. rec
  elseif self.state == 2 then
    local play = (self.play[self.selected_ray] == 0) and "-" or "+"
    state_text = state_text .. states[self.state] .. play
  elseif self.state == 3 then
    local loop = (self.loop[self.selected_ray] == 0) and "-" or "+"
    state_text = state_text .. states[self.state] .. loop
  end
  screen.text(state_text)

  -- update lower right labels for engine commands
  local engine_command_data = sun_mode_2.get_engine_command_data(self,self.selected_ray) 
  local engine_val = self.engine_vals[self.selected_ray]
  local engine_command_name = engine_command_data[1]

  local top_right_x = (self.index == 1) and 60 or 127
  local top_right_y = 5
  screen.move(top_right_x, top_right_y)
  screen.rect(top_right_x-15, top_right_y-5, 18, 8)
  screen.level(0)
  screen.fill()
  
  screen.move(top_right_x, top_right_y)
  screen.level(3)
  screen.text_right(engine_command_name)

  if engine_val then
    if engine_val < 10 then 
      engine_val = util.round(engine_val,0.01)
    else
      engine_val = util.round(engine_val,0.1)
    end 
    local bottom_right_x = (self.index == 1) and 60 or 127
    local bottom_right_y = 62
    screen.move(bottom_right_x, bottom_right_y)
    screen.rect(bottom_right_x-16, bottom_right_y-5, 18, 8)
    screen.level(0)
    screen.fill()
  
    screen.move(bottom_right_x, bottom_right_y)
    screen.level(3)
    local engine_val = tostring(engine_val)
    screen.text_right(engine_val)
  end
  


  local point_x, point_y = sun_mode_2.calc_pointer_position(self)
  screen.level(0)
  screen.circle(point_x, point_y, 2)
  screen.fill()
end

------------------------------------------
------------------------------------------
-- Reflection code       
------------------------------------------
------------------------------------------
function sun_mode_2.store_reflector_data(self, reflector_id, data)
  if self.reflectors[reflector_id] then
    -- print("store reflector data",reflector_id,self.reflectors[reflector_id],data.reflector,data.value)
    self.reflectors[reflector_id]:watch{
      reflector = data.reflector,
      value = data.value
    }
  else
    print("can't store reflector data",reflector_id,self.reflectors[reflector_id])

  end
end

function sun_mode_2.init_reflectors(self)
  self.reflectors = {}
  self.reflector_data = {}
  self.reflector_processors = {}

  for i=1, #self.reflector_locations do
    local reflector_id = self.reflector_locations[i]
    self.reflector_data[reflector_id] = {}

    self.reflectors[reflector_id] = reflection.new()
    -- [[ 0_0 ]] -- set looping on by default
    self.reflectors[reflector_id]:set_loop(1)                   
    self.reflectors[reflector_id].process = function(event)
      local value = event.value
      
      -- update the ui
      sun_mode_2.set_reflector_cursor(self, reflector_id, value)

      -- pass the event value to the router
      sun_mode_2.event_router(self, reflector_id, "process", value)

    end

    -- end-of-loop callback
    self.reflectors[reflector_id].end_of_loop_callback = function()
      sun_mode_2.event_router(self, reflector_id, "end_of_loop")
      -- print("reflector step", reflector_id)
    end
    
    -- (optional) callback for recording start
    self.reflectors[reflector_id].start_callback = function()
      sun_mode_2.event_router(self, reflector_id, "record_start")
      -- print("recording started", reflector_id)
    end
    
    -- (optional) callback for recording stop
    self.reflectors[reflector_id].end_of_rec_callback = function()
      sun_mode_2.event_router(self, reflector_id, "record_end")
      -- print("recording ended", reflector_id)
    end

    -- (optional) callback for reflector step
    self.reflectors[reflector_id].step_callback = function()
      sun_mode_2.event_router(self, reflector_id, "step")
      -- print("reflector step", reflector_id)
    end
    
    self.reflectors[reflector_id].end_callback = function()
      -- print("pattern end callback", reflector_id)
      sun_mode_2.event_router(self, reflector_id, "pattern_end")
      -- local is_looping = (self.loop[reflector_id] == 1)
      -- if not is_looping then self.play[reflector_id] = 0 end
    end
  end
end

--======--===========================--======--
--======--111111111111111111111111111--======--
--===========    sun sound code     =========--
--======--111111111111111111111111111--======--    
--======--===========================--======--
------------------------------------------
-- Init sounds
------------------------------------------
function sun_mode_2.init_sounds(self)
  -- Init lattice
  sun_mode_2.init_lattice(self)
  
  -- Sync the active photon to supercollider sunshine engine values
  -- Note:   at the moment each time a sun is set to this mode (#2)
  --         The sunshine engine voice will be reset to its default values
  --         Since the code currently only defines a single voice for the engine,
  --           and not, for example, one voice per sun
  for reflector_id=1, NUM_RAYS do
    local sc_voice = 1
    local engine_command_data = sun_mode_2.get_engine_command_data(self,reflector_id) 
    if engine_command_data then
      local engine_command_ranges = engine_command_data[3]
      local engine_command_default_val = engine_command_data[4]
      local min = engine_command_ranges[1]
      local max = engine_command_ranges[2]
      
      --Set the photon to match the default value 
      --This will send an update to the sc engine to set the default value
      local photon_val = util.linlin(min,max,1,128,engine_command_default_val)
      -- print("init reflector cursor",min,max,engine_command_default_val,photon_val)
      sun_mode_2.set_reflector_cursor(self,reflector_id,photon_val)
      
      --Update the engine_vals table to display the value on the screen
      self.engine_vals[reflector_id] = engine_command_default_val
    end
  end
end


------------------------------------------
-- Lattice code
-- Note: the lattice code is here for reference,
--       but isn't actually used
------------------------------------------
-- Init lattice
function sun_mode_2.init_lattice(self)
  local sun = self.index

  self.lattice = lattice:new{
    auto = true,
    ppqn = 96
  }   

  -- Define sprockets for sun1 and sun 2
  self.sprocket_1 = self.lattice:new_sprocket{
    action = function(t) 
      sun_mode_2.event_router(self, nil, "sprocket")
    end,
    division = 1/4, -- [[ 0_0 ]] --
    enabled = true  -- [[ 0_0 ]] --
  }

  self.sprocket_2 = self.lattice:new_sprocket{
    action = function(t) 
      sun_mode_2.event_router(self, nil, "sprocket")
    end,
    division = 1/8, -- [[ 0_0 ]] --
    enabled = true  -- [[ 0_0 ]] --
  }

  self.lattice:start()
end

------------------------------------------
-- supercollider communication code
------------------------------------------

-- Initialize a table containing engine command names
--   along with functions to put the reflector values in proper ranges
-- IMPORTANT: the order of the engine commands sets which sun ray/reflector 
--            updates which engine command. if there are more items in the `engine_commands`
--            table than there are items in the `reflector_locations` table, the code will break
sun_mode_2.init_engine_commands = function (self)
  -- The engine_commands table holds data that is used for a number of purposes, including:
  --    * The labels displayed on the screen for each engine command 
  --    * The engine commands called by lua and sent to SuperCollider
  --    * Min/max value ranges for each engine command 
  --    * Whether each engine command value should be rounded (and the rounding decimal place)
  --    * The default value for each engine command (set when sun mode 2 is initialized)
  --
  --    For example, the item in the `engine_commands` table defines:
  --    * "sp" as the screen label 
  --    * `engine.speed` as the engine command
  --    *  -5 and 5 as the min/max values that can be sent to the engine for this command
  --    * Rounding is set to true and 0.1 is set as the rounding value
  --    * The default is set to 1

  -- [[ 0_0 ]] --
  -- Try changing the default values for these params
  -- Try replacing one of the params with the one at the bottom (for engine.buf_win_end) that is commented out 
  engine_commands = {
  -- abbr.      engine command       range, rounding       default         
     { "sp",    engine.speed,        { -2,2,true,0.1 },    1         },
     { "dn",    engine.density,      { 1,40,true },        1         },
     { "ps",    engine.pos,          { 0,1 },              0         },
     { "sz",    engine.size,         { 0.01,0.5 },         0.1       },
     { "jt",    engine.jitter,       { 0,1 },              0         },
     { "ge",    engine.grain_env,    { 1,6,true,1 },       6         },
     { "rl",    engine.rec_level,    { 0,1,true,0.01 },    1         },
     { "pl",    engine.pre_level,    { 0,1,true,0.01 },    0         },
  -- { "we",    engine.buf_win_end,  { 0.01,1 },           1         },
  }

  -- Update the engine with the default settings for each engine command
  local voice = self.index
  for ix=1,#engine_commands do
    local command_abbr = engine_commands[ix][1]
    local command = engine_commands[ix][2]
    local default = engine_commands[ix][4]
    print("init command", command_abbr, default)
    command(voice,default)
  end
end

sun_mode_2.engine_cmd_range_mapper = function (range_data,value)
  local min = range_data[1]
  local max = range_data[2]
  local round = range_data[3]
  local round_precision =  range_data[4] and range_data[4] or 0
  local mapped_val
  if round == true then 
    mapped_val = util.round(util.linlin(1,128,min,max,value),round_precision)
  else
    mapped_val = util.linlin(1,128,min,max,value)
  end
  return mapped_val
end


function sun_mode_2.get_engine_command_data(self,reflector_id) 
  local command_location, command_data
  for location=1,#engine_commands do 
    if self.reflector_locations[location] == reflector_id then 
      command_location = location 
      command_data = engine_commands[command_location]
      return command_data
    end
  end
end

-- For each item in the `engine_commands` table, look up the command name acronym
--   which is located in the first slot of the `engine_commands` table
-- If the acronym matches the one in this functions `engine_command_name` parameter,
--   look up the corresponding `reflector_id` from the `self.reflector_locations` table
function sun_mode_2.get_reflector_id_by_engine_command_name(self, engine_command_name)
  local reflector_id
  for engine_command_ix=1,#engine_commands do
    local engine_command = engine_commands[engine_command_ix]
    local command_name = engine_command[1]
    if command_name == engine_command_name then
      reflector_id = self.reflector_locations[engine_command_ix]
      -- print("found reflector_id", reflector_id)
      return reflector_id
    end
  end
  if not reflector_id then print("couldn't find reflector id for ", engine_command_name) end
end
  
-- Update the SuperCollider engine and keep track of the updates
-- Note#1: for the third parameter (reflector_id_or_command_name) you can send either a `reflector_id` 
--         or the two letter acronym for the engine command (e.g. 'sz' for engine.size).
--         See `engine_commands` above for the list of acronyms.
-- Note#2: the 4th parameter, `value`, is relative to the photon value (1-128)
--         The update_engine code remaps these values to the ones expected by the supercollider engine
--         For example, setting a value of 128 for speed would be mapped to 5 (i.e. max speed)
function sun_mode_2.update_engine(self, sc_voice, reflector_id_or_command_name, value)
  -- If reflector_id_or_command_name is a number, assumed it is a reflector_id
  --   Otherwise, assume it is a command name acronym from the `engine_commmands` table.
  local reflector_id, engine_command_name, engine_command_data
  if type(reflector_id_or_command_name) == "number" then
    reflector_id = reflector_id_or_command_name
    engine_command_data = sun_mode_2.get_engine_command_data(self,reflector_id) 
    engine_command_name = engine_command_data[1]
  else
    engine_command_name = reflector_id_or_command_name
    reflector_id = sun_mode_2.get_reflector_id_by_engine_command_name(self, engine_command_name)
    engine_command_data = sun_mode_2.get_engine_command_data(self,reflector_id) 
  end    
  
  local engine_command_ranges = engine_command_data[3]
  local mapped_val = sun_mode_2.engine_cmd_range_mapper(engine_command_ranges,value)
  local engine_fn = engine_command_data[2]
  self.engine_vals[reflector_id] = mapped_val
  
  -- Call the SuperCollider engine command
  engine_fn(sc_voice,mapped_val)
  -- print("update engine (reflector/command/mapped value/original)  ", reflector_id, engine_command_name, mapped_val,value)
end
  
------------------------------------------
-- Event router (configure controls here)
------------------------------------------
-- Define an event router that consolidates all the reflector events and lattice/sprocket events
function sun_mode_2.event_router(self, reflector_id, event_type, value)
  local sun = self.index
  -- print('sun 2 '..reflector_id, value)
  if not self.sprocket_1 or not self.sprocket_2 then return end

  if sun == 1 then
    if event_type == "process" then 
      -- Update changes triggered by encoder 3 and/or reflector recordings
      local sc_voice = sun
      sun_mode_2.update_engine(self, sc_voice, reflector_id, value)
      sun_mode_2_grid_state(reflector_id, value)
    end

  elseif sun == 2 then
    if event_type == "process" then 
      -- Update changes triggered by encoder 3 and/or reflector recordings
      local sc_voice = 2
      sun_mode_2.update_engine(self, sc_voice, reflector_id, value)
    end

  end
  -- sun_mode_2_grid_state(reflector_id, value)
end


function sun_mode_2_grid_state(reflector, value)
  local grid_value = util.round_up(util.linlin(0, 127, 8, 1, value))
  local x = (reflector+1)/2
  lit[x] = {}
  for i=8,grid_value,-1 do
    lit[x][i] = 1
  end
  grid_dirty = true
end

return sun_mode_2