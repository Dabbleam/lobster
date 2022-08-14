-- this doesn't work at all yet

local xml = require "xml2lua"
local tree = require "xmlhandler.tree"

local xmlPrettifier = {}

function xmlPrettifier.prettify( data )
    local handler = tree:new()
    local parser = xml.parser( handler )
    parser:parse( data )
    print( parser.root )
    local prettified = xml.toXml( parser.root )

    return prettified
end

return xmlPrettifier