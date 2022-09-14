local sqlite = require "sqlite"

local db = {}
db.__index = db

local models = {}

models.settings = {
	key = { type = "text", primary = true, unique = true },
	value = { type = "text" }
}

-- hang on, I actually think I want this to be in another db
-- will have to think about it

--[[models.history = {
	id = { type = "integer", primary = true, unique = true },
	url = { type = "text" },
	headers = { type = "luatable" },
	body = { type = "text" },
	response_code = { type = "integer" },
	response_headers = { type = "luatable" },
	response_body = { type = "text" },
	timestamp = { type = "integer", default = sqlite.lib.strftime( "%s", "now" ) }
}]]

function db.open( filename )
	local config_table = {
		uri = filename
	}

	for k, v in pairs( models ) do
		config_table[ k ] = v
	end

	local sql = sqlite( config_table )

	local self = { filename = filename, sql = sql }
	setmetatable( self, db )

	return self
end

function db:get( key )
	local result = self.sql.settings:get( { where = { key = key } } )
	if #result == 0 then
		return nil
	end

	return result[ 1 ].value
end

function db:set( key, value )
	local setting = self:get( key )
	if setting then
		self.sql.settings:update {
			set = { value = value },
			where = { key = key }
		}
	else
		self.sql.settings:insert( { key = key, value = value } )
	end
end

return db