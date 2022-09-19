local lgi = require "lgi"

local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local Pango = lgi.Pango

local state = require "core.state"

local panel = require "ui.gtk.components.sidebar.panel"

local requestHistory = {}
requestHistory.__index = requestHistory

local _initialized = false

function requestHistory.new()
    if not _initialized then
        local cssProvider = Gtk.CssProvider()
        cssProvider:load_from_data([[
            .request_method {
                font-weight: bold;
            }

            .response_code {
                font-size: 12px;
                font-weight: bold;
                color: #fff;
                padding: 2px 5px;
                border-radius: 3px;
                background-color: #000;
            }

            .response_code_1xx {
                background-color: #5bc0de;
            }

            .response_code_2xx {
                background-color: #5cb85c;
            }

            .response_code_3xx {
                background-color: #d913af;
            }

            .response_code_4xx {
                background-color: #f0ad4e;
            }

            .response_code_5xx {
                background-color: #d9534f;
            }
        ]])

        Gtk.StyleContext.add_provider_for_screen( Gdk.Screen.get_default(), cssProvider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION )
    end

    local panel = panel.new( "REQUEST HISTORY" )

    local listScrollable = Gtk.ScrolledWindow {
        hexpand = true,
        vexpand = true
    }

    local list = Gtk.ListBox {
        hexpand = true,
        vexpand = true
    }

    listScrollable:add( list )
    panel:add( listScrollable )

    local self = {
        element = panel.element,
        list = list
    }

    local _self = self
    function list:on_row_selected( row )
        if _self.on_row_selected then
            _self.on_row_selected( row )
        end
    end

    setmetatable( self, requestHistory )

    state:on( "history_entries", function( history )
        -- TODO: this is super wasteful, we should only create or remove
        -- the entries that have changed
        for k, v in pairs( history ) do print( k, v ) end
        self:clear()

        for k, item in pairs( history ) do
            self:add_entry( item )
        end
    end )

    state:on( "new_history_entry", function( entry )
        self:add_entry( entry, true )
    end )

    for k, item in ipairs( state.history_entries ) do
        self:add_entry( item )
    end

    return self
end

function requestHistory:clear()
    self.list:foreach( function( row )
        self.list:remove( row )
    end )
end

function requestHistory:add_entry( item, is_new )
    local index = item.id
    local row = Gtk.ListBoxRow {
        hexpand = false,
        vexpand = false
    }

    row:set_name( index )

    local rowBox = Gtk.Box {
        orientation = Gtk.Orientation.HORIZONTAL,
        hexpand = false,
        vexpand = false,
        spacing = 10,
        margin_top = 10,
        margin_bottom = 10,
        margin_left = 10,
        margin_right = 10
    }

    -- if we don't have a response code, this request was aborted in-flight
    if not item.response_code then
        row:set_selectable( false )
    end

    local responseCodeLabel = Gtk.Label {
        label = item.response_code or "XXX"
    }

    local responseCodeType = string.sub( item.response_code or "500", 1, 1 )

    responseCodeLabel:get_style_context():add_class( "response_code" )
    responseCodeLabel:get_style_context():add_class( "response_code_" .. responseCodeType .. "xx" )

    local methodLabel = Gtk.Label {
        label = item.method,
        hexpand = false,
        vexpand = false
    }

    methodLabel:get_style_context():add_class( "request_method" )

    local urlLabel = Gtk.Label {
        label = item.url,
        hexpand = false,
        vexpand = false
    }

    urlLabel:set_ellipsize( Pango.EllipsizeMode.END )
    urlLabel:set_has_tooltip( true )
    local tooltip_content = item.url

    if not item.response_code then
        tooltip_content = tooltip_content .. "\n\nThis request was cancelled."
    end

    row:set_tooltip_text( tooltip_content )

    rowBox:pack_start( responseCodeLabel, false, false, 0 )
    rowBox:pack_start( methodLabel, false, false, 0 )
    rowBox:pack_start( urlLabel, false, false, 0 )

    row:add( rowBox )

    if is_new then
        self.list:insert( row, 0 )
    else
        self.list:insert( row, -1 )
    end
    self.list:show_all()
end

return requestHistory
