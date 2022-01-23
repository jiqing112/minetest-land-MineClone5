function minetest.is_creative_enabled()
	return false
end

function vector.offset(v,x,y,z)
	return vector.add(v,{x=x,y=y,z=z})
end

--[[
minetest.register_on_joinplayer(function(ObjectRef, last_login)
	if not ObjectRef.set_moon then
		function ObjectRef.set_moon()
		end
	end
end)
]]
