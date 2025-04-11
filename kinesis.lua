-- kinesis (gestures): built for the habitus workshop
-- 0.1 @jaseknighter
-- l.llllllll.co/<insert link to lines thread>
--
--
--  this script presents two "suns" made up of "rays" and "photons"
--     each sun operates in one of four modes
--     to change modes: press K1 + K2 (sun 1) or K1 + K3 (sun 2)
--
--  the modes are:
--     mode 1: encoder "activates" a "photon" around the sun
--     mode 2: encoder velocity is measured and the velocity is 
--         used to "activate" a "photon" around the sun
--     mode 3: encoder velocity is measured and the velocity is 

-- lines starting with "--" are comments, they don't get executed

-- find the --[[ 0_0 ]]-- for good places to edit!

-- https://monome.org/docs/norns/reference/lib/reflection

---------------------------------------------------
-- todo: 
-- add a deinit function to the modes to clear out their custom variables
-- add the --[[ 0_0 ]]-- for good places to edit!
-- add mode 3 to integrate the reflection library
-- move sun code into its own file so main file is 90% for easy experimation
-- update code so setting a photon is more like grid set state: led (x, y, val)
-- add key functions to all sun mode files
---------------------------------------------------
-- reflection = require 'reflection' -- a gesture library built into norns


lattice = require("lattice")
reflection = require 'reflection'
musicutil = require 'musicutil'

include "lib/utilities"
local Sun = include "lib/sun"

engine.name = 'Moonshine'

screen_dirty = true
local prev_norns_menu_status = false
local redrawtimer

alt_key = false

num_sun_modes = 4

suns = {}

-- there are 4 "modes"
--   mode1: encoder changes the active "photon"
--   mode2: encoder sets a velocity for changing the active "photon"
--   mode3: uses the reflection library to animate photons
--   mode4: up to the user to program how the ui is changed
sun_modes = {3, 3} 


-- these two callbacks (ray_selected_callback and photon_selected_callback)
--    are used in modes 1 and 2
function ray_selected_callback(sun,ray,photon)
    -- print("new ray selected",sun, ray, photon)
end

function photon_selected_callback(sun,ray,photon)
    -- print("new photon selected",sun, ray, photon)    
end

function init()
    init_sun(1)
    init_sun(2)
    redrawtimer = metro.init(function()
        if prev_norns_menu_status and not norns.menu.status() then
            screen_dirty = true
        elseif not norns.menu.status() then
            redraw()            
        end
        prev_norns_menu_status = norns.menu.status()
    end, 1/30, -1)

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
    suns[sun] = Sun:new(sun, mode,ray_selected_callback,photon_selected_callback)
    screen_dirty = true
end

function key(n, z)
    if n==1 then
        if  z==1 then
            alt_key = true
        elseif n==1 and z==0 then
            alt_key = false
        end
    elseif n==2 then
        if z==1 then
            if alt_key == true then
                sun_modes[1] = util.wrap(sun_modes[1]+1,1,num_sun_modes)
                init_sun(1,sun_modes[1])
            end
        end
    elseif n==3 then 
        print(n,z)
        if z==1 then
            if alt_key == true then
                sun_modes[2] = util.wrap(sun_modes[2]+1,1,num_sun_modes)
                init_sun(2,sun_modes[2])
            end
        end
    end

    if (n == 2 or n == 3) then
        local sun_index = n - 1
        suns[sun_index]:key(n, z)
    end
end

function enc(n, delta)
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
    screen.level(3)                     -- set a brightness level for the screen
    screen.move(2,5)                    -- 1st sun: move the screen cursor 
    screen.text(sun_modes[1])           -- 1st sun: draw the sun's number
    screen.move(67,5)                   -- 2nd sun: move the screen cursor 
    screen.text(sun_modes[2])           -- 2nd sun: draw the sun's number

    screen.update()                     -- update the screen
    
    -- set screen_dirty to false so we only draw when necessary
    screen_dirty = false                
end