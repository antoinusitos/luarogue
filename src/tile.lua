local tile_mt = {}
local tile = {}

tile.id = {
	floor = 0,
	wall = 1,
	room = 2,
	candidate = 3,
	lock = 4,
	hidden = 5
}

function tile.new( id, group )
	local self = setmetatable({},{__index=tile_mt})
	self.id = id or tile.id.wall
	self.group = group

	return self
end

return tile