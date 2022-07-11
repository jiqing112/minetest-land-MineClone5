local modname = minetest.get_current_modname()
<<<<<<< HEAD
local modpath = minetest.get_modpath(modname)

local chance_per_chunk = 17
local noise_multiplier = -0.9
local random_offset    = 8
local scanning_ratio   = 0.01
local struct_threshold = chance_per_chunk

local mcl_structures_get_perlin_noise_level = mcl_structures.get_perlin_noise_level

local schematic_file = modpath .. "/schematics/mcl_structures_witch_hut.mts"

local witch_hut_schematic_lua = minetest.serialize_schematic(schematic_file, "lua", {lua_use_comments = false, lua_num_indent_spaces = 0}) .. " return schematic"
local witch_hut_schematic = loadstring(witch_hut_schematic_lua)()

local node_list = {"mcl_core:dirt_with_grass", "mcl_core:dirt"}

local WITCH_HUT_HEIGHT = 2 -- Exact Y level to spawn witch huts at. This height refers to the height of the floor

local witch_hut_offsets = {
	["0"] = {
		{x=1, y=0, z=1}, {x=1, y=0, z=5}, {x=6, y=0, z=1}, {x=6, y=0, z=5},
	},
	["180"] = {
		{x=2, y=0, z=1}, {x=2, y=0, z=5}, {x=7, y=0, z=1}, {x=7, y=0, z=5},
	},
	["270"] = {
		{x=1, y=0, z=1}, {x=5, y=0, z=1}, {x=1, y=0, z=6}, {x=5, y=0, z=6},
	},
	["90"] = {
		{x=1, y=0, z=2}, {x=5, y=0, z=2}, {x=1, y=0, z=7}, {x=5, y=0, z=7},
	},
}

local function on_placed(place, rotation, pr, size)
	local offsets = witch_hut_offsets[rotation]
	if not offsets then return end
	for _, offset in pairs(offsets) do
		local tpos = vector.add(place, offset)
		for y = place.y - 1, mcl_mapgen.get_chunk_beginning(place.y - 1), -1 do
			tpos.y = y
			local nn = minetest.get_node(tpos).name
	 		if not nn then break end
       			local node = minetest.registered_nodes[nn]
			local groups = node.groups
			if nn == "mcl_flowers:waterlily" or nn == "mcl_core:water_source" or nn == "mcl_core:water_flowing" or nn == "air" or groups.deco_block then
				minetest.swap_node(tpos, {name="mcl_core:tree"})
			else
 				break
			end
		end
	end
end


local function place(pos, rotation, pr)
	mcl_structures.place_schematic({pos = pos, rotaton = rotation, schematic = witch_hut_schematic, pr = pr, on_placed = on_placed})
end

local function get_place_rank(pos)
	local x, y, z = pos.x, pos.y, pos.z
	local p1 = {x = x + 1, y = y + 1, z = z + 1}
	local p2 = {x = x + 4, y = y + 4, z = z + 4}
	local counter = #minetest.find_nodes_in_area(p1, p2, {"air", "group:buildable_to", "group:deco_block"}, false)
	return counter
end

local function tune_pos(pos)
	local pos = table.copy(pos)
	local y = pos.y - 1
	if y >= WITCH_HUT_HEIGHT - 5 and y <= WITCH_HUT_HEIGHT + 5 then
		pos.y = WITCH_HUT_HEIGHT
		return pos
	end
	local x = pos.x
	local z = pos.z
	local p1 = {x = x - 3, y = y    , z = z - 3}
	local p2 = {x = x + 3, y = y + 2, z = z + 3}
	local water_list = minetest.find_nodes_in_area(p1, p2, {"group:water"}, false)
	if not water_list or #water_list < 1 then
		pos.y = y
		return pos
	end
	local top = -1
	for _, pos in pairs(water_list) do
		if pos.y > top then
			top = pos.y
		end
	end
	pos.y = top
	return pos
end

mcl_structures.register_structure({
	name = "witch_hut",
	decoration = {
		deco_type = "simple",
		place_on = node_list,
		spawn_by = {"mcl_core:water_source", "group:frosted_ice"},
		num_spawn_by = 1,
		-- flags = "all_floors",
		fill_ratio = scanning_ratio,
		y_min = mcl_mapgen.overworld.min,
		y_max = mcl_mapgen.overworld.max,
		height = 1,
		biomes = mcl_mapgen.v6 and {
			"Normal",
		} or {
			"Swampland",
			"Swampland_shore",
			"Swampland_ocean",
			"Swampland_deep_ocean",
		},
	},
	on_finished_chunk = function(minp, maxp, seed, vm_context, pos_list)
		local pr = PseudoRandom(seed + random_offset)
		local random_number = pr:next(1, chance_per_chunk)
		local noise = mcl_structures_get_perlin_noise_level(minp) * noise_multiplier
		if (random_number + noise) < struct_threshold then return end
		local pos = tune_pos(pos_list[1])
		if #pos_list > 1 then
			local count = get_place_rank(pos)
			for i = 2, #pos_list do
				local pos_i = pos_list[i]
				local count_i = get_place_rank(pos_i)
				if count_i > count then
					count = count_i
					pos = pos_i
				end
			end
		end
		place(pos, nil, pr)
	end,
	place_function = place,
=======
local S = minetest.get_translator(modname)
local modpath = minetest.get_modpath(modname)

local function spawn_witch(p1,p2)
	local c = minetest.find_node_near(p1,15,{"mcl_cauldrons:cauldron"})
	if c then
		local nn = minetest.find_nodes_in_area_under_air(vector.new(p1.x,c.y-1,p1.z),vector.new(p2.x,c.y-1,p2.z),{"mcl_core:sprucewood"})
		local witch = minetest.add_entity(vector.offset(nn[math.random(#nn)],0,1,0),"mobs_mc:witch"):get_luaentity()
		local cat = minetest.add_entity(vector.offset(nn[math.random(#nn)],0,1,0),"mobs_mc:cat"):get_luaentity()
		witch._home = c
		witch.can_despawn = false
		cat.object:set_properties({textures = {"mobs_mc_cat_black.png"}})
		cat.owner = "!witch!" --so it's not claimable by player
		cat._home = c
		cat.can_despawn = false
		return
	end
end

local function hut_placement_callback(pos,def,pr)
	local hl = def.sidelen / 2
	local p1 = vector.offset(pos,-hl,-hl,-hl)
	local p2 = vector.offset(pos,hl,hl,hl)
	local legs = minetest.find_nodes_in_area(vector.offset(pos,-hl,0,-hl),vector.offset(pos,hl,0,hl), "mcl_core:tree")
	local tree = {}
	for _,leg in pairs(legs) do
		while minetest.get_item_group(mcl_vars.get_node(vector.offset(leg,0,-1,0), true, 333333).name, "water") ~= 0 do
			leg = vector.offset(leg,0,-1,0)
			table.insert(tree,leg)
		end
	end
	minetest.bulk_set_node(tree, {name = "mcl_core:tree", param2 = 2})
	spawn_witch(p1,p2)
end

mcl_structures.register_structure("witch_hut",{
	place_on = {"group:sand","group:grass_block","mcl_core:water_source","group:dirt"},
	fill_ratio = 0.01,
	flags = "place_center_x, place_center_z, liquid_surface, force_placement",
	sidelen = 8,
	chunk_probability = 300,
	y_max = mcl_vars.mg_overworld_max,
	y_min = -4,
	y_offset = 0,
	biomes = { "Swampland", "Swampland_ocean", "Swampland_shore" },
	filenames = { modpath.."/schematics/mcl_structures_witch_hut.mts" },
	after_place = hut_placement_callback,
>>>>>>> mcl2/master
})
