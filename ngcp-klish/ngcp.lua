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
require 'uri'

local function uri_get_username(str)
  local uri = URI:new(str)
  return uri:username()
end

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
| $(callid) | $(caller) | $(callee) | $(date) | $(peer) | $(rtp_ports) | $(hash) |]],
	reg_stats=[[
Total Users online: $(reg_users)]],
	reg_info=[[
Address: ${address}
Expires: ${expires}
Call-ID: ${callid}
CSeq: ${'cseq'}
User-Agent: ${agent}
Received: ${received}
Path: ${path}
State: ${state}
Socket: ${socket}]]
}

local patterns = {
	cc_stats = {
		total='profile::  name=total value= count=(%d+)',
		peerout='profile::  name=peerout value= count=(%d+)',
		internal='profile::  name=type value=internal count=(%d+)',
		incoming='profile::  name=type value=incoming count=(%d+)'
	},
	cc_list = {
		[1]={{'hash','state','timestart'},
			'hash:(%d+:%d+) state:(%d) ref_count:%d+ timestart:(%d+) timeout:%d+$'},
		[2]={{'callid','from_tag','to_tag'},
			'callid:([%w-%.]+) from_tag:([%w-%.]+) to_tag:([%w-%.]+)$'},
		[3]={{'from_uri','to_uri'},
			'from_uri:(sip:%w+@[%w%.]+) to_uri:(sip:%w+@[%w%.]+)$'},
		[4]={{'caller_contact'},
			'caller_contact:(sip:%w+@[%w%.]+:%d+) caller_cseq:%d+$'},
		[6]={{'callee_contact'},
			'callee_contact:(sip:%w+@%[%w%.]+:%d+) callee_cseq:%d+$'},
	},
	reg_stats = {
		reg_users='usrloc:registered_users = (%d+)'
	},
	reg_lookup = {
		[3]={address='Address: (.+)$'},
		[4]={expires='Expires: (%d+)$'},
		[6]={callid='Call%-ID: (.*)$'},
		[7]={cseq='CSeq: (%d+)$'},
		[8]={agent='User%-Agent: (.*)$'},
		[9]={received='Received: (.*)$'},
		[10]={path='Path: (.*)$'},
		[11]={state='State: (.*)$'},
		[14]={socket='Socket: (.*)$'}
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
	local result = {}
	local line,temp,count,_,k,p
	local foutput = io.popen (string.format('%s', prog_call), 'r')

	for line in foutput:lines() do
		local a,b,c
		if string.starts(line,'hash') then
			if temp then result[temp.callid] = temp end
			temp = {}; count = 0
		end
		count = count + 1
		-- just parse the lines we want some info
		if patterns.cc_list[count] then
			for a,b,c in string.gmatch(line, patterns.cc_list[count][2]) do
				local temp_line = {a,b,c}
				local j = 1
				-- set the result line values with proper key
				for _,k in pairs(patterns.cc_list[count][1]) do
					temp[k] = temp_line[j]
					j = j + 1
				end
			end
		end
	end
	foutput:close()
	-- last item
	if temp then result[temp.callid] = temp end
	-- header
	print("| Call-ID | Caller | Callee | Time | Peer | RTP ports| Dialog hash |")
	for _,v in pairs(result) do
		print(expand(templates.cc_list, cc_list_prepare(v)))
	end
end

function cc_details(callid)
	if callid == "" then
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

function reg_stats()
	local k,v
	local prog_call='ngcp-kamctl proxy fifo get_statistics usrloc::registered_users'
	local stats = {}

	local val, line
	local foutput = io.popen (string.format('%s', prog_call), 'r')
	for line in foutput:lines() do
		for val in string.gmatch(line, patterns.reg_stats.reg_users) do
			stats.reg_users = tonumber(val)
		end
	end
	foutput:close()
	print(expand(templates.reg_stats, stats))
end

function reg_info(aor)
	local prog_call='ngcp-sercmd proxy ul.lookup location'
	local result = {}
	local line, val, k, p
	local count = 0
	local foutput = io.popen (string.format('%s %s', prog_call, aor), 'r')

	for line in foutput:lines() do
		count = count + 1
		-- just parse the lines we want some info
		if patterns.reg_lookup[count] then
			for k,p in pairs(patterns.reg_lookup[count]) do
				for val in string.gmatch(line, p) do
					result[k] = val
				end
			end
		end
	end
	foutput:close()
	if not result.address then
		print("Not found")
	else
		print(expand(templates.reg_info, result))
	end
end
