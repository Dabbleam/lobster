local lgi = require "lgi"

local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local Gio = lgi.Gio
local GtkSource = lgi.GtkSource
local GObject = lgi.GObject
local GLib = lgi.GLib
local Granite = lgi.Granite

local state = require "ui.state"
local sidebar = require "ui.gtk.components.sidebar"

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

		#requestTypeSelector,
		#requestTypeSelector button,
		#requestUrlEntry
		{
			border-right: 0;
			border-top-right-radius: 0;
			border-bottom-right-radius: 0;
		}

		#requestUrlEntry, #requestSendButton
		{
			border-top-left-radius: 0;
			border-bottom-left-radius: 0;
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

		local headerBar = Gtk.HeaderBar {
			title = "Lobster",
			show_close_button = true
		}

		local darkModeSwitch = Granite.ModeSwitch.from_icon_name( "display-brightness-symbolic", "weather-clear-night-symbolic" )

		darkModeSwitch:set_primary_icon_tooltip_text( "Light mode" )
		darkModeSwitch:set_secondary_icon_tooltip_text( "Dark mode" )
		darkModeSwitch:set_valign( Gtk.Align.CENTER )

		headerBar:pack_end( darkModeSwitch )

		window:set_titlebar( headerBar )

		-- TODO: settings
		local isDarkMode = true
		local gtkSettings = Gtk.Settings.get_default()

		if isDarkMode then
			darkModeSwitch:set_active( true )
			gtkSettings:set_property( "gtk-application-prefer-dark-theme", GObject.Value( GObject.Type.BOOLEAN, true ) )
		end

		local sidebarInstance = sidebar.new()

		local requestInfoPanel = Gtk.Box {
			orientation = Gtk.Orientation.VERTICAL,
			spacing = 10,
			hexpand = true,
			vexpand = true,
		}

		local requestGrid = Gtk.Grid {
			row_spacing = 10,
			column_spacing = 10,
			margin_left = 0,
			margin_right = 0,
			margin_top = 0,
			margin_bottom = 0,
			orientation = Gtk.Orientation.VERTICAL
		}

		local requestTypeSelector = Gtk.ComboBoxText {
			name = "requestTypeSelector"
		}

		local requestUrlEntry = Gtk.Entry {
			name = "requestUrlEntry"
		}

		requestUrlEntry:set_text( "https://dabbleam.com" )
		requestUrlEntry:set_placeholder_text( "Endpoint URL" )

		local comboWrapper = Gtk.Box {
			orientation = Gtk.Orientation.HORIZONTAL,
			spacing = 0,
			hexpand = true,
			vexpand = false,
			margin_left = 10,
			margin_right = 10,
			margin_top = 10,
			margin_bottom = 10
		}

		local sendButton = Gtk.Button {
			name = "requestSendButton",
			label = "Send"
		}

		sendButton:get_style_context():add_class( "suggested-action" )
		sendButton:set_always_show_image( true )
		sendButton:set_image( Gtk.Image {
			icon_name = "mail-send-symbolic"
		} )

		requestUrlEntry:set_activates_default( true )
		sendButton:set_can_default( true )

		function sendButton:on_clicked()
			local requestType = requestTypeSelector:get_active_text()
			local requestUrl = requestUrlEntry:get_text()
			state.sending_request = true
			request = state.managers.request.http( requestUrl, requestType )
		end

		local spinner = Gtk.Spinner {
			active = true
		}

		-- this is horrible and will probably break soon
		local sendButtonInnerContainer = sendButton:get_child():get_child()
		sendButtonInnerContainer:add( spinner )

		comboWrapper:pack_start( requestTypeSelector, false, false, 0 )
		comboWrapper:pack_start( requestUrlEntry, true, true, 0 )
		comboWrapper:pack_start( sendButton, false, false, 0 )

		local buffer = GtkSource.Buffer {}
		local languageManager = GtkSource.LanguageManager()

		local scrollWindow = Gtk.ScrolledWindow {
			hscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
			vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
			hexpand = true,
			vexpand = true,
		}

		local responseContainer = Gtk.Box {
			orientation = Gtk.Orientation.VERTICAL,
			spacing = 0,
			hexpand = true,
			vexpand = true,
			margin_left = 0,
			margin_right = 0,
			margin_top = 0,
			margin_bottom = 0
		}

		local sourceView = GtkSource.View {
			buffer = buffer
		}

		sourceView:set_show_line_numbers( true )
		sourceView:set_highlight_current_line( true )
		sourceView:set_name( "sourceView" )
		sourceView:set_editable( false )

		if isDarkMode then
			local manager = GtkSource.StyleSchemeManager.get_default()
			local scheme = manager:get_scheme( "solarized-dark" )
			buffer:set_style_scheme( scheme )
		end

		scrollWindow:add( sourceView )

		local infoBar = Gtk.InfoBar {
			message_type = Gtk.MessageType.WARNING,
			hexpand = true,
			vexpand = false,
			margin_left = 0,
			margin_right = 0,
			margin_top = 0,
			margin_bottom = 0
		}

		infoBar:set_show_close_button( true )

		local infoBarLabel = Gtk.Label {}

		local infoBarMain = infoBar:get_content_area()
		infoBarMain:pack_start( infoBarLabel, false, false, 0 )

		requestInfoPanel:pack_start( infoBar, false, false, 0 )
		responseContainer:pack_start( scrollWindow, true, true, 0 )

		local responseActions = Gtk.Grid {
			column_spacing = 5,
			margin_left = 0,
			margin_right = 0,
			margin_top = 0,
			margin_bottom = 0,
			orientation = Gtk.Orientation.HORIZONTAL
		}

		responseActions:get_style_context():add_class( "library-toolbar" )

		prettifyButton = Gtk.ToggleButton {
			name = "prettifyButton"
		}

		prettifyButton:get_style_context():add_class( "flat" )

		prettifyButton:set_always_show_image( true )
		prettifyButton:set_image( Gtk.Image {
			icon_name = "text-css"
		} )

		local prettifyShortcutMarkup = Granite.markup_accel_tooltip( { "<Ctrl>P" }, "Prettify" )
		prettifyButton:set_tooltip_markup( prettifyShortcutMarkup )

		function prettifyButton:on_toggled()
			state.is_showing_prettified = self:get_active()
		end

		local copyButton = Gtk.Button {
			name = "copyButton"
		}

		copyButton:get_style_context():add_class( "flat" )
		copyButton:set_always_show_image( true )
		copyButton:set_image( Gtk.Image {
			icon_name = "edit-copy-symbolic"
		} )
		copyButton:set_tooltip_text( "Copy" )

		function copyButton:on_clicked()
			local clipboard = Gtk.Clipboard.get( Gdk.SELECTION_CLIPBOARD )
			clipboard:set_text( state.response.body, -1 )
		end

		copyButton:set_sensitive( false )
		prettifyButton:set_sensitive( false )

		responseActions:attach( prettifyButton, 0, 0, 1, 1 )
		responseActions:attach( copyButton, 1, 0, 1, 1 )

		responseContainer:pack_start( responseActions, false, false, 0 )

		requestGrid:attach( comboWrapper, 0, 0, 1, 1 )
		requestGrid:attach( responseContainer, 0, 1, 1, 1 )

		requestInfoPanel:add( requestGrid )

		local paned = Gtk.Paned {
			orientation = Gtk.Orientation.HORIZONTAL,
			hexpand = true,
			vexpand = true,
		}

		paned:add1( sidebarInstance.element )
		paned:add2( requestInfoPanel )

		sidebarInstance:switch_to( "history" )

		window:add( paned )

		function window:on_destroy()
			application:quit()
		end

		local acceleratorGroup = Gtk.AccelGroup()

		acceleratorGroup:connect( Gdk.KEY_Q, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE, GObject.Closure( function()
			application:quit()
		end ) )

		acceleratorGroup:connect( Gdk.KEY_P, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE, GObject.Closure( function()
			if prettifyButton:get_sensitive() then
				prettifyButton:clicked()
			end
		end ) )

		window:add_accel_group( acceleratorGroup )

		-- hook everything up!

		local httpMethods = state.protocols.http.methods

		for _, method in ipairs( httpMethods ) do
			requestTypeSelector:append( method, method )
		end

		requestTypeSelector:set_active( 0 )

		state:on( "response.contentType", function( contentType )
			local language = languageManager:guess_language( nil, contentType )
			buffer:set_language( language )
		end )

		state:on( "response.prettified", function( prettified )
			if prettified then
				buffer:set_text( prettified, -1 )
				prettifyButton:set_active( true )
				prettifyButton:set_tooltip_text( "Prettify" )
			else
				buffer:set_text( state.response.body, -1 )
				prettifyButton:set_active( false )
				prettifyButton:set_tooltip_text( "Show original" )
			end
		end )

		state:on( "sending_request", function( busy )
			sendButton:set_sensitive( not busy )
			sendButton:set_always_show_image( not busy )
			spinner:set_visible( busy )
		end )

		state:on( "response", function( response )
			state.sending_request = false
		end )

		state:on( "response.error", function( error )
			if error then
				infoBarLabel:set_text( error )
				infoBar:set_visible( true )
				infoBar:set_revealed( true )
			else
				infoBar:set_revealed( false )
			end
		end )

		state:on( "response.body", function( body )
			state.prettified = nil

			prettifyButton:set_active( false )
			if body and body ~= "" then
				buffer:set_text( body, -1 )
				copyButton:set_sensitive( true )
				prettifyButton:set_sensitive( true )
			else
				copyButton:set_sensitive( true )
				prettifyButton:set_sensitive( true )
			end

			buffer:set_text( body, -1 )
		end )

		state:on( "is_showing_prettified", function( is_showing_prettified )
			if not is_showing_prettified then
				buffer:set_text( state.response.body, -1 )
				prettifyButton:set_tooltip_text( "Prettify" )
			else
				local prettified = state.prettified
				if not prettified then
					local source = state.response.body
					local type = state.response.contentType

					-- TODO: none of this should be here, and all of it should run
					-- on another thread without blocking the UI!!!

					if type == "text/html" then
						prettified = state.prettifiers.html.prettify( source )
					elseif type == "application/json" then
						prettified = state.prettifiers.json.prettify( source )
					end

					state.prettified = prettified
				end

				-- reenable syntax highlighting in case a long minified response
				-- caused the "highlighting single line took too much time" thing
				-- this actually does not work and I will probably have to patch GtkSourceView
				buffer:set_highlight_syntax( true )
				buffer:set_text( state.prettified, -1 )
				prettifyButton:set_tooltip_text( "Show original" )
			end
		end )

		local gtkSettings = Gtk.Settings.get_default()
		local darkModeClosure = GObject.Closure( function( object, value )
			gtkSettings:set_property( "gtk-application-prefer-dark-theme", value )
			local manager = GtkSource.StyleSchemeManager.get_default()
			local scheme = manager:get_scheme( "classic" )
			if value.value then
				scheme = manager:get_scheme( "solarized-dark" )
			end
				buffer:set_style_scheme( scheme )
		end )

		darkModeSwitch:bind_property_full( "active", gtkSettings, "gtk-application-prefer-dark-theme", 0, darkModeClosure, darkModeClosure )

		-- Need to upgrade to OS 6.0+ to use this:
		--[[local graniteSettings = Granite.Settings.get_default()
		gtkSettings.gtk_application_prefer_dark_theme = graniteSettings:get_prefers_color_scheme() == Granite.Settings.ColorScheme.DARK]]

		window:show_all()

		-- this needs to be here because otherwise gtk complains
		sendButton:grab_default()
		-- and then this needs to be here because of show_all
		spinner:set_visible( false )
		infoBar:set_visible( false )
		infoBar:set_revealed( false )
		requestUrlEntry:grab_focus()
	end

	return application
end

local function pump( app, main_event_loop )
	-- first argument is priority, 200 is G_PRIORITY_DEFAULT_IDLE
	-- not sure where I can find this defined as an enum
	GLib.idle_add( 200, main_event_loop )
	app:run()
end

return {
	create_application = create_application,
	pump = pump
}