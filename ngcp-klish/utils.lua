--
-- Copyright 2013-2020 SipWise Team <development@sipwise.com>
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

local utils = { table = {}, string = {}}

-- copy a table
function utils.table.deepcopy(object)
    local lookup_table = {}
    local function _copy(obj)
        if type(obj) ~= "table" then
            return obj
        elseif lookup_table[obj] then
            return lookup_table[obj]
        end
        local new_table = {}
        lookup_table[obj] = new_table
        for index, value in pairs(obj) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(obj))
    end
    return _copy(object)
end

function utils.table.contains(table, element)
    if table then
      for _, value in pairs(table) do
        if value == element then
          return true
        end
      end --for
    end --if
    return false
end

-- add if element is not in table
function utils.table.add(t, element)
  if not utils.table.contains(t, element) then
    table.insert(t, element)
  end
end

function utils.table.val_to_str( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and utils.table.tostring( v ) or
      tostring( v )
  end
end

function utils.table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. utils.table.val_to_str( k ) .. "]"
  end
end

function utils.table.tostring( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, utils.table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        utils.table.key_to_str( k ) .. "=" .. utils.table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

-- from table to string
-- t = {'a','b'}
-- implode(",",t,"'")
-- "'a','b'"
-- implode("#",t)
-- "a#b"
function utils.implode(delimiter, list, quoter)
    local len = #list
    if not delimiter then
        error("delimiter is nil")
    end
    if len == 0 then
        return nil
    end
    if not quoter then
        quoter = ""
    end
    local string = quoter .. list[1] .. quoter
    for i = 2, len do
        string = string .. delimiter .. quoter .. list[i] .. quoter
    end
    return string
end

-- from string to table
function utils.explode(delimiter, text)
    local list = {}
    local pos = 1

    if not delimiter then
        error("delimiter is nil")
    end
    if not text then
        error("text is nil")
    end
    if string.find("", delimiter, 1) then
        -- We'll look at error handling later!
        error("delimiter matches empty string!")
    end
    while 1 do
        local first, last = string.find(text, delimiter, pos)
        -- print (first, last)
        if first then
            table.insert(list, string.sub(text, pos, first-1))
            pos = last+1
        else
            table.insert(list, string.sub(text, pos))
            break
        end
    end
    return list
end

function utils.string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function utils.string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function utils.uri_get_username(str)
  return str:match('sip:([^@]+)')
end

-- Stack Table
-- Uses a table as stack, use <table>:push(value) and <table>:pop()
-- Lua 5.1 compatible

utils.Stack = {
  __class__ = 'Stack'
}
local Stack_MT = {
  __tostring = function(t)
    return utils.table.tostring(utils.Stack.list(t))
  end,
  -- this works only on Lua5.2
  __len = function(t)
    return utils.Stack.size(t)
  end,
  __index = function(t,k)
    if type(k) == 'number' then
      return utils.Stack.get(t,k)
    end
    return rawget(utils.Stack,k)
  end,
  __newindex = function(t,k,v)
    if type(k) == 'number' then
      utils.Stack.set(t,k,v)
    end
  end
}

  -- Create a Table with stack functions
  function utils.Stack.new()
    local t = { _et = {} }
    setmetatable(t, Stack_MT)
    return t
  end

  -- push a value on to the stack
  function utils.Stack:push(...)
    if ... then
      local targs = {...}
      -- add values
      for _,v in pairs(targs) do
        table.insert(self._et, v)
      end
    end
  end

  -- pop a value from the stack
  function utils.Stack:pop(num)
    -- get num values from stack
    local _num = num or 1

    -- return table
    local entries = {}

    -- get values into entries
    for _ = 1, _num do
      -- get last entry
      if #self._et ~= 0 then
        table.insert(entries, self._et[#self._et])
        -- remove last value
        table.remove(self._et)
      else
        break
      end
    end
    -- return unpacked entries
    return unpack(entries)
  end

  -- get pos ( starts on 0)
  function utils.Stack:get(pos)
    assert(pos)
    assert(pos>=0)
    local indx = #self._et - pos
    if indx>0 then
      return self._et[indx]
    end
  end

  -- set a value in a pos (stars on 0)
  function utils.Stack:set(pos, value)
    assert(pos)
    assert(pos>=0)
    local indx = #self._et - pos
    if indx>0 then
      if self._et[indx] then
        self._et[indx] = value
      else
        error("No pos:"..pos)
      end
    end
  end

  -- get entries
  function utils.Stack:size()
    return #self._et
  end

  -- list values
  function utils.Stack:list()
    local entries = {}
    for i = #self._et, 1, -1 do
      table.insert(entries, self._et[i])
    end
    return entries
  end
-- end class

return utils
--EOF