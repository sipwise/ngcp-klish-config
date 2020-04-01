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
local bencode = require 'ngcp-klish.bencode'

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

describe("helper functions", function()
    it("should encode", function()
        assert.same(
            '5323_1 d7:command4:pinge',
            msg_encode("5323_1", 'command', 'ping')
        )
    end)

    it("should decode", function()
       local seq, msg = msg_decode('5323_1 d6:result4:ponge')
       assert.same('5323_1', seq)
       assert.same({result='pong'}, msg)
    end)
end)

describe("rtpengine", function()
    local rtp, mp
    local socket

    setup(function()
    end)

    before_each(function()
        socket = {
            dns = {
                toip = true
            },
            udp = true
        }
        package.loaded['ngcp-klish.rtpengine'] = nil
        package.loaded.socket = nil
        package.preload['socket'] = function ()
            return socket
        end
        rtp = require("ngcp-klish.rtpengine")
        mp = rtp:new()
    end)

    it("should provide uniq cookies", function()
        assert.same(tostring(mp._uniq).."_1", mp:cookie())
        assert.same(tostring(mp._uniq).."_2", mp:cookie())
    end)

    it("should resolve host when server is called", function()
        socket.dns.toip = function(server)
                    assert.same("fake.local", server)
                    return "172.0.0.1"
                end
        assert.same('127.0.0.1', mp._ip)
        mp:server("fake.local")
        assert.same('172.0.0.1', mp._ip)
    end)

    it("should have a default port", function()
        assert.same(2223, mp._port)
    end)

    it("should support ping command", function()
        local cookie = tostring(mp._uniq).."_1"
        local message = msg_encode(cookie, 'command', 'ping')
        local response = msg_encode(cookie, 'result', 'pong')

        local t = {
            sendto = function(_, msg, ip, port)
                assert.same(message, msg)
                assert.same(mp._ip, ip)
                assert.same(mp._port, port)
                return true
            end,
            receive = function(_) return(response) end
        }
        socket.udp = function() return t end
        assert.is_true(mp:ping())
    end)

    it("should support query command", function()
        local cookie = tostring(mp._uniq).."_1"
        local param = {}
        param['call-id'] = 'callid1'
        local message = msg_encode(cookie, 'command', 'query', param)
        -- luacheck: ignore
        local respose_param = {created=1381997760,totals={input={rtcp={bytes=11054,packets=113,errors=0},rtp={bytes=3909179,packets=26195,errors=0}},output={rtcp={bytes=9048,packets=116,errors=0},rtp={bytes=0,packets=0,errors=0}}},streams={{{status="confirmed peer address",codec="unknown",stats={rtcp={counters={bytes=10976,packets=112,errors=0},["local port"]=30001,["advertised peer address"]={family="IPv4",port=50005,address="10.15.20.191"},["peer address"]={family="IPv4",port=50005,address="10.15.20.191"}},rtp={counters={bytes=3908936,packets=26194,errors=0},["local port"]=30000,["advertised peer address"]={family="IPv4",port=50004,address="10.15.20.191"},["peer address"]={family="IPv4",port=50004,address="10.15.20.191"}}},
            tag="callid1"},{status="known but unconfirmed peer address",stats={rtcp={counters={bytes=8970,packets=115,errors=0},["local port"]=30003,["advertised peer address"]={family="IPv4",port=50007,address="10.15.20.191"},["peer address"]={family="IPv4",port=50007,address="10.15.20.191"}},rtp={counters={bytes=0,packets=0,errors=0},["local port"]=30002,["advertised peer address"]={family="IPv4",port=50006,address="10.15.20.191"},["peer address"]={family="IPv4",port=50006,address="10.15.20.191"}}},tag="7A4FE68B-525F9CC000060653-E28A0700"}},{{status="known but unconfirmed peer address",codec="unknown",stats={rtcp={counters={bytes=78,packets=1,errors=0},["local port"]=0,["advertised peer address"]={family="IPv6",port=0,address="::"},["peer address"]={family="IPv6",port=0,address="::"}},rtp={counters={bytes=243,packets=1,errors=0},["local port"]=0,["advertised peer address"]={family="IPv6",port=0,address="::"},["peer address"]={family="IPv6",port=0,address="::"}}},tag=""},{status="known but unconfirmed peer address",stats={rtcp={counters={bytes=78,packets=1,errors=0},["local port"]=0,["advertised peer address"]={family="IPv6",port=0,address="::"},["peer address"]={family="IPv6",port=0,address="::"}},rtp={counters={bytes=0,packets=0,errors=0},["local port"]=0,["advertised peer address"]={family="IPv6",port=0,address="::"},["peer address"]={family="IPv6",port=0,address="::"}}},tag=""}}}}
        local response = msg_encode(cookie, 'result', 'ok', respose_param)

        local t = {
            sendto = function(_, msg, ip, port)
                assert.same(message, msg)
                assert.same(mp._ip, ip)
                assert.same(mp._port, port)
                return true
            end,
            receive = function(_) return(response) end
        }
        socket.udp = function() return t end
        assert.same('ok', mp:query('callid1').result)
    end)
end)