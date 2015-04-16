local tile_mt = {}
local tile = {}

tile.id = {
	wall = 1,
	floor = 0,
	room = 2,
	candidate = 3
}

function tile.new( id, group )
	local self = setmetatable({},{__index=tile_mt})
	self.id = id or tile.id.wall
	self.group = group

	return self
end

return tile