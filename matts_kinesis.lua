-- matt's kinesis: built on top of 
-- jaseknighter's kinesis script 
-- as part of habitus workshop
-- 0.1 @mbn


-- load norns modules
lattice = require("lattice")
reflection = require 'reflection'
musicutil = require 'musicutil'
fileselect=require 'fileselect'


engine.name = 'Sunshine'      -- use the Sunshine SuperCollider engine

include "lib/utilities"       -- load utilities written for this script

local Sun = include "lib/sun" 

screen_dirty = true
local num_sun_modes = 2
local prev_norns_menu_status = false
local redrawtimer
alt_key = false
suns = {}

-- GRID 
g = grid.connect()
lit = {} -- lit keys for grid presses
 grid_dirty = true


-- By default, set sun 1 to mode 2 and sun 2 to mode 3
local current_modes = {2, 3} -- [[ 0_0 ]] -- change the default mode for each sun

-- All norns scripts call an init function when the script first loads
function init()
  screen.clear()
  init_sun(1)
  init_sun(2)

  -- Clear the softcut buffer in case it was being used by a previously loaded script
  softcut.buffer_clear()
 
  local redraw_rate = 1/15
  redrawtimer = metro.init(function()
    if prev_norns_menu_status and not norns.menu.status() then
      screen_dirty = true

    end
    prev_norns_menu_status = norns.menu.status()
    redraw()
  end, redraw_rate, -1)

  clock.run(function()
    clock.sleep(1) -- Delay starting the redraw timer to give the script time to finish initializing
    
    redrawtimer:start()
  end)
  
  audio.level_adc_cut (0.0) 
  audio.level_eng_cut (1.0)
  
  for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
    lit[x] = {} -- create a table that holds...
    for y = 1,8 do -- each y-row (8 on a 128-sized grid)!
      lit[x][y] = false -- the state of each key is 'off'
    end
  end
  clock.run(grid_redraw_clock)
  
  -- janky grid initialization
  for i=1, 8 do
    g.key(i, 4, 1)
  end
  g.key(9, 5, 1)
  g.key(10, 5, 1)
  g.key(11, 3, 1)
  g.key(12, 3, 1)
  g.key(13, 1, 1)
  g.key(14, 1, 1)
  g.key(15, 7, 1)
  g.key(16, 5, 1)
end

function init_sun(sun)
  local mode = current_modes[sun]
  if suns[sun] then suns[sun].deinit(suns[sun]) end
  suns[sun] = Sun:new(sun, mode)
  screen_dirty = true
end

function key(n, z)
  -- print("key", n, z) -- [[ 0_0 ]] --
  if n==1 then
    if  z==1 then
      alt_key = true
    elseif n==1 and z==0 then
      alt_key = false
    end
     print (alt_key)
  end

  if (n == 2 or n == 3)  then
    local sun_index = n - 1
    suns[sun_index]:key(n, z)
  end
end

function enc(n, delta)
  -- print("enc", n, delta) -- [[ 0_0 ]] --
  if n == 1 then
    suns[1]:enc(n,delta)
    suns[2]:enc(n,delta)
  elseif (n == 2 or n == 3) then
    local sun_index = n - 1
    suns[sun_index]:enc(n,delta)
  end
end

function g.key(x,y,z)
  -- print('grid pressed '..x,y,z)
  local sun_index = 1
  if x>8 then sun_index = 2 end
  suns[sun_index]:grid(x,y,z)
end


function redraw()
  if screen_dirty then 
    screen.clear()                        -- Clear the screen
    screen.level(3)                       -- Set a brightness level
    screen.move(2,5)                      -- 1st sun: move the screen cursor 
    screen.text("m"..current_modes[1])    -- 1st sun: draw the sun's number
    screen.move(67,5)                     -- 2nd sun: move the screen cursor 
    screen.text("m"..current_modes[2])    -- 2nd sun: draw the sun's number   
    screen.level(15)                      -- Set a brightness level for the screen
    screen.move(64,0)                     -- Move the drawing position the the top center
    screen.line(64,64)                    -- Draw a line to the bottom center
    screen.stroke()                       -- 
  end
  
  for i=1, 2 do
    suns[i]:redraw(screen_dirty)          -- Call each sun's redraw function
  end
  screen.update()                         -- Copy the screen buffer to the screen
  screen_dirty = false
  
end


function grid_redraw()
  g:all(0)
  for x = 1,8 do -- for each column...
    for y = 1,8 do -- and each row...
      if lit[x][y] then -- if the key is held...
        g:led(x,y,15) -- turn on that LED!
      end
    end
  end
  for x = 9,16 do -- for each column...
    for y = 1,8 do -- and each row...
      if lit[x][y] then -- if the key is held...
        g:led(x,y,9) -- turn on that LED!
      end
    end
  end
  g:refresh()
end

function grid_redraw_clock()
  while true do
    clock.sleep(1/30)
    if grid_dirty then 
      grid_redraw() 
      grid_dirty = false 
    end
  end
end
