local _http = require "http.request"

local http = {}
http.__index = http

http.methods = {
	"GET",
	"POST",
	"PUT",
	"DELETE",
	"PATCH",
	"HEAD",
	"CONNECT",
	"OPTIONS",
	"TRACE"
}

function http.new( url, method, headers, body )
	local self = {
		url = url,
		method = method,
		headers = headers,
		body = body
	}

	setmetatable( self, http )

	return self
end

function http:send()
	local req = _http.new_from_uri( self.url )
	req.headers:upsert( ":method", self.method )
	if self.headers then
		for k, v in pairs( self.headers ) do
			req.headers:upsert( k, v )
		end
	end
	if self.body then
		req.body = self.body
	end

	local headers, stream = req:go()
	if not headers then
		return {
			error = stream
		}
	end

	local body = stream:get_body_as_string()

	local headers_tab = {}
	local contentType = "text/plain"

	for k, v in headers:each() do
		headers_tab[ k ] = v

		if k:lower() == "content-type" then
			contentType = v:match( "^([^;]*)" ):lower()
		end
	end

	return {
		headers = headers_tab,
		body = body,
		contentType = contentType
	}
end

return http