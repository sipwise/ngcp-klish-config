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
require('luaunit')
local URI = require "uri"

TestUri = {}
function TestUri:test()
    local u = URI:new('sip:username1:password@domain.com:5080;user=phone?header1=value1&header2=value2')
    assertEquals(u:username(), 'username1')
    assertEquals(u:port(), 5080)
    assertEquals(u:host(), 'domain.com')
    assertEquals(u:fragment(), 'user=phone')
    assertEquals(u:query(), 'header1=value1&header2=value2')
end
