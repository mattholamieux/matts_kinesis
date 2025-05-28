-- Sun mode 2: granular synthesis using the GrainBuf UGen, controlled with the reflection library
-- References: 
--   https://monome.org/docs/norns/reference/lib/reflection
--   https://doc.sccode.org/Classes/GrainBuf.html 

sun_mode_3 = {}

-- define state names.
local states = {'r','p','l'}  -- record, play, loop
local rates = {-4, -3, -2, -1, -0.5, 0.5, 1, 2, 4}
------------------------------------------
-- Initialization and deinitialization
------------------------------------------
function sun_mode_3.init(self)
  -- print("grain_params_created",self.index,grain_params_created)
  -- If sun mode 2 is being inited for the first time, create a global variable called `grain_params_created`  
  if grain_params_created == nil then grain_params_created = false end
  
  self.reflection_indices = {}
  self.max_cursor = 8 * 16
  self.state = 1  -- States: 1 = record, 2 = play, 3 = loop
  -- self.grain_mode = 1 -- Grain modes: 1 = granulate live audio, 2 = granulate an audio file
  
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
  self.softcut_vals = {1, 1, 5, 5, 8000, 8000, 0.5, 0}
  
  
  for i=1, #self.reflector_locations do
    local reflector_id = self.reflector_locations[i]
    self.record[reflector_id]  = 0
    self.play[reflector_id]    = 1
    self.loop[reflector_id]    = 1
    sun_mode_3.deselect_reflector(self, reflector_id)
  end

  sun_mode_3.init_reflectors(self)
  sun_mode_3.hide_non_reflector_rays(self)

  -- 0_0 -- Make the 2nd reflector selected by default
  self.selected_ray = self.reflector_locations[2]
  sun_mode_3.select_reflector(self, self.selected_ray)

  -- Deinit (cleanup) function
  self.deinit = function(self)
    -- print("deinit sun "..self.index .. " mode 2")
    -- engine.gate(self.index,0) -- set gate to 1 so grains can play
    -- self.lattice:stop()
    self.lattice = nil
    for reflector=1,#self.reflectors do
      self.reflectors[reflector]:stop()
      self.reflectors[reflector]:clear()
    end
    _menu:rebuild_params()
    self.deinit = nil
  end  
  
  softcut.buffer_clear()
  audio.level_eng_cut(1.0)
  
  for i=1, 2 do
    softcut.enable(i,1)
    softcut.buffer(i,i)
    softcut.level(i,1.0)
    softcut.rate(i,1.0)
    softcut.loop(i,1)
    softcut.loop_start(i,1)
    softcut.position(i,1)
    softcut.play(i,1)
    softcut.fade_time(i,0.01)
    softcut.rate_slew_time(i,0.5)
    softcut.rec_level(i,1.0)
    softcut.pre_level(i,0.0)
    softcut.pan(i, 0)
    softcut.post_filter_dry(i,0.0)
    softcut.post_filter_lp(i,1.0)
    softcut.post_filter_fc(i,4000)
    softcut.post_filter_rq(i,0.5)
    softcut.rec(i,1)
  end
    softcut.level_input_cut(1,1,1.0)
    softcut.level_input_cut(2,1,0.0)
    softcut.level_input_cut(1,2,0.0)
    softcut.level_input_cut(2,2,1.0)
    softcut.level_cut_cut(1, 2, 0 )
    softcut.level_cut_cut(2, 1, 0 )
end



------------------------------------------
-- Helpers
------------------------------------------
function sun_mode_3.hide_non_reflector_rays(self)
  for ray = 1, NUM_RAYS do
    if not table_contains(self.reflector_locations, ray) then
      self:set_ray_brightness(ray, 0)
    end
  end
end

------------------------------------------
-- Get minimum brightness for a reflector
------------------------------------------
function sun_mode_3.get_min_level(self, reflector_id)
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
function sun_mode_3.get_next_ray(self, delta)
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
function sun_mode_3.grid(self, x, y, z)
  
  -- Adjust reflector cursor for the relevant reflector.
  self.selected_ray = ((x-8)*2)-1
  
  sun_mode_3.set_reflector_cursor_grid(self, self.selected_ray, y)
  sun_mode_3.draw_reflector_cursor(self, self.selected_ray)
end


------------------------------------------
-- Encoder handler
------------------------------------------
function sun_mode_3.enc(self, n, delta)
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
      self.selected_ray = sun_mode_3.get_next_ray(self, delta)
      sun_mode_3.select_reflector(self, self.selected_ray)
      sun_mode_3.draw_reflector_cursor(self, self.selected_ray)
    else
      -- Adjust reflector cursor for the selected reflector.
      sun_mode_3.set_reflector_cursor_rel(self, self.selected_ray, delta)
      sun_mode_3.draw_reflector_cursor(self, self.selected_ray)
    end
  end
end

------------------------------------------
-- Key handler
------------------------------------------
function sun_mode_3.key(self, n, z)
  if alt_key == true then
    for i=1, 15, 2 do
      local reflector_id = i
      self.reflectors[reflector_id]:clear()
    end
  else
    for i=1, 15, 2 do
      local reflector_id = i
        -- local reflector_id = self.selected_ray
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

------------------------------------------
-- Get last selected photon for a reflector
------------------------------------------
function sun_mode_3.get_last_selected_photon(self, reflector_id)
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
function sun_mode_3.get_photon_brightness(self, reflector_id, photon)
  local brightness, last_ph, last_ph_brightness
  if self.reflection_indices[reflector_id] then
    last_ph, last_ph_brightness = sun_mode_3.get_last_selected_photon(self, reflector_id)
    if photon < last_ph then
      brightness = MAX_LEVEL
    elseif photon == last_ph then
      brightness = last_ph_brightness
    else
      brightness = sun_mode_3.get_min_level(self, reflector_id)
    end
  else
    brightness = sun_mode_3.get_min_level(self, reflector_id)
  end
  return brightness, last_ph
end

------------------------------------------
-- Draw the reflector cursor for a given reflector
------------------------------------------
function sun_mode_3.draw_reflector_cursor(self, reflector_id)
  local brightness_fn = function(photon_id,photon)
    local brightness = sun_mode_3.get_photon_brightness(self, reflector_id, photon_id)
    photon:set_brightness(brightness)
    return nil
  end
  self:set_ray_brightness(reflector_id,brightness_fn)
end

------------------------------------------
-- Set reflector cursor (absolute)
------------------------------------------
function sun_mode_3.set_reflector_cursor(self, reflector_id, val)
  
  if not self.reflection_indices[reflector_id] then
    self.reflection_indices[reflector_id] = { reflection_cursor = 1 }
  end
  
  self.reflection_indices[reflector_id].reflection_cursor = val
  -- print("set_reflector_cursor", reflector_id, val)
  sun_mode_3.draw_reflector_cursor(self, reflector_id)
end

------------------------------------------
-- Set reflector cursor (relative)
------------------------------------------
function sun_mode_3.set_reflector_cursor_rel(self, reflector_id, delta)
  if not self.reflection_indices[reflector_id] then
    self.reflection_indices[reflector_id] = { reflection_cursor = 1 }
  end
  local cursor = self.reflection_indices[reflector_id].reflection_cursor
  local new_cursor = util.clamp(cursor + delta, 1, self.max_cursor)
  self.reflection_indices[reflector_id].reflection_cursor = new_cursor
  -- Store reflector data.
  local new_data = { reflector = reflector_id, value = new_cursor } -- IS THIS THE KEY?
  sun_mode_3.store_reflector_data(self, reflector_id, new_data)

  -- pass the event value to the router
  print('event router '..reflector_id, new_data.value)
  sun_mode_3.event_router(self, reflector_id, "process", new_data.value)
end

------------------------------------------
-- Set reflector cursor (GRID)
------------------------------------------
function sun_mode_3.set_reflector_cursor_grid(self, reflector_id, val)
  if not self.reflection_indices[reflector_id] then
    self.reflection_indices[reflector_id] = { reflection_cursor = 1 }
  end
  local new_val = 9-val
  local cursor = self.reflection_indices[reflector_id].reflection_cursor
  local new_cursor = util.linlin(1,8, 1, self.max_cursor,new_val)
  self.reflection_indices[reflector_id].reflection_cursor = new_cursor
  -- Store reflector data.
  local new_data = { reflector = reflector_id, value = new_cursor } -- IS THIS THE KEY?
  sun_mode_3.store_reflector_data(self, reflector_id, new_data)

  -- pass the event value to the router
  sun_mode_3.event_router(self, reflector_id, "process", new_data.value)
end

------------------------------------------
-- Deselect a reflector
------------------------------------------
function sun_mode_3.deselect_reflector(self, reflector_id)
  self:set_ray_brightness(reflector_id,function() 
    return sun_mode_3.get_min_level(self, reflector_id)
  end)
end

------------------------------------------
-- Select a reflector
------------------------------------------
function sun_mode_3.select_reflector(self, reflector_id)
  -- First, hide all non-reflector rays.
  sun_mode_3.hide_non_reflector_rays(self)
  -- Then update the display for the selected reflector.
  local set_reflector_brightness = function(photon_id, photon)
    if sun_mode_3.ray_has_cursor(self) then
      sun_mode_3.draw_reflector_cursor(self, reflector_id)
    end
    if photon_id < PHOTONS_PER_RAY then
      return min_level
    else
      local brightness = sun_mode_3.get_photon_brightness(self, reflector_id, photon_id)
      photon:morph_photon(MAX_LEVEL, brightness, 1, 15, 'lin', nil, reflector_id)
      return nil
    end
  end
  self:set_ray_brightness(reflector_id,set_reflector_brightness)
end

------------------------------------------
-- Check if the currently selected reflector has cursor data
------------------------------------------
function sun_mode_3.ray_has_cursor(self)
  return self.reflection_indices[self.selected_ray] ~= nil
end

------------------------------------------
-- Calculate pointer position (for display)
------------------------------------------
function sun_mode_3.calc_pointer_position(self)
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
function sun_mode_3.redraw(self)
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

  local softcut_params = {'l1', 'l2', 'r1', 'r2', 'c1', 'c2', 'fb', 'sp'}
  local selected_param = softcut_params[(self.selected_ray +1) /2]
  local top_right_x = (self.index == 1) and 60 or 127
  local top_right_y = 5
  screen.move(top_right_x, top_right_y)
  screen.rect(top_right_x-15, top_right_y-5, 18, 8)
  screen.level(0)
  screen.fill()
  screen.move(top_right_x, top_right_y)
  screen.level(3)
  if (selected_param) then 
    screen.text_right(selected_param)
  end
  
  local bottom_right_x = (self.index == 1) and 60 or 110
  local bottom_right_y = 62
  screen.move(bottom_right_x, bottom_right_y)
  screen.rect(bottom_right_x, bottom_right_y-5, 18, 8)
  screen.level(0)
  screen.fill()
  screen.move(bottom_right_x, bottom_right_y)
  screen.level(3)
  local val = util.round(self.softcut_vals[(self.selected_ray +1) /2], 0.1)
  screen.text(val)
  
  local point_x, point_y = sun_mode_3.calc_pointer_position(self)
  screen.level(0)
  screen.circle(point_x, point_y, 2)
  screen.fill()
end

------------------------------------------
------------------------------------------
-- Reflection code       
------------------------------------------
------------------------------------------
function sun_mode_3.store_reflector_data(self, reflector_id, data)
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

function sun_mode_3.init_reflectors(self)
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
      sun_mode_3.set_reflector_cursor(self, reflector_id, value)

      -- pass the event value to the router
      sun_mode_3.event_router(self, reflector_id, "process", value)

    end

    -- end-of-loop callback
    self.reflectors[reflector_id].end_of_loop_callback = function()
      sun_mode_3.event_router(self, reflector_id, "end_of_loop")
      -- print("reflector step", reflector_id)
    end
    
    -- (optional) callback for recording start
    self.reflectors[reflector_id].start_callback = function()
      sun_mode_3.event_router(self, reflector_id, "record_start")
      -- print("recording started", reflector_id)
    end
    
    -- (optional) callback for recording stop
    self.reflectors[reflector_id].end_of_rec_callback = function()
      sun_mode_3.event_router(self, reflector_id, "record_end")
      -- print("recording ended", reflector_id)
    end

    -- (optional) callback for reflector step
    self.reflectors[reflector_id].step_callback = function()
      sun_mode_3.event_router(self, reflector_id, "step")
      -- print("reflector step", reflector_id)
    end
    
    self.reflectors[reflector_id].end_callback = function()
      -- print("pattern end callback", reflector_id)
      sun_mode_3.event_router(self, reflector_id, "pattern_end")
      -- local is_looping = (self.loop[reflector_id] == 1)
      -- if not is_looping then self.play[reflector_id] = 0 end
    end
  end
end


------------------------------------------
-- Lattice code
-- Note: the lattice code is here for reference,
--       but isn't actually used
------------------------------------------
-- Init lattice
function sun_mode_3.init_lattice(self)
  local sun = self.index

  self.lattice = lattice:new{
    auto = true,
    ppqn = 96
  }   

  -- Define sprockets for sun1 and sun 2
  self.sprocket_1 = self.lattice:new_sprocket{
    action = function(t) 
      sun_mode_3.event_router(self, nil, "sprocket")
    end,
    division = 1/4, -- [[ 0_0 ]] --
    enabled = true  -- [[ 0_0 ]] --
  }

  self.sprocket_2 = self.lattice:new_sprocket{
    action = function(t) 
      sun_mode_3.event_router(self, nil, "sprocket")
    end,
    division = 1/8, -- [[ 0_0 ]] --
    enabled = true  -- [[ 0_0 ]] --
  }

  self.lattice:start()
end

------------------------------------------
-- Event router (configure controls here).  <<<<<<<< THIS IS WHERE THE MAGIC HAPPENS!
------------------------------------------
-- Define an event router that consolidates all the reflector events and lattice/sprocket events
function sun_mode_3.event_router(self, reflector_id, event_type, value)
  
  local sun = self.index
  -- if not self.sprocket_1 or not self.sprocket_2 then return end

  if sun == 1 then
  

  elseif sun == 2 then
    if event_type == "process" then 
      -- Update changes triggered by encoder 3 and/or reflector recordings
      if reflector_id == 1 then
        local new_value =  util.linlin(1, 128, 0.1, 2.0, value)
        self.softcut_vals[1] = new_value
        softcut.loop_end(1, 1+new_value)
        -- print('length left '..new_value)
      elseif reflector_id == 3 then
        local new_value =  util.linlin(1, 128, 0.1, 2.0, value)
        self.softcut_vals[2] = new_value
        softcut.loop_end(2, 1+new_value) 
        -- print('length right '..new_value)
      elseif reflector_id == 5 then
        local new_value =  util.round_up(util.linlin(1, 128, 1, #rates, value),1)
        self.softcut_vals[3] = rates[new_value]
        softcut.rate(1, rates[new_value])   
        -- print('rate left '..rates[new_value])
      elseif reflector_id == 7 then
        local new_value =  util.round_up(util.linlin(1, 128, 1, #rates, value),1)
        self.softcut_vals[4] = rates[new_value]
        softcut.rate(2, rates[new_value])   
        -- print('rate right '..rates[new_value])
      elseif reflector_id == 9 then
        local new_value =  util.linexp(1, 128, 200, 10000, value)
        self.softcut_vals[5] = new_value
        softcut.post_filter_fc(1, new_value)   
        -- print('filter cutoff left '..new_value)
      elseif reflector_id == 11 then
        local new_value =  util.linexp(1, 128, 200, 10000, value)
        self.softcut_vals[6] = new_value
        softcut.post_filter_fc(2, new_value)   
        -- print('filter cutoff right '..new_value)
      elseif reflector_id == 13 then
        local new_value =  util.linlin(1, 128, 0.0, 1.0, value)
        self.softcut_vals[7] = new_value
        if new_value > 0.99 then
          for i=1, 2 do
            softcut.rec_level(i,0.0)
            softcut.pre_level(i,1.0)
          end
        else
          for i=1, 2 do
            softcut.rec_level(i,1.0)
            softcut.pre_level(i,0.0)
          end
          softcut.level_cut_cut(1, 2, new_value )
          softcut.level_cut_cut(2, 1, new_value )
        end
        -- print('feedback '..new_value)
      elseif reflector_id == 15 then
        local new_value =  util.linlin(1, 128, -1.0, 1.0, value)
        self.softcut_vals[8] = new_value
        softcut.pan(1, -new_value)
        softcut.pan(2, new_value)
        -- print('panL '..-new_value)
        -- print('panR '..new_value)
      end
      sun_mode_3_grid_state(reflector_id, value)
    end
  end
end


function sun_mode_3_grid_state(reflector, value)
  local grid_value = util.round_up(util.linlin(0, 127, 8, 1, value))
  local x = ((reflector+1)/2+8)
  lit[x] = {}
  for i=8,grid_value,-1 do
    lit[x][i] = 1
  end
  grid_dirty = true
end


return sun_mode_3
