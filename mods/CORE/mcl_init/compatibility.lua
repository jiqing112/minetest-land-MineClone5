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
