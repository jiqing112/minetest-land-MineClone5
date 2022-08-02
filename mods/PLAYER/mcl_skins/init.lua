-- Skins for MineClone 5

local S = minetest.get_translator("mcl_skins")
local color_to_string = minetest.colorspec_to_colorstring

mcl_skins = {
	tab_names = {"base", "footwear", "eye", "mouth", "bottom", "top", "hair", "headwear"}, -- Rendering order
	tab_names_display_order = {"template", "base", "headwear", "hair", "eye", "mouth", "top", "arm", "bottom", "footwear"},
	tab_descriptions = {
		template = S("Templates"),
		arm = S("Arm size"),
		base = S("Bases"),
		footwear = S("Footwears"),
		eye = S("Eyes"),
		mouth = S("Mouths"),
		bottom = S("Bottoms"),
		top = S("Tops"),
		hair = S("Hairs"),
		headwear = S("Headwears")
	},
	steve = {}, -- Stores skin values for Steve skin
	alex = {}, -- Stores skin values for Alex skin
	base = {}, -- List of base textures
	
	-- Base color is separate to keep the number of junk nodes registered in check
	base_color = {0xffeeb592, 0xffb47a57, 0xff8d471d},
	color = {
		0xff613915, -- 1 Dark brown Steve hair, Alex bottom
		0xff97491b, -- 2 Medium brown
		0xffb17050, -- 3 Light brown
		0xffe2bc7b, -- 4 Beige
		0xff706662, -- 5 Gray
		0xff151515, -- 6 Black
		0xffc21c1c, -- 7 Red
		0xff178c32, -- 8 Green Alex top
		0xffae2ad3, -- 9 Plum
		0xffebe8e4, -- 10 White
		0xffe3dd26, -- 11 Yellow
		0xff449acc, -- 12 Light blue Steve top
		0xff124d87, -- 13 Dark blue Steve bottom
		0xfffc0eb3, -- 14 Pink
		0xffd0672a, -- 15 Orange Alex hair
	},
	footwear = {},
	mouth = {},
	eye = {},
	bottom = {},
	top = {},
	hair = {},
	headwear = {},
	masks = {},
	previews = {},
	players = {}
}

function mcl_skins.register_item(item)
	assert(mcl_skins[item.type], "Skin item type " .. item.type .. " does not exist.")
	local texture = item.texture or "blank.png"
	if item.steve then
		mcl_skins.steve[item.type] = texture
	end
	
	if item.alex then
		mcl_skins.alex[item.type] = texture
	end
	
	table.insert(mcl_skins[item.type], texture)
	mcl_skins.masks[texture] = item.mask
	if item.preview then mcl_skins.previews[texture] = item.preview end
end

function mcl_skins.save(player)
	if not player or not player:is_player() then return end
	local name = player:get_player_name()
	local skin = mcl_skins.players[name]
	if not skin then return end
	player:get_meta():set_string("mcl_skins:skin", minetest.serialize(skin))
end

minetest.register_chatcommand("skin", {
	description = S("Open skin configuration screen."),
	privs = {},
	func = function(name, param) mcl_skins.show_formspec(minetest.get_player_by_name(name)) end
})

function mcl_skins.make_hand_texture(base, colorspec)
	local output = ""
	if mcl_skins.masks[base] then
		output = mcl_skins.masks[base] ..
			"^[colorize:" .. color_to_string(colorspec) .. ":alpha"
	end
	if #output > 0 then output = output .. "^" end
	output = output .. base
	return output
end

function mcl_skins.compile_skin(skin)
	local output = ""
	for i, tab in pairs(mcl_skins.tab_names) do
		local texture = skin[tab]
		if texture and texture ~= "blank.png" then
			
			if skin[tab .. "_color"] and mcl_skins.masks[texture] then
				if #output > 0 then output = output .. "^" end
				local color = color_to_string(skin[tab .. "_color"])
				output = output ..
					"(" .. mcl_skins.masks[texture] .. "^[colorize:" .. color .. ":alpha)"
			end
			if #output > 0 then output = output .. "^" end
			output = output .. texture
		end
	end
	return output
end

function mcl_skins.update_player_skin(player)
	if not player then
		return
	end
	
	local skin = mcl_skins.players[player:get_player_name()]

	mcl_player.player_set_skin(player, mcl_skins.compile_skin(skin))
	
	local model = skin.slim_arms and "mcl_armor_character_female.b3d" or "mcl_armor_character.b3d"
	mcl_player.player_set_model(player, model)
	
	mcl_inventory.update_inventory_formspec(player)
	
	for i=1, #mcl_skins.registered_on_set_skins do
		mcl_skins.registered_on_set_skins[i](player)
	end
end

-- Load player skin on join
minetest.register_on_joinplayer(function(player)
	local function table_get_random(t)
		return t[math.random(#t)]
	end
	local name = player:get_player_name()
	local skin = player:get_meta():get_string("mcl_skins:skin")
	if skin then
		skin = minetest.deserialize(skin)
	end
	if skin then
		mcl_skins.players[name] = skin
	else
		if math.random() > 0.5 then
			skin = table.copy(mcl_skins.steve)
		else
			skin = table.copy(mcl_skins.alex)
		end
		mcl_skins.players[name] = skin
	end
	mcl_skins.save(player)
	mcl_skins.update_player_skin(player)
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	if name then
		mcl_skins.players[name] = nil
	end
end)

mcl_skins.registered_on_set_skins = {}

function mcl_skins.register_on_set_skin(func)
	table.insert(mcl_skins.registered_on_set_skins, func)
end

function mcl_skins.show_formspec(player, active_tab, page_num)
	active_tab = active_tab or "template"
	page_num = page_num or 1
	
	local page_count
	if page_num < 1 then page_num = 1 end
	if mcl_skins[active_tab] then
		page_count = math.ceil(#mcl_skins[active_tab] / 25)
		if page_num > page_count then
			page_num = page_count
		end
	else
		page_num = 1
		page_count = 1
	end
	
	local player_name = player:get_player_name()
	local skin = mcl_skins.players[player_name]
	local formspec = "formspec_version[3]" ..
		"size[13,10]"
	
	for i, tab in pairs(mcl_skins.tab_names_display_order) do
		if tab == active_tab then
			formspec = formspec ..
				"style[" .. tab .. ";bgcolor=green]"
		end
		
		local y = 0.3 + (i - 1) * 0.8
		formspec = formspec ..
			"button[0.3," .. y .. ";3,0.8;" .. tab .. ";" .. mcl_skins.tab_descriptions[tab] .. "]"
	end

	local mesh = skin.slim_arms and "mcl_armor_character_female.b3d" or "mcl_armor_character.b3d"
	
	formspec = formspec ..
		"model[9.5,0.3;3,7;player_mesh;" .. mesh .. ";" ..
		mcl_skins.compile_skin(skin) ..
		",blank.png,blank.png;0,180;false;true;0,0;0]"
	
	if mcl_skins[active_tab] then
		local textures = mcl_skins[active_tab]
		local page_start = (page_num - 1) * 25 + 1
		local page_end = math.min(page_start + 25 - 1, #textures)
		
		for j = page_start, page_end do
			local i = j - page_start + 1
			local texture = textures[j]
			local preview = ""
			if mcl_skins.previews[texture] then
				preview = mcl_skins.previews[texture]
				if skin[active_tab .. "_color"] then
					local color = minetest.colorspec_to_colorstring(skin[active_tab .. "_color"])
					preview = preview:gsub("{color}", color)
				end
			elseif active_tab == "base" then
				if mcl_skins.masks[texture] then
					preview = mcl_skins.masks[texture] .. "^[sheet:8x4:1,1" ..
						"^[colorize:" .. color_to_string(skin.base_color) .. ":alpha"
				end
				if #preview > 0 then preview = preview .. "^" end
				preview = preview .. "(" .. texture .. "^[sheet:8x4:1,1)"
			elseif active_tab == "mouth" or active_tab == "eye" then
				preview = texture .. "^[sheet:8x4:1,1"
			elseif active_tab == "headwear" then
				preview = texture .. "^[sheet:8x4:5,1^(" .. texture .. "^[sheet:8x4:1,1)"
			elseif active_tab == "hair" then
				if mcl_skins.masks[texture] then
					preview = mcl_skins.masks[texture] .. "^[sheet:8x4:1,1" ..
						"^[colorize:" .. color_to_string(skin.hair_color) .. ":alpha^(" ..
						texture .. "^[sheet:8x4:1,1)^(" ..
						mcl_skins.masks[texture] .. "^[sheet:8x4:5,1" ..
						"^[colorize:" .. color_to_string(skin.hair_color) .. ":alpha)" ..
						"^(" .. texture .. "^[sheet:8x4:5,1)"
				else
					preview = texture .. "^[sheet:8x4:5,1"
				end
			elseif active_tab == "top" then
				if mcl_skins.masks[texture] then
					preview = "[combine:12x12:-18,-20=" .. mcl_skins.masks[texture] ..
						"^[colorize:" .. color_to_string(skin.top_color) .. ":alpha"
				end
				if #preview > 0 then preview = preview .. "^" end
				preview = preview .. "[combine:12x12:-18,-20=" .. texture .. "^[mask:mcl_skins_top_preview_mask.png"
			elseif active_tab == "bottom" then
				if mcl_skins.masks[texture] then
					preview = "[combine:12x12:0,-20=" .. mcl_skins.masks[texture] ..
						"^[colorize:" .. color_to_string(skin.bottom_color) .. ":alpha"
				end
				if #preview > 0 then preview = preview .. "^" end
				preview = preview .. "[combine:12x12:0,-20=" .. texture .. "^[mask:mcl_skins_bottom_preview_mask.png"
			elseif active_tab == "footwear" then
				preview = "[combine:12x12:0,-20=" .. texture .. "^[mask:mcl_skins_bottom_preview_mask.png"
			end
			
			if skin[active_tab] == texture then
				preview = preview .. "^mcl_skins_select_overlay.png"
			end
			
			i = i - 1
			local x = 3.6 + i % 5 * 1.1
			local y = 0.3 + math.floor(i / 5) * 1.1
			formspec = formspec ..
				"image_button[" .. x .. "," .. y ..
				";1,1;" .. preview .. ";" .. texture .. ";]"
		end
	elseif active_tab == "arm" then
		local thick_overlay = not skin.slim_arms and "^mcl_skins_select_overlay.png" or ""
		local slim_overlay = skin.slim_arms and "^mcl_skins_select_overlay.png" or ""
		formspec = formspec ..
			"image_button[3.6,0.3;1,1;mcl_skins_thick_arms.png" .. thick_overlay ..";thick_arms;]" ..
			"image_button[4.7,0.3;1,1;mcl_skins_slim_arms.png" .. slim_overlay ..";slim_arms;]"
	
	elseif active_tab == "template" then
		formspec = formspec ..
			"model[4,2;2,3;player_mesh;" .. mesh .. ";" ..
			mcl_skins.compile_skin(mcl_skins.steve) ..
			",blank.png,blank.png;0,180;false;true;0,0;0]" ..

			"button[4,5.2;2,0.8;steve;" .. S("Select") .. "]" ..

			"model[6.5,2;2,3;player_mesh;" .. mesh .. ";" ..
			mcl_skins.compile_skin(mcl_skins.alex) ..
			",blank.png,blank.png;0,180;false;true;0,0;0]" ..
			
			"button[6.5,5.2;2,0.8;alex;" .. S("Select") .. "]"
			
	end
	
	if skin[active_tab .. "_color"] then
		local colors = mcl_skins.color
		if active_tab == "base" then colors = mcl_skins.base_color end
		
		local tab_color = active_tab .. "_color"
		
		for i, colorspec in pairs(colors) do
			local overlay = ""
			if skin[tab_color] == colorspec then
				overlay = "^mcl_skins_select_overlay.png"
			end
		
			local color = minetest.colorspec_to_colorstring(colorspec)
			i = i - 1
			local x = 3.6 + i % 8 * 1.1
			local y = 7 + math.floor(i / 8) * 1.1
			formspec = formspec ..
				"image_button[" .. x .. "," .. y ..
				";1,1;blank.png^[noalpha^[colorize:" ..
				color .. ":alpha" .. overlay .. ";" .. colorspec .. ";]"
		end
	end
	
	if page_num > 1 then
		formspec = formspec ..
			"image_button[3.6,5.8;1,1;mcl_skins_arrow.png^[transformFX;previous_page;]"
	end
	
	if page_num < page_count then
		formspec = formspec ..
			"image_button[8,5.8;1,1;mcl_skins_arrow.png;next_page;]"
	end
	
	if page_count > 1 then
		formspec = formspec ..
			"label[5.9,6.3;" .. page_num .. " / " .. page_count .. "]"
	end

	minetest.show_formspec(player_name, "mcl_skins:" .. active_tab .. "_" .. page_num, formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.__mcl_skins then
		mcl_skins.show_formspec(player)
		return false
	end

	if not formname:find("^mcl_skins:") then return false end
	local _, _, active_tab, page_num = formname:find("^mcl_skins:(%a+)_(%d+)")
	if not page_num or not active_tab then return true end
	page_num = math.floor(tonumber(page_num) or 1)
	local player_name = player:get_player_name()
	
	for field, value in pairs(fields) do
		if field == "quit" then
			mcl_skins.save(player)
			return true
		end
		
		if field == "alex" then
			mcl_skins.players[player_name] = table.copy(mcl_skins.alex)
			mcl_skins.update_player_skin(player)
			mcl_skins.show_formspec(player, active_tab, page_num)
			return true
		elseif field == "steve" then
			mcl_skins.players[player_name] = table.copy(mcl_skins.steve)
			mcl_skins.update_player_skin(player)
			mcl_skins.show_formspec(player, active_tab, page_num)
			return true
		end
		
		for i, tab in pairs(mcl_skins.tab_names_display_order) do
			if field == tab then
				mcl_skins.show_formspec(player, tab, page_num)
				return true
			end
		end
		
		local skin = mcl_skins.players[player_name]
		if not skin then return true end
		
		if field == "next_page" then
			page_num = page_num + 1
			mcl_skins.show_formspec(player, active_tab, page_num)
			return true
		elseif field == "previous_page" then
			page_num = page_num - 1
			mcl_skins.show_formspec(player, active_tab, page_num)
			return true
		end
		
		if active_tab == "arm" then
			if field == "thick_arms" then
				skin.slim_arms = false
			elseif field == "slim_arms" then
				skin.slim_arms = true
			end
			mcl_skins.update_player_skin(player)
			mcl_skins.show_formspec(player, active_tab, page_num)
			return true
		end
		
		-- See if field is a texture
		if mcl_skins[active_tab] then
			for i, texture in pairs(mcl_skins[active_tab]) do
				if texture == field then
					skin[active_tab] = texture
					mcl_skins.update_player_skin(player)
					mcl_skins.show_formspec(player, active_tab, page_num)
					return true
				end
			end
		end
		
		-- See if field is a color
		if skin[active_tab .. "_color"] then
			local color = math.floor(tonumber(field) or 0)
			if color and color >= 0 and color <= 0xffffffff then
				skin[active_tab .. "_color"] = color
				mcl_skins.update_player_skin(player)
				mcl_skins.show_formspec(player, active_tab, page_num)
				return true
			end
		end
	end

	return true
end)

local function init()
	local function file_exists(name)
		local f = io.open(name)
		if not f then
			return false
		end
		f:close()
		return true
	end
	mcl_skins.modpath = minetest.get_modpath("mcl_skins")

	local f = io.open(mcl_skins.modpath .. "/list.json")
	assert(f, "Can't open the file list.json")
	local data = f:read("*all")
	assert(data, "Can't read data from list.json")
	local json, error = minetest.parse_json(data)
	assert(json, error)
	f:close()
	
	for _, item in pairs(json) do
		mcl_skins.register_item(item)
	end
	mcl_skins.steve.base_color = mcl_skins.base_color[1]
	mcl_skins.steve.hair_color = mcl_skins.color[1]
	mcl_skins.steve.top_color = mcl_skins.color[12]
	mcl_skins.steve.bottom_color = mcl_skins.color[13]
	mcl_skins.steve.slim_arms = false
	
	mcl_skins.alex.base_color = mcl_skins.base_color[1]
	mcl_skins.alex.hair_color = mcl_skins.color[15]
	mcl_skins.alex.top_color = mcl_skins.color[8]
	mcl_skins.alex.bottom_color = mcl_skins.color[1]
	mcl_skins.alex.slim_arms = true
	
	mcl_skins.previews["blank.png"] = "blank.png"
end

init()
