--[[
	All files in the source distribution of lua-bencode may be copied under the
	same terms as Lua 5.0, 5.1, and 5.2. These terms are also known as the "MIT/X
	Consortium License".

	For reasons of clarity, a copy of these terms is included below.

	Copyright (c) 2009, 2010, 2011, 2012 by Moritz Wilhelmy
	Copyright (c) 2009 by Kristofer Karlsson

	Permission is hereby granted, free of charge, to any person obtaining a copy of
	this software and associated documentation files (the "Software"), to deal in
	the Software without restriction, including without limitation the rights to
	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
	of the Software, and to permit persons to whom the Software is furnished to do
	so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

	public domain lua-module for handling bittorrent-bencoded data.
	This module includes both a recursive decoder and a recursive encoder.

]]--

local sort, concat, insert = table.sort, table.concat, table.insert
local pairs, ipairs, type, tonumber = pairs, ipairs, type, tonumber
local sub, find = string.sub, string.find

local bencode = {
	encode_rec = nil -- encode_list/dict and encode_rec are mutually recursive...
}

-- helpers

local function islist(t)
	local n = #t
	for k, _ in pairs(t) do
		if type(k) ~= "number"
		or k % 1 ~= 0 		-- integer?
		or k < 1
		or k > n
		then
			return false
		end
	end
	for i = 1, n do
		if t[i] == nil then
			return false
		end
	end
	return true
end

-- encoder functions

local function encode_list(t, x)

	insert(t, "l")

	for _,v in ipairs(x) do
		local err,ev = bencode.encode_rec(t, v);    if err then return err,ev end
	end

	insert(t, "e")
end

local function encode_dict(t, x)
	insert(t, "d")
	-- bittorrent requires the keys to be sorted.
	local sortedkeys = {}
	for k, v in pairs(x) do
		if type(k) ~= "string" then
			return "bencoding requires dictionary keys to be strings", k
		end
		insert(sortedkeys, k)
	end
	sort(sortedkeys)

	for k, v in ipairs(sortedkeys) do
		local err,ev = bencode.encode_rec(t, v);    if err then return err,ev end
		      err,ev = bencode.encode_rec(t, x[v]); if err then return err,ev end
	end
	insert(t, "e")
end

local function encode_int(t, x)

	if x % 1 ~= 0 then return "number is not an integer", x end
	insert(t, "i" )
	insert(t,  x  )
	insert(t, "e" )
end

local function encode_str(t, x)

	insert(t, #x  )
	insert(t, ":" )
	insert(t,  x  )
end

bencode.encode_rec = function(t, x)

	local  typx = type(x)
	if     typx == "string" then  return encode_str  (t, x)
	elseif typx == "number" then  return encode_int  (t, x)
	elseif typx == "table"  then

		if islist(x)    then  return encode_list (t, x)
		else                  return encode_dict (t, x)
		end
	else
		return "type cannot be converted to an acceptable type for bencoding", typx
	end
end

-- call recursive bencoder function with empty table, stringify that table.
-- this is the only encode* function visible to module users.
function bencode.encode(x)

	local t = {}
	local err, val = bencode.encode_rec(t,x)
	if not err then
		return concat(t)
	else
		return nil, err, val
	end
end

-- decoder functions

local function decode_integer(s, index)
	local _, b, int = find(s, "^(%-?%d+)e", index)
	if not int then return nil, "not a number", nil end
	int = tonumber(int)
	if not int then return nil, "not a number", int end
	return int, b + 1
end

local function decode_list(s, index)
	local t = {}
	while sub(s, index, index) ~= "e" do
		local obj, ev
		obj, index, ev = bencode.decode(s, index)
		if not obj then return obj, index, ev end
		insert(t, obj)
	end
	index = index + 1
	return t, index
end

local function decode_dictionary(s, index)
	local t = {}
	while sub(s, index, index) ~= "e" do
		local obj1, obj2, ev

		obj1, index, ev = bencode.decode(s, index)
		if not obj1 then return obj1, index, ev end

		obj2, index, ev = bencode.decode(s, index)
		if not obj2 then return obj2, index, ev end

		t[obj1] = obj2
	end
	index = index + 1
	return t, index
end

local function decode_string(s, index)
	local _, b, len = find(s, "^([0-9]+):", index)
	if not len then return nil, "not a length", len end
	index = b + 1

	local v = sub(s, index, index + len - 1)
	if #v < len - 1 then return nil, "truncated string at end of input", v end
	index = index + len
	return v, index
end


function bencode.decode(s, index)
	if not s then return nil, "no data", nil end
	index = index or 1
	local t = sub(s, index, index)
	if not t then return nil, "truncation error", nil end

	if t == "i" then
		return decode_integer(s, index + 1)
	elseif t == "l" then
		return decode_list(s, index + 1)
	elseif t == "d" then
		return decode_dictionary(s, index + 1)
	elseif t >= '0' and t <= '9' then
		return decode_string(s, index)
	else
		return nil, "invalid type", t
	end
end

return bencode
