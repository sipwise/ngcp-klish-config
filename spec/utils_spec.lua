--
-- Copyright 2020 SipWise Team <development@sipwise.com>
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

describe("utils", function()
    local ut
    local simple_hash
    local simple_list
    local complex_hash

    setup(function()
        ut = require("ngcp-klish.utils")
    end)

    before_each(function()
        simple_hash = {
            one = 1, two = 2, three = 3
        }
        simple_list = {
            1, 2, 3
        }
        complex_hash = {
            cone = simple_list,
            ctwo = simple_hash
        }
    end)

    describe("table", function()
        it("deepcopy", function()
            local res = ut.table.deepcopy(simple_hash)
            assert.same(res, simple_hash)
            assert.is_not(res, simple_hash)
        end)

        it("contains should find the value", function()
            assert.True(ut.table.contains(simple_hash, 3))
        end)

        it("contains should not find the value", function()
            assert.False(ut.table.contains(simple_hash, 4))
        end)

        it("contains should not find anything in nil", function()
            assert.False(ut.table.contains(nil))
        end)

        it("contains should throw an error with a string", function()
            local f = function()
                ut.table.contains("hola", 1)
            end
            assert.has_error(f,
                "bad argument #1 to 'pairs' (table expected, got string)")
        end)

        it("add", function ()
            assert.same(simple_list, {1,2,3})
            ut.table.add(simple_list, 1)
            assert.same(simple_list, {1,2,3})
            ut.table.add(simple_list, 5)
            assert.same(simple_list, {1,2,3,5})
            ut.table.add(simple_list, 4)
            assert.same(simple_list, {1,2,3,5,4})
        end)

        it("tostring", function()
            local f = function()
                ut.table.tostring("nil")
            end
            assert.has_error(f)
            assert.same(ut.table.tostring(simple_list), "{1,2,3}")
            assert.not_nil(ut.table.tostring(simple_hash))
            assert.not_nil(ut.table.tostring(complex_hash))
        end)
    end) -- end table

    it("implode", function()
        assert.same(ut.implode(',', simple_list, "'"), "'1','2','3'")
    end)

    it("implode should error with nil string", function()
        local f = function()
            ut.implode(nil, simple_list, "'")
        end
        assert.has_error(f)
    end)

    it("implode should error with nil table", function()
        local f = function()
            ut.implode(',', nil, "'")
        end
        assert.has_error(f)
    end)

    it("explode", function()
        assert.equal_items(ut.explode(',',"1,2,3"), {'1','2','3'})
        assert.equal_items(ut.explode('=>',"1=>2=>3"), {'1','2','3'})
    end)

    describe("string", function()

        it("starts should error with nil", function()
            local f = function()
                ut.string.stats(nil, "g")
            end
            assert.has_error(f)
            assert.has_error(function() ut.string.stats("goga", nil) end)
        end)

        it("starts", function()
            assert.True(ut.string.starts("goga", "g"))
            assert.True(ut.string.starts("goga", "go"))
            assert.True(ut.string.starts("goga", "gog"))
            assert.True(ut.string.starts("goga", "goga"))
            assert.False(ut.string.starts("goga", "a"))
            assert.True(ut.string.starts("$goga", "$"))
            assert.True(ut.string.starts("(goga)", "("))
        end)

        it("ends should error with nil", function()
            assert.has_error(function() ut.string.ends(nil, "g") end)
            assert.has_error(function() ut.string.ends("goga", nil) end)
        end)

        it("ends", function()
            assert.True(ut.string.ends("goga", "a"))
            assert.True(ut.string.ends("goga", "ga"))
            assert.True(ut.string.ends("goga", "oga"))
            assert.True(ut.string.ends("goga", "goga"))
            assert.False(ut.string.ends("goga", "f"))
        end)
    end) -- end string

    describe("uri_get_username", function()
        it("should wotk with dns", function()
            assert.same(
                'vseva',
                ut.uri_get_username('sip:vseva@fake.local')
            )
        end)

        it("should wotk with ipv4", function()
            assert.same(
                'vseva',
                ut.uri_get_username('sip:vseva@127.0.0.1:50602')
            )
        end)

        it("should wotk with ipv6", function()
            local t = 'sip:vseva@[2620:0:2ef0:7070:250:60ff:fe03:32b7]:5060;transport=tcp'
            assert.same(
                'vseva',
                ut.uri_get_username(t)
            )
        end)
    end)
end)
