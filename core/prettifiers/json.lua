local json = require "rapidjson"

local jsonPrettifier = {}

function jsonPrettifier.prettify( data )
	local prettified = json.encode( json.decode( data ), { pretty = true } )
	return prettified
end

return jsonPrettifier