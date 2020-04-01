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

describe("bencode", function()
    local bencode

    setup(function()
        bencode = require("ngcp-klish.bencode")
    end)

    it("should encode a number", function()
        assert.same('i345e', bencode.encode(345))
    end)

    it("should encode a string", function()
        assert.same('7:g5323_1', bencode.encode('g5323_1'))
    end)

    it("should encode a list of numbers", function()
        assert.same('li1ei2ei3ee', bencode.encode({1,2,3}))
    end)

    it("should encode a dict with mixed values",function()
        assert.same(
            'd3:dosi2e4:tres5:three3:unoi1ee',
            bencode.encode({uno=1,dos=2,tres='three'})
        )
    end)

    it("should decode a number", function()
        assert.same(345, bencode.decode('i345e'))
    end)

    it("should decode a string", function()
        assert.same('g5323_1', bencode.decode('7:g5323_1'))
    end)

    it("should decode a list of numbers", function()
        assert.same({1,2,3}, bencode.decode('li1ei2ei3ee'))
    end)

    it("should decode a dict with mixed values",function()
        assert.same(
            {uno=1,dos=2,tres='three'},
            bencode.decode('d3:dosi2e4:tres5:three3:unoi1ee')
        )
    end)
end)
