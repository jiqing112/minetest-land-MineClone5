local S = minetest.get_translator(minetest.get_current_modname())

local math_abs = math.abs
local mcl_util_move_item_container = mcl_util.move_item_container
local minetest_facedir_to_dir = minetest.facedir_to_dir
local minetest_get_inventory = minetest.get_inventory
local minetest_get_item_group = minetest.get_item_group
local minetest_get_meta = minetest.get_meta
local minetest_get_node = minetest.get_node
local minetest_get_objects_inside_radius = minetest.get_objects_inside_radius
local minetest_registered_nodes = minetest.registered_nodes

local HOPPER = "mcl_hoppers:hopper"
local HOPPER_SIDE = "mcl_hoppers:hopper_side"
local GROUPS_TO_PUT_INTO_COMMON_SLOT = {
	[2] = true,
	[3] = true,
	[5] = true,
	[6] = true,
}
local GROUPS_TO_PUT_INTO_FUEL_SLOT = {
	[4] = true,
}
local mcl_hoppers_formspec =
	"size[9,7]"..
	"label[2,0;"..minetest.formspec_escape(minetest.colorize("#313131", S("Hopper"))).."]"..
	"list[context;main;2,0.5;5,1;]"..
	mcl_formspec.get_itemslot_bg(2,0.5,5,1)..
	"label[0,2;"..minetest.formspec_escape(minetest.colorize("#313131", S("Inventory"))).."]"..
	"list[current_player;main;0,2.5;9,3;9]"..
	mcl_formspec.get_itemslot_bg(0,2.5,9,3)..
	"list[current_player;main;0,5.74;9,1;]"..
	mcl_formspec.get_itemslot_bg(0,5.74,9,1)..
	"listring[context;main]"..
	"listring[current_player;main]"

-- Downwards hopper (base definition)

local def_hopper = {
	inventory_image = "mcl_hoppers_item.png",
	wield_image = "mcl_hoppers_item.png",
	groups = {pickaxey=1, container=2,deco_block=1,hopper=1},
	drawtype = "nodebox",
	paramtype = "light",
	tiles = {
		"mcl_hoppers_hopper_inside.png^mcl_hoppers_hopper_top.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_outside.png"
	},
	node_box = {
		type = "fixed",
		fixed = {
			--funnel walls
			{-0.5,  0.0,  0.4,  0.5,  0.5,  0.5,},
			{ 0.4,  0.0, -0.5,  0.5,  0.5,  0.5,},
			{-0.5,  0.0, -0.5, -0.4,  0.5,  0.5,},
			{-0.5,  0.0, -0.5,  0.5,  0.5, -0.4,},
			--funnel base
			{-0.5,  0.0, -0.5,  0.5,  0.1,  0.5,},
			--spout
			{-0.3, -0.3, -0.3,  0.3,  0.0,  0.3,},
			{-0.1, -0.3, -0.1,  0.1, -0.5,  0.1,},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			--funnel
			{-0.5,  0.0, -0.5,  0.5,  0.5,  0.5,},
			--spout
			{-0.3, -0.3, -0.3,  0.3,  0.0,  0.3,},
			{-0.1, -0.3, -0.1,  0.1, -0.5,  0.1,},
		},
	},
	is_ground_content = false,

	on_construct = function(pos)
		local meta = minetest_get_meta(pos)
		meta:set_string("formspec", mcl_hoppers_formspec)
		local inv = meta:get_inventory()
		inv:set_size("main", 5)
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest_get_meta(pos)
		local meta2 = meta:to_table()
		meta:from_table(oldmetadata)
		local inv = meta:get_inventory()
		for i=1,inv:get_size("main") do
			local stack = inv:get_stack("main", i)
			if not stack:is_empty() then
				local p = {x=pos.x+math.random(0, 10)/10-0.5, y=pos.y, z=pos.z+math.random(0, 10)/10-0.5}
				minetest.add_item(p, stack)
			end
		end
		meta:from_table(meta2)
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return count
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff in mcl_hoppers at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff to mcl_hoppers at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" takes stuff from mcl_hoppers at "..minetest.pos_to_string(pos))
	end,
	sounds = mcl_sounds.node_sound_metal_defaults(),

	_mcl_blast_resistance = 4.8,
	_mcl_hardness = 3,
}

-- Enabled downwards hopper

local def_hopper_enabled = table.copy(def_hopper)
def_hopper_enabled.description = S("Hopper")
def_hopper_enabled._tt_help = S("5 inventory slots").."\n"..S("Collects items from above, moves items to container below").."\n"..S("Can be disabled with redstone power")
def_hopper_enabled._doc_items_longdesc = S("Hoppers are containers with 5 inventory slots. They collect dropped items from above, take items from a container above and attempt to put its items it into an adjacent container. Hoppers can go either downwards or sideways. Hoppers interact with chests, droppers, dispensers, shulker boxes, furnaces and hoppers.").."\n\n"..

S("Hoppers interact with containers the following way:").."\n"..
S("• Furnaces: Hoppers from above will put items into the source slot. Hoppers from below take items from the output slot. They also take items from the fuel slot when they can't be used as a fuel. Sideway hoppers that point to the furnace put items into the fuel slot").."\n"..
S("• Ender chests: No interaction.").."\n"..
S("• Other containers: Normal interaction.").."\n\n"..

S("Hoppers can be disabled when supplied with redstone power. Disabled hoppers don't move items.")
def_hopper_enabled._doc_items_usagehelp = S("To place a hopper vertically, place it on the floor or a ceiling. To place it sideways, place it at the side of a block. Use the hopper to access its inventory.")
def_hopper_enabled.on_place = function(itemstack, placer, pointed_thing)
	local upos  = pointed_thing.under
	local apos = pointed_thing.above

	local uposnode = minetest_get_node(upos)
	local uposnodedef = minetest_registered_nodes[uposnode.name]
	if not uposnodedef then return itemstack end
	-- Use pointed node's on_rightclick function first, if present
	if placer and not placer:get_player_control().sneak then
		if uposnodedef and uposnodedef.on_rightclick then
			return uposnodedef.on_rightclick(pointed_thing.under, uposnode, placer, itemstack) or itemstack
		end
	end

	local fake_itemstack = ItemStack(itemstack)
	local dx = apos.x - upos.x
	local dz = apos.z - upos.z
	local param2
	if (dx ~= 0) or (dz ~= 0) then
		param2 = minetest.dir_to_facedir({x = dx, y = 0, z = dz})
		fake_itemstack:set_name(HOPPER_SIDE)
	end
	local itemstack, _ = minetest.item_place_node(fake_itemstack, placer, pointed_thing, param2)
	itemstack:set_name(HOPPER)
	return itemstack
end
def_hopper_enabled.mesecons = {
	effector = {
		action_on = function(pos, node)
			minetest.swap_node(pos, {name="mcl_hoppers:hopper_disabled", param2=node.param2})
		end,
	},
}

minetest.register_node(HOPPER, def_hopper_enabled)

-- Disabled downwards hopper

local def_hopper_disabled = table.copy(def_hopper)
def_hopper_disabled.description = S("Disabled Hopper")
def_hopper_disabled.inventory_image = nil
def_hopper_disabled._doc_items_create_entry = false
def_hopper_disabled.groups.not_in_creative_inventory = 1
def_hopper_disabled.drop = HOPPER
def_hopper_disabled.mesecons = {
	effector = {
		action_off = function(pos, node)
			minetest.swap_node(pos, {name=HOPPER, param2=node.param2})
		end,
	},
}

minetest.register_node("mcl_hoppers:hopper_disabled", def_hopper_disabled)

-- Sidewadrs hopper (base definition)

local def_hopper_side = {
	_doc_items_create_entry = false,
	drop = HOPPER,
	groups = {
		container = 2,
		hopper = 2,
		not_in_creative_inventory = 1,
		pickaxey = 1,
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	tiles = {
		"mcl_hoppers_hopper_inside.png^mcl_hoppers_hopper_top.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_outside.png",
		"mcl_hoppers_hopper_outside.png",
	},
	node_box = {
		type = "fixed",
		fixed = {
			--funnel walls
			{-0.5,  0.0,  0.4,  0.5,  0.5,  0.5,},
			{ 0.4,  0.0, -0.5,  0.5,  0.5,  0.5,},
			{-0.5,  0.0, -0.5, -0.4,  0.5,  0.5,},
			{-0.5,  0.0, -0.5,  0.5,  0.5, -0.4,},
			--funnel base
			{-0.5,  0.0, -0.5,  0.5,  0.1,  0.5,},
			--spout
			{-0.3, -0.3, -0.3,  0.3,  0.0,  0.3,},
			{-0.1, -0.3, -0.5,  0.1, -0.1,  0.1,},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			--funnel
			{-0.5,  0.0, -0.5,  0.5,  0.5,  0.5,},
			--spout
			{-0.3, -0.3, -0.3,  0.3,  0.0,  0.3,},
			{-0.1, -0.3, -0.5,  0.1, -0.1,  0.1,},
		},
	},
	is_ground_content = false,

	on_construct = function(pos)
		local meta = minetest_get_meta(pos)
		meta:set_string("formspec", mcl_hoppers_formspec)
		local inv = meta:get_inventory()
		inv:set_size("main", 5)
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local meta = minetest_get_meta(pos)
		local meta2 = meta
		meta:from_table(oldmetadata)
		local inv = meta:get_inventory()
		for i=1,inv:get_size("main") do
			local stack = inv:get_stack("main", i)
			if not stack:is_empty() then
				local p = {x=pos.x+math.random(0, 10)/10-0.5, y=pos.y, z=pos.z+math.random(0, 10)/10-0.5}
				minetest.add_item(p, stack)
			end
		end
		meta:from_table(meta2:to_table())
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return count
		end
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local name = player:get_player_name()
		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return 0
		else
			return stack:get_count()
		end
	end,
	on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff in mcl_hoppers at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" moves stuff to mcl_hoppers at "..minetest.pos_to_string(pos))
	end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		minetest.log("action", player:get_player_name()..
				" takes stuff from mcl_hoppers at "..minetest.pos_to_string(pos))
	end,
	on_rotate = screwdriver.rotate_simple,
	sounds = mcl_sounds.node_sound_metal_defaults(),

	_mcl_blast_resistance = 4.8,
	_mcl_hardness = 3,
}

-- Enabled sidewards hopper

local def_hopper_side_enabled = table.copy(def_hopper_side)
def_hopper_side_enabled.description = S("Side Hopper")
def_hopper_side_enabled.mesecons = {
	effector = {
		action_on = function(pos, node)
			minetest.swap_node(pos, {name="mcl_hoppers:hopper_side_disabled", param2=node.param2})
		end,
	},
}
minetest.register_node(HOPPER_SIDE, def_hopper_side_enabled)

-- Disabled sidewards hopper

local def_hopper_side_disabled = table.copy(def_hopper_side)
def_hopper_side_disabled.description = S("Disabled Side Hopper")
def_hopper_side_disabled.mesecons = {
	effector = {
		action_off = function(pos, node)
			minetest.swap_node(pos, {name=HOPPER_SIDE, param2=node.param2})
		end,
	},
}
minetest.register_node("mcl_hoppers:hopper_side_disabled", def_hopper_side_disabled)

minetest.register_abm({
	label = "Hopper",
	nodenames = {
		HOPPER,
		HOPPER_SIDE,
	},
	interval = 1,
	chance = 1,
	action = function(pos, node)
		local pos = pos
		local meta = minetest_get_meta(pos)
		local inv = meta:get_inventory()
		if not inv then return end

		local x, y, z = pos.x, pos.y, pos.z

		-- Move an item from the hopper into the container to which the hopper points to
		local dst_pos
		if node.name == HOPPER then
			dst_pos = {x = x, y = y - 1, z = z}
		else
			local param2 = node.param2
			local dir = minetest_facedir_to_dir(param2)
			if not dir then return end
			dst_pos = {x = x - dir.x, y = y, z = z - dir.z}
		end
		local dst_node = minetest_get_node(dst_pos)
		local dst_node_name = dst_node.name
		local dst_container_group = minetest_get_item_group(dst_node_name, "container")
		if GROUPS_TO_PUT_INTO_COMMON_SLOT[dst_container_group] then
			mcl_util_move_item_container(pos, dst_pos)
		elseif GROUPS_TO_PUT_INTO_FUEL_SLOT[dst_container_group] then
			local sinv = minetest_get_inventory({type="node", pos = pos})
			local dinv = minetest_get_inventory({type="node", pos = dst_pos})
			local slot_id,_ = mcl_util.get_eligible_transfer_item_slot(
				sinv,
				"main",
				dinv,
				"fuel",
				function(itemstack, src_inventory, src_list, dst_inventory, dst_list)
					-- Returns true if itemstack is fuel, but not for lava bucket if destination already has one
					if not mcl_util.is_fuel(itemstack) then return false end
					if itemstack:get_name() ~= "mcl_buckets:bucket_lava" then return true end
					return dst_inventory:is_empty(dst_list)
				end
			)
		end

		local y_above = y + 1
		local pos_above = {x = x, y = y_above, z = z}
		local above_node = minetest_get_node(pos_above)
		local above_node_name = above_node.name
		local above_container_group = minetest_get_item_group(above_node_name, "container")
		if above_container_group ~= 0 then
			-- Suck an item from the container above into the hopper
			if not mcl_util_move_item_container(pos_above, pos)
			and above_container_group == 4 then
				local finv = minetest_get_inventory({type="node", pos = pos_above})
				if finv and not mcl_util.is_fuel(finv:get_stack("fuel", 1)) then
					mcl_util_move_item_container(pos_above, pos, "fuel")
				end
			end
		else
			-- Suck in dropped items
			local y_top_touch_to_suck = y_above + 0.5
			for _, object in pairs(minetest_get_objects_inside_radius(pos_above, 1)) do
				if not object:is_player() then
					local entity = object:get_luaentity()
					local entity_name = entity and entity.name
					if entity_name == "__builtin:item" then
						local itemstring = entity.itemstring
						if itemstring and itemstring ~= "" and inv:room_for_item("main", ItemStack(itemstring)) then
							local object_pos = object:get_pos()
							local object_pos_y = object_pos.y
							local object_collisionbox = object:get_properties().collisionbox
							local touches_from_above = object_pos_y + object_collisionbox[2] <= y_top_touch_to_suck
							if touches_from_above
							and (math_abs(object_pos.x - x) <= 0.5)
							and (math_abs(object_pos.z - z) <= 0.5)
							then
								object:remove()
								inv:add_item("main", ItemStack(itemstring))
							end
						end
					end
				end
			end
		end
	end,
})

minetest.register_craft({
	output = HOPPER,
	recipe = {
		{"mcl_core:iron_ingot","","mcl_core:iron_ingot"},
		{"mcl_core:iron_ingot","mcl_chests:chest","mcl_core:iron_ingot"},
		{"","mcl_core:iron_ingot",""},
	}
})

if minetest.get_modpath("doc") then
	doc.add_entry_alias("nodes", HOPPER, "nodes", HOPPER_SIDE)
end

minetest.register_lbm({
	label = "Update hopper formspecs (0.60.0",
	name = "mcl_hoppers:update_formspec_0_60_0",
	nodenames = { "group:hopper" },
	run_at_every_load = false,
	action = function(pos, node)
		local meta = minetest_get_meta(pos)
		meta:set_string("formspec", mcl_hoppers_formspec)
	end,
})

-- Legacy
minetest.register_alias("mcl_hoppers:hopper_item", HOPPER)
