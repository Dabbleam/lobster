local lgi = require "lgi"

local Gtk = lgi.Gtk

local state = require "core.state"

local panel = {}
panel.__index = panel

function panel.new( title )
    local self = {
        element = panel
    }

    local panelInstance = Gtk.Box {
        orientation = Gtk.Orientation.VERTICAL,
        spacing = 10,
        hexpand = true,
        vexpand = true,
    }

    local panelHeader = Gtk.Box {
        orientation = Gtk.Orientation.HORIZONTAL,
        hexpand = true,
        vexpand = false,
        margin_top = 10,
        margin_bottom = 10,
        margin_left = 10,
        margin_right = 10
    }

    local panelTitle = Gtk.Label {
        label = title
    }

    panelTitle:get_style_context():add_class( "h4" )

    local panelTitleAlignment = Gtk.Alignment {
        xalign = 0.5,
        yalign = 0.5,
        hexpand = true,
        vexpand = false,
        child = panelTitle
    }

    panelHeader:pack_start( panelTitleAlignment, true, true, 0 )

    panelInstance:pack_start( panelHeader, false, false, 0 )

    local self = {
        element = panelInstance
    }

    setmetatable( self, panel )

    return self
end

return panel