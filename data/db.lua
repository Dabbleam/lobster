local sqlite = require "sqlite"

local db = {}
db.__index = db

local models = {}

models.settings = {
	key = { type = "text", primary = true, unique = true },
	value = { type = "luatable" }
}

models.history = {
	id = { type = "integer", primary = true, unique = true },
	url = { type = "text" },
	method = { type = "text" },
	headers = { type = "luatable" },
	body = { type = "text" },
	response_code = { type = "integer" },
	response_headers = { type = "luatable" },
	response_body = { type = "text" },
	timestamp = { type = "integer", default = sqlite.lib.strftime( "%s", "now" ) }
}

function db.open( filename, schema )
	assert( models[ schema ], "unknown database schema " .. schema )

	local config_table = {
		uri = filename
	}

	config_table[ schema ] = models[ schema ]

	local sql = sqlite( config_table )

	local self = { filename = filename, sql = sql, schema = schema }
	setmetatable( self, db )

	return self
end

function db:get( key, default )
	local result = self.sql[ self.schema ]:get( { where = { key = key } } )
	if #result == 0 then
		return default, false
	end

	return result[ 1 ].value.value, true
end

function db:set( key, value )
	local setting, exists = self:get( key )
	if exists then
		self.sql[ self.schema ]:update {
			set = { value = { value = value } },
			where = { key = key }
		}
	else
		self.sql[ self.schema ]:insert( { key = key, value = { value = value } } )
	end
end

function db:insert( data )
	return self.sql[ self.schema ]:insert( data )
end

-- TODO: params is a leaky abstraction
function db:select( params )
	return self.sql[ self.schema ]:get( params )
end

return db