local room_mt = {}
local room = {}

function room.new(TheX, TheY, TheW, TheH)

	self = setmetatable({}, {__index = room_mt})

	self.x = TheX
	self.y = TheY
	self.w = TheW
	self.h = TheH
	self.group = -100
	self.neighbors = {}
	
	return self
end

return room