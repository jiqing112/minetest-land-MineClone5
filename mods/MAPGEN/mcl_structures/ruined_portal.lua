local chance_per_chunk = 400
local noise_multiplier = 2.5
local random_offset    = 9159
local scanning_ratio   = 0.001
local struct_threshold = 393.91

local mcl_structures_get_perlin_noise_level = mcl_structures.get_perlin_noise_level
local minetest_find_nodes_in_area = minetest.find_nodes_in_area
local minetest_swap_node = minetest.swap_node
local math_round = math.round
local math_abs = math.abs

local function insert_times(how_many_times, what, where)
	for i = 1, how_many_times do
		where[#where + 1] = what
	end
end

local function create_probability_picker(table_of_how_many_times_what)
	local picker = {}
	for _, v in pairs(table_of_how_many_times_what) do
		insert_times(v[1], v[2], picker)
	end
	return picker
end

local STONE_DECOR = {
	"mcl_core:stonebrickcarved",
	"mcl_blackstone:blackstone_chiseled_polished",
}
local PANE_OR_CHAIN = {
	"xpanes:bar",
	"mcl_lanterns:chain",
}
local PANE_OR_CHAIN_FLAT = {
	"xpanes:bar_flat",
	"mcl_lanterns:chain",
}
local STAIR1 = {
	"mcl_stairs:stair_stonebrickcracked",

	-- TODO: stair_blackstone_brick_polished_cracked:
	"mcl_stairs:stair_deepslate_bricks",
}
local STAIR2 = {
	"mcl_stairs:stair_stonebrickmossy",
	"mcl_stairs:stair_blackstone_brick_polished",
}
local STAIR3 = {
	"mcl_stairs:stair_stone_rough",
	"mcl_stairs:stair_blackstone_chiseled_polished",
}
local STAIR4 = {
	"mcl_stairs:stair_stonebrick",
	"mcl_stairs:stair_blackstone_brick_polished",
}
local STAIR_OUTER1 = {
	"mcl_stairs:stair_stonebrickcracked_outer",

	-- TODO: stair_blackstone_brick_polished_cracked_outer:
	"mcl_stairs:stair_deepslate_bricks_outer",
}
local STAIR_OUTER2 = {
	"mcl_stairs:stair_stonebrickmossy_outer",
	"mcl_stairs:stair_blackstone_brick_polished_outer",
}
local STAIR_OUTER3 = {
	"mcl_stairs:stair_stone_rough_outer",
	"mcl_stairs:stair_blackstone_chiseled_polished_outer",
}
local STAIR_OUTER4 = {
	"mcl_stairs:stair_stonebrick_outer",
	"mcl_stairs:stair_blackstone_brick_polished_outer",
}
local TOP_DECOR1 = {
	"mcl_core:goldblock",
	"mcl_core:goldblock",
}
local TOP_DECOR2 = {
	"mcl_core:stone_with_gold",
	"mcl_core:stone_with_gold",
}
local STONE1 = {
	"mcl_core:stonebrickcracked",

	-- TODO: polished_blackstone_brick_cracked:
	"mcl_deepslate:deepslate_bricks_cracked",
}
local STONE2 = {
	"mcl_core:stonebrickmossy",
	"mcl_blackstone:blackstone_brick_polished",
}
local STONE3 = {
	"mcl_nether:magma",
	"mcl_core:packed_ice",
}
local STONE4 = {
	"mcl_core:stonebrick",
	"mcl_blackstone:blackstone_brick_polished",
}
local STONE5 = {
	"mcl_core:stone",
	"mcl_blackstone:blackstone",
}
local STONE6 = {
	"mcl_core:cobble",
	"mcl_blackstone:basalt_polished",
}
local STONE7 = {
	"mcl_core:mossycobble",
	"mcl_blackstone:blackstone_chiseled_polished",
}
local SLAB_TOP1 = {
	"mcl_stairs:slab_stonebrickcracked_top",

	-- TODO: slab_polished_blackstone_brick_cracked_top:
	"mcl_stairs:slab_goldblock_top",
}
local SLAB_TOP2 = {
	"mcl_stairs:slab_stonebrickmossy_top",
	"mcl_stairs:slab_blackstone_brick_polished_top",
}
local SLAB_TOP3 = {
	"mcl_stairs:slab_stone_top",
	"mcl_stairs:slab_blackstone_top",
}
local SLAB_TOP4 = {
	"mcl_stairs:slab_stonebrick_top",
	"mcl_stairs:slab_blackstone_brick_polished_top",
}
local SLAB1 = {
	"mcl_stairs:slab_stone",
	"mcl_stairs:slab_blackstone",
}
local SLAB2 = {
	"mcl_stairs:slab_stonebrick",
	"mcl_stairs:slab_blackstone_brick_polished",
}
local SLAB3 = {
	"mcl_stairs:slab_stonebrickcracked",

	-- TODO: slab_polished_blackstone_brick_cracked:
	"mcl_stairs:slab_goldblock",
}
local SLAB4 = {
	"mcl_stairs:slab_stonebrickmossy",
	"mcl_stairs:slab_blackstone_brick_polished",
}
local GARBAGE1 = {
	"mcl_nether:netherrack",
	"mcl_core:stone",
}
local LAVA_SOURCE = {
	"mcl_nether:nether_lava_source",
	"mcl_core:lava_source",
}
local GARBAGE3 = {
	"mcl_nether:magma",
	"mcl_nether:magma",
}

local stair_set_for_frame = create_probability_picker({
	{ 3, STAIR1,},
	{ 1, STAIR2,},
	{ 1, STAIR3,},
	{10, STAIR4,},
})
local stone_set_for_frame = create_probability_picker({
	{ 3, STONE1,},
	{ 1, STONE2,},
	{ 1, STONE3,},
	{10, STONE4,},
})
local slab_set_for_frame = create_probability_picker({
	{ 3, SLAB_TOP1,},
	{ 1, SLAB_TOP2,},
	{ 1, SLAB_TOP3,},
	{10, SLAB_TOP4,},
})
local stair_set_for_stairs = create_probability_picker({
	{ 1, STAIR1,},
	{ 2, STAIR2,},
	{ 7, STAIR3,},
	{ 3, STAIR4,},
})
local top_decoration_list = create_probability_picker({
	{ 2, TOP_DECOR1,},
	{ 1, TOP_DECOR2,},
})
local node_garbage = create_probability_picker({
	{ 4, GARBAGE1,},
	{ 1, LAVA_SOURCE,},
	{ 1, GARBAGE3,},
})
local stair_replacement_list = {
	"air",
	"group:water",
	"group:lava",
	"group:buildable_to",
	"group:deco_block",
}
local stair_outer_names = {
	STAIR_OUTER1,
	STAIR_OUTER2,
	STAIR_OUTER3,
	STAIR_OUTER4,
}
local stair_content = create_probability_picker({
	{1, LAVA_SOURCE,},
	{5, STONE5,},
	{1, STONE4,},
	{1, STONE3,},
	{2, GARBAGE1,},
})
local stair_content_bottom = create_probability_picker({
	{2, STONE3,},
	{4, GARBAGE1,},
})
local slabs = create_probability_picker({
	{5, SLAB1,},
	{2, SLAB2,},
	{1, SLAB3,},
	{1, SLAB4,},
})
local stones = create_probability_picker({
	{3, STONE5,},
	{1, STONE6,},
	{1, STONE7,},
})

local rotation_to_orientation = {
	["0"]   = 1,
	["90"]  = 0,
	["180"] = 1,
	["270"] = 0,
}

local rotation_to_param2 = {
	["0"]   = 3,
	["90"]  = 0,
	["180"] = 1,
	["270"] = 2,
}



local function draw_frame(frame_pos, frame_width, frame_height, orientation, pr, is_chain, rotation, is_blackstone)
	local param2 = rotation_to_param2[rotation]
	local variant = is_blackstone and 2 or 1

	local function set_ruined_node(pos, node)
		if pr:next(1, 5) == 4 then return end
		minetest_swap_node(pos, node)
	end

	local function get_random_stone_material()
		local rnd = pr:next(1, #stone_set_for_frame)
		return {name = stone_set_for_frame[rnd][variant]}
	end

	local function get_random_slab()
		local rnd = pr:next(1, 15)
		return {name = slab_set_for_frame[rnd][variant]}
	end

	local function get_random_stair(param2_offset)
		local param2 = (param2 + (param2_offset or 0)) % 4
		local rnd = pr:next(1, #stair_set_for_frame)
		local stare_name = stair_set_for_frame[rnd][variant]
		return {name = stare_name, param2 = param2}
	end

	local function set_frame_stone_material(pos)
		minetest_swap_node(pos, get_random_stone_material())
	end

	local function set_ruined_frame_stone_material(pos)
		set_ruined_node(pos, get_random_stone_material())
	end

	local is_chain = is_chain
	local orientation = orientation
	local x1 = frame_pos.x
	local y1 = frame_pos.y
	local z1 = frame_pos.z
	local slide_x = (1 - orientation)
	local slide_z = orientation
	local last_x = x1 + (frame_width - 1) * slide_x
	local last_z = z1 + (frame_width - 1) * slide_z
	local last_y = y1 + frame_height - 1

	-- it's about the portal frame itself, what it will consist of
	local frame_nodes = 2 * (frame_height + frame_width) - 4
	local obsidian_nodes = pr:next(math_round(frame_nodes * 0.5), math_round(frame_nodes * 0.73))
	local crying_obsidian_nodes = pr:next(math_round(obsidian_nodes * 0.09), math_round(obsidian_nodes * 0.5))
	local air_nodes = frame_nodes - obsidian_nodes

	local function set_frame_node(pos)
		local node_choice = math_round(mcl_structures_get_perlin_noise_level(pos) * (air_nodes + obsidian_nodes))
		if node_choice > obsidian_nodes and air_nodes > 0 then
			air_nodes = air_nodes - 1
			return
		end
		obsidian_nodes = obsidian_nodes - 1
		if node_choice >= crying_obsidian_nodes then
			minetest_swap_node(pos, {name = "mcl_core:obsidian"})
			return 1
		end
		minetest_swap_node(pos, {name = "mcl_core:crying_obsidian"})
		crying_obsidian_nodes = crying_obsidian_nodes - 1
		return 1
	end

	local function set_outer_frame_node(def)
		local is_top = def.is_top
		if is_chain then
			local pos2 = def.pos_outer2
			local is_top_hole = is_top and frame_width > 5 and ((pos2.x == x1 + slide_x * 2 and pos2.z == z1 + slide_z * 2) or (pos2.x == last_x - slide_x * 2 and pos2.z == last_z - slide_z * 2))
			if is_top_hole then
				if pr:next(1, 7) > 1 then
					minetest_swap_node(pos2, {name = PANE_OR_CHAIN_FLAT[variant], param2 = orientation})
				end
			else
				set_frame_stone_material(pos2)
			end
		end
		local is_obsidian = def.is_obsidian
		if not is_obsidian and pr:next(1, 2) == 1 then return end
		local pos = def.pos_outer1
		local is_decor_here = not is_top and pos.y % 3 == 2
		if is_decor_here then
			minetest_swap_node(pos, {name = STONE_DECOR[variant]})
		elseif is_chain then
			if not is_top and not is_obsidian then
				minetest_swap_node(pos, {name = PANE_OR_CHAIN[variant]})
			else
				minetest_swap_node(pos, {name = PANE_OR_CHAIN_FLAT[variant], param2 = orientation})
			end
		else
			if pr:next(1, 5) == 3 then
				minetest_swap_node(pos, {name = STONE1[variant]})
			else
				minetest_swap_node(pos, {name = STONE4[variant]})
			end
		end
	end

	local function draw_roof(pos, length)
		local x = pos.x
		local y = pos.y
		local z = pos.z
		local number_of_roof_nodes = length
		if number_of_roof_nodes > 1 then
			set_ruined_node({x = x, y = y, z = z}, get_random_stair((param2 == 1 or param2 == 2) and -1 or 1))
			set_ruined_node({x = x + (length - 1) * slide_x, y = y, z = z + (length - 1) * slide_z}, get_random_stair((param2 == 1 or param2 == 2) and 1 or -1))
			number_of_roof_nodes = number_of_roof_nodes - 2
			x = x + slide_x
			z = z + slide_z
		end
		while number_of_roof_nodes > 0 do
			set_ruined_node({x = x, y = y, z = z}, get_random_stair((param2 == 1 or param2 == 2) and 2 or 0))
			x = x + slide_x
			z = z + slide_z
			number_of_roof_nodes = number_of_roof_nodes - 1
		end
	end

	-- bottom corners
	set_frame_node({x = x1, y = y1, z = z1})
	set_frame_node({x = last_x, y = y1, z = last_z})

	-- top corners
	local is_obsidian_top_left = set_frame_node({x = x1, y = last_y, z = z1})
	local is_obsidian_top_right = set_frame_node({x = last_x, y = last_y, z = last_z})

	if is_chain then
		if is_obsidian_top_left and pr:next(1, 4) ~= 2 then
			set_frame_stone_material({x = x1 - slide_x * 2, y = last_y + 2, z = z1 - slide_z * 2})
		end
		if is_obsidian_top_left and pr:next(1, 4) ~= 2 then
			set_frame_stone_material({x = x1 - slide_x * 2, y = last_y + 1, z = z1 - slide_z * 2})
		end
		if is_obsidian_top_left and pr:next(1, 4) ~= 2 then
			set_frame_stone_material({x = last_x + slide_x * 2, y = last_y + 2, z = last_z + slide_z * 2})
		end
		if is_obsidian_top_left and pr:next(1, 4) ~= 2 then
			set_frame_stone_material({x = last_x + slide_x * 2, y = last_y + 1, z = last_z + slide_z * 2})
		end
	end

	for y = y1, last_y do
		local begin_or_end = y == y1 or y == last_y
		local is_obsidian_left  = begin_or_end and is_obsidian_top_left  or set_frame_node({x = x1    , y = y, z = z1    })
		local is_obsidian_right = begin_or_end and is_obsidian_top_right or set_frame_node({x = last_x, y = y, z = last_z})
		set_outer_frame_node({
			pos_outer1 = {x = x1 - slide_x    , y = y, z = z1 - slide_z    },
			pos_outer2 = {x = x1 - slide_x * 2, y = y, z = z1 - slide_z * 2},
			is_obsidian = is_obsidian_left,
		})
		set_outer_frame_node({
			pos_outer1 = {x = last_x + slide_x    , y = y, z = last_z + slide_z    },
			pos_outer2 = {x = last_x + slide_x * 2, y = y, z = last_z + slide_z * 2},
			is_obsidian = is_obsidian_right,
		})
	end

	for i = 0, 1 do
		set_outer_frame_node({
			pos_outer1  = {x = x1 - slide_x * i, y = last_y + 1, z = z1 - slide_z * i},
			pos_outer2  = {x = x1 - slide_x * i, y = last_y + 2, z = z1 - slide_z * i},
			is_obsidian = is_obsidian_top_left,
			is_top      = true,
		})
		set_outer_frame_node({
			pos_outer1  = {x = last_x + slide_x * i, y = last_y + 1, z = last_z + slide_z * i},
			pos_outer2  = {x = last_x + slide_x * i, y = last_y + 2, z = last_z + slide_z * i},
			is_obsidian = is_obsidian_top_right,
			is_top      = true,
		})
	end

	for x = x1 + slide_x, last_x - slide_x do for z = z1 + slide_z, last_z - slide_z do
		set_frame_node({x = x, y = y1, z = z})
		local is_obsidian_top = set_frame_node({x = x, y = last_y, z = z})
		set_outer_frame_node({
			pos_outer1  = {x = x, y = last_y + 1, z = z},
			pos_outer2  = {x = x, y = last_y + 2, z = z},
			is_obsidian = is_obsidian_top,
			is_top      = true
		})
	end end

	local node_top = {name = top_decoration_list[pr:next(1, #top_decoration_list)][variant]}
	if is_chain then
		set_ruined_frame_stone_material({x = x1     + slide_x * 2, y = last_y + 3, z = z1     + slide_z * 2})
		set_ruined_frame_stone_material({x = x1     + slide_x    , y = last_y + 3, z = z1     + slide_z    })
		set_ruined_frame_stone_material({x = last_x - slide_x    , y = last_y + 3, z = last_z - slide_z    })
		set_ruined_frame_stone_material({x = last_x - slide_x * 2, y = last_y + 3, z = last_z - slide_z * 2})
		for x = x1 + slide_x * 3, last_x - slide_x * 3 do for z = z1 + slide_z * 3, last_z - slide_z * 3 do
			set_ruined_node({x = x, y = last_y + 3, z = z}, node_top)
			set_ruined_node({x = x - slide_z, y = last_y + 3, z = z - slide_x}, get_random_slab())
			set_ruined_node({x = x + slide_z, y = last_y + 3, z = z + slide_x}, get_random_slab())
		end end
		draw_roof({x = x1 + slide_x * 3, y = last_y + 4, z = z1 + slide_z * 3}, frame_width - 6)
	else
		set_ruined_frame_stone_material({x = x1     + slide_x * 3, y = last_y + 2, z = z1     + slide_z * 3})
		set_ruined_frame_stone_material({x = x1     + slide_x * 2, y = last_y + 2, z = z1     + slide_z * 2})
		set_ruined_frame_stone_material({x = last_x - slide_x * 2, y = last_y + 2, z = last_z - slide_z * 2})
		set_ruined_frame_stone_material({x = last_x - slide_x * 3, y = last_y + 2, z = last_z - slide_z * 3})
		for x = x1 + slide_x * 4, last_x - slide_x * 4 do for z = z1 + slide_z * 4, last_z - slide_z * 4 do
			set_ruined_node({x = x, y = last_y + 2, z = z}, node_top)
			set_ruined_node({x = x - slide_z, y = last_y + 2, z = z - slide_x}, get_random_slab())
			set_ruined_node({x = x + slide_z, y = last_y + 2, z = z + slide_x}, get_random_slab())
		end end
		draw_roof({x = x1 + slide_x * 3, y = last_y + 3, z = z1 + slide_z * 3}, frame_width - 6)
	end
end

local possible_rotations = {"0", "90", "180", "270"}

local function draw_trash(pos, width, height, lift, orientation, pr, is_blackstone)
	local variant = is_blackstone and 2 or 1
	local pos = pos
	local slide_x = (1 - orientation)
	local slide_z = orientation
	local x1 = pos.x - lift - 1
	local x2 = pos.x + (width - 1) * slide_x + lift + 1
	local z1 = pos.z - lift - 1
	local z2 = pos.z + (width - 1) * slide_z + lift + 1
	local y1 = pos.y - pr:next(1, height) - 1
	local y2 = pos.y
	local opacity_layers = math.floor((y2 - y1) / 2)
	local opacity_layer = -opacity_layers
	for y = y1, y2 do
		local inverted_opacity_0_5 = math_round(math_abs(opacity_layer) / opacity_layers * 5)
		for x = x1 + pr:next(0, 2), x2 - pr:next(0, 2) do
			for z = z1 + pr:next(0, 2), z2 - pr:next(0, 2) do
				if inverted_opacity_0_5 == 0 or (x % inverted_opacity_0_5 ~= pr:next(0, 1) and z % inverted_opacity_0_5 ~= pr:next(0, 1)) then
					minetest_swap_node({x = x, y = y, z = z}, {name = node_garbage[pr:next(1, #node_garbage)][variant]})
				end
			end
		end
		opacity_layer = opacity_layer + 1
	end
end

local stair_selector = {
	[-1] = {
		[-1] = {
			names = stair_outer_names,
			param2 = 1,
		},
		[0] = {
			names = stair_set_for_stairs,
			param2 = 1,
		},
		[1] = {
			names = stair_outer_names,
			param2 = 2,
		},
	},
	[0] = {
		[-1] = {
			names = stair_set_for_stairs,
			param2 = 0,
		},
		[0] = {
			names = stair_content,
		},
		[1] = {
			names = stair_set_for_stairs,
			param2 = 2,
		},
	},
	[1] = {
		[-1] = {
			names = stair_outer_names,
			param2 = 0,
		},
		[0] = {
			names = stair_set_for_stairs,
			param2 = 3,
		},
		[1] = {
			names = stair_outer_names,
			param2 = 3,
		},
	},
}

local stair_offset_from_bottom = 2

local function draw_stairs(pos, width, height, lift, orientation, pr, is_chain, param2, is_blackstone)
	local variant = is_blackstone and 2 or 1
	local current_stair_content = stair_content
	local current_stones = stones
	local param2 = param2
	local mirror = param2 == 1 or param2 == 2
	if mirror then param2 = (param2 + 2) % 4 end
	local chain_offset = is_chain and 1 or 0
	local lift = lift + stair_offset_from_bottom
	local slide_x = (1 - orientation)
	local slide_z = orientation
	local width = width + 2
	local x1 = pos.x - (chain_offset + 1    ) * slide_x - 1
	local x2 = pos.x + (chain_offset + width) * slide_x + 1
	local z1 = pos.z - (chain_offset + 1    ) * slide_z - 1
	local z2 = pos.z + (chain_offset + width) * slide_z + 1
	local y1 = pos.y - stair_offset_from_bottom
	local y2 = pos.y + lift - stair_offset_from_bottom
	local stair_layer = true
	local y = y2
	local place_slabs = true
	local x_key, z_key
	local chest_pos
	local ruinity = height + lift
	local y_layer_to_start_squeezing = y1 - 2 * lift
	while (true) do
		local x11 = math_round(x1)
		local x22 = math_round(x2)
		local z11 = math_round(z1)
		local z22 = math_round(z2)
		local good_nodes = minetest_find_nodes_in_area({x = x11, y = y, z = z11}, {x = x22, y = y, z = z22}, stair_replacement_list, false)
		local good_nodes_ratio =  #good_nodes / (x22 - x11 + 1) / (z22 - z11 + 1)
		if y < y1 and good_nodes_ratio <= 0.07 then return chest_pos end
		for _, pos in pairs(good_nodes) do
			if pr:next(1, ruinity) > 1 then
				local x, z = pos.x, pos.z
				x_key = (x == x11) and -1 or (x == x22) and 1 or 0
				z_key = (z == z11) and -1 or (z == z22) and 1 or 0
				local should_be_a_stair_here = (x_key ~= 0) or (z_key ~= 0)
				if should_be_a_stair_here then
					if stair_layer then
						local stair = stair_selector[x_key][z_key]
						local names = stair.names
						minetest_swap_node(pos, {name = names[pr:next(1, #names)][variant], param2 = stair.param2})
					elseif place_slabs then
						minetest_swap_node(pos, {name = slabs[pr:next(1, #slabs)][variant]})
					else
						minetest_swap_node(pos, {name = current_stones[pr:next(1, #current_stones)][variant]})
						if not chest_pos then
							chest_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
							minetest_swap_node(chest_pos, {name = "mcl_chests:chest_small"})
						end
					end
				elseif not stair_layer then
					minetest_swap_node(pos, {name = current_stair_content[pr:next(1, #current_stair_content)][variant]})
				end
			end
		end
		if y >= y1 - lift then
			x1 = x1 - 1
			x2 = x2 + 1
			z1 = z1 - 1
			z2 = z2 + 1
		elseif y < y_layer_to_start_squeezing then
			local noise = mcl_structures_get_perlin_noise_level(pos) + 0.5
			x1 = x1 + noise * pr:next(0,2)
			x2 = x2 - noise * pr:next(0,2)
			z1 = z1 + noise * pr:next(0,2)
			z2 = z2 - noise * pr:next(0,2)
			if x1 >= x2 then return chest_pos end
			if z1 >= z2 then return chest_pos end
		elseif y == y_layer_to_start_squeezing then
			current_stones = stair_content_bottom
		end
		if y >= y1 then
			if (stair_layer or place_slabs) then
				y = y - 1
				if y <= y1 then
					current_stair_content = stair_content_bottom
				end
			end
			place_slabs = not place_slabs
			stair_layer = false
		else
			place_slabs = false
			y = y - 1
		end
		if ruinity > 2 then ruinity = math.max(ruinity - pr:next(0,2), 2) end
	end
end

local function enchant(stack, pr)
	-- 75%-100% damage
	mcl_enchanting.enchant_randomly(stack, 30, true, false, false, pr)
end

local function enchant_armor(stack, pr)
	-- itemstack, enchantment_level, treasure, no_reduced_bonus_chance, ignore_already_enchanted, pr)
	mcl_enchanting.enchant_randomly(stack, 30, false, false, false, pr)
end

local function common_place(pos, rotation, pr, width, height, lift, is_blackstone)
	local pos = pos
	local width = width
	local height = height
	local lift = lift
	local rotation = rotation
	local orientation = rotation_to_orientation[rotation]
	local param2 = rotation_to_param2[rotation]
	local is_chain = pr:next(1, 3) > 1
	draw_trash(pos, width, height, lift, orientation, pr, is_blackstone)
	local chest_pos = draw_stairs(pos, width, height, lift, orientation, pr, is_chain, param2, is_blackstone)
	draw_frame({x = pos.x, y = pos.y + lift, z = pos.z}, width + 2, height + 2, orientation, pr, is_chain, rotation, is_blackstone)
	if not chest_pos then return end

	local lootitems = mcl_loot.get_loot(
		{
			stacks_min = 4,
			stacks_max = 8,
			items = {
				{itemstring = "mcl_core:iron_nugget",                            weight = 40, amount_min = 9, amount_max = 18},
				{itemstring = "mcl_core:flint",                                  weight = 40, amount_min = 9, amount_max = 18},
				{itemstring = "mcl_core:obsidian",                               weight = 40, amount_min = 1, amount_max =  2},
				{itemstring = "mcl_fire:fire_charge",                            weight = 40, amount_min = 1, amount_max =  1},
				{itemstring = "mcl_fire:flint_and_steel",                        weight = 40, amount_min = 1, amount_max =  1},
				{itemstring = "mcl_core:gold_nugget",                            weight = 15, amount_min = 4, amount_max = 24},
				{itemstring = "mcl_core:apple_gold",                             weight = 15},
				{itemstring = "mcl_tools:axe_gold",                              weight = 15, func = enchant},
				{itemstring = "mcl_farming:hoe_gold",                            weight = 15, func = enchant},
				{itemstring = "mcl_tools:pick_gold",                             weight = 15, func = enchant},
				{itemstring = "mcl_tools:shovel_gold",                           weight = 15, func = enchant},
				{itemstring = "mcl_tools:sword_gold",                            weight = 15, func = enchant},
				{itemstring = "mcl_armor:helmet_gold",                           weight = 15, func = enchant_armor},
				{itemstring = "mcl_armor:chestplate_gold",                       weight = 15, func = enchant_armor},
				{itemstring = "mcl_armor:leggings_gold",                         weight = 15, func = enchant_armor},
				{itemstring = "mcl_armor:boots_gold",                            weight = 15, func = enchant_armor},
				{itemstring = "mcl_potions:speckled_melon",                      weight =  5, amount_min = 4, amount_max = 12},
				{itemstring = "mcl_farming:carrot_item_gold",                    weight =  5, amount_min = 4, amount_max = 12},
				{itemstring = "mcl_core:gold_ingot",                             weight =  5, amount_min = 2, amount_max =  8},
				{itemstring = "mcl_clock:clock",                                 weight =  5},
				{itemstring = "mesecons_pressureplates:pressure_plate_gold_off", weight =  5},
				{itemstring = "mobs_mc:gold_horse_armor",                        weight =  5},
				{itemstring = TOP_DECOR1,                                        weight =  1, amount_min = 1, amount_max =  2},
				{itemstring = "mcl_bells:bell",                                  weight =  1},
				{itemstring = "mcl_core:apple_gold_enchanted",                   weight =  1},
			}
		},
		pr
	)
	mcl_structures.init_node_construct(chest_pos)
	local meta = minetest.get_meta(chest_pos)
	local inv = meta:get_inventory()
	mcl_loot.fill_inventory(inv, "main", lootitems, pr)
end

local function place(pos, rotation, pr)
	local width = pr:next(2, 10)
	local height = pr:next(((width < 3) and 3 or 2), math.floor((10 + width/2)))
	local lift = pr:next(0, 2)
	local rotation = rotation or possible_rotations[pr:next(1, #possible_rotations)]
	common_place(pos, rotation, pr, width, height, lift, false)
	minetest.log("action","Ruined portal generated at " .. minetest.pos_to_string(pos))
end

local function place_blackstone(pos, rotation, pr)
	local width = pr:next(2, 5)
	local height = pr:next(((width < 3) and 3 or 2), math.floor((5 + width/2)))
	local lift = pr:next(0, 1)
	local rotation = rotation or possible_rotations[pr:next(1, #possible_rotations)]
	common_place(pos, rotation, pr, width, height, lift, true)
	minetest.log("action","Ruined portal v2 generated at " .. minetest.pos_to_string(pos))
end

local function get_place_rank(pos)
	local x, y, z = pos.x, pos.y, pos.z
	local p1 = {x = x    , y = y, z = z    }
	local p2 = {x = x + 7, y = y, z = z + 7}
	local air_pos_list_surface = #minetest_find_nodes_in_area(p1, p2, "air", false)
	p1.y = p1.y - 1
	p2.y = p2.y - 1
	local opaque_pos_list_surface = #minetest_find_nodes_in_area(p1, p2, "group:opaque", false)
	return air_pos_list_surface + 3 * opaque_pos_list_surface
end

mcl_structures.register_structure({
	name = "ruined_portal",
	decoration = {
		deco_type = "simple",
		flags = "all_floors",
		fill_ratio = scanning_ratio,
		height = 1,
		place_on = {"mcl_core:sand", "mcl_core:dirt_with_grass", "mcl_core:water_source", "mcl_core:dirt_with_grass_snow"},
	},
	on_finished_chunk = function(minp, maxp, seed, vm_context, pos_list)
		if maxp.y < mcl_mapgen.overworld.min then return end
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
	place_function = place,
})

mcl_structures.register_structure({
	name = "ruined_portal_black",
	decoration = {
		deco_type = "simple",
		flags = "all_floors",
		fill_ratio = scanning_ratio,
		height = 1,
		place_on = {"mcl_nether:netherrack", "mcl_nether:soul_sand", "mcl_nether:nether_lava_source", "mcl_core:lava_source"},
	},
	on_finished_chunk = function(minp, maxp, seed, vm_context, pos_list)
		if minp.y > mcl_mapgen.nether.max then return end
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
		place_blackstone(pos, nil, pr)
	end,
	place_function = place_blackstone,
})
