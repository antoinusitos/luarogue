local player_mt = {}
local player = {}

function player.new()
	self = setmetatable({}, {__index = player_mt})
	
	self.x = 10
	self.y = 10
	self.name = "pd"
	self.speed = 10
	
	self.keys = 1
	
	return self
end



return player
