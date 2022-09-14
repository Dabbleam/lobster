local lgi = require "lgi"

local Gtk = lgi.Gtk

local state = require "ui.state"

local panel = require "ui.gtk.components.sidebar.panel"

local requestHistory = {}
requestHistory.__index = requestHistory

function requestHistory.new()
    local panel = panel.new( "REQUEST HISTORY" )

    local self = {
        element = panel.element
    }

    setmetatable( self, requestHistory )

    return self
end

return requestHistory