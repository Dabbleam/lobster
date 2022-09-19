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

    -- todo: this logic probably should be part of request-history
    requestHistoryPanel.on_row_selected = function( row )
        if not row then return end

        if self.on_history_entry_selected then
            local entry_id = tonumber( row:get_name() )
            local entry_data

            -- should we just grab the entry from the db?
            -- or alternatively index the history entries by id
            -- anything would be better than iterating over the entire list
            for k, v in pairs( state.history_entries ) do
                if v.id == entry_id then
                    entry_data = v
                    break
                end
            end

            self.on_history_entry_selected( entry_data )
        end
    end

    setmetatable( self, sidebar )

    return self
end

function sidebar:switch_to( what )
    if what == "requestHistory" then
        self.element:set_visible_child( self.requestHistoryPanel.element )
    end
end

function sidebar:unselect_history_entry()
    self.requestHistoryPanel.list:unselect_all()
end

return sidebar