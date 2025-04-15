-- kinesis (gestures): built for the habitus workshop
-- 0.1 @jaseknighter
-- l.llllllll.co/<insert link to lines thread>
--
--
--  this script presents two "suns" made up of "rays" and "photons"
--  each sun operates in a "modes"
--   to change modes: press K1 + K2 (sun 1) or K1 + K3 (sun 2)
--
--   mode 1
--     ui behavior:    turning an encoder moves photons around the sun
--     sound behavior: softcut
--   mode 2 
--     ui behavior:   the movement of photons in each ray gets recorded 
--                     and played back (using the reflection library)
--     sound behavior: softcut
--   mode 3
--     ui behavior: encoders activate a photon moving around its sun
--     sound behavior: nothing by default. up to you to define
--   mode 4
--     ui behavior: same as mode 1
--     sound behavior: nothing by default. up to you to define

-- lines starting with "--" are comments, they don't get executed

-- find the --[[ 0_0 ]]-- for good places to edit!

---------------------------------------------------
-- todo: 
-- fix code so redraw timer doesn't have to constantly set screen_dirty to true
-- consider updating each sun mode's init func so it sets state details in a unique table
--   (e.g. `suns[sun_id][mode_id]`)
-- for sun 2 (granular voice):
--   finish setting up the mode to send granulate a recording
--   add a param to switch between live and recorded mode
--   should we create two voices (one for each sun)?
--   update the sun brightness to reflect the position of the grainbuf playhead
-- add the --[[ 0_0 ]]-- for good places to edit!
-- add "ideas for experimenting for each sun"
--   for example: 
--     switch rec and pre levels for the live recording
--     add panning
---------------------------------------------------

lattice = require("lattice")
reflection = require 'reflection'
musicutil = require 'musicutil'

include "lib/utilities"

local Sun = include "lib/sun"

engine.name = 'Sunshine'
-- engine.name = 'Kinesis'

screen_dirty = true

local num_sun_modes = 4
local prev_norns_menu_status = false
local redrawtimer
alt_key = false

suns = {}

-- there are 4 "modes" 
--   note: modes 3 & 4 doesn't actually do anything sound-wise by default
--   mode1: (softcut controls) encoder sets a photon's velocity
--   mode2: (supercollider synth controls) uses the reflection library to animate photons in each "ray"
--   mode3: (generic) encoder changes the active "photon"
--   mode4: (generic) encoder sets a photon's velocity
sun_modes = {2, 1} 

function init()
  init_sun(1)
  init_sun(2)

  -- clear the softcut buffer in case it was being used by a 
  --   previously loaded script
  softcut.buffer_clear()
 
  redrawtimer = metro.init(function()
    screen_dirty = true -- this shouldn't be necessary by default
    if prev_norns_menu_status and not norns.menu.status() then
      screen_dirty = true
    -- elseif not norns.menu.status() and screen_dirty == true then
    elseif not norns.menu.status() then
      redraw()
    end
    prev_norns_menu_status = norns.menu.status()
  end, 1/15, -1)

  clock.run(function()
    --delay starting the redraw timer
    --to give the script time to finish initializing
    clock.sleep(1)
    redrawtimer:start()
  end)
end

function init_sun(sun)
  local mode = sun_modes[sun]

  if suns[sun] and suns[sun].deinit then suns[sun].deinit(suns[sun]) end
  suns[sun] = Sun:new(sun, mode)
  screen_dirty = true
end

function key(n, z)
  screen_dirty = true
  if n==1 then
    if  z==1 then
      alt_key = true
    elseif n==1 and z==0 then
      alt_key = false
    end
  elseif n==2 then
    if z==0 then
      if alt_key == true then
        sun_modes[1] = util.wrap(sun_modes[1]+1,1,num_sun_modes)
        init_sun(1,sun_modes[1])
      end
    end
  elseif n==3 then 
    print(n,z)
    if z==0 then
      if alt_key == true then
        sun_modes[2] = util.wrap(sun_modes[2]+1,1,num_sun_modes)
        init_sun(2,sun_modes[2])
      end
    end
  end

  if (n == 2 or n == 3) and alt_key == false then
    local sun_index = n - 1
    suns[sun_index]:key(n, z)
  end
end

function enc(n, delta)
  screen_dirty = true
  if n == 1 then
    suns[1]:enc(n,delta)
    suns[2]:enc(n,delta)
  elseif (n == 2 or n == 3) then
    local sun_index = n - 1
    suns[sun_index]:enc(n,delta)
  end
end
  
function redraw()
  if screen_dirty then screen.clear() end
  for i = 1, 2 do
    suns[i]:redraw(screen_dirty)
  end

  -- draw the sun mode # at the top left of each sun
  screen.level(3)               -- set a brightness level for the screen
  screen.move(2,5)              -- 1st sun: move the screen cursor 
  screen.text(sun_modes[1])     -- 1st sun: draw the sun's number
  screen.move(67,5)             -- 2nd sun: move the screen cursor 
  screen.text(sun_modes[2])     -- 2nd sun: draw the sun's number
  
  
  screen.level(15)               -- set a brightness level for the screen
  screen.move(64,0)
  screen.line(64,64)
  screen.stroke()
  screen.update()               -- update the screen
  -- set screen_dirty to false so we only draw when necessary
  screen_dirty = false        
end