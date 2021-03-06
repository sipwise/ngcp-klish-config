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
local yaml = require "lyaml"
local constants
local DBI = require "DBI"
local io = require "io"

local configs = {}

-- return the content of file
function configs.readAll(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end

-- return the ngcp constants as table
function configs.get_constants(force)
	if not constants or force then
		constants = yaml.load(configs.readAll('/etc/ngcp-config/constants.yml'))
	end
	return constants
end

-- connection for provisioning
function configs.get_connection()
	configs.get_constants()
	local config = {
		dbname = constants.ossbss.provisioning.database.name,
		dbuser = constants.ossbss.provisioning.database.user,
		dbpassword = constants.ossbss.provisioning.database.pass,
		dbhost = constants.database.dbhost,
		dbport = constants.database.dbport
	}
	local dbh,err = assert(DBI.Connect('MySQL', config.dbname, config.dbuser,
		config.dbpassword, config.dbhost, config.dbport))
	if err then
		error(err)
	end
	return dbh
end

function configs.get_users()
	local dbc = configs.get_connection()
	local res, err = DBI.Do(dbc,
		"select * from voip_subscribers where account_id is not null")
	dbc:close()
	if err then
		error(err)
	end
	--affected_rows
	return res
end

return configs