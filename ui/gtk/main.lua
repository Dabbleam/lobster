local lgi = require "lgi"

local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local Gio = lgi.Gio
local GtkSource = lgi.GtkSource
local GObject = lgi.GObject
local GLib = lgi.GLib

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

		-- TODO: settings
		local isDarkMode = true
		local gtkSettings = Gtk.Settings.get_default()

		if isDarkMode then
			gtkSettings:set_property( "gtk-application-prefer-dark-theme", GObject.Value( GObject.Type.BOOLEAN, true ) )
		end

		local button = Gtk.Button {
			label = "Change state"
		}

		local requestHistoryPanel = Gtk.Box {
			orientation = Gtk.Orientation.VERTICAL,
			spacing = 10,
			hexpand = true,
			vexpand = true,
		}

		local requestInfoPanel = Gtk.Box {
			orientation = Gtk.Orientation.VERTICAL,
			spacing = 10,
			hexpand = true,
			vexpand = true,
		}

		local requestHistoryPanelHeader = Gtk.Box {
			orientation = Gtk.Orientation.HORIZONTAL,
			hexpand = true,
			vexpand = false,
			margin_top = 10,
			margin_bottom = 10,
			margin_left = 10,
			margin_right = 10
		}

		local requestHistoryPanelTitle = Gtk.Label {
			label = "REQUEST HISTORY",
			name = "requestHistoryPanelTitle",
		}

		requestHistoryPanelTitle:get_style_context():add_class( "h4" )

		local requestHistoryPanelTitleAlignment = Gtk.Alignment {
			xalign = 0.5,
			yalign = 0.5,
			hexpand = true,
			vexpand = false,
			child = requestHistoryPanelTitle
		}
		requestHistoryPanelHeader:pack_start( requestHistoryPanelTitleAlignment, true, true, 0 )

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

		local function update_state_response( response )
			state.response = response
		end

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
		prettifyButton:set_tooltip_text( "Prettify" )

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

		requestHistoryPanel:pack_start( requestHistoryPanelHeader, false, false, 0 )
		requestHistoryPanel:pack_start( button, true, false, 0 )
		requestInfoPanel:add( requestGrid )

		local paned = Gtk.Paned {
			orientation = Gtk.Orientation.HORIZONTAL,
			hexpand = true,
			vexpand = true,
		}

		paned:add1( requestHistoryPanel )
		paned:add2( requestInfoPanel )

		window:add( paned )

		function window:on_destroy()
			application:quit()
		end

		local acceleratorGroup = Gtk.AccelGroup()

		acceleratorGroup:connect( Gdk.KEY_Q, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE, GObject.Closure( function()
			application:quit()
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

		state:on( "response.body", function( body )
			state.sending_request = false

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

					if type == "text/html" or type == "text/xml" or type == "application/xml" then
						prettified = state.prettifiers.xml.prettify( source )
					elseif type == "application/json" then
						prettified = state.prettifiers.json.prettify( source )
					end

					state.prettified = prettified
				end

				buffer:set_text( state.prettified, -1 )
				prettifyButton:set_tooltip_text( "Show original" )
			end
		end )

		window:show_all()

		-- this needs to be here because otherwise gtk complains
		sendButton:grab_default()
		-- and then this needs to be here because of show_all
		spinner:set_visible( false )
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