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
require 'luaunit'
require 'lemock'
require 'ngcp-klish.bencode'

local mc, udp, socket
local MP

local function msg_decode(received)
	local _,q = string.find(received, '^([^_]+_%d+)')
	local seq, message
	if q then
		seq = received:sub(1,q)
		message = received:sub(q+2)
	end
	return seq, assert(bencode.decode(message))
end

local function msg_encode(seq, type, command, param)
	local message = {}
	message[type] = command
	if not param then param = {} end
	for k,v in pairs(param) do
		message[k]=v
	end
	message = assert(bencode.encode(message))
	return string.format('%s %s', seq, message)
end

Test = {}
function Test:test_encode()
	assertEquals('5323_1 d7:command4:pinge',
		msg_encode("5323_1", 'command', 'ping'))
end

function Test:test_decode()
	local seq, msg = msg_decode('5323_1 d6:result4:ponge')
	assertEquals(seq, '5323_1')
	assertEquals(msg, {result='pong'})
end

TestMP = {}
function TestMP:setUp()
	mc = lemock.controller()
	udp = mc:mock()
	socket = {
		dns={ toip=mc:mock() },
		udp= udp
	}
	package.loaded['ngcp-klish.mediaproxy-ng'] = nil
	package.loaded.socket = nil
	package.preload['socket'] = function ()
	    return socket
	end
	MP = require 'ngcp-klish.mediaproxy-ng'
	self.mp = MP:new()
end

function TestMP:test()
	assertEquals(self.mp:cookie(), tostring(self.mp._uniq).."_1")
	assertEquals(self.mp:cookie(), tostring(self.mp._uniq).."_2")
end

function TestMP:test_host()
	-- default
	assertEquals(self.mp._ip, '127.0.0.1')

	socket.dns.toip('localhost') ;mc :returns('127.0.0.1')
	mc:replay()
	self.mp:server('localhost')
	mc:verify()
	assertEquals(self.mp._ip, '127.0.0.1')
end

function TestMP:test_port()
	-- default
	assertEquals(self.mp._port, 2223)
end

function TestMP:test_ping()
	local cookie = tostring(self.mp._uniq).."_1"
	local message = msg_encode(cookie, 'command', 'ping')
	local response = msg_encode(cookie, 'result', 'pong')

	socket.udp() ;mc :returns(udp)
	udp:sendto(message, self.mp._ip, self.mp._port) ;mc :returns(true)
	udp:receive() ;mc :returns(response)

	mc:replay()
	local res = self.mp:ping()
	mc:verify()
	assertTrue(res)
end

function TestMP:test_query()
	local cookie = tostring(self.mp._uniq).."_1"
	local param = {}
	param['call-id'] = 'callid1'
	local message = msg_encode(cookie, 'command', 'query', param)
	local respose_param = {created=1381997760,totals={input={rtcp={bytes=11054,packets=113,errors=0},rtp={bytes=3909179,packets=26195,errors=0}},output={rtcp={bytes=9048,packets=116,errors=0},rtp={bytes=0,packets=0,errors=0}}},streams={{{status="confirmed peer address",codec="unknown",stats={rtcp={counters={bytes=10976,packets=112,errors=0},["local port"]=30001,["advertised peer address"]={family="IPv4",port=50005,address="10.15.20.191"},["peer address"]={family="IPv4",port=50005,address="10.15.20.191"}},rtp={counters={bytes=3908936,packets=26194,errors=0},["local port"]=30000,["advertised peer address"]={family="IPv4",port=50004,address="10.15.20.191"},["peer address"]={family="IPv4",port=50004,address="10.15.20.191"}}},
		tag="callid1"},{status="known but unconfirmed peer address",stats={rtcp={counters={bytes=8970,packets=115,errors=0},["local port"]=30003,["advertised peer address"]={family="IPv4",port=50007,address="10.15.20.191"},["peer address"]={family="IPv4",port=50007,address="10.15.20.191"}},rtp={counters={bytes=0,packets=0,errors=0},["local port"]=30002,["advertised peer address"]={family="IPv4",port=50006,address="10.15.20.191"},["peer address"]={family="IPv4",port=50006,address="10.15.20.191"}}},tag="7A4FE68B-525F9CC000060653-E28A0700"}},{{status="known but unconfirmed peer address",codec="unknown",stats={rtcp={counters={bytes=78,packets=1,errors=0},["local port"]=0,["advertised peer address"]={family="IPv6",port=0,address="::"},["peer address"]={family="IPv6",port=0,address="::"}},rtp={counters={bytes=243,packets=1,errors=0},["local port"]=0,["advertised peer address"]={family="IPv6",port=0,address="::"},["peer address"]={family="IPv6",port=0,address="::"}}},tag=""},{status="known but unconfirmed peer address",stats={rtcp={counters={bytes=78,packets=1,errors=0},["local port"]=0,["advertised peer address"]={family="IPv6",port=0,address="::"},["peer address"]={family="IPv6",port=0,address="::"}},rtp={counters={bytes=0,packets=0,errors=0},["local port"]=0,["advertised peer address"]={family="IPv6",port=0,address="::"},["peer address"]={family="IPv6",port=0,address="::"}}},tag=""}}}}
	local response = msg_encode(cookie, 'result', 'ok', respose_param)

	socket.udp() ;mc :returns(udp)
	udp:sendto(message, self.mp._ip, self.mp._port) ;mc :returns(true)
	udp:receive() ;mc :returns(response)

	mc:replay()
	local res = self.mp:query('callid1')
	mc:verify()
	assertEquals(res.result,'ok')
end
