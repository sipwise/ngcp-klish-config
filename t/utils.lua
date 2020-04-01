--
-- Copyright 2013 SipWise Team <development@sipwise.com>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This package is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
-- .
-- On Debian systems, the complete text of the GNU General
-- Public License version 3 can be found in "/usr/share/common-licenses/GPL-3".
--
local lu = require('luaunit')
local ut = require 'ngcp-klish.utils'

-- luacheck: ignore TestUtils
TestUtils = {} --class

    function TestUtils:setUp()
        self.simple_hash = {
            one = 1, two = 2, three = 3
        }
        self.simple_list = {
            1, 2, 3
        }
        self.complex_hash = {
            cone = self.simple_list,
            ctwo = self.simple_hash
        }
    end

    function TestUtils:test_table_deepcopy()
        lu.assertNotIs(ut.table.deepcopy(self.simple_hash), self.simple_hash)
        -- if the parameter is not a ut.table... it has to be the same
        lu.assertIs(ut.table.deepcopy("hola"), "hola")
    end

    function TestUtils:test_table_contains()
        lu.assertTrue(ut.table.contains(self.simple_hash, 3))
        lu.assertFalse(ut.table.contains(self.simple_hash, 4))
        lu.assertFalse(ut.table.contains(nil))
        lu.assertError(ut.table.contains, "hola",1)
    end

    function TestUtils:test_table_add()
        lu.assertEquals(self.simple_list, {1,2,3})
        ut.table.add(self.simple_list, 1)
        lu.assertEquals(self.simple_list, {1,2,3})
        ut.table.add(self.simple_list, 5)
        lu.assertEquals(self.simple_list, {1,2,3,5})
        ut.table.add(self.simple_list, 4)
        lu.assertEquals(self.simple_list, {1,2,3,5,4})
    end

    function TestUtils:test_table_tostring()
        lu.assertError(ut.table.tostring,nil)
        lu.assertEquals(ut.table.tostring(self.simple_list), "{1,2,3}")
        lu.assertTrue(ut.table.tostring(self.simple_hash))
        --print(ut.table.tostring(self.simple_hash) .. "\n")
        lu.assertTrue(ut.table.tostring(self.complex_hash))
        --print(ut.table.tostring(self.complex_hash))
    end

    function TestUtils:test_implode()
        lu.assertEquals(ut.implode(',', self.simple_list, "'"), "'1','2','3'")
        lu.assertError(ut.implode, nil, self.simple_list, "'")
        lu.assertError(ut.implode, ',', nil, "'")
    end

    function TestUtils.test_explode()
        lu.assertItemsEquals(ut.explode(',',"1,2,3"), {'1','2','3'})
        lu.assertItemsEquals(ut.explode('=>',"1=>2=>3"), {'1','2','3'})
    end

    function TestUtils.test_starts()
        lu.assertError(ut.string.stats, nil, "g")
        lu.assertTrue(ut.string.starts("goga", "g"))
        lu.assertTrue(ut.string.starts("goga", "go"))
        lu.assertTrue(ut.string.starts("goga", "gog"))
        lu.assertTrue(ut.string.starts("goga", "goga"))
        lu.assertFalse(ut.string.starts("goga", "a"))
        lu.assertError(ut.string.starts, "goga", nil)
        lu.assertTrue(ut.string.starts("$goga", "$"))
        lu.assertTrue(ut.string.starts("(goga)", "("))
    end

    function TestUtils.test_ends()
        lu.assertError(ut.string.ends, nil, "g")
        lu.assertTrue(ut.string.ends("goga", "a"))
        lu.assertTrue(ut.string.ends("goga", "ga"))
        lu.assertTrue(ut.string.ends("goga", "oga"))
        lu.assertTrue(ut.string.ends("goga", "goga"))
        lu.assertFalse(ut.string.ends("goga", "f"))
        lu.assertError(ut.string.ends, "goga", nil)
    end
-- class TestUtils

-- luacheck: ignore TestStack
local TestStack = {}
    function TestStack.test()
        local s = ut.Stack:new()
        lu.assertEquals(type(s), 'table')
        lu.assertEquals(s.__class__, 'Stack')
    end

    function TestStack.test_size()
        local s = ut.Stack:new()
        lu.assertEquals(s:size(),0)
        s:push(1)
        lu.assertEquals(s:size(),1)
        s:pop()
        lu.assertEquals(s:size(),0)
    end

    function TestStack.test_push()
        local s s = ut.Stack:new()
        s:push(1)
        lu.assertEquals(s:size(),1)
    end

    function TestStack.test_pop()
        local s = ut.Stack:new()
        lu.assertEquals(s:pop(), nil)
        s:push(1)
        lu.assertEquals(s:size(),1)
        lu.assertEquals(s:pop(),1)
        lu.assertEquals(s:size(),0)
    end

    function TestStack.test_get()
        local s = ut.Stack:new()
        s:push(1)
        lu.assertEquals(s:get(0),1)
        s:push({1,2,3})
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),1)
        lu.assertError(s.get, s, -1)
        lu.assertIsNil(s:get(2))
    end

    function TestStack.test_get_op()
        local s = ut.Stack:new()
        s:push(1)
        lu.assertEquals(s[0],1)
        s:push({1,2,3})
        lu.assertEquals(s[0],{1,2,3})
        lu.assertEquals(s[1],1)
        lu.assertIsNil(s[2])
    end

    function TestStack.test_set()
        local s = ut.Stack:new()
        s:push(1)
        s:push({1,2,3})
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),1)
        s:set(1, 2)
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),2)
        s:set(2, 3)
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),2)
        lu.assertIsNil(s:get(2))
        lu.assertError(s.set, s, "no", -1)
        lu.assertError(s.set, s, -1, 2)
    end

    function TestStack.test_set_op()
        local s = ut.Stack:new()
        s:push(1)
        s:push({1,2,3})
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),1)
        s[1] = 2
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),{1,2,3})
        lu.assertEquals(s:get(1),2)
        s[0] = "new"
        lu.assertEquals(s:size(),2)
        lu.assertEquals(s:get(0),"new")
        lu.assertEquals(s:get(1),2)
        s[1] = "old"
        lu.assertEquals(s:get(0),"new")
        lu.assertEquals(s:get(1),"old")
        lu.assertEquals(s:size(),2)
        s[2] = "error"
        lu.assertEquals(s:get(0),"new")
        lu.assertEquals(s:get(1),"old")
        lu.assertIsNil(s:get(2))
        lu.assertEquals(s:size(),2)
    end

    function TestStack.test_list()
        local s = ut.Stack:new()
        local l = s:list()
        lu.assertEquals(#l, 0)
        s:push(1)
        s:push({1,2,3})
        lu.assertEquals(s:size(),2)
        l = s:list()
        lu.assertItemsEquals(l[1],{1,2,3})
        lu.assertEquals(l[2],1)
        lu.assertEquals(s:size(),2)
    end

    function TestStack.test_tostring()
        local s = ut.Stack:new()
        s:push(1)
        lu.assertEquals(tostring(s), "{1}")
        s:push(2)
        lu.assertEquals(tostring(s), "{2,1}")
    end
-- class TestStack
--EOF
