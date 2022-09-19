local lgi = require "lgi"

local Gtk = lgi.Gtk
local Gdk = lgi.Gdk

local state = require "core.state"

local panel = {}
panel.__index = panel

local _initialized = false

function panel.new( title )
    if not _initialized then
        _initialized = true
        local cssProvider = Gtk.CssProvider()
        cssProvider:load_from_data( [[
            .sidebar-header {
                box-shadow: inset 0 -4px 4px -6px rgba(0, 0, 0, 0.5);
            }
        ]] )

        Gtk.StyleContext.add_provider_for_screen( Gdk.Screen.get_default(), cssProvider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION )
    end

    local self = {
        element = panel
    }

    local panelInstance = Gtk.Box {
        orientation = Gtk.Orientation.VERTICAL,
        spacing = 0,
        hexpand = true,
        vexpand = true,
    }

    local panelHeader = Gtk.Box {
        orientation = Gtk.Orientation.HORIZONTAL,
        hexpand = true,
        vexpand = false,
    }

    panelHeader:get_style_context():add_class( "sidebar-header" )

    local panelTitle = Gtk.Label {
        label = title
    }

    panelTitle:get_style_context():add_class( "h4" )

    local panelTitleAlignment = Gtk.Alignment {
        xalign = 0.5,
        yalign = 0.5,
        hexpand = true,
        vexpand = false,
        child = panelTitle,
        margin_top = 8,
        margin_bottom = 7,
        margin_left = 10,
        margin_right = 10
    }

    panelHeader:pack_start( panelTitleAlignment, true, true, 0 )

    local panelBody = Gtk.Box {
        orientation = Gtk.Orientation.VERTICAL,
        hexpand = true,
        vexpand = true
    }

    panelInstance:pack_start( panelHeader, false, false, 0 )
    panelInstance:pack_start( panelBody, true, true, 0 )

    local self = {
        element = panelInstance,
        body = panelBody
    }

    setmetatable( self, panel )

    return self
end

function panel:add( element )
    self.body:pack_start( element, true, true, 0 )
end

return panel