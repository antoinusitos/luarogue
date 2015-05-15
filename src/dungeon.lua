local dungeon_mt = {}
local dungeon = {}
local tile = require("tile")
local connection = require("connection")
local useful = require("useful")

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

-- CONSTRUCTEUR --
function dungeon.new(options)
	options = options or {}
	local self = setmetatable({}, {__index=dungeon_mt})
	
	self.data = {}
	self.xsize = options.xsize or 10
	self.ysize = options.ysize or 10
	self.w = self.xsize * 2 +1
	self.h = self.ysize * 2 +1
	self.rooms = {}
	self.doorsToPlace = 3
	self.TotalDoor = self.doorsToPlace
	self.groups = {A={}, B={}, C={}, D={}}
	self.playerRoom = 1
	self.keys = {{x = 0, y = 0, picked = false, group = "A"}, {x = 0, y = 0, picked = false, group = "B"},{x = 0, y = 0, picked = false, group = "C"}}
	
	for i=1, self.w do
		for j=1, self.h do
			self:setTile(i, j, tile.new(tile.id.wall, 0))
		end
	end
	
	return self
end

-- Applique une fonction "cb" à un ensemble de cases en rectangle
function dungeon_mt:mapRect(cb, x, y, w, h)
	local x = x or 1
	local y = y or 1
	local w = w or self.xsize-(x-1)
	local h = h or self.ysize-(y-1)
	for i=x,x+w do
		for j=y,y+h do
			cb(self:getTile(i,j),i,j)
		end
	end
end

-- place les clés dans les salles du groupe correspondant --
function dungeon_mt:placeKeys(G, R, W)

	local rand = math.random() * #self.groups.A + 1
	rand = math.floor(rand)
	print(rand)
	local x = self.groups.A[rand].dimensions.x + math.floor(math.random() * self.groups.A[rand].dimensions.w)
	local y = self.groups.A[rand].dimensions.y + math.floor(math.random() * self.groups.A[rand].dimensions.h)
	W.x = x
	W.y = y
	W.group = "A"

	rand = math.random() * #self.groups.B + 1
	rand = math.floor(rand)
	print(rand)
	x = self.groups.B[rand].dimensions.x + math.floor(math.random() * self.groups.B[rand].dimensions.w)
	y = self.groups.B[rand].dimensions.y + math.floor(math.random() * self.groups.B[rand].dimensions.h)
	R.x = x
	R.y = y
	R.group = "B"

	rand = math.random() * #self.groups.C + 1
	rand = math.floor(rand)
	print(rand)
	x = self.groups.C[rand].dimensions.x + math.floor(math.random() * self.groups.C[rand].dimensions.w)
	y = self.groups.C[rand].dimensions.y + math.floor(math.random() * self.groups.C[rand].dimensions.h)
	G.x = x
	G.y = y
	G.group = "C"

	
end

-- recherches les porte d'une salle --
function dungeon_mt:searchDoors(theRoom)
	local index = 1
	self:mapRect(function(t, i, j)
		if t.id==tile.id.floor then
			table.insert(theRoom.doors, {index = index, x = i, y = j})
			index = index + 1
		end
	end, theRoom.dimensions.x-1, theRoom.dimensions.y-1, theRoom.dimensions.w+1, theRoom.dimensions.h+1)

end

function dungeon_mt:getRoomByGroup(theGroup)
	for i= 1, #self.rooms do
		if i == theGroup then
			return self.rooms[i]
		end
	end
	error("cannot find room:"..theGroup)
end

function dungeon_mt:getRoomByDoor(theDoor)
	for i= 1, #self.rooms do
		if i == theGroup then
			return self.rooms[i]
		end
	end
end

function dungeon_mt:contains(array, value)
	for i= 1, #array do
		if array[i].group == value.group then
			return true
		end
	end
	return false
end

-- trouve le neighbors de la room --
function dungeon_mt:findNeighborByRoom(TheRoom, TheSearchedRoom)
	for i= 1, #TheRoom.neighbors do
		if TheRoom.neighbors[i].group == TheSearchedRoom.group then
			return TheRoom.neighbors[i]
		end
	end
end

-- parcours en profondeur entre la porte et le joueur --
function dungeon_mt:findThePath(theLastRoom, theRoom, theVisitedRoom)
	if theRoom.group == theLastRoom.group then

		return
	elseif self:contains(theVisitedRoom, theRoom) then
		return
	elseif self:contains(self.groups.A, theRoom) then
		table.insert(theVisitedRoom, theRoom)

		for i= 1, #theRoom.neighbors do
			if theRoom.neighbors[i].group == theLastRoom.group then
				local door = theLastRoom.doors[self:findNeighborByRoom(theLastRoom, theRoom).index]
				if self:getTile(door.x, door.y).id ~= tile.id.lock then
					self:setTile(door.x, door.y, tile.new(tile.id.lock, (self.TotalDoor+1 - self.doorsToPlace)*1000))
					print((self.TotalDoor+1 - self.doorsToPlace)*1000)
					
				end
			end
			self:findThePath(theLastRoom, self:getRoomByGroup(theRoom.neighbors[i].group), theVisitedRoom)
		end
	end
end

--deplace les rooms du groupe A dans le groupe vide si elle ne sont pas visitee --
function dungeon_mt:invertMoveRooms(theVisitedRoom)
	local theGroup = nil
	if #self.groups.D == 0 then
		theGroup = self.groups.D
	elseif #self.groups.C == 0 then
		theGroup = self.groups.C
	elseif #self.groups.B == 0 then
		theGroup = self.groups.B
	end

	if theGroup ~= nil then
		local aSupprimer = {}
		for i = 1, #self.groups.A do

			if not self:contains(theVisitedRoom, self:getRoomByGroup(self.groups.A[i].group)) then
				table.insert(theGroup, self.groups.A[i])
				table.insert(aSupprimer, self.groups.A[i].group)
				--table.remove(self.groups.A, self:getIndexByGroup(self.groups.A[i].group))
			end
		end
		for i = 1, #aSupprimer do
			table.remove(self.groups.A, self:getIndexByGroup(aSupprimer[i]))
		end
	end

end

-- recupere l'index en fonction du groupe --
function dungeon_mt:getIndexByGroup(theGroup)
	for i = 1, #self.groups.A do
		if self.groups.A[i].group == theGroup then
			return i
		end
	end
end

-- place une porte dans le niveau --
function dungeon_mt:placeDoor()
	local visitedRoom = {}
	while(#visitedRoom < self.doorsToPlace + 2) do
		local random = math.random(1, #self.rooms)
		while not self:contains(self.groups.A, self:getRoomByGroup(random)) do
			random = math.random(1, #self.rooms)
		end
		local lastRoom = self.groups.A[self:getIndexByGroup(random)]
		local room = self:getRoomByGroup(self.playerRoom)
		self:findThePath(lastRoom, room, visitedRoom)
	end
	self:invertMoveRooms(visitedRoom)
	self.doorsToPlace = self.doorsToPlace - 1
	--self:printRoomsGroup(self.groups.A)
end

-- recherches les voisins d'une salle --
function dungeon_mt:searchNeighbors(theRoom, indexRoom)
	local neighbors = {}
	for i=1, #theRoom.doors do
		self:append(neighbors, self:makeNeighbors(theRoom.doors[i].x, theRoom.doors[i].y, theRoom.doors[i].x, theRoom.doors[i].y, theRoom.doors[i], indexRoom))
	end
	return neighbors
end

function dungeon_mt:getRoom(group)
	return self.rooms[group]
end

-- recherche des voisins par rapport à une porte --
function dungeon_mt:makeNeighbors(X, Y, pX, pY, theDoor, theID, longueur)
	local longueur = longueur or 1
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
			if tableVoisin then
				longueur = longueur + 1
				self:append(tableVoisin, self:makeNeighbors(X + v.x, Y + v.y, X, Y, theDoor, theID, longueur))
			end
		elseif self:getTile(X + v.x, Y + v.y).id == tile.id.room and self:getTile(X + v.x, Y + v.y).group ~= theID then
			table.insert(tableVoisin, {group = self:getTile(X + v.x, Y + v.y).group, index = theDoor.index, length = longueur})
		end
	end
	return tableVoisin
end

-- ajoute le tableau arrayAdd dans le tableau array --
function dungeon_mt:append(array, arrayAdd)
	for i=1, #arrayAdd do
		table.insert(array, arrayAdd[i])
	end
end

-- print un array --
function dungeon_mt:printTable(array)
	if type(array[1]) == "table" then
		for i=1, #array do
			self:printTable(array[i])
		end
	else
		for i=1, #array do
			print(array[i])
		end
	end
end

-- print le gorupe des salles --
function dungeon_mt:printRoomsGroup(array)
	for i=1, #array do
		print(array[i].group)
	end
end

-- print les rooms --
function dungeon_mt:printRoom(theRoom, IDRoom)
	print("salle:", IDRoom)
	print("door")
	self:printTable(theRoom.doors)
	print("neighbors")
	self:printTable(theRoom.neighbors)
	print("dimensions")
	self:printTable(theRoom.dimensions)
	print("END ROOM")
end

-- place le joueur dans une piece --
function dungeon_mt:placePlayer(p)
	local room = self:getRoomByGroup(self.playerRoom)
	p.x = room.dimensions.x
	p.y = room.dimensions.y
end

-- genere les salles, place les chemins, raccorde les salles, supprime les cul-de-sac --
function dungeon_mt:generate()
	self:placeRooms(10)
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
				removed = removed or self:removeDead(i,j)
			end
		end
	end

	for i= 1, #self.rooms do
		self:searchDoors(self.rooms[i])
		self.rooms[i].neighbors = self:searchNeighbors(self.rooms[i], i)
		--self:printRoom(self.rooms[i], i)
	end
	for i= 1, #self.rooms do
		table.insert(self.groups.A, i, self.rooms[i])
	end
	--useful.printPretty(self.rooms)
	--useful.printPretty(self.groups)
	while self.doorsToPlace > 0 do
		self:placeDoor()
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
	table.insert(self.rooms, group, {group = group, doors = {}, neighbors = {}, dimensions = {x = x, y = y, w = w+1, h = h+1}})
	self:mapRect(function(t,i,j)
			self:setTile(i,j,tile.new(tile.id.room, group))
	end,x,y,w,h)
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
		end
	end
end

-- verouille une porte dans le niveau --
function dungeon_mt:lockDoors()
	local doors = {}
	for i=1,self.xsize do
		for j=1,self.ysize do
			if self:getTile(i,j).id==tile.id.candidate then
				table.insert(doors, self:getTile(i,j))
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