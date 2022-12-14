local lgi = require "lgi"

local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local Gio = lgi.Gio
local GtkSource = lgi.GtkSource
local GObject = lgi.GObject
local GLib = lgi.GLib
local Granite = lgi.Granite

local state = require "core.state"
local sidebar = require "ui.gtk.components.sidebar"

local function create_application( settings, history )
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

		local sidebarInstance = sidebar.new()

		local requestInfoPanel = Gtk.Box {
			orientation = Gtk.Orientation.VERTICAL,
			spacing = 10,
			hexpand = true,
			vexpand = true,
		}

		local requestGrid = Gtk.Grid {
			row_spacing = 0,
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

		requestUrlEntry:set_text( settings:get( "last_url", "" ) )
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

		local spinner = Gtk.Spinner {
			active = true
		}

		-- this is horrible and will probably break soon
		local sendButtonInnerContainer = sendButton:get_child():get_child()
		sendButtonInnerContainer:add( spinner )

		comboWrapper:pack_start( requestTypeSelector, false, false, 0 )
		comboWrapper:pack_start( requestUrlEntry, true, true, 0 )
		comboWrapper:pack_start( sendButton, false, false, 0 )

		local parametersContainer = Gtk.Box {
			orientation = Gtk.Orientation.VERTICAL,
			spacing = 10,
			hexpand = true,
			vexpand = true,
		}

		local parametersStack = Gtk.Stack {
			transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT,
			transition_duration = 200,
			hexpand = true,
			vexpand = true
		}

		local parametersStackSwitcher = Gtk.StackSwitcher {
			stack = parametersStack
		}

		local headersParent = Gtk.Box {
			orientation = Gtk.Orientation.VERTICAL,
			hexpand = true,
			vexpand = true,
		}

		local headersActions = Gtk.Grid {
			column_spacing = 0,
			margin_left = 0,
			margin_right = 0,
			margin_top = 0,
			margin_bottom = 0,
			orientation = Gtk.Orientation.HORIZONTAL
		}

		local headersContainer = Gtk.ScrolledWindow {
			hscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
			vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
			hexpand = true,
			vexpand = true,
		}

		local headersTreeView = Gtk.TreeView {
			hexpand = true,
			vexpand = true,
		}

		local headersListStore = Gtk.ListStore.new {
			GObject.Type.STRING,
			GObject.Type.STRING
		}

		headersTreeView:set_model( headersListStore )

		function headersTreeView:on_button_press_event( event )
			if event.button == 3 then -- right click
				local path, column, x, y = headersTreeView:get_path_at_pos( event.x, event.y )
				if path then
					local iter = headersListStore:get_iter( path )
					local headerName = headersListStore:get_value( iter, 0 )
					local menu = Gtk.Menu {}

					local removeItem = Gtk.MenuItem {
						label = "Remove " .. headerName.value
					}

					function removeItem:on_activate()
						headersListStore:remove( iter )
					end

					menu:append( removeItem )
					menu:show_all()
					menu:popup_at_pointer( event )
				end
			end
		end

		-- all of this should be moved to a nice lua component
		getSelectedHeaders = function()
			local headers = {}
			headersListStore:foreach( function( model, path, iter )
				local key = model:get_value( iter, 0 )
				local value = model:get_value( iter, 1 )

				key = key:get_string()
				value = value:get_string()

				if key ~= "" then
					headers[ key ] = value
				end
			end )
			return headers
		end

		local headersNameColumn = Gtk.TreeViewColumn {
			title = "Name",
			resizable = true,
			sort_column_id = 0
		}

		local headersValueColumn = Gtk.TreeViewColumn {
			title = "Value",
			resizable = true,
			sort_column_id = 1
		}

		-- todo: probably shouldn't hardcode these numbers?
		headersNameColumn:set_fixed_width( 150 )
		headersValueColumn:set_fixed_width( 450 )

		local headersNameCellRenderer = Gtk.CellRendererText { editable = true }
		local headersValueCellRenderer = Gtk.CellRendererText { editable = true }

		-- when enter is pressed on the name cell, focus the value cell
		function headersNameCellRenderer:on_edited( path, new_text )
			-- need to do this with a small delay because otherwise
			-- it gets unfocused immediately
			GLib.timeout_add( GLib.PRIORITY_DEFAULT, 10, function()
				local iter = headersListStore:get_iter_from_string( path )
				headersTreeView:set_cursor( Gtk.TreePath.new_from_string( path ), headersValueColumn, true )
			end )
		end

		headersNameColumn:pack_start( headersNameCellRenderer, true )
		headersNameColumn:add_attribute( headersNameCellRenderer, "text", 0 )

		headersValueColumn:pack_start( headersValueCellRenderer, true )
		headersValueColumn:add_attribute( headersValueCellRenderer, "text", 1 )

		headersNameCellRenderer.on_edited = function( renderer, path, new_text )
			local treepath = Gtk.TreePath.new_from_string( path )
			local model = headersTreeView:get_model()
			model:set_value( model:get_iter( treepath ), 0, GObject.Value( GObject.Type.STRING, new_text ) )
		end

		headersValueCellRenderer.on_edited = function( renderer, path, new_text )
			local treepath = Gtk.TreePath.new_from_string( path )
			local model = headersTreeView:get_model()
			model:set_value( model:get_iter( treepath ), 1, GObject.Value( GObject.Type.STRING, new_text ) )
		end

		headersTreeView:append_column( headersNameColumn )
		headersTreeView:append_column( headersValueColumn )

		local addHeaderButton = Gtk.Button {
			name = "addHeaderButton"
		}

		addHeaderButton:get_style_context():add_class( "flat" )

		addHeaderButton:set_always_show_image( true )
		addHeaderButton:set_image( Gtk.Image {
			icon_name = "list-add-symbolic"
		} )

		function addHeaderButton:on_clicked()
			headersListStore:append( { "", "" } )
			local path = Gtk.TreePath.new_from_indices {
				headersListStore:iter_n_children() - 1
			}
			headersTreeView:set_cursor( path, headersNameColumn, true )
		end

		local deleteHeaderButton = Gtk.Button {
			name = "deleteHeaderButton"
		}

		deleteHeaderButton:get_style_context():add_class( "flat" )

		deleteHeaderButton:set_always_show_image( true )
		deleteHeaderButton:set_image( Gtk.Image {
			icon_name = "list-remove-symbolic"
		} )

		function deleteHeaderButton:on_clicked()
			local selection = headersTreeView:get_selection()
			local model, iter = selection:get_selected()
			if iter then
				model:remove( iter )
			end
		end

		headersActions:attach( addHeaderButton, 0, 0, 1, 1 )
		headersActions:attach( deleteHeaderButton, 1, 0, 1, 1 )

		headersContainer:add( headersTreeView )
		headersParent:add( headersContainer )
		headersParent:add( headersActions )

		local bodyContainer = Gtk.Box {
			orientation = Gtk.Orientation.VERTICAL,
			spacing = 10,
			hexpand = true,
			vexpand = true,
		}

		local bodyBuffer = GtkSource.Buffer {}
		local bodyLanguageManager = GtkSource.LanguageManager()
		local bodyLanguage = bodyLanguageManager:get_language( "json" )
		bodyBuffer:set_language( bodyLanguage )

		local bodyEditor = GtkSource.View {
			hexpand = true,
			vexpand = true,
			buffer = bodyBuffer
		}

		bodyEditor:set_show_line_numbers( true )
		bodyEditor:set_auto_indent( true )
		bodyEditor:set_indent_on_tab( true )

		bodyContainer:add( bodyEditor )

		local bodyLabel = Gtk.Label {
			label = "Body",
			hexpand = true,
			vexpand = false,
			halign = Gtk.Align.START,
			valign = Gtk.Align.CENTER
		}

		parametersStack:add_titled( headersParent, "headers", "Headers" )
		parametersStack:add_titled( bodyContainer, "body", "Body" )

		local parametersStackSwitcherAlignment = Gtk.Alignment {
			parametersStackSwitcher,
			xalign = 0.5,
			yalign = 0.5,
			xscale = 0.0,
			yscale = 0.0,
			hexpand = true,
			vexpand = false
		}
		parametersContainer:add( parametersStackSwitcherAlignment )
		parametersContainer:add( parametersStack )

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
			column_spacing = 0,
			margin_left = 0,
			margin_right = 0,
			margin_top = 0,
			margin_bottom = 0,
			orientation = Gtk.Orientation.HORIZONTAL
		}

		responseActions:get_style_context():add_class( "library-toolbar" )

		local prettifyButton = Gtk.ToggleButton {
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

		local parametersResponsePaned = Gtk.Paned {
			orientation = Gtk.Orientation.VERTICAL,
			hexpand = true,
			vexpand = true,
			margin_left = 0,
			margin_right = 0,
			margin_top = 0,
			margin_bottom = 0
		}

		parametersResponsePaned:pack1( parametersContainer, true, false )
		parametersResponsePaned:pack2( responseContainer, true, false )

		requestGrid:attach( comboWrapper, 0, 0, 1, 1 )
		requestGrid:attach( parametersResponsePaned, 0, 1, 1, 1 )

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

		acceleratorGroup:connect( Gdk.KEY_Return, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE, GObject.Closure( function()
			if sendButton:get_sensitive() then
				sendButton:clicked()
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

		state:on( "request_method", function( method )
			if method == "POST" or method == "PUT" or method == "PATCH" then
				bodyContainer:show()
			else
				bodyContainer:hide()
			end
		end )

		local httpMethods = state.protocols.http.methods

		for _, method in ipairs( httpMethods ) do
			requestTypeSelector:append( method, method )
		end

		function sendButton:on_clicked()
			if state.sending_request then
				state.sending_request:cancel()
				return
			end

			local requestType = requestTypeSelector:get_active_text()
			local requestUrl = requestUrlEntry:get_text()
			settings:set( "last_url", requestUrl )
			local headers = getSelectedHeaders()
			local body = bodyBuffer:get_text( bodyBuffer:get_start_iter(), bodyBuffer:get_end_iter(), true )
			if not bodyContainer:is_visible() then
				body = nil
			end

			state.sending_request = state.managers.request.http( requestUrl, requestType, headers, body )
			sidebarInstance:unselect_history_entry()
		end

		function requestTypeSelector:on_changed()
			local method = self:get_active_text()
			state.request_method = method
		end

		sidebarInstance.on_history_entry_selected = function( entry )
			requestUrlEntry:set_text( entry.url )

			local methodIndex = 0
			for i, method in ipairs( httpMethods ) do
				if method == entry.method then
					methodIndex = i
					break
				end
			end
			requestTypeSelector:set_active( methodIndex - 1 )

			headersListStore:clear()
			for header, value in pairs( entry.headers ) do
				local row = headersListStore:append()
				headersListStore:set( row, { header, value } )
			end

			local contentType = nil
			for header, value in pairs( entry.response_headers ) do
				if header:lower() == "content-type" then
					contentType = value:match( "^([^;]*)" ):lower()
					break
				end
			end

			state.response = {
				body = entry.response_body,
				contentType = contentType,
				headers = entry.response_headers,
				status = entry.response_code
			}
		end

		local isDarkMode = settings:get( "dark_mode" )
		local gtkSettings = Gtk.Settings.get_default()

		local function setDarkMode( enabled )
			settings:set( "dark_mode", enabled )
			local value = GObject.Value( GObject.Type.BOOLEAN, enabled )
			gtkSettings:set_property( "gtk-application-prefer-dark-theme", value )
			local manager = GtkSource.StyleSchemeManager.get_default()
			local scheme = manager:get_scheme( "classic" )
			if value.value then
				scheme = manager:get_scheme( "solarized-dark" )
			end
			buffer:set_style_scheme( scheme )
			bodyBuffer:set_style_scheme( scheme )
		end

		local gtkSettings = Gtk.Settings.get_default()
		local darkModeClosure = GObject.Closure( function( object, value )
			setDarkMode( value.value )
		end )

		if isDarkMode then
			-- we don't do this in the closure because we don't want to trigger
			-- the callback when we set the property (might cause an infinite loop or something)
			darkModeSwitch:set_active( true )
		end

		setDarkMode( isDarkMode )

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

		requestTypeSelector:set_active( 0 )

		-- split sizes reasonably between the request and response panes once we're all inited
		local sizeAllocation = parametersResponsePaned:get_allocation()
		parametersResponsePaned:set_position( sizeAllocation.height / 2.5 )
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