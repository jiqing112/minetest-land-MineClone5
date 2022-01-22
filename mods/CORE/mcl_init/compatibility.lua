function minetest.is_creative_enabled()
	return false
end

function vector.offset(v,x,y,z)
	return vector.add(v,{x=x,y=y,z=z})
end
