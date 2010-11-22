-- Grab environment we need
local pairs = pairs
local table = table
local string = string
local type = type
local setmetatable = setmetatable
local wibox = wibox
local image = image
local widget = widget
local capi =
{
    screen = screen,
    mouse = mouse,
    client = client,
    keygrabber = keygrabber,
    tag = tag
}
local util = require("awful.util")
local tags = require("awful.tag")
local client = require ("awful.client")
local awbeautiful = require("beautiful")
local tonumber = tonumber

local io = io

module("awful.clientgrid")

local clients_table = {}
local wiboxes = {}
local wibox_style = {}
local current_row = 1
local current_col = 1


local function grid_grabber(mod, key, event)
    if event == "release" then
       return true
    end
    
    local beautiful
    beautiful = awbeautiful.get()
    
    wiboxes[current_row][current_col][1].border_color = wibox_style.border_normal
	
    if util.table.hasitem({"Up"}, key) or util.table.hasitem ({"k"}, key) then
		current_row = current_row - 1
		if (current_row) < 1 then current_row = #wiboxes end
		if (current_col > #(wiboxes[current_row])) then current_col = #(wiboxes[current_row]) end
		
    elseif util.table.hasitem({"Down"}, key) or util.table.hasitem ({"j"}, key) then
		current_row = current_row + 1
		if (current_row) > #wiboxes then current_row = 1 end
		if (current_col > #(wiboxes[current_row])) then current_col = #(wiboxes[current_row]) end
		
	elseif util.table.hasitem({"Right"}, key) or util.table.hasitem ({"l"}, key) then
		current_col = current_col + 1
		if (current_col > #(wiboxes[current_row])) then current_col = 1 end
		
    elseif util.table.hasitem({"Left"}, key) or util.table.hasitem ({"h"}, key) then
		current_col = current_col - 1
		if (current_col < 1) then current_col = #(wiboxes[current_row]) end
		
	elseif util.table.hasitem({"Return"}, key) then
	
		for x in pairs (wiboxes) do
			for y in pairs (wiboxes[x]) do
				wiboxes[x][y][1].visible = false
				client.focus.history.delete(wiboxes[x][y][2])
			end
		end
		tags.viewonly (capi.screen[capi.mouse.screen]:tags ()[wiboxes[current_row][current_col][3]])
		capi.client.focus = wiboxes[current_row][current_col][2]
		wiboxes[current_row][current_col][2]:raise ()
		wiboxes = {}
		return false
		
	elseif util.table.hasitem({"Escape"}, key) then
		for x in pairs (wiboxes) do
			for y in pairs (wiboxes[x]) do
				wiboxes[x][y][1].visible = false
			end
		end
		wiboxes = {}
		return false
    end
	
	wiboxes[current_row][current_col][1].border_color = wibox_style.border_focus
	
    return true
end

function run (style_table)

	wibox_style = style_table

	local beautiful
    beautiful = awbeautiful.get()

	if (wibox_style.border_width == nil) then wibox_style.border_width = beautiful.border_width end
	if (wibox_style.fg_color == nil) then wibox_style.fg_color = beautiful.fg_normal end
	if (wibox_style.border_normal == nil) then wibox_style.border_normal = beautiful.border_normal end
	if (wibox_style.border_focus == nil) then wibox_style.border_focus = beautiful.border_focus end
	if (wibox_style.font == nil) then wibox_style.font = beautiful.font end

	local wibox_row = {}
    local name_widgets
    local tags = {}
    local i = 0
    
    repeat
		for i, j in pairs (capi.screen[i+1]:tags ()) do
			table.insert (tags, j)
		end
		i = i+1
	until i > #capi.screen
    
    clients = {}
    wiboxes = {}
    local client_wibox_table = {}
    local screen_geometry = {}
    
    for i, j in pairs (capi.screen[capi.mouse.screen].geometry) do
		screen_geometry [#screen_geometry + 1] = j
	end
	
    --Loop through the tags
    for i, j in pairs (tags) do
		clients = j:clients ()
		wibox_row = {}
		--Loop through the clients on that tag
		for y, z in pairs (clients) do
			client_wibox_table = {}
			--client_wibox_table[1] contains the wibox
			client_wibox_table [1] = wibox ({fg = wibox_style.fg_color, bg = string.sub (Hexify (z.class), 1, 7), 
								border_color = wibox_style.border_normal, border_width = wibox_style.border_width})
			client_wibox_table [1].width = 120
			client_wibox_table [1].height = 50
			client_wibox_table [1].x = screen_geometry[4]/2 - 200 + (y+1)*120
			client_wibox_table [1].y = screen_geometry[3]/3 - 100 + (#wiboxes)*50
			client_wibox_table [1].screen = capi.mouse.screen
			client_wibox_table [1].ontop = true
			name_widgets = widget ({ type = "textbox"})
			name_widgets.align = "center"
			margin = { bottom = 0, top = 18, left = 0, right = 0}
			name_widgets:margin (margin)
			name_widgets.text = string.format ('<span font_desc="%s">%s</span>', wibox_style.font, util.escape (z.name))
			client_wibox_table [1].widgets = {name_widgets}
			--client_wibox_table[2] contains the client associated with that wibox
			client_wibox_table[2] = z
			client_wibox_table[3] = i --store the tag number, since we can't trust the row will be the same
			--each row contains a client_wibox_table
			wibox_row [#wibox_row + 1] = client_wibox_table
		end
		if (#wibox_row > 0) then wiboxes [#wiboxes + 1] = wibox_row end
	end
	--"wiboxes": the rows = tag, column = client
	wiboxes[current_row][current_col][1].border_color = wibox_style.border_focus
	capi.keygrabber.run(grid_grabber)
end

-- Convert a string to a string of hex escapes
-- source: http://lua-users.org/wiki/SciteHexify
function Hexify(s) 
  local hexits = "#f"
  for i = 1, string.len(s) do
    hexits = hexits .. string.format("%x", string.byte(s, i))
  end
  return hexits
end


setmetatable(_M, { __call = function(_, ...) return new(...) end })

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:encoding=utf-8:textwidth=80
