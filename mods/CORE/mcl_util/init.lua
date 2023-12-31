mcl_util = {}

local minetest_get_item_group = minetest.get_item_group
local minetest_get_meta = minetest.get_meta
local minetest_get_node = minetest.get_node
local minetest_get_node_timer = minetest.get_node_timer
local table_copy = table.copy

-- Updates all values in t using values from to*.
function table.update(t, ...)
	for _, to in ipairs{...} do
		for k,v in pairs(to) do
			t[k] = v
		end
	end
	return t
end

-- Updates nil values in t using values from to*.
function table.update_nil(t, ...)
	for _, to in ipairs{...} do
		for k,v in pairs(to) do
			if t[k] == nil then
				t[k] = v
			end
		end
	end
	return t
end

-- Creates a function that calls to the minetest
-- function minetest_rotate_and_place. It rotates 
-- a block based on where it thinks the player is facing
-- at the moment. This is typically called by pillar-like nodes.

function mcl_util.rotate_axis(itemstack, placer, pointed_thing)
	minetest.rotate_and_place(itemstack, placer, pointed_thing,
		minetest.is_creative_enabled(placer:get_player_name()))
	return itemstack
end

-- Iterates through all items in the given inventory and
-- returns the slot of the first item which matches a condition.
-- Returns nil if no item was found.
--- source_inventory: Inventory to take the item from
--- source_list: List name of the source inventory from which to take the item
--- destination_inventory: Put item into this inventory
--- destination_list: List name of the destination inventory to which to put the item into
--- condition: Function which takes an itemstack and returns true if it matches the desired item condition.
---            If set to nil, the slot of the first item stack will be taken unconditionally.
-- dst_inventory and dst_list can also be nil if condition is nil.
function mcl_util.get_eligible_transfer_item_slot(src_inventory, src_list, dst_inventory, dst_list, condition)
	local size = src_inventory:get_size(src_list)
	local stack
	for i=1, size do
		stack = src_inventory:get_stack(src_list, i)
		if not stack:is_empty() and (condition == nil or condition(stack, src_inventory, src_list, dst_inventory, dst_list)) then
			return i
		end
	end
	return nil
end

-- Returns true if itemstack is a shulker box
local function is_not_shulker_box(itemstack)
	local g = minetest_get_item_group(itemstack:get_name(), "shulker_box")
	return g == 0 or g == nil
end

-- Moves a single item from one inventory to another.
--- source_inventory: Inventory to take the item from
--- source_list: List name of the source inventory from which to take the item
--- source_stack_id: The inventory position ID of the source inventory to take the item from (-1 for first occupied slot)
--- destination_inventory: Put item into this inventory
--- destination_list: List name of the destination inventory to which to put the item into

-- Returns true on success and false on failure
-- Possible failures: No item in source slot, destination inventory full
function mcl_util.move_item(source_inventory, source_list, source_stack_id, destination_inventory, destination_list)
	if source_stack_id == -1 then
		source_stack_id = mcl_util.get_first_occupied_inventory_slot(source_inventory, source_list)
		if source_stack_id == nil then
			return false
		end
	end

	if not source_inventory:is_empty(source_list) then
		local stack = source_inventory:get_stack(source_list, source_stack_id)
		if not stack:is_empty() then
			local new_stack = ItemStack(stack)
			new_stack:set_count(1)
			if not destination_inventory:room_for_item(destination_list, new_stack) then
				return false
			end
			stack:take_item()
			source_inventory:set_stack(source_list, source_stack_id, stack)
			destination_inventory:add_item(destination_list, new_stack)
			return true
		end
	end
	return false
end

-- Moves a single item from one container node into another. Performs a variety of high-level
-- checks to prevent invalid transfers such as shulker boxes into shulker boxes
--- source_pos: Position ({x,y,z}) of the node to take the item from
--- destination_pos: Position ({x,y,z}) of the node to put the item into
--- source_list (optional): List name of the source inventory from which to take the item. Default is normally "main"; "dst" for furnace
--- source_stack_id (optional): The inventory position ID of the source inventory to take the item from (-1 for slot of the first valid item; -1 is default)
--- destination_list (optional): List name of the destination inventory. Default is normally "main"; "src" for furnace
-- Returns true on success and false on failure.
local SHULKER_BOX        = 3
local FURNACE            = 4
local DOUBLE_CHEST_LEFT  = 5
local DOUBLE_CHEST_RIGHT = 6
local CONTAINER_GROUP_TO_LIST = {
	[1]                  = "main",
	[2]                  = "main",
	[SHULKER_BOX]        = "main",
	[FURNACE]            = "dst",
	[DOUBLE_CHEST_LEFT]  = "main",
	[DOUBLE_CHEST_RIGHT] = "main",
}
function mcl_util.move_item_container(source_pos, destination_pos, source_list, source_stack_id, destination_list)
	local spos = table_copy(source_pos)
	local snode = minetest_get_node(spos)
	local sctype = minetest_get_item_group(snode.name, "container")
	local default_source_list = CONTAINER_GROUP_TO_LIST[sctype]
	if not default_source_list then return end
	if sctype == DOUBLE_CHEST_RIGHT then
		local sparam2 = snode.param2
		if     sparam2 == 0 then spos.x = spos.x - 1
		elseif sparam2 == 1 then spos.z = spos.z + 1
		elseif sparam2 == 2 then spos.x = spos.x + 1
		elseif sparam2 == 3 then spos.z = spos.z - 1
		end
		snode = minetest_get_node(spos)
		sctype = minetest_get_item_group(snode.name, "container")
		if sctype ~= DOUBLE_CHEST_LEFT then return end
	end
	local smeta = minetest_get_meta(spos)
	local sinv = smeta:get_inventory()
	local source_list = source_list or default_source_list

	local dpos = table_copy(destination_pos)
	local dnode = minetest_get_node(dpos)
	local dctype = minetest_get_item_group(dnode.name, "container")
	local default_destination_list = CONTAINER_GROUP_TO_LIST[sctype]
	if not default_destination_list then return end
	if dctype == DOUBLE_CHEST_RIGHT then
		local dparam2 = dnode.param2
		if     dparam2 == 0 then dpos.x = dpos.x - 1
		elseif dparam2 == 1 then dpos.z = dpos.z + 1
		elseif dparam2 == 2 then dpos.x = dpos.x + 1
		elseif dparam2 == 3 then dpos.z = dpos.z - 1
		end
		dnode = minetest_get_node(dpos)
		dctype = minetest_get_item_group(dnode.name, "container")
		if dctype ~= DOUBLE_CHEST_LEFT then return end
	end
	local dmeta = minetest_get_meta(dpos)
	local dinv = dmeta:get_inventory()

	-- Automatically select stack slot ID if set to automatic
	local source_stack_id = source_stack_id or -1
	if source_stack_id == -1 then
		local cond = nil
		-- Prevent shulker box inception
		if dctype == SHULKER_BOX then cond = is_not_shulker_box end
		source_stack_id = mcl_util.get_eligible_transfer_item_slot(sinv, source_list, dinv, dpos, cond)
		if not source_stack_id then
			if sctype == DOUBLE_CHEST_LEFT then
				local sparam2 = snode.param2
				if     sparam2 == 0 then spos.x = spos.x + 1
				elseif sparam2 == 1 then spos.z = spos.z - 1
				elseif sparam2 == 2 then spos.x = spos.x - 1
				elseif sparam2 == 3 then spos.z = spos.z + 1
				end
				snode = minetest_get_node(spos)
				sctype = minetest_get_item_group(snode.name, "container")
				if sctype ~= DOUBLE_CHEST_RIGHT then return end
				smeta = minetest_get_meta(spos)
				sinv = smeta:get_inventory()
				source_stack_id = mcl_util.get_eligible_transfer_item_slot(sinv, source_list, dinv, dpos, cond)
			end
		end
		if not source_stack_id then return end
	end

	-- Abort transfer if shulker box wants to go into shulker box
	if dctype == SHULKER_BOX then
		local stack = sinv:get_stack(source_list, source_stack_id)
		if stack and minetest_get_item_group(stack:get_name(), "shulker_box") == 1 then return end
	end

	local destination_list = destination_list or default_destination_list
	-- Move item
	local ok = mcl_util.move_item(sinv, source_list, source_stack_id, dinv, destination_list)
	-- Try transfer to neighbor node if transfer failed and double container
	if not ok then
		if dctype == DOUBLE_CHEST_LEFT then
			local dparam2 = dnode.param2
			if     dparam2 == 0 then dpos.x = dpos.x + 1
			elseif dparam2 == 1 then dpos.z = dpos.z - 1
			elseif dparam2 == 2 then dpos.x = dpos.x - 1
			elseif dparam2 == 3 then dpos.z = dpos.z + 1
			end
			dnode = minetest_get_node(dpos)
			dctype = minetest_get_item_group(dnode.name, "container")
			if dctype ~= DOUBLE_CHEST_RIGHT then return end
			dmeta = minetest_get_meta(dpos)
			dinv = dmeta:get_inventory()
			ok = mcl_util.move_item(sinv, source_list, source_stack_id, dinv, destination_list)
		end
	end
	-- Update furnace
	if ok and dctype == FURNACE then
		-- Start furnace's timer function, it will sort out whether furnace can burn or not.
		minetest_get_node_timer(dpos):start(1.0)
	end
	return ok
end

-- Returns the ID of the first non-empty slot in the given inventory list
-- or nil, if inventory is empty.
function mcl_util.get_first_occupied_inventory_slot(inventory, listname)
	return mcl_util.get_eligible_transfer_item_slot(inventory, listname)
end

-- Returns true if item (itemstring or ItemStack) can be used as a furnace fuel.
-- Returns false otherwise
function mcl_util.is_fuel(item)
	return minetest.get_craft_result({method="fuel", width=1, items={item}}).time ~= 0
end

-- Returns a on_place function for plants
-- * condition: function(pos, node, itemstack)
--    * A function which is called by the on_place function to check if the node can be placed
--    * Must return true, if placement is allowed, false otherwise.
--    * If it returns a string, placement is allowed, but will place this itemstring as a node instead
--    * pos, node: Position and node table of plant node
--    * itemstack: Itemstack to place
function mcl_util.generate_on_place_plant_function(condition)
	return function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			-- no interaction possible with entities
			return itemstack
		end

		-- Call on_rightclick if the pointed node defines it
		local node = minetest_get_node(pointed_thing.under)
		if placer and not placer:get_player_control().sneak then
			if minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].on_rightclick then
				return minetest.registered_nodes[node.name].on_rightclick(pointed_thing.under, node, placer, itemstack) or itemstack
			end
		end

		local place_pos
		local def_under = minetest.registered_nodes[minetest_get_node(pointed_thing.under).name]
		local def_above = minetest.registered_nodes[minetest_get_node(pointed_thing.above).name]
		if not def_under or not def_above then
			return itemstack
		end
		if def_under.buildable_to then
			place_pos = pointed_thing.under
		elseif def_above.buildable_to then
			place_pos = pointed_thing.above
		else
			return itemstack
		end

		-- Check placement rules
		local result, param2 = condition(place_pos, node, itemstack)
		if result == true then
			local idef = itemstack:get_definition()
			local new_itemstack, success = minetest.item_place_node(itemstack, placer, pointed_thing, param2)

			if success then
				if idef.sounds and idef.sounds.place then
					minetest.sound_play(idef.sounds.place, {pos=pointed_thing.above, gain=1}, true)
				end
			end
			itemstack = new_itemstack
		end

		return itemstack
	end
end

-- adjust the y level of an object to the center of its collisionbox
-- used to get the origin position of entity explosions
function mcl_util.get_object_center(obj)
	local collisionbox = obj:get_properties().collisionbox
	local pos = obj:get_pos()
	local ymin = collisionbox[2]
	local ymax = collisionbox[5]
	pos.y = pos.y + (ymax - ymin) / 2.0
	return pos
end

function mcl_util.get_color(colorstr)
	local mc_color = mcl_colors[colorstr:upper()]
	if mc_color then
		colorstr = mc_color
	elseif #colorstr ~= 7 or colorstr:sub(1, 1) ~= "#" then
		return
	end
	local hex = tonumber(colorstr:sub(2, 7), 16)
	if hex then
		return colorstr, hex
	end
end

function mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
	-- Call on_rightclick if the pointed node defines it
	if pointed_thing and pointed_thing.type == "node" then
		local pos = pointed_thing.under
		local node = minetest_get_node(pos)
		if player and not player:get_player_control().sneak then
			local nodedef = minetest.registered_nodes[node.name]
			local on_rightclick = nodedef and nodedef.on_rightclick
			if on_rightclick then
				return on_rightclick(pos, node, player, itemstack, pointed_thing) or itemstack
			end
		end
	end
end

function mcl_util.calculate_durability(itemstack)
	local unbreaking_level = mcl_enchanting.get_enchantment(itemstack, "unbreaking")
	local armor_uses = minetest_get_item_group(itemstack:get_name(), "mcl_armor_uses")

	local uses

	if armor_uses > 0 then
		uses = armor_uses
		if unbreaking_level > 0 then
			uses = uses / (0.6 + 0.4 / (unbreaking_level + 1))
		end
	else
		local def = itemstack:get_definition()
		if def then
			local fixed_uses = def._mcl_uses
			if fixed_uses then
				uses = fixed_uses
				if unbreaking_level > 0 then
					uses = uses * (unbreaking_level + 1)
				end
			end
		end

		local _, groupcap = next(itemstack:get_tool_capabilities().groupcaps)
		uses = uses or (groupcap or {}).uses
	end

	return uses or 0
end

function mcl_util.use_item_durability(itemstack, n)
	local uses = mcl_util.calculate_durability(itemstack)
	itemstack:add_wear(65535 / uses * n)
end

function mcl_util.deal_damage(target, damage, mcl_reason)
	local luaentity = target:get_luaentity()

	if luaentity then
		if luaentity.deal_damage then
			luaentity:deal_damage(damage, mcl_reason or {type = "generic"})
			return
		elseif luaentity._cmi_is_mob then
			-- local puncher = mcl_reason and mcl_reason.direct or target
			-- target:punch(puncher, 1.0, {full_punch_interval = 1.0, damage_groups = {fleshy = damage}}, vector.direction(puncher:get_pos(), target:get_pos()), damage)
			if luaentity.health > 0 then
				luaentity.health = luaentity.health - damage
				luaentity.pause_timer = 0.4
			end
			return
		end
	end

	local hp = target:get_hp()

	if hp > 0 then
		target:set_hp(hp - damage, {_mcl_reason = mcl_reason})
	end
end

function mcl_util.get_hp(obj)
	local luaentity = obj:get_luaentity()

	if luaentity and luaentity._cmi_is_mob then
		return luaentity.health
	else
		return obj:get_hp()
	end
end

function mcl_util.get_inventory(object, create)
	if object:is_player() then
		return object:get_inventory()
	else
		local luaentity = object:get_luaentity()
		local inventory = luaentity.inventory

		if create and not inventory and luaentity.create_inventory then
			inventory = luaentity:create_inventory()
		end

		return inventory
	end
end

function mcl_util.get_wielded_item(object)
	if object:is_player() then
		return object:get_wielded_item()
	else
		-- ToDo: implement getting wielditems from mobs as soon as mobs have wielditems
		return ItemStack()
	end
end

function mcl_util.get_object_name(object)
	if object:is_player() then
		return object:get_player_name()
	else
		local luaentity = object:get_luaentity()

		if not luaentity then
			return tostring(object)
		end

		return luaentity.nametag and luaentity.nametag ~= "" and luaentity.nametag or luaentity.description or luaentity.name
	end
end

function mcl_util.replace_mob(obj, mob)
	local rot = obj:get_yaw()
	local pos = obj:get_pos()
	obj:remove()
	obj = minetest.add_entity(pos, mob)
	obj:set_yaw(rot)
	return obj
end

function mcl_util.get_pointed_thing(player)
	local pos = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
	local look_dir = vector.multiply(player:get_look_dir(), 5)
	local pos2 = vector.add(pos, look_dir)
	local ray = minetest.raycast(pos, pos2, false, true)
	
	if ray then
		for pointed_thing in ray do
			return pointed_thing
		end
	end
end

local possible_hackers = {}

function mcl_util.is_player(obj)
	if not obj then return end
	if not obj.is_player then return end
	if not obj:is_player() then return end
	local name = obj:get_player_name()
	if not name then return end
	if possible_hackers[name] then return end
	return true
end

minetest.register_on_authplayer(function(name, ip, is_success)
	if not is_success then return end
	possible_hackers[name] = true
end)

minetest.register_on_joinplayer(function(player)
	possible_hackers[player:get_player_name()] = nil
end)
