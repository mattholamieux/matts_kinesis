-- Important notes about using LuaUnit: 
--    LuaUnit is designed for synchronous testing, so asynchronous tests 
--      such as tests using clock.run won't be included in the initial run of LuaUnit.
--      That said, as demonstrated in `test_morph` below, LuaUnit functions can be included in a run.
--        However, errors from LuaUnit functions in an async context won't be reported until after the initial LuaUnit results are presented.
--    To run these tests from a terminal, follow these steps: 
--      Install lua5.3 (see the tests.md file for details)
--      Navigate to the kinesis directory, i.e., `cd /home/we/dust/code/kinesis/`
--      Run lua5.3 lib/<name_of_test_file>_test.lua -v`
--      Include any norns modules and/or script libs required for the tests (e.g. util, )
--    

-- Norns_Utils = dofile('/home/we/norns/lua/lib/util.lua')
-- Kinesis_Utils = dofile('/home/we/dust/code/kinesis/lib/utilities.lua')

local T = dofile('/home/we/norns/lua/lib/test/luaunit.lua')

function test_sign()
  local pos = sign(3) 
  local neg = sign(-3) 
  local zero = sign(0) 
  T.assertEquals(pos, 1)
  T.assertEquals(neg, -1)
  T.assertEquals(zero, 0)
end

function test_quotient_remainder()
  --test 1
  local integer_quotient1, remainder1 = quotient_remainder(3,3)
  T.assertEquals(integer_quotient1, 1)
  T.assertEquals(remainder1, 0)
  -- test 2
  local integer_quotient2, remainder2 = quotient_remainder(1,3)
  remainder2 = tostring(util.round(remainder2, 0.0001))
  T.assertEquals(integer_quotient2, 0)
  T.assertEquals(remainder2, "0.3333")
  -- test 3
  local integer_quotient3, remainder3 = quotient_remainder(10,3)
  remainder3 = tostring(util.round(remainder3, 0.0001))
  T.assertEquals(integer_quotient3, 3)
  T.assertEquals(remainder3, "0.3333")
  -- test 4
  local integer_quotient4, remainder4 = quotient_remainder(10,-3)
  remainder4 = tostring(util.round(remainder4, 0.0001))
  T.assertEquals(integer_quotient4, -3)
  T.assertEquals(remainder4, "-0.3333")
end

function test_morph_callback(next_val, done, caller_id)
  if done == true then -- if done, next value should be 10
    print("test morph done",next_val, done, caller_id)
    T.assertEquals(next_val,10)
    tests_done()
  end
end

function test_morph()
  clock.run(function()
    morph(nil,1,10,2,10,'lin',test_morph_callback)
  end)
end

function tests_done()
  print("")
  print("completed: unit tests for /lib/utilities.lua")
  print("----------------------------------------")
end

function run()
  -- T.LuaUnit.run("test_quotient_remainder",)
  T.LuaUnit.run("test_morph")
end

clock.run(function()
  clock.sleep(1)
  print("")
  print("----------------------------------------")
  print("start: unit tests for /lib/utilities.lua")
  run()
end)