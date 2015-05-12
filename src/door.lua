local door_mt = {}
local door = {}

function door.new(TheID, TheIDKey)

	self = setmetatable({}, {__index = door_mt})

	self.id = TheID or -1
	self.idKey = TheIDKey or -1

	return self
end

return door