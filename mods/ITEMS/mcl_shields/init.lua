local minetest, math, vector = minetest, math, vector
local modname = minetest.get_current_modname()
local S = minetest.get_translator(modname)

mcl_shields = {
	types = {
		mob = true,
		player = true,
		arrow = true,
		generic = true,
		explosion = true, -- ghasts don't work
		dragon_breath = true,
	},
	enchantments = {"mending", "unbreaking"},
	players = {},
}

local interact_priv = minetest.registered_privileges.interact
interact_priv.give_to_singleplayer = false
interact_priv.give_to_admin = false

local overlay = mcl_enchanting.overlay
local hud = "mcl_shield_hud.png"

minetest.register_tool("mcl_shields:shield", {
	description = S("Shield"),
	_doc_items_longdesc = S("A shield is a tool used for protecting the player against attacks."),
	inventory_image = "mcl_shield.png",
	stack_max = 1,
	groups = {
		shield = 1,
		weapon = 1,
		enchantability = 1,
		no_wieldview = 1,
		offhand_item = 1,
	},
	sound = {breaks = "default_tool_breaks"},
	_repair_material = "group:wood",
	wield_scale = vector.new(2, 2, 2),
})

local function wielded_item(obj, i)
	local itemstack = obj:get_wielded_item()
	if i == 1 then
		itemstack = obj:get_inventory():get_stack("offhand", 1)
	end
	return itemstack:get_name()
end

function mcl_shields.wielding_shield(obj, i)
	return wielded_item(obj, i):find("mcl_shields:shield")
end

local function shield_is_enchanted(obj, i)
	return mcl_enchanting.is_enchanted(wielded_item(obj, i))
end

minetest.register_entity("mcl_shields:shield_entity", {
	initial_properties = {
		visual = "mesh",
		mesh = "mcl_shield.obj",
		physical = false,
		pointable = false,
		collide_with_objects = false,
		textures = {"mcl_shield_base_nopattern.png"},
		visual_size = vector.new(1, 1, 1),
	},
	_blocking = false,
	_shield_number = 2,
	on_step = function(self, dtime, moveresult)
		local player = self.object:get_attach()
		if player then
			local shield_texture = "mcl_shield_base_nopattern.png"
			local i = self._shield_number
			local item = wielded_item(player, i)

			if item ~= "mcl_shields:shield" and item ~= "mcl_shields:shield_enchanted" then
				local itemstack = player:get_wielded_item()
				if i == 1 then
					itemstack = player:get_inventory():get_stack("offhand", 1)
				end
				local meta_texture = itemstack:get_meta():get_string("mcl_shields:shield_custom_pattern_texture")
				if meta_texture ~= "" then
					shield_texture = meta_texture
				else
					local color = minetest.registered_items[item]._shield_color
					if color then
						shield_texture = "mcl_shield_base_nopattern.png^(mcl_shield_pattern_base.png^[colorize:" .. color .. ")"
					end
					
				end
			end

			if shield_is_enchanted(player, i) then
				shield_texture = shield_texture .. overlay
			end

			self.object:set_properties({textures = {shield_texture}})
		else
			self.object:remove()
		end
	end,
})

for _, e in pairs(mcl_shields.enchantments) do
	mcl_enchanting.enchantments[e].secondary.shield = true
end

function mcl_shields.is_blocking(obj)
	local blocking = mcl_shields.players[obj].blocking
	if blocking > 0 then
		local shieldstack = obj:get_wielded_item()
		if blocking == 1 then
			shieldstack = obj:get_inventory():get_stack("offhand", 1)
		end
		return blocking, shieldstack
	end
end

mcl_damage.register_modifier(function(obj, damage, reason)
	local type = reason.type
	local damager = reason.direct
	local blocking, shieldstack = mcl_shields.is_blocking(obj)
	if obj:is_player() and blocking and mcl_shields.types[type] and damager then
		local entity = damager:get_luaentity()
		if entity and (type == "arrow" or type == "generic") then
			damager = entity._shooter
		end
		if vector.dot(obj:get_look_dir(), vector.subtract(damager:get_pos(), obj:get_pos())) >= 0 then
			local durability = 336
			local unbreaking = mcl_enchanting.get_enchantment(shieldstack, mcl_shields.enchantments[2])
			if unbreaking > 0 then
				durability = durability * (unbreaking + 1)
			end
			if not minetest.is_creative_enabled(obj:get_player_name()) and damage >= 3 then
				shieldstack:add_wear(65535 / durability)
				if blocking == 2 then
					obj:set_wielded_item(shieldstack)
				else
					obj:get_inventory():set_stack("offhand", 1, shieldstack)
					mcl_inventory.update_inventory_formspec(obj)
				end
			end
			minetest.sound_play({name = "mcl_block"})
			return 0
		end
	end
end)

local function modify_shield(player, vpos, vrot, i)
	local arm = "Right"
	if i == 1 then
		arm = "Left"
	end
	local shield = mcl_shields.players[player].shields[i]
	if shield then
		shield:set_attach(player, "Arm_" .. arm, vpos, vrot, false)
	end
end

local function set_shield(player, block, i)
	if block then
		if i == 1 then
			modify_shield(player, vector.new(-9, 4, 0.5), vector.new(80, 100, 0), i) -- TODO
		else
			modify_shield(player, vector.new(-8, 4, -2.5), vector.new(80, 80, 0), i)
		end
	else
		if i == 1 then
			modify_shield(player, vector.new(-3, -5, 0), vector.new(0, 180, 0), i)
		else
			modify_shield(player, vector.new(3, -5, 0), vector.new(0, 0, 0), i)
		end
	end
	local shield = mcl_shields.players[player].shields[i]
	if not shield then return end
	local luaentity = shield:get_luaentity()
	if not luaentity then return end
	luaentity._blocking = block
end

local function set_interact(player, interact)
	local player_name = player:get_player_name()
	local privs = minetest.get_player_privs(player_name)
	if privs.interact ~= interact then
		local meta = player:get_meta()
		if meta:get_int("ineract_revoked") ~= 1 then
			privs.interact = interact
			minetest.set_player_privs(player_name, privs)
		end
	end
end

local shield_hud = {}

local function remove_shield_hud(player)
	if shield_hud[player] then
		player:hud_remove(shield_hud[player])
		shield_hud[player] = nil
		set_shield(player, false, 1)
		set_shield(player, false, 2)
	end

	local hf=player:hud_get_flags()
	if not hf.wielditem then
		player:hud_set_flags({wielditem = true})
	end

	playerphysics.remove_physics_factor(player, "speed", "shield_speed")
	set_interact(player, true)
end

local function add_shield_entity(player, i)
	local shield = minetest.add_entity(player:get_pos(), "mcl_shields:shield_entity")
	shield:get_luaentity()._shield_number = i
	mcl_shields.players[player].shields[i] = shield
	set_shield(player, false, i)
end

local function remove_shield_entity(player, i)
	local shields = mcl_shields.players[player].shields
	if shields[i] then
		shields[i]:remove()
		shields[i] = nil
	end
end

local function handle_blocking(player)
	local player_shield = mcl_shields.players[player]
	local rmb = player:get_player_control().RMB
	if rmb then
		local shield_in_offhand = mcl_shields.wielding_shield(player, 1)
		local shield_in_hand = mcl_shields.wielding_shield(player)
		local not_blocking = player_shield.blocking == 0

		local pos = player:get_pos()
		if shield_in_hand then
			if not_blocking then
				minetest.after(0.25, function()
					if (not_blocking or not shield_in_offhand) and shield_in_hand and rmb then
						player_shield.blocking = 2
						set_shield(player, true, 2)
					end
				end)
			elseif not shield_in_offhand then
				player_shield.blocking = 2
			end
		elseif shield_in_offhand then
			local offhand_can_block = (wielded_item(player) == "" or not mcl_util.get_pointed_thing(player))
			if offhand_can_block then
				if not_blocking then
					minetest.after(0.25, function()
						if (not_blocking or not shield_in_hand) and shield_in_offhand and rmb  and offhand_can_block then
							player_shield.blocking = 1
							set_shield(player, true, 1)
						end
					end)
				elseif not shield_in_hand then
					player_shield.blocking = 1
				end
			end
		else
			player_shield.blocking = 0
		end
	else
		player_shield.blocking = 0
	end
end

local function update_shield_entity(player, blocking, i)
	local shield = mcl_shields.players[player].shields[i]
	if mcl_shields.wielding_shield(player, i) then
		if not shield then
			add_shield_entity(player, i)
		else
			if blocking == i then
				if shield:get_luaentity() and not shield:get_luaentity()._blocking then
					set_shield(player, true, i)
				end
			else
				set_shield(player, false, i)
			end
		end
	elseif shield then
		remove_shield_entity(player, i)
	end
end

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do

		handle_blocking(player)

		local blocking, shieldstack = mcl_shields.is_blocking(player)

		if blocking then
			local shieldhud = shield_hud[player]
			if not shieldhud then
				local texture = hud
				if mcl_enchanting.is_enchanted(shieldstack:get_name()) then
					texture = texture .. overlay
				end
				local offset = 100
				if blocking == 1 then
					texture = texture .. "^[transform4"
					offset = -100
				else
					player:hud_set_flags({wielditem = false})
				end
				shield_hud[player] = player:hud_add({
					hud_elem_type = "image",
					position = {x = 0.5, y = 0.5},
					scale = {x = -101, y = -101},
					offset = {x = offset, y = 0},
					text = texture,
					z_index = -200,
				})
				playerphysics.add_physics_factor(player, "speed", "shield_speed", 0.5)
				set_interact(player, nil)
			else
				local wielditem = player:hud_get_flags().wielditem
				if blocking == 1 then
					if not wielditem then
						player:hud_change(shieldhud, "text", hud .. "^[transform4")
						player:hud_change(shieldhud, "offset", {x = -100, y = 0})
						player:hud_set_flags({wielditem = true})
					end
				else
					if wielditem then
						player:hud_change(shieldhud, "text", hud)
						player:hud_change(shieldhud, "offset", {x = 100, y = 0})
						player:hud_set_flags({wielditem = false})
					end
				end

				local image = player:hud_get(shieldhud).text
				local enchanted = hud .. overlay
				local enchanted1 = image == enchanted
				local enchanted2 = image == enchanted .. "^[transform4"
				if mcl_enchanting.is_enchanted(shieldstack:get_name()) then
					if not enchanted1 and not enchanted2 then
						if blocking == 1 then
							player:hud_change(shieldhud, "text", hud .. overlay .. "^[transform4")
						else
							player:hud_change(shieldhud, "text", hud .. overlay)
						end
					end
				elseif enchanted1 or enchanted2 then
					if blocking == 1 then
						player:hud_change(shieldhud, "text", hud .. "^[transform4")
					else
						player:hud_change(shieldhud, "text", hud)
					end
				end
			end
		else
			remove_shield_hud(player)
		end

		for i = 1, 2 do
			update_shield_entity(player, blocking, i)
		end
	end
end)

minetest.register_on_dieplayer(function(player)
	remove_shield_hud(player)
	if not minetest.settings:get_bool("mcl_keepInventory") then
		remove_shield_entity(player, 1)
		remove_shield_entity(player, 2)
	end
end)

minetest.register_on_leaveplayer(function(player)
	shield_hud[player] = nil
	mcl_shields.players[player] = nil
end)

minetest.register_craft({
	output = "mcl_shields:shield",
	recipe = {
		{"group:wood", "mcl_core:iron_ingot", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
		{"", "group:wood", ""},
	}
})

for _, colortab in pairs(mcl_banners.colors) do
	minetest.register_tool("mcl_shields:shield_" .. colortab[1], {
		description = S(colortab[6] .. " Shield"),
		_doc_items_longdesc = S("A shield is a tool used for protecting the player against attacks."),
		inventory_image = "mcl_shield.png^(mcl_shield_item_overlay.png^[colorize:" .. colortab[4] ..")",
		stack_max = 1,
		groups = {
			shield = 1,
			weapon = 1,
			enchantability = 1,
			no_wieldview = 1,
			not_in_creative_inventory = 1,
			offhand_item = 1,
		},
		sound = {breaks = "default_tool_breaks"},
		_repair_material = "group:wood",
		wield_scale = vector.new(2, 2, 2),
		_shield_color = colortab[4],
	})

	local banner = "mcl_banners:banner_item_" .. colortab[1]
	minetest.register_craft({
		type = "shapeless",
		output = "mcl_shields:shield_" .. colortab[1],
		recipe = {"mcl_shields:shield", banner},
	})
end

local function to_shield_texture(banner_texture)
	return banner_texture
	:gsub("mcl_banners_base_inverted.png", "mcl_shield_base_nopattern.png^mcl_shield_pattern_base.png")
	:gsub("mcl_banners_banner_base.png", "mcl_shield_base_nopattern.png^mcl_shield_pattern_base.png")
	:gsub("mcl_banners_base", "mcl_shield_pattern_base")
	:gsub("mcl_banners", "mcl_shield_pattern")
end

local function craft_banner_on_shield(itemstack, player, old_craft_grid, craft_inv)
	if string.find(itemstack:get_name(), "mcl_shields:shield_") then
		local shield_stack
		for i = 1, player:get_inventory():get_size("craft") do
			local stack = old_craft_grid[i]
			local name = stack:get_name()
			if name == "mcl_shields:shield" then
				shield_stack = stack
				break
			end
		end
		for i = 1, player:get_inventory():get_size("craft") do
			local banner_stack = old_craft_grid[i]
			local banner_name = banner_stack:get_name()
			if string.find(banner_name, "mcl_banners:banner") and shield_stack then
				local banner_meta = banner_stack:get_meta()
				local layers_meta = banner_meta:get_string("layers")
				local new_shield_meta = itemstack:get_meta()
				if layers_meta ~= "" then
					local color = mcl_banners.color_reverse(banner_name)
					local layers = minetest.deserialize(layers_meta)
					local texture = mcl_banners.make_banner_texture(color, layers)
					new_shield_meta:set_string("description", mcl_banners.make_advanced_banner_description(itemstack:get_description(), layers))
					new_shield_meta:set_string("mcl_shields:shield_custom_pattern_texture", to_shield_texture(texture))
				end
				itemstack:set_wear(shield_stack:get_wear())
				break
			end
		end
	end
	return itemstack
end

minetest.register_craft_predict(function(itemstack, player, old_craft_grid, craft_inv)
	return craft_banner_on_shield(itemstack, player, old_craft_grid, craft_inv)
end)

minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
	return craft_banner_on_shield(itemstack, player, old_craft_grid, craft_inv)
end)

minetest.register_on_joinplayer(function(player)
	mcl_shields.players[player] = {
		shields = {},
		blocking = 0,
	}
	remove_shield_hud(player)
end)
