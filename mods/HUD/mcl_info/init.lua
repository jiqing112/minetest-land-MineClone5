local refresh_interval      = .63
local huds                  = {}
local default_debug         = 5
local after                 = minetest.after
local get_connected_players = minetest.get_connected_players
local get_biome_name        = minetest.get_biome_name
local get_biome_data        = minetest.get_biome_data
local get_node              = minetest.get_node
local format                = string.format
local table_concat          = table.concat
local floor                 = math.floor
local minetest_get_gametime = minetest.get_gametime
local get_voxel_manip       = minetest.get_voxel_manip

local min1, min2, min3 = mcl_mapgen.overworld.min, mcl_mapgen.end_.min, mcl_mapgen.nether.min
local max1, max2, max3 = mcl_mapgen.overworld.max, mcl_mapgen.end_.max, mcl_mapgen.nether.max + 128
local CS = mcl_mapgen.CS_NODES

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)
local storage = minetest.get_mod_storage()
local player_dbg = minetest.deserialize(storage:get_string("player_dbg") or "return {}") or {}

local function get_text(pos, bits)
	local pos = pos
	local bits = bits
	if bits == 0 then return "" end
	local y = pos.y
	if y >= min1 then
		y = y - min1
	elseif y >= min3 and y <= max3 then
		y = y - min3
	elseif y >= min2 and y <= max2 then
		y = y - min2
	end

	local will_show_mapgen_status = bits % 8 > 3
	local will_show_coordinates   = bits % 4 > 1
	local will_show_biome_name    = bits % 2 > 0
	local will_be_shown = {}

	if will_show_biome_name then
		local biome_data = get_biome_data(pos)
		local biome_name = biome_data and get_biome_name(biome_data.biome) or "No biome"
		will_be_shown[#will_be_shown + 1] = biome_name
	end
	if will_show_coordinates then
		local coordinates = format("x:%.1f y:%.1f z:%.1f", pos.x, y, pos.z)
		will_be_shown[#will_be_shown + 1] = coordinates
	end
	if will_show_mapgen_status then
		local pos_x = floor(pos.x)
		local pos_y = floor(pos.y)
		local pos_z = floor(pos.z)
		local c = 0
		for x = pos_x - CS, pos_x + CS, CS do
			for y = pos_y - CS, pos_y + CS, CS do
				for z = pos_z - CS, pos_z + CS, CS do
					local pos = {x = x, y = y, z = z}
					get_voxel_manip():read_from_map(pos, pos)
					local node = get_node(pos)
					if node.name ~= "ignore" then c = c + 1 end
				end
			end
		end
		local p = floor(c / 27 * 100 + 0.5)
		local status = format("Generated %u%% (%u/27 chunks)", p, c)
		will_be_shown[#will_be_shown + 1] = status
	end

	local text = table_concat(will_be_shown, ' ')
	return text
end

local function info()
	for _, player in pairs(get_connected_players()) do
		local name = player:get_player_name()
		local pos = player:get_pos()
		local text = get_text(pos, player_dbg[name] or default_debug)
		local hud = huds[name]
		if not hud then
			local def = {
				hud_elem_type = "text",
				alignment     = {x = 1, y = -1},
				scale         = {x = 100, y = 100},
				position      = {x = 0.0073, y = 0.989},
				text          = text,
				style         = 5,
				["number"]    = 0xcccac0,
				z_index       = 0,
			}
			local def_bg = table.copy(def)
			def_bg.offset = {x = 2, y = 1}
			def_bg["number"] = 0
			def_bg.z_index = -1
			huds[name] = {
				player:hud_add(def),
				player:hud_add(def_bg),
				text,
			}
		elseif text ~= hud[3] then
			hud[3] = text
			player:hud_change(huds[name][1], "text", text)
			player:hud_change(huds[name][2], "text", text)
		end
	end
	after(refresh_interval, info)
end

minetest.register_on_authplayer(function(name, ip, is_success)
	if is_success then
		huds[name] = nil
	end
end)

minetest.register_chatcommand("debug",{
	description = S("Set debug bit mask: 0 = disable, 1 = biome name, 2 = coordinates, 4 = mapgen status, 7 = all"),
	func = function(name, params)
		local dbg = math.floor(tonumber(params) or default_debug)
		if dbg < 0 or dbg > 7 then
			minetest.chat_send_player(name, S("Error! Possible values are integer numbers from @1 to @2", 0, 7))
			return
		end
		if dbg == default_debug then
			player_dbg[name] = nil
		else
			player_dbg[name] = dbg
		end
		minetest.chat_send_player(name, S("Debug bit mask set to @1", dbg))
	end
})

minetest.register_on_shutdown(function()
	storage:set_string("player_dbg", minetest.serialize(player_dbg))
end)

info()
