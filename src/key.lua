local key_mt = {}
local key = {}

function key.new(x, y, group)
	self = setmetatable({}, {__index = key_mt})
	
	self.x = x or 0
	self.y = y or 0
	self.group = group or ""
	self.picked = false
	
	return self
end



return key