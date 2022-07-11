local get_item_group = minetest.get_item_group

<<<<<<< HEAD
=======
mcl_wieldview = {
	players = {}
}

function mcl_wieldview.get_item_texture(itemname)
	if itemname == "" or minetest.get_item_group(itemname, "no_wieldview") ~= 0 then
		return
	end

	local def = minetest.registered_items[itemname]
	if not def then
		return
	end

	local inv_image = def.inventory_image
	if inv_image == "" then
		return
	end

	local texture = inv_image

	local transform = get_item_group(itemname, "wieldview_transform")
	if transform then
		-- This actually works with groups ratings because transform1, transform2, etc.
		-- have meaning and transform0 is used for identidy, so it can be ignored
		texture = texture .. "^[transform" .. transform
	end

	return texture
end

function mcl_wieldview.update_wielded_item(player)
	if not player then
		return
	end
	local itemstack = player:get_wielded_item()
	local itemname = itemstack:get_name()

	local def = mcl_wieldview.players[player]

	if def.item == itemname then
		return
	end

	def.item = itemname
	def.texture = mcl_wieldview.get_item_texture(itemname) or "blank.png"

	mcl_player.player_set_wielditem(player, def.texture)
end

>>>>>>> mcl2/master
minetest.register_on_joinplayer(function(player)
	if not player or not player:is_player() then
		return
	end
	local itementity = minetest.add_entity(player:get_pos(), "mcl_wieldview:wieldnode")
	if not itementity then return end
	itementity:set_attach(player, "Wield_Item", vector.new(0, 0, 0), vector.new(0, 0, 0))
	--itementity:set_attach(player, "Hand_Right", vector.new(0, 1, 0), vector.new(90, 45, 90))
	itementity:get_luaentity()._wielder = player
end)

minetest.register_entity("mcl_wieldview:wieldnode", {
	visual = "wielditem",
	physical = false,
	pointable = false,
	collide_with_objects = false,
	static_save = false,
	visual_size  = {x = 0.21, y = 0.21},
	on_step = function(self)
<<<<<<< HEAD
		if not self._wielder or not self._wielder:is_player() then
=======
		if self.wielder:is_player() then
			local def = mcl_wieldview.players[self.wielder]
			local itemstring = def.item

			if self.itemstring ~= itemstring then
				local itemdef = minetest.registered_items[itemstring]
				self.object:set_properties({glow = itemdef and itemdef.light_source or 0})

				-- wield item as cubic
				if def.texture == "blank.png" then
					self.object:set_properties({textures = {itemstring}})
				-- wield item as flat
				else
					self.object:set_properties({textures = {""}})
				end

				if minetest.get_item_group(itemstring, "no_wieldview") ~= 0 then
					self.object:set_properties({textures = {""}})
				end

				self.itemstring = itemstring
			end
		else
>>>>>>> mcl2/master
			self.object:remove()
		end
		local player = self._wielder
		
		local item = player:get_wielded_item():get_name()

		if item == self._item then return end
		
		self._item = item
		
		if get_item_group(item, "no_wieldview") ~= 0 then
			local def = player:get_wielded_item():get_definition()
			if def and def._wieldview_item then
				item = def._wieldview_item
			else
				item = ""
			end
		end
		
		local item_def = minetest.registered_items[item]
		self.object:set_properties({
			glow = item_def and item_def.light_source or 0,
			wield_item = item,
			is_visible = item ~= ""
		})
	end,
})
