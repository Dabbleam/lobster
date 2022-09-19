local lanes = require "lanes".configure()
local state = require "core.state"

local request = {}

local request_object = {}

local threads = {}

function request_object:cancel()
	if self.thread then
		-- TODO: this doesn't work. we could forcibly kill the thread
		-- but that leaks resources.

		self.thread:cancel()
	end
end

request_object.__index = request_object

function request.init()
	local historyEntries = state.history:select( {
		order_by = { desc = "timestamp" }
	} )

	state.history_entries = historyEntries
end

function request.http( url, method, headers, body )
	local thread = lanes.gen( "*", {
		cancelstep = true,
	}, function( url, method, headers, body )
		local http = require "core.net.http"
		local req = http.new( url, method, headers, body )
		local result = req:send()
		return result
	end )( url, method, headers, body )

	table.insert( threads, {
		thread = thread,
		cb = function( result )
			if not result.error then
				result.error = NULL
			end

			state.response = result
			if state.history then
				local entry = {
					url = url,
					method = method,
					headers = headers,
					body = body,
					response_code = result.status,
					response_headers = result.headers,
					response_body = result.body
				}

				entry.id = state.history:insert( entry )
				table.insert( state.history_entries, 1, entry )
				-- this is ungreat, would be cool if the state thing watched for changes with table.insert
				state:notify( "new_history_entry", entry )
			end
		end
	} )

	local obj = {
		url = url,
		method = method,
		headers = headers,
		body = body,
		thread = thread
	}
	
	setmetatable( obj, request_object )
	return obj
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