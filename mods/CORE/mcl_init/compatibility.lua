mcl_compatibility = {}

function vector.offset(v,x,y,z)
	return vector.add(v,{x=x,y=y,z=z})
end

local minetest_get_node = minetest.get_node

mcl_compatibility.sort_nodes = function(nodes)
	if not nodes then return {} end
	for _, pos in pairs(nodes) do
		if not pos.x or not pos.y or not pos.z then
			return nodes
		end
	end
	local new_nodes = {}
	for _, pos in pairs(nodes) do
		local node = minetest_get_node(pos)
		local name = node.name
		if not new_nodes[name] then
			new_nodes[name] = { pos }
		else
			table.insert(new_nodes[name], pos)
		end
	end
	return new_nodes
end

function mcl_vars.pos_to_block(pos)
	return mcl_mapgen and mcl_mapgen.pos_to_block(pos)
end

function mcl_vars.pos_to_chunk(pos)
	return mcl_mapgen and mcl_mapgen.pos_to_chunk(pos)
end

function mcl_vars.get_chunk_number(pos)
	return mcl_mapgen and get_chunk_number(pos)
end

function mcl_vars.is_generated(pos)
	local node = minetest.get_node(pos)
	if not node then return false end
	if node.name == "ignore" then return false end
	return true
end

function mcl_vars.get_node(p, force, us_timeout)
	if not p or not p.x or not p.y or not p.z then return {name="error"} end
	local node = minetest.get_node(p)
	if node.name ~= "ignore" then return node end
	minetest.get_voxel_manip():read_from_map(p, p)
	return minetest.get_node(pos)
end

mcl_vars.mg_overworld_min = -62
mcl_vars.mg_overworld_max_official = 198
mcl_vars.mg_bedrock_overworld_min = -62
mcl_vars.mg_bedrock_overworld_max = -58
mcl_vars.mg_lava_overworld_max = -52
mcl_vars.mg_lava = true
mcl_vars.mg_bedrock_is_rough = true
mcl_vars.mg_overworld_max = 30927
mcl_vars.mg_nether_min = -29067
mcl_vars.mg_nether_max = -28939
mcl_vars.mg_bedrock_nether_bottom_min = -29067
mcl_vars.mg_bedrock_nether_top_max = -29063
mcl_vars.mg_end_min = -27073
mcl_vars.mg_end_max_official = -26817
mcl_vars.mg_end_max = -2062
mcl_vars.mg_end_platform_pos = { x = 100, y = -26999, z = 0 }
mcl_vars.mg_realm_barrier_overworld_end_max = -2062
mcl_vars.mg_realm_barrier_overworld_end_min = -2073
mcl_vars.mg_dungeons = true

