local dungeon_mt = {}
local dungeon = {}
local tile = require("tile")
local connection = require("connection")
local room = require("room")
local door = require("door")

-- CONSTRUCTEUR --
function dungeon.new(options)
	options = options or {}
	local self = setmetatable({}, {__index=dungeon_mt})
	
	self.data = {}
	self.xsize = options.xsize or 25
	self.ysize = options.ysize or 25
	self.w = self.xsize * 2 +1
	self.h = self.ysize * 2 +1
	self.rooms = {}
	self.exit = -1
	
	for i=1, self.w do
		for j=1, self.h do
			self:setTile(i, j, tile.new(tile.id.wall, 0))
		end
	end
	
	return self
end

-- place le joueur dans une piece --
function dungeon_mt:placePlayer(p)
	for i=1,self.xsize do
		for j=1,self.ysize do
			if d:getTile(i,j).id==tile.id.room then
				p.x = i
				p.y = j
				return
			end
		end
	end
end

-- genere les salles, place les chemins, raccorde les salles, supprime les cul-de-sac --
function dungeon_mt:generate()
	self:placeRooms(100)
	local group = -1
	for i=1,self.xsize do
		for j=1,self.ysize do
			self:maze(i*2, j*2, group)
			group = group -1
		end
	end
	self:makeConnections()
	local removed = true
	while removed do
		removed = false
		for i=2, self.w-1 do
			for j=2, self.h-1 do
				removed = removed or d:removeDead(i,j)
			end
		end
	end
end

-- trouve les endroits ou poser des portes et renvoi un tableau des cases possibles et de leur coordonnees --
function dungeon_mt:findCandidates()
	local candidates = {}
	
	local n_list = {
		{x = 1, y = 0},
		{x = -1, y = 0},
		{x = 0, y = 1},
		{x = 0, y = -1}
	}
	
	for i=2, self.w-1 do
		for j=2, self.h-1 do
			if self:getTile(i,j).id == tile.id.room then
				for _,v in ipairs(n_list) do
					if self:getTile(i+v.x,j+v.y).id == tile.id.wall and
					self:getTile(i+v.x*2,j+v.y*2).id ~= tile.id.wall then
						table.insert(candidates, {
							x = i+v.x,
							y = j+v.y,
							connects = {
								self:getTile(i,j).group,
								self:getTile(i+v.x*2,j+v.y*2).group
							}
						})
					end
				end
			end
		end
	end
	
	return candidates
	
end

-- melange le tableau --
local shuffle = function(array)
	local s_array = {}
	while #array>0 do
		local i = math.random(1, #array)
		table.insert(s_array, array[i])
		table.remove(array, i)
	end
	return s_array
end

-- place le chemin de façon aleatoire --
function dungeon_mt:maze(x,y, group)
	if self:getTile(x,y).id ~= tile.id.wall then
		return
	end
	self:setTile(x,y,tile.new(tile.id.floor, group))
	local n_list = {
		{x = 1, y = 0},
		{x = -1, y = 0},
		{x = 0, y = 1},
		{x = 0, y = -1}
	}
	
	n_list = shuffle(n_list)
	
	for _,v in ipairs(n_list) do
		local nx = (x+2*v.x) 
		local ny = (y+2*v.y)
		if nx>0 and nx<self.w 
		and ny>0 and ny<self.h 
		and self:getTile(nx,ny).id == tile.id.wall then
			self:setTile(x+v.x, y+v.y, tile.new(tile.id.floor, group))
			self:maze(nx,ny, group)
		end
	end
end

-- tente de placer des rooms dans le jeu --
function dungeon_mt:placeRooms(max_failed)
	local failed = 0
	local group = 1
	while failed < max_failed do
		local w = math.random(1,3)
		local h = math.random(1,3)
		local x = math.random(1, self.xsize-w)
		local y = math.random(1, self.ysize-h)
		local nope = false
		for i=x*2,x*2+w*2 do
			for j=y*2,y*2+h*2 do
				if self:getTile(i,j).id ~= tile.id.wall then
					nope = true
					break
				end
			end
			if nope then
				break
			end
		end
		if nope then
			failed = failed + 1
		else
			self:placeRoom(x*2, y*2, w*2, h*2, group)
			group = group + 1
		end		
	end
end

-- ajoute une room au jeu --
function dungeon_mt:placeRoom(x,y,w,h, group)
	local TheRoom = room.new(x,y,w,h)
	table.insert(self.rooms, TheRoom)
	for i=x,x+w do
		for j=y,y+h do
			self:setTile(i,j,tile.new(tile.id.room, group))
		end
	end
end
 
-- verifie qu'un objet est contenu dans un tableau --
local contains = function(array, content)
	for i,v in ipairs(array) do
		if v==content then
			return true
		end
	end
end

--cree des connections entre pieces et entre chemin et piece
-- recupere les cases possibles pour une porte, melange le tableau, place du sol si c'est possible --
function dungeon_mt:makeConnections ()
	local cands = self:findCandidates()
	local c = connection.new()
	cands = shuffle(cands)
	for _,v in ipairs(cands) do
		local c1 = v.connects[1]
		local c2 = v.connects[2]
		if not c:isConnected(c1, c2) then
			self:setTile(v.x, v.y, tile.new(tile.id.floor, 0))
			--self:setTile(v.x, v.y, tile.new(tile.id.candidate, 0))
			c:connect(c1,c2)
			table.insert(c.doors, v)
		end
	end
	for _,v in ipairs(c.doors) do
		
	end
end

-- recherche des voisins par rapport à une porte --
function dungeon_mt:makeNeighbors(X, Y, pX, pY)
	local tableVoisin = {}
	local n_list = {
		{x = 1, y = 0},
		{x = -1, y = 0},
		{x = 0, y = 1},
		{x = 0, y = -1}
	}
	for _,v in ipairs(n_list) do
		if v.x + X == pX and v.y + Y == pY then
		
		elseif self:getTile(X + v.x, Y + v.y).id == tile.id.floor then
		if not tableVoisin then
			print("tableVoisin est nil")
		end
			self:append(tableVoisin, self:makeNeighbors(X + v.x, Y + v.y, X, Y))
			
		elseif self:getTile(X + v.x, Y + v.y).id == tile.id.room then
			table.insert(tableVoisin, self:getTile(X + v.x, Y + v.y).group)
		end
	end
	return tableVoisin
end

-- ajoute le tableau arrayAdd dans le tableau array --
function dungeon_mt:append(array, arrayAdd)
	if array == nil then
		print("array est nil")
	end
	if not arrayAdd then
		print("arrayAdd est nil")
	end
	for i=1, #arrayAdd do
		table.insert(array, arrayAdd[i])
	end
end

function dungeon_mt:placeLockedDoors(p)
	self:getRooms(p)
	self:chooseExit(p)
end

-- creer les voisins pour chaque rooms--
function dungeon_mt:getRooms(p)
	for i=1, #self.rooms do
		-- le haut de la salle --
		for haut=self.rooms[i].x, self.rooms[i].x + self.rooms[i].w do
			if self:getTile(haut,self.rooms[i].y-1).id == tile.id.floor then
				self:append(self.rooms[i].neighbors, self:makeNeighbors(haut, self.rooms[i].y-1, haut, self.rooms[i].y))
			end
		end
		-- la droite de la salle --
		for droit=self.rooms[i].y, self.rooms[i].y + self.rooms[i].h do
			if self:getTile(self.rooms[i].x + self.rooms[i].w + 1 ,droit).id == tile.id.floor then
				self:append(self.rooms[i].neighbors, self:makeNeighbors(self.rooms[i].x + self.rooms[i].w + 1,droit, self.rooms[i].x, droit))
			end
		end
		-- le bas de la salle --
		for bas=self.rooms[i].x, self.rooms[i].x + self.rooms[i].w do
			if self:getTile(bas,self.rooms[i].y + self.rooms[i].h +1).id == tile.id.floor then
				self:append(self.rooms[i].neighbors, self:makeNeighbors(bas, self.rooms[i].y + self.rooms[i].h +1, bas, self.rooms[i].y))
			end
		end
		-- la gauche de la salle --
		for gauche=self.rooms[i].y, self.rooms[i].y + self.rooms[i].h do
			if self:getTile(self.rooms[i].x - 1 , gauche).id == tile.id.floor then
				self:append(self.rooms[i].neighbors, self:makeNeighbors(self.rooms[i].x - 1, gauche, self.rooms[i].x, gauche))
			end
		end
	end
end

function dungeon_mt:chooseExit(p)
	for i=1, #self.rooms do
		if #self.rooms[i].neighbors == 1 and self:getTile(self.rooms[i].x, self.rooms[i].y).group ~= self:getTile(p.x, p.y).group then
			self.exit = self:getTile(self.rooms[i].x, self.rooms[i].y).group
			print("exit:",self.exit)
			return
		end
	end
end

-- supprime les bouts de chemin isoles --
function dungeon_mt:removeDead(x,y)
	if self:getTile(x,y).id == tile.id.floor then
		local n_list = {
			{x = 1, y = 0},
			{x = -1, y = 0},
			{x = 0, y = 1},
			{x = 0, y = -1}
		}
		local walls = 0
		for i,v in ipairs(n_list) do
			if self:getTile(x+v.x, y+v.y).id == tile.id.wall then
				walls = walls + 1
			end
		end
		if walls >= 3 then
			self:setTile(x,y,tile.new(tile.id.wall, 0))
			for i,v in ipairs(n_list) do
				if self:getTile(x+v.x, y+v.y).id == tile.id.wall then
					self:removeDead(x+v.x, y+v.y)
				end
			end
			return true
		end
	end
end

-- place une tile dans le jeu -- 
function dungeon_mt:setTile(x, y, tile)
	x = ((x-1)%self.w)+1
	y = ((y-1)%self.h)+1
	self.data[ (x-1) + (y-1) * self.w + 1  ] = tile
end

-- recupere une tile avec ses coordonnees--
function dungeon_mt:getTile(x, y)
	x = ((x-1)%self.w)+1
	y = ((y-1)%self.h)+1
	return self.data[ (x-1) + (y-1) * self.w + 1  ] or tile.new(tile.id.wall, -1)
end

return dungeon