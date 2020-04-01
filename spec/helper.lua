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

local assert = require("luassert")
local say    = require("say")

-- https://github.com/bluebird75/luaunit/blob/master/luaunit.lua
local function _is_table_equals(actual, expected, cycleDetectTable)
    local type_a, type_e = type(actual), type(expected)

    if type_a ~= type_e then
        return false -- different types won't match
    end

    if type_a ~= 'table' then
        -- other typtes compare directly
        return actual == expected
    end

    cycleDetectTable = cycleDetectTable or { actual={}, expected={} }
    if cycleDetectTable.actual[ actual ] then
        -- oh, we hit a cycle in actual
        if cycleDetectTable.expected[ expected ] then
            -- uh, we hit a cycle at the same time in expected
            -- so the two tables have similar structure
            return true
        end

        -- cycle was hit only in actual, the structure differs from expected
        return false
    end

    if cycleDetectTable.expected[ expected ] then
        -- no cycle in actual, but cycle in expected
        -- the structure differ
        return false
    end

    -- at this point, no table cycle detected, we are
    -- seeing this table for the first time

    -- mark the cycle detection
    cycleDetectTable.actual[ actual ] = true
    cycleDetectTable.expected[ expected ] = true


    local actualKeysMatched = {}
    for k, v in pairs(actual) do
        actualKeysMatched[k] = true -- Keep track of matched keys
        if not _is_table_equals(v, expected[k], cycleDetectTable) then
            -- table differs on this key
            -- clear the cycle detection before returning
            cycleDetectTable.actual[ actual ] = nil
            cycleDetectTable.expected[ expected ] = nil
            return false
        end
    end

    for k, _ in pairs(expected) do
        if not actualKeysMatched[k] then
            -- Found a key that we did not see in "actual" -> mismatch
            -- clear the cycle detection before returning
            cycleDetectTable.actual[ actual ] = nil
            cycleDetectTable.expected[ expected ] = nil
            return false
        end
        -- Otherwise actual[k] was already matched against v = expected[k].
    end

    -- all key match, we have a match !
    cycleDetectTable.actual[ actual ] = nil
    cycleDetectTable.expected[ expected ] = nil
    return true
end
local is_equal = _is_table_equals

local function table_findkeyof(t, element)
    -- Return the key k of the given element in table t, so that t[k] == element
    -- (or `nil` if element is not present within t). Note that we use our
    -- 'general' is_equal comparison for matching, so this function should
    -- handle table-type elements gracefully and consistently.
    if type(t) == "table" then
        for k, v in pairs(t) do
            if is_equal(v, element) then
                return k
            end
        end
    end
    return nil
end

local function _is_table_items_equals(actual, expected )
    local type_a, type_e = type(actual), type(expected)

    if type_a ~= type_e then
        return false

    elseif (type_a == 'table') --[[and (type_e == 'table')]] then
        for _, v in pairs(actual) do
            if table_findkeyof(expected, v) == nil then
                return false -- v not contained in expected
            end
        end
        for _, v in pairs(expected) do
            if table_findkeyof(actual, v) == nil then
                return false -- v not contained in actual
            end
        end
        return true

    elseif actual ~= expected then
        return false
    end

    return true
end
--- end

local function set_failure_message(state, message)
  if message ~= nil then
    state.failure_message = message
  end
end

local function equal_items(state, arguments)
  if _is_table_items_equals(arguments[1], arguments[2]) then
	return true
  end
  set_failure_message(state, arguments[3])
  return false
end

say:set_namespace("en")
say:set("assertion.equal_items.positive",
	"Expected objects have same items.\nPassed in:\n%s\nExpected:\n%s")
say:set("assertion.equal_items.negative",
	"Expected objects don't have same items.\nPassed in:\n%s\nDid not expect:\n%s")
assert:register("assertion", "equal_items", equal_items,
	"assertion.equal_items.positive", "assertion.equal_items.negative")
