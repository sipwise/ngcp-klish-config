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
Total Concurrent Internal Calls: $(internal)
Total Concurrent Calls with RTP: $(rtp)
Average Amount of Calls (last hour): $(average)]],
	cc_list=[[
| $(callid) | $(caller) | $(callee) | $(date) | $(peer) | $(rtp_ports) | $(hash) |]]
}

local patterns = {
	cc_stats = {
		total='profile::  name=total value= count=(%d+)',
		peerout='profile::  name=peerout value= count=(%d+)',
		internal='profile::  name=type value=internal count=(%d+)',
		incoming='profile::  name=type value=incoming count=(%d+)'
	},
	cc_list = {
		'hash:(%d+:%d+) state:(%d) ref_count:%d+ timestart:(%d+) timeout:%d+$',
		'%s+callid:([%w-]+) from_tag:([%w-]+) to_tag:([%w-]+)$',
		'%s+from_uri:(sip:%w+@[%w\.]+) to_uri:(sip:%w+@[%w\.]+)$',
		'%s+caller_contact:(sip:%w+@[%w\.]+:%d+) caller_cseq:%d+$',
		'%s+caller_route_set:.*$',
		'%s+callee_contact:(sip:%w+@%[%w\.]+:%d+) callee_cseq:%d+$',
		'%s+callee_route_set:.*$',
		'%s+caller_bind_addr:%w+:[%w\.]+:%d+ callee_bind_addr:%w+:[%w\.]+:%d+$'
	},
	cc_list_keys = {
		{'hash','state','timestart'},
		{'callid','from_tag','to_tag'},
		{'from_uri','to_uri'},
		{'caller_contact'},
		{},
		{'callee_contact'},
		{},
		{}
	}
}

-- get the stats info
local function cc_stats_info()
	local k,v
	local prog_call='ngcp-kamctl proxy fifo profile_get_size'
	local args = { total="", peerout="", internal="type", incoming="type" }
	local stats = {
		rtp=-1, average=-1,
		total=-1, peerout=-1,
		internal=-1, incoming=-1
	}

	for k,v in pairs(args) do
		local val, line
		local foutput = io.popen (string.format('%s %s %s', prog_call, v, k), 'r')
		for line in foutput:lines() do
			for val in string.gmatch(line, patterns.cc_stats[k]) do
				stats[k] = tonumber(val)
			end
		end
		foutput:close()
	end
	return stats
end

-- prints concurrent calls stats
-- if result <0 it's an error
function cc_stats()
	local stats = cc_stats_info()
	print(expand(templates.cc_stats, stats))
end

-- formats the values before output them
-- @param t table
-- @return table with the fields formated
local function cc_list_prepare(t)
	local f = {
		callid=t.callid,
		caller=uri_get_username(t.from_uri),
		callee=uri_get_username(t.to_uri),
		date=os.date('%Y/%m/%d %H:%M:%S', t.timestart),
		peer='',
		rtp_ports='',
		hash=t.hash
	}
	return f
end

--prints concurrent calls list
function cc_list()
	local prog_call='ngcp-sercmd proxy dlg.list'
	local line
	local result = {}
	local temp,k,v
	local foutput = io.popen (string.format('%s', prog_call), 'r')

	for line in foutput:lines() do
		local a,b,c
		if string.starts(line,'hash') then
			if temp then
				result[temp.callid] = temp
			end
			temp = {}
		end
		for k,v in ipairs(patterns.cc_list) do
			for a,b,c in string.gmatch(line, v) do
				local rk,_
				local temp_line = {a,b,c}
				local count = 1
				-- set the result line values with proper key
				for _,rk in pairs(patterns.cc_list_keys[k]) do
					temp[rk] = temp_line[count]
					count = count + 1
				end
			end
		end
	end
	foutput:close()
	-- last item
	if temp then
		result[temp.callid] = temp
	end
	-- header
	print("| Call-ID | Caller | Callee | Time | Peer | RTP ports| Dialog hash |")
	for _,v in pairs(result) do
		print(expand(templates.cc_list, cc_list_prepare(v)))
	end
end


function cc_details(callid)
	if callif ~= "" then
		local stats = cc_stats_info()
		-- TODO: kamailio has to have a num offset parameter on dlg.list
		if stats.total <= 50 then 
			cc_list()
		else
			print('Total concurrent calls exceed 50')
		end
		return
	end
	print("TODO")
end