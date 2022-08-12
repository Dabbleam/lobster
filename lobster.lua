package.path = package.path .. ";includes/?.lua;includes/thirdparty/?.lua"

local gtkUi = require "ui.gtk.main"

gtkUi.pump_events( gtkUi.create_application() )