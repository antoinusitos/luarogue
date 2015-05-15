local dungeon_mt = {}
local dungeon = {}
local tile = require("tile")
local connection = require("connection")
local room = require("room")

-- CONSTRUCTEUR --
function dungeon.new(options)
	options = options or {}
	local self = setmetatable({}, {__index=dungeon_mt})
	
	self.data = {}
	self.xsize = options.xsize or 25
	self.ysize = options.ysize or 25
	self.w = self.xsize * 2 +1
	self.h = self.ysize * 2 +1
	self.roomList = {}
	self.secretRooms = {}
	
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

-- place les npcs dans les pieces cachées --
function dungeon_mt:placeNPC(tabOfNPC)
	for i,salle in ipairs(self.secretRooms) do
		tabOfNPC[i].x = salle.dimensions.X+math.floor(math.random()*salle.dimensions.width)
		tabOfNPC[i].y = salle.dimensions.Y+math.floor(math.random()*salle.dimensions.height)
		salle.NPC = tabOfNPC[i]
	end
	return tabOfNPC
end

local append = function(array1, array2)

	local newArray = {}
	for _,v in ipairs(array1) do
		table.insert(newArray,v)
	end
	for _,t in ipairs(array2) do
		table.insert(newArray,t)
	end
	return newArray
end

-- genere les salles, place les chemins, raccorde les salles, supprime les cul-de-sac --
function dungeon_mt:generate()
	self:placeRooms(1994)
	-- les salles sont placées
	local n_list = {
		{x = 1, y = 0},
		{x = -1, y = 0},
		{x = 0, y = 1},
		{x = 0, y = -1}
	}
	local group = -1
	for i=1,self.xsize do
		for j=1,self.ysize do
			self:maze(i*2, j*2, group)
			group = group -1
		end
	end
	-- les morceaux de labyrinthe sont générés
	local removed = true
	
	self:makeConnections()
	-- les connections sont makées
	
	-- c'est tout propre !
	while removed do
		removed = false
		for i=2, self.w-1 do
			for j=2, self.h-1 do
				removed = removed or d:removeDead(i,j)
			end
		end
	end
	
	self:getDoors()
	--print("taille de la liste des salles : "..table.getn(self.roomList))
	for _,salle in ipairs(self.roomList) do
		if not salle.neighbors then
			salle.neighbors = {}
		end
		--print("je cherche dans une salle "..v.id)
		for _,porte in ipairs(salle.doors) do
			for _,direction in ipairs(n_list) do
				if(self:getTile(porte.x+direction.x,porte.y+direction.y).group == salle.id) then
					salle.neighbors = append(salle.neighbors,self:getNeighbors(porte.x,porte.y,porte.x+direction.x,porte.y+direction.y,0))
				end
			end
		end
	end

	--for _,o in ipairs(self.roomList) do
		--o:toString()
	--end

	self:hideRoom()
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
	table.insert(self.roomList,room.new(group,{},{},{
		X=x,
		Y=y,
		width = w,
		height = h
	}))
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
			self:setTile(v.x, v.y, tile.new(tile.id.candidate, 0))
			c:connect(c1,c2)
		end
	end
end

-- verouille une porte dans le niveau --
function dungeon_mt:lockDoors()
	local doors = {}
	for i=1,self.xsize do
		for j=1,self.ysize do
			if d:getTile(i,j).id==tile.id.candidate then
				table.insert(doors, d:getTile(i,j))
			end
		end
	end
	doors = shuffle(doors)
	for _,v in ipairs(doors) do
		v.id = tile.id.lock
	end
end

-- supprime les bouts de chemin isoles --
function dungeon_mt:removeDead(x,y)
	if self:getTile(x,y).id == tile.id.floor or self:getTile(x,y).id == tile.id.candidate then
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

-- (je) flante les rooms qui sont toutes seules --
function dungeon_mt:hideRoom()
	
	for _,salle in ipairs(self.roomList) do
		if table.getn(salle.neighbors) == 1 then
			local voisin = salle.neighbors[1]
			if voisin.length == 1 then
				local x = salle.dimensions.X
				local y = salle.dimensions.Y
				local w = salle.dimensions.width
				local h = salle.dimensions.height
				table.insert(self.secretRooms,salle)
				for i=x, x+w do
					for j=y, y+h do
						self:setTile(i,j,tile.new(tile.id.hidden, salle.id))
					end
				end
				self:setTile(salle.doors[1].x,salle.doors[1].y,tile.new(tile.id.hidden, salle.id))
			end
		end
	end
end

function dungeon_mt:unHidden(id)
	for _,salle in ipairs(self.roomList) do
		if salle.id == id then
			local x = salle.dimensions.X
			local y = salle.dimensions.Y
			local w = salle.dimensions.width
			local h = salle.dimensions.height
			for i=x, x+w do
				for j=y, y+h do
					self:setTile(i,j,tile.new(tile.id.room, salle.id))
				end
			end
			salle.NPC.hide = false
			self:setTile(salle.doors[1].x,salle.doors[1].y,tile.new(tile.id.floor, salle.id))
		end
	end
end

function dungeon_mt:getDoors()
	
	local n_list = {
		{x = 1, y = 0},
		{x = -1, y = 0},
		{x = 0, y = 1},
		{x = 0, y = -1}
	}
	--print(" lol "..table.getn(self.roomList))
	for _,k in ipairs(self.roomList) do
		local x = k.dimensions.X
		local y = k.dimensions.Y
		local w = k.dimensions.width
		local h = k.dimensions.height
		local nbConnection = 0
		local nbCandidate = 0
		for i=x, x+w do
			for j=y, y+h do
				if self:getTile(i,j).id == tile.id.room then
					for _,v in ipairs(n_list) do
						if self:getTile(i+v.x,j+v.y).id == tile.id.candidate and
						self:getTile(i+v.x*2,j+v.y*2).id == tile.id.room then
							nbConnection = nbConnection + 1
						end
						if self:getTile(i+v.x,j+v.y).id == tile.id.candidate then
							nbCandidate = nbCandidate +1
							table.insert(k.doors,{x=i+v.x,y=j+v.y})
						end
					end
					
				end
			end
		end
	end
end


function dungeon_mt:getNeighbors(x1,y1,px,py,length)
	--print("debut fonction lol")
	local dist = length+1
	local X = x1
	local Y = y1

	local n_list = {
		{x = 1, y = 0},
		{x = -1, y = 0},
		{x = 0, y = 1},
		{x = 0, y = -1}
	}
	local neighborsList = {}
	for _,v in ipairs(n_list) do
		if X+v.x == px and Y+v.y == py then
			
		elseif self:getTile(X+v.x,Y+v.y).id == tile.id.floor or self:getTile(X+v.x,Y+v.y).id == tile.id.candidate then
			local gn = self:getNeighbors(X+v.x,Y+v.y,X,Y,dist)
			if #gn>0 then
				neighborsList = append(neighborsList,gn)
			end
			for _,k in ipairs(neighborsList) do
				k.length = k.length + 1
			end
		elseif self:getTile(X+v.x,Y+v.y).id == tile.id.room then
			table.insert(neighborsList,{id = self:getTile(X+v.x,Y+v.y).group,door = "lol",length = dist})
		end
	end
	return neighborsList
end

return dungeon