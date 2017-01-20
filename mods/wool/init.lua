-- minetest/wool/init.lua

-- Backwards compatibility with jordach's 16-color wool mod
minetest.register_alias("wool:dark_blue", "wool:blue")
minetest.register_alias("wool:gold", "wool:yellow")

local wool = {}
-- This uses a trick: you can first define the recipes using all of the base
-- colors, and then some recipes using more specific colors for a few non-base
-- colors available. When crafting, the last recipes will be checked first.
wool.dyes = {
	{"white",      "white",		"White",      nil},
	{"grey",       "dark_grey",	"Grey",       "unicolor_darkgrey"},
	{"silver",     "grey",		"Light Gray", "basecolor_grey"},
	{"black",      "black",		"Black",      "basecolor_black"},
	{"red",        "red",		"Red",        "basecolor_red"},
	{"yellow",     "yellow",	"Yellow",     "basecolor_yellow"},
	{"green",      "green",		"Green",      "unicolor_dark_green"},
	{"cyan",       "cyan",		"Cyan",       "basecolor_cyan"},
	{"blue",       "blue",		"Blue",       "basecolor_blue"},
	{"magenta",    "magenta",	"Magenta",    "basecolor_magenta"},
	{"orange",     "orange",	"Orange",     "excolor_orange"},
	{"purple",     "violet",	"Purple",     "excolor_violet"},
	{"brown",      "brown",		"Brown",      "unicolor_dark_orange"},
	{"pink",       "pink",		"Pink",       "unicolor_light_red"},
	{"lime",       "lime",		"Lime",       "basecolor_green"},
	{"light_blue", "light_blue",	"Light Blue", "unicolor_light_blue"},
}

for _, row in ipairs(wool.dyes) do
	local name = row[1]
	local texture = row[2]
	local desc = row[3]
	local craft_color_group = row[4]
	-- Node Definition
		minetest.register_node("wool:"..name, {
			description = desc.." Wool",
			stack_max = 64,
			is_ground_content = false,
			tiles = {"wool_"..texture..".png"},
			groups = {snappy=2,choppy=2,oddly_breakable_by_hand=3,flammable=1,wool=1,building_block=1},
			sounds = default.node_sound_defaults(),
		})
		minetest.register_node("wool:"..name.."_carpet", {
			description = desc.." Carpet",
			walkable = false,
			is_ground_content = false,
			tiles = {"wool_"..texture..".png"},
			wield_image = "wool_"..name..".png",
			groups = {snappy=2,choppy=2,oddly_breakable_by_hand=3,flammable=1,carpet=1,deco_block=1},
			sounds = default.node_sound_defaults(),
			paramtype = "light",
			stack_max = 64,
			drawtype = "nodebox",
			node_box = {
				type = "fixed",
				fixed = {
					{-8/16, -8/16, -8/16, 8/16, -7/16, 8/16},
				},
			},
		})
	if craft_color_group then
	-- Crafting from dye and white wool
		minetest.register_craft({
			type = "shapeless",
			output = 'wool:'..name,
			recipe = {'group:dye,'..craft_color_group, 'group:wool'},
		})
		minetest.register_craft({
			output = 'wool:'..name..'_carpet 3',
			recipe = {{'wool:'..name, 'wool:'..name}},
		})
	end
end

minetest.register_craft({
	type = "fuel",
	recipe = "group:wool",
	burntime = 5,
})
minetest.register_craft({
	type = "fuel",
	recipe = "group:carpet",
	-- Original value: 3.35
	burntime = 3,
})
