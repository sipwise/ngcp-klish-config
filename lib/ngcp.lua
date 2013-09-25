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
require 'ngcp-klish.expand'

-- templates
local templates = {
	cc_stats=[[
Total Concurrent Calls: $(total)
Total Concurrent Outgoing Calls: $(peerout)
Total Concurrent Incoming Calls: $(incoming)
Total Concurrent Internal Calls: $(local)
Total Concurrent Calls with RTP: $(rtp)
Average Amount of Calls (last hour): $(average)]]
}

-- prints concurrent calls stats
-- if result <0 it's an error
function cc_stats()
	local _,k,v
	local prog_call='ngcp-kamctl proxy fifo profile_get_size'
	local args = { 'total', 'incoming', 'peerout', 'local' }
	local result_pattern = {'profile::  name=', ' value= count=(%d+)' }
	local stats = {rtp=-1, average=-1}

	for _,v in ipairs(args) do
		local val, line
		local foutput = io.popen (string.format('%s %s', prog_call, v), 'r')
		for line in foutput:lines() do
			for val in string.gmatch(line, result_pattern[1]..v..result_pattern[2]) do
				stats[v] = tonumber(val)
			end
			if not stats[v] then
				stats[v] = -1
			end
		end
		foutput:close()
	end
	print(expand(templates.cc_stats, stats))
end
