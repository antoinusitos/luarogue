local NPC_mt = {}
local NPC = {}
local enemy_mt = setmetatable({},{__index = NPC_mt})
local friendly_mt = setmetatable({},{__index = NPC_mt})

NPC_mt.name = "Flan"
NPC_mt.x = 0
NPC_mt.y = 0
NPC_mt.speed = 0

NPC.id = {
	ClapFlan = 2,
	R2DFlan = 1,
	DarkFlandor = -1,
	DarkFlaul = -2
}

NPC.img = {
	ClapFlan = "image/clapflan.png",
	R2DFlan = "image/R2DFLAN.png",
	DarkFlandor = "image/darkflandor.png",
	DarkFlaul = "image/darkflaul.png"
}

function NPC.new(id)
	local self = setmetatable({},{__index=NPC_mt})
	self.x = 0
	self.y = 0
	self.hide = true
	if id < 0 then
		self = newEnemy(id);
	else
		self = newFriendly(id);
	end

	return self
end

function newEnemy(id)
	local self = setmetatable({},{__index = enemy_mt})
	if id == -1 then
		self.img = love.graphics.newImage(NPC.img.DarkFlandor)
	else
		self.img = love.graphics.newImage(NPC.img.DarkFlaul)
	end
	self.id = id
	return self
end
function newFriendly(id)
	local self = setmetatable({},{__index = friendly_mt})
	if id == 1 then
		self.img = love.graphics.newImage(NPC.img.R2DFlan)
	else
		self.img = love.graphics.newImage(NPC.img.ClapFlan)
	end
	self.id = id
	return self
end

return NPC