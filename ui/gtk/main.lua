local lgi = require "lgi"

local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local Gio = lgi.Gio
local GtkSource = lgi.GtkSource
local GObject = lgi.GObject

local state = require "ui.state"

local function create_application()
	local application = Gtk.Application {
		application_id = "com.dabbleam.lobster",
		flags = Gio.ApplicationFlags.FLAGS_NONE,
	}

	local cssProvider = Gtk.CssProvider()
	cssProvider:load_from_data( [[
		#sourceView
		{
			font-family: monospace;
		}
	]] )

	Gtk.StyleContext.add_provider_for_screen( Gdk.Screen.get_default(), cssProvider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION )

	function application:on_activate()
		local window = Gtk.ApplicationWindow {
			application = application,
			title = "Lobster",
			default_width = 900,
			default_height = 700,
		}

		local grid = Gtk.Grid {
			row_spacing = 10,
			column_spacing = 10,
			margin_left = 10,
			margin_right = 10,
			margin_top = 10,
			margin_bottom = 10,
			orientation = Gtk.Orientation.VERTICAL
		}

		local myOwnCode = io.open( "ui/gtk/main.lua", "r" )
		local myOwnCodeText = myOwnCode:read( "*all" )
		myOwnCode:close()

		local buffer = GtkSource.Buffer {
			text = myOwnCodeText
		}

		state:on( "responseText", function( response )
			buffer:set_text( response, -1 )
		end )

		local languageManager = GtkSource.LanguageManager()
		local language = languageManager:get_language( "lua" )
		buffer:set_language( language )

		local scrollWindow = Gtk.ScrolledWindow {
			hscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
			vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
			hexpand = true,
			vexpand = true,
		}

		local sourceView = GtkSource.View {
			buffer = buffer
		}

		sourceView:set_show_line_numbers( true )
		sourceView:set_highlight_current_line( true )
		sourceView:set_name( "sourceView" )
		sourceView:set_editable( false )

		scrollWindow:add( sourceView )

		local button = Gtk.Button {
			label = "Change state"
		}

		function button:on_clicked()
			state.responseText = "-- Test"
		end

		grid:attach( button, 0, 1, 1, 1 )
		grid:attach( scrollWindow, 0, 0, 1, 1 )

		window:add( grid )

		function window:on_destroy()
			application:quit()
		end

		local acceleratorGroup = Gtk.AccelGroup()
		acceleratorGroup:connect( Gdk.KEY_Q, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE, GObject.Closure( function()
			application:quit()
		end ) )

		window:add_accel_group( acceleratorGroup )

		window:show_all()
	end

	return application
end

local function pump_events( app )
	app:run()
end

return {
	create_application = create_application,
	pump_events = pump_events
}