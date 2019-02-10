-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

Super = "Mod4"
Hyper = "Mod3"
Shift = "Shift"
Ctrl = "Control"

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors,
		position = "bottom_left"
	})
end

-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure we don't go into an endless error loop
		if in_error then return end
		in_error = true

		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err)
		})
		in_error = false
	end)
end
-- }}}

beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme.lua")
local scripts_path = beautiful.confdir .. "/scripts/"

-- Startup {{{
local function run_once(cmd)
	local findme = cmd
	local firstspace = cmd:find(" ")
	if firstspace then
		findme = cmd:sub(0, firstspace - 1)
	end
	awful.spawn.with_shell(
		"pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")"
	)
end

-- run_once("konsole -e zsh")
run_once("alacritty")

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts =
	{
		awful.layout.suit.tile,
		awful.layout.suit.tile.bottom,
		awful.layout.suit.tile.top,
		awful.layout.suit.fair
	}

-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
	awful.button({}, 1, function(t)
		t:view_only()
	end),
	awful.button({ Super }, 1, function(t)
		if client.focus then
			client.focus:move_to_tag(t)
		end
	end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({ Super }, 3, function(t)
		if client.focus then
			client.focus:toggle_tag(t)
		end
	end),
	awful.button({}, 4, function(t)
		awful.tag.viewnext(t.screen)
	end),
	awful.button({}, 5, function(t)
		awful.tag.viewprev(t.screen)
	end)
)

local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			if not c:isvisible() and c.first_tag then
				c.first_tag:view_only()
			end
			client.focus = c
			c:raise()
		end
	end)
)

local function set_wallpaper(s)
	if beautiful.wallpaper then
		local wallpaper = beautiful.wallpaper
		gears.wallpaper.maximized(wallpaper, s, true)
	end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- Widgets {{{
local function wrap_widget(
target_widget,
	target_bg,
	target_fg,
	margin_left,
	margin_right
)
	local wrapped_inner = wibox.container.margin()
	wrapped_inner:set_right(margin_right)
	wrapped_inner:set_left(margin_left)
	wrapped_inner:set_widget(target_widget)

	local wrapped_widget = wibox.container.background()
	wrapped_widget:set_widget(wrapped_inner)
	wrapped_widget:set_bg(target_bg)
	wrapped_widget:set_fg(target_fg)

	return wrapped_widget
end

local function read_pipe(cmd)
	local f = assert(io.popen(cmd))
	local output = f:read("*all")
	f:close()

	return output
end

local function wrap_arrow(image)
	local wrapped_icon = wibox.container.margin()
	wrapped_icon:set_widget(wibox.widget.imagebox(image))
	wrapped_icon:set_margins(-1)

	return wrapped_icon
end

-- arrows {{{
local arrow_0L0 = wrap_arrow(beautiful.arrow_0L0)
local arrow_0L1 = wrap_arrow(beautiful.arrow_0L1)
local arrow_1L2 = wrap_arrow(beautiful.arrow_1L2)
local arrow_2L1 = wrap_arrow(beautiful.arrow_2L1)
local arrow_2L3 = wrap_arrow(beautiful.arrow_2L3)
local arrow_0R0 = wrap_arrow(beautiful.arrow_0R0)
local arrow_1R0 = wrap_arrow(beautiful.arrow_1R0)
-- }}}

awful.screen.connect_for_each_screen(function(s)
	set_wallpaper(s)

	awful.tag(
		{ "1", "2", "3", "4", "5", "6", "7", "8", "9" },
		s,
		{
			awful.layout.layouts[3],
			awful.layout.layouts[1],
			awful.layout.layouts[1],
			awful.layout.layouts[1],
			awful.layout.layouts[1],
			awful.layout.layouts[1],
			awful.layout.layouts[1],
			awful.layout.layouts[1],
			awful.layout.layouts[3]
		}
	)

	if s.index == 1 then
		s.tags[1].master_count = 1
		s.tags[1].column_count = 1
		s.tags[1].master_width_factor = 0.85

		for t = 2, 8 do
			s.tags[t].master_count = 1
			s.tags[t].column_count = 1
			s.tags[t].master_width_factor = 0.75
		end

		s.tags[9].master_count = 3
		s.tags[9].column_count = 1
		s.tags[9].master_width_factor = 0.5
	else
		for t = 1, 9 do
			if not s.tags[t] then
				s.tags[t] = {
					master_count = 1,
					column_count = 1,
					master_width_factor = 0.85
				}
			else
				s.tags[t].master_count = 1
				s.tags[t].column_count = 1
				s.tags[t].master_width_factor = 0.85
			end
		end
	end

	s.mypromptbox = awful.widget.prompt()

	s.promptbox_wrap = wrap_widget(s.mypromptbox, beautiful.bg_normal, beautiful.fg_normal, 4, 1)

	s.mytaglist = awful.widget.taglist{
		screen = s,
		filter = awful.widget.taglist.filter.all,
		buttons = taglist_buttons
	}

	s.taglist_wrap =
		wrap_widget(s.mytaglist, beautiful.midgray_0, beautiful.fg_normal, 1, 6)

	s.mytasklist = awful.widget.tasklist{
		screen = s,
		filter = awful.widget.tasklist.filter.currenttags,
		buttons = tasklist_buttons
	}

	s.mywibox = awful.wibar({
		position = "top",
		screen = s,
		height = beautiful.wibar_height
	})

	s.mywibox:setup{
		layout = wibox.layout.align.horizontal,
		{
			layout = wibox.layout.fixed.horizontal,
			s.taglist_wrap,
			arrow_1R0,
			s.promptbox_wrap,
			arrow_0R0
		},
		s.mytasklist,
		{
			layout = wibox.layout.fixed.horizontal,
			wibox.widget.systray(),
			arrow_0L0,
			{
				{
					awful.widget.watch(
						"zsh -c " .. scripts_path .. "iploc",
						10
					),
					bg = beautiful.bg_normal,
					fg = beautiful.fg_muted,
					widget = wibox.container.background
				},
				left = 2,
				right = 2,
				widget = wibox.container.margin
			},
			{
				{
					text = ":",
					widget = wibox.widget.textbox
				},
				bg = beautiful.bg_normal,
				fg = beautiful.primary_muted,
				widget = wibox.container.background
			},
			{
				{
					awful.widget.watch(
						"zsh -c " .. scripts_path .. "ipext",
						10
					),
					bg = beautiful.bg_normal,
					fg = beautiful.primary_muted,
					widget = wibox.container.background
				},
				left = 2,
				right = 2,
				widget = wibox.container.margin
			},
			arrow_0L1,
			{
				{
					awful.widget.watch(
						"zsh -c 'print ${$(free --mega)[9]}'",
						10
					),
					left = 2,
					right = 2,
					widget = wibox.container.margin
				},
				bg = beautiful.midgray_0,
				fg = beautiful.fg_normal,
				widget = wibox.container.background
			},
			{
				{
					layout = wibox.layout.align.horizontal,
					{
						text = ":",
						widget = wibox.widget.textbox
					},
					{
						awful.widget.watch(
							"zsh -c " .. scripts_path .. "cpu",
							5
						),
						left = 2,
						right = 4,
						widget = wibox.container.margin
					}
				},
				bg = beautiful.midgray_0,
				fg = beautiful.primary,
				widget = wibox.container.background
			},
			arrow_1L2,
			{
				{
					layout = wibox.layout.align.horizontal,
					{
						{
							text = "v",
							widget = wibox.widget.textbox
						},
						left = 2,
						right = 1,
						widget = wibox.container.margin
					},
					{
						awful.widget.watch(
							"zsh -c " .. scripts_path .. "volp",
							60
						),
						left = 1,
						right = 4,
						widget = wibox.container.margin
					}
				},
				bg = beautiful.midgray_1,
				fg = beautiful.fg_normal,
				widget = wibox.container.background
			},
			arrow_2L1,
			{
				{
					layout = wibox.layout.align.horizontal,
					{
						{
							text = "b",
							widget = wibox.widget.textbox
						},
						left = 4,
						right = 1,
						widget = wibox.container.margin
					},
					{
						awful.widget.watch(
							"zsh -c " .. scripts_path .. "pwrp",
							30
						),
						left = 1,
						right = 4,
						widget = wibox.container.margin
					}
				},
				bg = beautiful.midgray_0,
				fg = beautiful.primary,
				widget = wibox.container.background
			},
			arrow_1L2,
			{
				{
					wibox.widget.textclock(
						"<span>" .. tostring("%d-%a") .. "</span>",
						100
					),
					left = 3,
					right = 2,
					widget = wibox.container.margin
				},
				bg = beautiful.midgray_1,
				fg = beautiful.fg_normal,
				widget = wibox.container.background
			},
			arrow_2L3,
			{
				{
					wibox.widget.textclock(
						"<span>" .. tostring("%H:%M") .. "</span>",
						10
					),
					left = 2,
					right = 5,
					widget = wibox.container.margin
				},
				bg = beautiful.primary,
				fg = beautiful.black,
				widget = wibox.container.background
			}
		},
	}
end)
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
	awful.key(
		{ Super },
		"h",
		function()
			awful.client.focus.global_bydirection("left")
			if client.focus then
				client.focus:raise()
			end
		end,
		{
			description = "focus by direction left",
			group = "client"
		}
	),
	awful.key(
		{ Super },
		"j",
		function()
			awful.client.focus.global_bydirection("down")
			if client.focus then
				client.focus:raise()
			end
		end,
		{
			description = "focus by direction down",
			group = "client"
		}
	),
	awful.key(
		{ Super },
		"k",
		function()
			awful.client.focus.global_bydirection("up")
			if client.focus then
				client.focus:raise()
			end
		end,
		{
			description = "focus by direction up",
			group = "client"
		}
	),
	awful.key(
		{ Super },
		"l",
		function()
			awful.client.focus.global_bydirection("right")
			if client.focus then
				client.focus:raise()
			end
		end,
		{
			description = "focus by direction right",
			group = "client"
		}
	),
	awful.key(
		{ Super, Shift },
		"h",
		function()
			awful.client.swap.global_bydirection("left")
		end,
		{
			description = "swap by direction left",
			group = "client"
		}
	),
	awful.key(
		{ Super, Shift },
		"j",
		function()
			awful.client.swap.global_bydirection("down")
		end,
		{
			description = "swap by direction down",
			group = "client"
		}
	),
	awful.key(
		{ Super, Shift },
		"k",
		function()
			awful.client.swap.global_bydirection("up")
		end,
		{
			description = "swap by direction up",
			group = "client"
		}
	),
	awful.key(
		{ Super, Shift },
		"l",
		function()
			awful.client.swap.global_bydirection("right")
		end,
		{
			description = "swap by direction right",
			group = "client"
		}
	),
	awful.key(
		{ Super },
		"w",
		function()
			awful.client.focus.byidx(1)
			if client.focus then
				client.focus:raise()
			end
		end,
		{
			description = "focus next",
			group = "client"
		}
	),
	awful.key(
		{ Super, Ctrl },
		"w",
		function()
			awful.client.cycle({ clockwise = true })
		end,
		{
			description = "focus next (cycle)",
			group = "client"
		}
	),
	awful.key(
		{ Super },
		"b",
		function()
			awful.client.focus.history.previous()
			if client.focus then
				client.focus:raise()
			end
		end,
		{
			description = "go back",
			group = "client"
		}
	),
	awful.key(
		{ Super, Ctrl },
		"a",
		function()
			local c = awful.client.restore()
			if c then
				client.focus = c
				c:raise()
			end
		end,
		{
			description = "restore minimized",
			group = "client",
			group = "client"
		}
	),
	awful.key({ Super, Ctrl }, "Left", awful.tag.viewprev, {
		description = "view previous",
		group = "tag"
	}),
	awful.key({ Super, Ctrl }, "Right", awful.tag.viewnext, {
		description = "view next",
		group = "tag"
	}),
	awful.key({ Super, Ctrl }, "Down", function()
		awful.tag.incnmaster(-1)
	end),
	awful.key({ Super, Ctrl }, "Up", function()
		awful.tag.incnmaster(1)
	end),
	awful.key({ Super }, "Right", function()
		awful.tag.incmwfact(0.01)
	end),
	awful.key({ Super }, "Left", function()
		awful.tag.incmwfact(-0.01)
	end),
	awful.key(
		{ Super },
		"s",
		function()
			awful.screen.focus_relative(1)
			if client.focus then
				client.focus:raise()
			end
		end,
		{
			description = "focus the next screen",
			group = "screen"
		}
	),
	awful.key({ Super }, "F1", hotkeys_popup.show_help, {
		description = "show help",
		group = "awesome"
	}),
	awful.key({ Super }, "F10", function()
		awful.spawn("touchpad_ctrl")
	end),
	awful.key({ Super }, "F12", function()
		awful.spawn("xscreensaver-command -lock")
	end),
	awful.key({ Super }, "c", function()
		os.execute("xsel -p -o | xsel -i -b")
	end),
	awful.key({}, "XF86AudioRaiseVolume", function()
		awful.spawn("amixer -q set Master 5%+")
	end),
	awful.key({}, "XF86AudioLowerVolume", function()
		awful.spawn("amixer -q set Master 5%-")
	end),
	awful.key({}, "XF86AudioMute", function()
		awful.spawn("amixer -q set Master playback toggle")
	end),
	awful.key({ Super, Ctrl }, "r", awesome.restart, {
		description = "reload awesome",
		group = "awesome"
	}),
	awful.key({ Super, Ctrl }, "q", awesome.quit, {
		description = "quit awesome",
		group = "awesome"
	}),
	awful.key(
		{ Super },
		"period",
		function()
			awful.tag.incncol(1)
		end,
		{ description = "increace n col" }
	),
	awful.key(
		{ Super },
		"comma",
		function()
			awful.tag.incncol(-1)
		end,
		{ description = "decreace n col" }
	),
	awful.key(
		{ Super },
		"space",
		function()
			awful.layout.inc(1)
		end,
		{
			description = "select next",
			group = "layout"
		}
	),
	awful.key(
		{ Super },
		"h",
		function()
			awful.tag.incmwfact(-0.05)
		end,
		{
			description = "decrease master width factor",
			group = "layout"
		}
	),
	awful.key(
		{ Super },
		"l",
		function()
			awful.tag.incmwfact(0.05)
		end,
		{
			description = "increase master width factor",
			group = "layout"
		}
	),
	awful.key(
		{ Super, Ctrl },
		"k",
		function()
			awful.tag.incnmaster(1, nil, true)
		end,
		{
			description = "increase the number of master clients",
			group = "layout"
		}
	),
	awful.key(
		{ Super, Ctrl },
		"j",
		function()
			awful.tag.incnmaster(-1, nil, true)
		end,
		{
			description = "decrease the number of master clients",
			group = "layout"
		}
	),
	awful.key(
		{ Super, Ctrl },
		"h",
		function()
			awful.tag.incncol(1, nil, true)
		end,
		{
			description = "increase the number of columns",
			group = "layout"
		}
	),
	awful.key(
		{ Super, Ctrl },
		"l",
		function()
			awful.tag.incncol(-1, nil, true)
		end,
		{
			description = "decrease the number of columns",
			group = "layout"
		}
	),
	awful.key(
		{ Super },
		"Return",
		function()
			-- awful.spawn("konsole -e zsh")
			awful.spawn("alacritty")
		end,
		{
			description = "open a terminal",
			group = "launcher"
		}
	),
	awful.key(
		{ Super },
		"KP_Enter",
		function()
			-- awful.spawn("alacritty")
			awful.spawn("konsole -e zsh")
		end,
		{
			description = "open a terminal",
			group = "launcher"
		}
	),
	awful.key({ Hyper }, "1", function()
		awful.spawn("chromium")
	end),
	awful.key({ Hyper, Ctrl }, "1", function()
		awful.spawn("tor-browser-en")
	end),
	awful.key({ Hyper }, "2", function()
		awful.spawn("firefox")
	end),
	awful.key({ Hyper, Ctrl }, "2", function()
		awful.spawn("chromium --kiosk")
	end),
	awful.key({ Hyper }, "3", function()
		awful.spawn("atom")
	end),
	awful.key({ Hyper, Ctrl }, "3", function()
		awful.spawn("blender")
	end),
	awful.key({ Hyper }, "4", function()
		awful.spawn("inkscape")
	end),
	awful.key({ Hyper }, "5", function()
		awful.spawn("gimp")
	end),
	awful.key({ Hyper }, "8", function()
		awful.spawn("transset-df 1")
	end),
	awful.key({ Hyper, Ctrl }, "8", function()
		awful.spawn("transset-df .8")
	end),
	awful.key({ Hyper }, "9", function()
		awful.spawn("transset-df .65")
	end),
	awful.key({ Hyper, Ctrl }, "9", function()
		awful.spawn("transset-df .4")
	end),
	awful.key(
		{ Super },
		"x",
		function()
			awful.screen.focused().mypromptbox:run()
		end,
		{
			description = "show the menubar",
			group = "launcher"
		}
	)
)

clientkeys = gears.table.join(
	awful.key({ Super, Shift }, "s", function(c) c:move_to_screen() end, { description = "move to screen", group = "client" }),
	awful.key({ Super }, "Escape", function(c) c:kill() end, { description = "close", group = "client" }),
	awful.key({ Super }, "slash", function(c) c:swap(awful.client.getmaster()) end, { description = "move to master", group = "client" }),
	awful.key( { Super }, "n", function(c) c.minimized = true end, { description = "minimize", group = "client" }),
	--  awful.key({ Super }, "y",     function (c) c.sticky = not c.sticky                                                                    end ),
	awful.key({ Super }, "g", awful.client.floating.toggle, {
		description = "toggle floating",
		group = "client"
	}),
	awful.key(
		{ Super },
		"t",
		function(c)
			c.ontop = not c.ontop
		end,
		{
			description = "toggle keep on top",
			group = "client"
		}
	),
	awful.key(
		{ Super },
		"u",
		function(c)
			c.below = not c.below
		end,
		{
			description = "toggle keep below",
			group = "client"
		}
	),

	-- awful.key({ Super }, "d",         function (c) c.size_hints_honor = not c.size_hints_honor                                                end ),
	-- awful.key({ Super }, "i",         function (c) c.above = not c.above                                                                      end ),
	awful.key({ Super }, "minus", function(c)
		c.maximized_horizontal = not c.maximized_horizontal
	end),
	awful.key({ Super }, "backslash", function(c)
		c.maximized_vertical = not c.maximized_vertical
	end),
	awful.key(
		{ Super },
		"m",
		function(c)
			c.maximized = not c.maximized
			c:raise()
		end,
		{
			description = "(un)maximize",
			group = "client"
		}
	),
	awful.key(
		{ Super },
		"backslash",
		function(c)
			c.maximized_vertical = not c.maximized_vertical
			c:raise()
		end,
		{
			description = "(un)maximize vertically",
			group = "client"
		}
	),
	awful.key(
		{ Super },
		"minus",
		function(c)
			c.maximized_horizontal = not c.maximized_horizontal
			c:raise()
		end,
		{
			description = "(un)maximize horizontally",
			group = "client"
		}
	)
)

-- Bind all key numbers to tags.
for i = 1, 9 do
	globalkeys = awful.util.table.join(
		globalkeys,
		awful.key(
			{ Super, Ctrl },
			"#" .. i + 9,
			function()
				local focused_screen = awful.screen.focused()
				local tag = focused_screen.tags[i]
				if tag then
					tag:view_only()
					awful.screen.focus(focused_screen)
				end
			end,
			{
				description = "toggle tag #" .. i,
				group = "tag"
			}
		),

		awful.key(
			{ Super },
			"#" .. i + 9,
			function()
				local focused_screen = awful.screen.focused()
				local tag = focused_screen.tags[i]
				if tag then
					tag:view_only()
				end
			end,
			{
				description = "view tag #" .. i,
				group = "tag"
			}
		),

		awful.key(
			{ Super, Shift },
			"#" .. i + 9,
			function()
				local focused_screen = awful.screen.focused()
				local tag = focused_screen.tags[i]
				if awful.client.focus and tag then
					awful.client.toggletag(tag)
				end
				awful.screen.focus(focused_screen)
			end,
			{
				description = "toggle focused client on tag #" .. i,
				group = "tag"
			}
		),

		awful.key(
			{ Super, Shift, Ctrl },
			"#" .. i + 9,
			function()
				local all_clients =
					awful.screen.focused().selected_tag:clients()
				local tag = awful.screen.focused().tags[i]
				if all_clients then
					for _, a_client in ipairs(all_clients) do
						local tagset = a_client:tags()
						local toggled = false

						for tag_index, tag_key in ipairs(tagset) do
							if tag_key == tag then
								table.remove(tagset, tag_index)
								a_client:tags(tagset)
								toggled = true
							end
						end

						if not toggled then
							table.insert(tagset, tag)
							a_client:tags(tagset)
						end
					end
				end
			end,
			{
				description = "toggle tag #" .. i .. " for all clients of current tag",
				group = "tag"
			}
		)
	)
end

clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		client.focus = c
		c:raise()
	end),
	awful.button({ Super }, 1, awful.mouse.client.move),
	awful.button({ Super }, 3, awful.mouse.client.resize)
)

root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
  {
    rule = {},
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
      titlebars_enabled = false,
      screen = awful.screen.preferred,
      placement = awful.placement.no_overlap + awful.placement.no_offscreen
    },
  },

  {
    rule_any = { class = { "Chromium" } },
    properties = {
      floating = false,
      maximized_horizontal = false,
      maximized_vertical = false,
    },
  },

  {
    rule_any = {
      instance = {
        "copyq",
        "pinentry",
      },
      class = {
        "Blender",
        "Gpick",
        "feh",
        "Kruler",
        "qt5ct",
        "Octave",
        "Sxiv",
        "MessageWin",
        "Wpa_gui",
        "pinentry",
        "veromix",
        "xtightvncviewer",
        "Popup",
      },
      name = {
        "Event Tester",
        "Page(s) Unresponsive",
        "Firefox Preferences",
        "Adblock Plus Filter Preferences",
        "Task Manager - Chromium",
      },
      role = {
        "AlarmWindow",
        "pop-up",
      }
    },
    properties = {
      floating = true,
    },
  },

  {
    rule = {
      name = "Picture in picture"
    },
    properties = {
      floating = true,
      ontop = true,
    },
  },

  {
    rule_any = { class = { "URxvt", "XTerm" } },
    properties = { size_hints_honor = false },
  },

  { rule = { class = "Blender" },         properties = { screen = 1, tag = "3" } },
  { rule = { class = "Atom" },            properties = { screen = 1, tag = "3" } },
  { rule = { class = "Inkscape" },        properties = { screen = 1, tag = "4" } },
  { rule = { class = "Gimp" },            properties = { screen = 1, tag = "5" } },
  { rule = { class = "Tor Browser" },     properties = { screen = 1, tag = "6" } },
  { rule = { class = "Arandr" },          properties = { screen = 1, tag = "8" } },
  { rule = { class = "Firefox" },         properties = { screen = 1, tag = "9" } },
  { rule = { class = "TelegramDesktop" }, properties = { screen = 1, tag = "9" } },
}

-- {{{ Signals
client.connect_signal("manage", function(c)
	if not awesome.startup then
		awful.client.setslave(c)
	end

	if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
		-- Prevent clients from being unreachable after screen count changes.
		awful.placement.no_offscreen(c)
		awful.placement.no_overlap(c)
	end
end)

client.connect_signal("focus", function(c)
	if c.maximized_horizontal == true and c.maximized_vertical == true then
		c.border_color = beautiful.border_normal
	else
		c.border_color = beautiful.border_focus
	end
end)

client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
