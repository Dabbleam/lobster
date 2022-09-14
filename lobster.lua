package.path = package.path .. ";includes/?.lua;includes/thirdparty/?.lua"

-- lanes bug: anything that requires lanes must be loaded
-- BEFORE the GTK UI code. otherwise we get this:

-- ASSERT failed: /root/lanes/src/tools.c:430 'lua_type( L, -1) == 3 || lua_type( L, -1) == 4'


local state = require "ui.state"

local protocols = require "core.protocols"
local prettifiers = require "core.prettifiers"
local request = require "core.managers.request"

state.prettifiers = prettifiers
state.managers = {
	request = request
}
state.protocols = protocols

local socket = require "socket"
local db = require "data.db"

-- TODO: use xdg/whatever is used in other platforms
-- to find where to store the database
local settings = db.open( "settings.db" )

local gtkUi = require "ui.gtk.main"
local app = gtkUi.create_application( settings )

local main_event_loop = function()
	request.pump()
	socket.sleep( 0.01 )
	return true
end

gtkUi.pump( app, main_event_loop )
