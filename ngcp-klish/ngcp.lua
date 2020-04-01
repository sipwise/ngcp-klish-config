--
-- Copyright 2013-2020 SipWise Team <development@sipwise.com>
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
local expand = require 'ngcp-klish.expand'
local MP = require 'ngcp-klish.rtpengine'
local ut = require 'ngcp-klish.utils'

local M = {}

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
	cc_rtp_info=[[$(from_local)($(from_ip):$(from))->$(to_local)($(to_ip):$(to))]],
	reg_stats=[[
Users: $(users)
Users online: $(reg_users)
Users offline: $(users-reg_users)]],
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
	local prog_call='ngcp-kamctl proxy fifo dlg.profile_get_size'
	local args = { total="", peerout="", internal="type", incoming="type" }
	local stats = {
		rtp=-1, average=-1,
		total=-1, peerout=-1,
		internal=-1, incoming=-1
	}

	for k,v in pairs(args) do
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
function M.cc_stats()
	local stats = cc_stats_info()
	print(expand(templates.cc_stats, stats))
end

-- formats the values of rtp
-- @param t table with all the info of the call + rtp_info
-- @return string
local function rtp_info_prepare(t)
	local result, temp = '', {}
	if t.rtp_info then
		temp.from_local = t.rtp_info[t.from_tag]["local port"]
		temp.from = t.rtp_info[t.from_tag]["peer address"].port
		temp.from_ip = t.rtp_info[t.from_tag]["peer address"].address
		temp.to_local = t.rtp_info[t.to_tag]["local port"]
		temp.to = t.rtp_info[t.to_tag]["peer address"].port
		temp.to_ip = t.rtp_info[t.to_tag]["peer address"].address
		result = expand(templates.cc_rtp_info, temp)
	end
	return result
end

-- formats the values before output them
-- @param t table
-- @return table with the fields formatted
local function cc_list_prepare(t)
	local f = {
		callid=t.callid,
		caller=ut.uri_get_username(t.from_uri),
		callee=ut.uri_get_username(t.to_uri),
		date=os.date('%Y/%m/%d %H:%M:%S', t.timestart),
		peer='',
		rtp_ports=rtp_info_prepare(t),
		hash=t.hash
	}
	return f
end

-- get dlg info
local function dlg_info(foutput)
	local result = {}
	local temp,count
	for line in foutput:lines() do
		if ut.string.starts(line,'hash') then
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
	return result
end

--prints concurrent calls list
function M.cc_list()
	local prog_call='ngcp-kamcmd proxy dlg.list'
	local foutput = io.popen (string.format('%s', prog_call), 'r')
	local result = dlg_info(foutput)
	-- header
	print("| Call-ID | Caller | Callee | Time | Peer | RTP ports | Dialog hash |")
	for _,v in pairs(result) do
		print(expand(templates.cc_list, cc_list_prepare(v)))
	end
end

-- gets the info for the callid
local function cc_rtp_info(info)
	local result = {}

	if info.streams then
		for _,s in ipairs(info.streams) do
			for _,s2 in ipairs(s) do
				if s2.tag and s2.tag ~= "" then
					result[s2.tag]=s2.stats.rtp
				end
			end
		end
	end
	return result
end

--get the dlg info for the callid
local function call_info(callid, rtp_info)
	local prog_call='ngcp-kamcmd proxy dlg.dlg_list'
	local result = {}
	for k,v in pairs(rtp_info) do
		local foutput = io.popen (string.format('%s %s %s', prog_call, callid, k), 'r')
		result = dlg_info(foutput)
		if result[callid] then
			result[callid]["rtp_info"] = rtp_info
			break
		end
	end
	if result then
		-- header
		print("| Call-ID | Caller | Callee | Time | Peer | RTP ports | Dialog hash |")
		for _,v in pairs(result) do
			print(expand(templates.cc_list, cc_list_prepare(v)))
		end
	else
		print(string.format("No callid:%s found", callid))
	end
end

function M.cc_details(callid)
	if not callid or callid == "" then
		local stats = cc_stats_info()
		-- TODO: kamailio has to have a num offset parameter on dlg.list
		if stats.total <= 50 then
			M.cc_list()
		else
			print('Total concurrent calls exceed 50')
		end
	else
		local mp = MP:new()
		local rtp_info = mp:query(callid)
		if rtp_info then
			call_info(callid, cc_rtp_info(rtp_info))
		end
	end
end

function M.reg_stats()
	local prog_call="ngcp-kamctl proxy fifo stats.get_statistics usrloc registered_users | jq '.[0]'"
	local stats = {}

	local foutput = io.popen (string.format('%s', prog_call), 'r')
	for line in foutput:lines() do
		for val in string.gmatch(line, patterns.reg_stats.reg_users) do
			stats.reg_users = tonumber(val)
		end
	end
	foutput:close()
	stats.users = M.get_users()
	print(expand(templates.reg_stats, stats))
end

function M.reg_info(aor)
	local prog_call='ngcp-kamcmd proxy ul.lookup location'
	local result = {}
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
