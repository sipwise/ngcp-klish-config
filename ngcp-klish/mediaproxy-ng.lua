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
-- module setup
local M = {}

-- importing
local math = math
local string = string
local io = io
local socket = require "socket"
require "ngcp-klish.bencode"
-- debug
local utils = require "ngcp-klish.utils"
-- forcing error on globals
_ENV = nil

function M:new(o)
	o = o or {_ip='127.0.0.1', _port=2223}
	setmetatable(o, self)
	self.__index = self
	math.randomseed( os.time() )
	self._seq = 0
	self._uniq = math.random()
	return o
end

function M:server(host)
	-- convert host name to ip address
	self._ip = assert(socket.dns.toip(host))
end

function M:port(port)
	self._port = assert(tonumber())
end

function M:cookie()
	self._seq = self._seq + 1
	return string.format("%s_%d", self._uniq, self._seq)
end

local function _send(self, command, param)
	local message = {command=command}
	if not param then param = {} end
	for k,v in pairs(param) do
		message[k]=v
	end
	message = assert(bencode.encode(message))
	if not self._udp then
		-- create a new UDP object
		self._udp = assert(socket.udp())
	end

	local cookie = self:cookie()
	message = string.format('%s %s', cookie, message)
	assert(self._udp:sendto(message, self._ip, self._port))

	local res = self._udp:receive()
	local _,q = string.find(res, '^([^_]+_%d+)')
	local seq = res:sub(1,q)
	if not q or  seq ~= cookie then
		error('cookie not match')
	end
	message = res:sub(q+2)
	return bencode.decode(message)
end

function M:ping()
	local result = _send(self, 'ping')
	if result.result == 'pong' then
		return true
	end
	return false
end

function M:offer()
end

function M:answer()
end

function M:delete()
end

function M:query(callid, from_tag, to_tag)
	local param = {}
	param['call-id'] = callid
	param['from-tag'] = from_tag
	param['to-tag'] = to_tag
	return _send(self, 'query', param)
end

function M:start_recording()
end

-- end module
return M
