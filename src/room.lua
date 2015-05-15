local room_mt = {}
local room = {}



function room.new(id,doors,neighbors,dimensions)
	local self = setmetatable({},{__index=room_mt})
	self.id = id
	self.doors = doors
	self.neighbors = neighbors
	self.dimensions = dimensions
	self.NPC = nil
	return self
end

function room_mt:toString()
	print("doooooooooors :")
	for _,v in ipairs(self.doors) do
		print("\n\tX = "..v.x.." \n\tY = "..v.y)
	end
	print("\nneighbors : "..table.getn(self.neighbors))
	for _,k in ipairs(self.neighbors) do
		print("\n\tid = "..k.id.." \n\tlength = "..k.length)
	end
	print("\ndimensions :")
	print("\n\tX = "..self.dimensions.X.." \n\tY = "..self.dimensions.Y.." \n\tW = "..self.dimensions.width.." \n\tH = "..self.dimensions.height)
	

end

return room