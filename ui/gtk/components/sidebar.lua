local lgi = require "lgi"

local Gtk = lgi.Gtk

local state = require "core.state"

local requestHistory = require "ui.gtk.components.sidebar.request-history"

local sidebar = {}
sidebar.__index = sidebar

function sidebar.new()
    local sidebarStack = Gtk.Stack {
        transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
        hexpand = true,
        vexpand = true,
    }

    local requestHistoryPanel = requestHistory.new()

    sidebarStack:add( requestHistoryPanel.element )

    local self = {
        element = sidebarStack,
        requestHistoryPanel = requestHistoryPanel,
    }

    setmetatable( self, sidebar )

    return self
end

function sidebar:switch_to( what )
    if what == "requestHistory" then
        self.element:set_visible_child( self.requestHistoryPanel.element )
    end
end

return sidebar