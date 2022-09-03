local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local S = minetest.get_translator(modname)

local chance_per_chunk = 600
local noise_multiplier = 1.4
local random_offset    = 555
local scanning_ratio   = 0.00003
local struct_threshold = chance_per_chunk

local mcl_structures_get_perlin_noise_level = mcl_structures.get_perlin_noise_level

local schematic_file = modpath .. "/schematics/mcl_structures_pillager_outpost.mts"

local outpost_schematic_lua = minetest.serialize_schematic(schematic_file, "lua", {lua_use_comments = false, lua_num_indent_spaces = 0}) .. " return schematic"
local outpost_schematic = loadstring(outpost_schematic_lua)()

local function on_placed(p1, rotation, pr, size)
	local p2 = {x = p1.x + size.x, y = p1.y + size.y, z = p1.z + size.z}
	-- Find chests.
	local chests = minetest.find_nodes_in_area(p1, p2, "mcl_chests:chest_small")

	-- Add desert temple loot into chests
	for c=1, #chests do
		local lootitems = mcl_loot.get_multi_loot({
		
		{
			stacks_min = 2,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_farming:wheat_item", weight = 7, amount_min = 3, amount_max=5 },
				{ itemstring = "mcl_farming:carrot_item", weight = 5, amount_min = 3, amount_max=5 },
				{ itemstring = "mcl_farming:potato_item", weight = 5, amount_min = 2, amount_max=5 },
			}
		},
		{
			stacks_min = 1,
			stacks_max = 2,
			items = {
				{ itemstring = "mcl_experience:bottle", weight = 6, amount_min = 0, amount_max=1 },
				{ itemstring = "mcl_bows:arrow", weight = 4, amount_min = 2, amount_max=7 },
				{ itemstring = "mcl_mobitems:string", weight = 4, amount_min = 1, amount_max=6 },
				{ itemstring = "mcl_core:iron_ingot", weight = 3, amount_min = 1, amount_max = 3 },
				{ itemstring = "mcl_books:book", weight = 1, func = function(stack, pr)
					mcl_enchanting.enchant_uniform_randomly(stack, {"soul_speed"}, pr)
				end },
			}
		},
		
		{
			stacks_min = 1,
			stacks_max = 3,
			items = {
				{ itemstring = "mcl_core:darktree", amount_min = 2, amount_max=3 },
			}
		},
		
		{
			stacks_min = 1,
			stacks_max = 1,
			items = {
				{ itemstring = "mcl_bows:crossbow" },
			}
		}
	}, pr)
		mcl_structures.init_node_construct(chests[c])
		local meta = minetest.get_meta(chests[c])
		local inv = meta:get_inventory()
		mcl_loot.fill_inventory(inv, "main", lootitems, pr)
	end
end

local function place(pos, rotation, pr)
	local pos_below  = {x = pos.x, y = pos.y -  1, z = pos.z}
	local pos_outpost = {x = pos.x, y = pos.y, z = pos.z}
	local node_below = minetest.get_node(pos_below)
	local nn = node_below.name,
mcl_structures.place_schematic({pos = pos_outpost, schematic = outpost_schematic, pr = pr, on_placed = on_placed})
	local p1 = pos
	local p2 = vector.offset(pos,14,20,14)
	local spawnon = {"mcl_core:stripped_oak"}
	local sp = minetest.find_nodes_in_area_under_air(p1,p2,spawnon)
	for _,n in pairs(minetest.find_nodes_in_area(p1,p2,{"group:wall"})) do
		local def = minetest.registered_nodes[minetest.get_node(n).name:gsub("_%d+$","")]
		if def and def.on_construct then
			def.on_construct(n)
		end
	end
	if sp and #sp > 0 then
		for i=1,5 do
			local p = sp[pr:next(1,#sp)]
			if p then
				minetest.add_entity(p,"mobs_mc:pillager")
			end
		end
		local p = sp[pr:next(1,#sp)]
		if p then
			minetest.add_entity(p,"mobs_mc:evoker")
		end
	end
end

local function get_place_rank(pos)
	local x, y, z = pos.x, pos.y - 1, pos.z
	local p1 = {x = x - 8, y = y, z = z - 8}
	local p2 = {x = x + 8, y = y, z = z + 8}
	local best_pos_list_surface = minetest.find_nodes_in_area(p1, p2, node_list, false)
	local other_pos_list_surface = minetest.find_nodes_in_area(p1, p2, "group:opaque", false)
	p1 = {x = x - 4, y = y -  7, z = z - 4}
	p2 = {x = x + 4, y = y +  7, z = z + 4}
	local best_pos_list_underground = minetest.find_nodes_in_area(p1, p2, node_list, false)
	local other_pos_list_underground = minetest.find_nodes_in_area(p1, p2, "group:opaque", false)
	return 10 * (#best_pos_list_surface) + 2 * (#other_pos_list_surface) + 5 * (#best_pos_list_underground) + #other_pos_list_underground
end

mcl_structures.register_structure({
	name = "pillager_outpost",
	decoration = {
		deco_type = "simple",
		place_on = node_list,
		flags = "all_floors",
		fill_ratio = scanning_ratio,
		y_min = 3,
		y_max = mcl_mapgen.overworld.max,
		height = 1,
		biomes = not mcl_mapgen.v6 and {
			"Desert",
			"Plains",
			"Savanna",
			"Desert_ocean",
			"Taiga",
		},
	},
	on_finished_chunk = function(minp, maxp, seed, vm_context, pos_list)
		local pr = PseudoRandom(seed + random_offset)
		local random_number = pr:next(1, chance_per_chunk)
		local noise = mcl_structures_get_perlin_noise_level(minp) * noise_multiplier
		if (random_number + noise) < struct_threshold then return end
		local pos = pos_list[1]
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
	place_function = place
})
