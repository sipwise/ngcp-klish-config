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
local lu = require 'luaunit'
local bencode = require 'ngcp-klish.bencode'

-- luacheck: ignore Test
local Test = {}
function Test.test_encode_number()
	lu.assertEquals(bencode.encode(345), 'i345e')
end

function Test.test_encode_string()
	lu.assertEquals(bencode.encode('g5323_1'), '7:g5323_1')
end

function Test.test_encode_list()
	lu.assertEquals(bencode.encode({1,2,3}),
		'li1ei2ei3ee')
end

function Test.test_encode_dict()
	lu.assertEquals(bencode.encode({uno=1,dos=2,tres='three'}),
		'd3:dosi2e4:tres5:three3:unoi1ee')
end

function Test.test_decode_number()
	lu.assertEquals(bencode.decode('i345e'), 345)
end

function Test.test_decode_string()
	lu.assertEquals(bencode.decode('7:g5323_1'), 'g5323_1')
end

function Test.test_decode_list()
	lu.assertEquals(bencode.decode('li1ei2ei3ee'), {1,2,3})
end

function Test.test_decode_dict()
	lu.assertEquals(bencode.decode('d3:dosi2e4:tres5:three3:unoi1ee'),
		{uno=1,dos=2,tres='three'})
end
