Unit testing with norns is possible using LuaUnit, which is packaged with norns in the `test.luaunit` module. 

This module is not used much (if at all) in norns scripting, although a good example of unit testing norns code may be found alongside the norns library's `container` modules.

According to the norns lib's `container` [TESTING.md](https://github.com/monome/norns/blob/main/lua/lib/container/TESTING.md) readme file, Luaunit test must be run individually with Lua 5.3, but the base norns os install only includes the lua5.1 interpreter. Therefore, to test using lua5.3, Lua 5.3 must first be installed on your norns, by ssh'ing to norns and then running `sudo apt-get install lua5.3`.


After Lua 5.3 has been installed, to run the tests in this directory:

- ssh to norns
- `cd /home/we/dust/code/kinesis/lib/tests` 
- `LUA_PATH='lib/?.lua' lua5.3 lib/container/<name_of_test_file>_test.lua -v`


Alternatively, it is possible to run LuaUnit directly from within a norns script, without having to install Lua 5.3 or run the tests from the command line. To see an example of this in action, uncomment this line from the main *kinesis.lua* file:

`-- include "lib/tests/utilities_test"       -- load unit tests for lib/utilities`