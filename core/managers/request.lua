local lanes = require "lanes".configure()
local state = require "ui.state"

local request = {}

local threads = {}

function request.http( ... )
	local thread = lanes.gen( "*", function( ... )
		local http = require "core.net.http"
		local req = http.new( ... )
		local result = req:send()
		return result
	end )( ... )

	table.insert( threads, {
		thread = thread,
		cb = function( result )
			if not result.error then
				result.error = NULL
			end

			state.response = result
		end
	} )
end

function request.pump()
	for i, v in ipairs( threads ) do
		local result, status = v.thread:join( 0 )
		if result then
			v.cb( result )
			table.remove( threads, i )
		end
	end
end

return request