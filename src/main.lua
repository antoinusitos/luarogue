function love.load(args)
	math.randomseed(os.time())
	dungeon = require("dungeon")
	tile = require("tile")
	thePlayer = require("player")
	theKey = require("key")
	tileSize = 20
	d = dungeon.new()
	
	
	key_Green = theKey.new()
	key_Green.img = love.graphics.newImage("image/key_green.png")
	key_Red = theKey.new()
	key_Red.img = love.graphics.newImage("image/key_red.png")
	key_White = theKey.new()
	key_White.img = love.graphics.newImage("image/key_white.png")

	player = thePlayer.new()
	player.img = love.graphics.newImage("image/kingflanyoda.png")
	
	love.generate()
end

function love.update(dt)
end

function love.generate()
	d:generate()
	d:placePlayer(player)
	d:placeKeys(key_Green, key_Red, key_White)
end

function love.draw()
	---[[
	for i=1,d.w do
		for j=1,d.h do
			if d:getTile(i,j).id==tile.id.floor then
				love.graphics.setColor(64, 50, 255)
			elseif d:getTile(i,j).id==tile.id.wall then
				love.graphics.setColor(160, 160, 54)
			elseif d:getTile(i,j).id==tile.id.candidate then
				love.graphics.setColor(255, 255,255)
			elseif d:getTile(i,j).id==tile.id.lock then
				if d:getTile(i,j).group == 1000 then
					love.graphics.setColor(0, 255, 0)
				elseif d:getTile(i,j).group == 2000 then
					love.graphics.setColor(255, 0, 0)
				elseif d:getTile(i,j).group == 3000 then
					love.graphics.setColor(255, 255, 255)
				end
			else
				love.graphics.setColor(255, 160, 154)
			end
			love.graphics.rectangle("fill", i*tileSize, j*tileSize, tileSize, tileSize)
			love.graphics.setColor(0, 0, 0)
			love.graphics.print(d:getTile(i,j).group, i*tileSize, j*tileSize)
		end
	end
	--]]
	--[[
	for i=1, #d.rooms do
		love.graphics.setColor(0, 255, 0)
		love.graphics.circle("fill", (d.rooms[i].dimensions.x + d.rooms[i].dimensions.w /2) * tileSize, (d.rooms[i].dimensions.y + d.rooms[i].dimensions.h /2) * tileSize,
		 ((d.rooms[i].dimensions.h+d.rooms[i].dimensions.w) /2) * tileSize/2)
	end
	for i=1, #d.rooms do
		for j=1, #d.rooms[i].neighbors do
			local theRoom = d:getRoom(d.rooms[i].neighbors[j].group)
			love.graphics.setColor(255, 0, 0)
			love.graphics.line((d.rooms[i].dimensions.x + d.rooms[i].dimensions.w /2) * tileSize, (d.rooms[i].dimensions.y + d.rooms[i].dimensions.h /2) * tileSize,
								(theRoom.dimensions.x + theRoom.dimensions.w /2) * tileSize, (theRoom.dimensions.y + theRoom.dimensions.h /2) * tileSize)
		end
	end
	--]]
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(player.img, player.x*tileSize, player.y*tileSize)
	if not key_Green.picked then
		love.graphics.draw(key_Green.img, key_Green.x*tileSize, key_Green.y*tileSize)
	end
	if not key_Red.picked then
		love.graphics.draw(key_Red.img, key_Red.x*tileSize, key_Red.y*tileSize)
	end
	if not key_White.picked then
		love.graphics.draw(key_White.img, key_White.x*tileSize, key_White.y*tileSize)
	end
end

function haveTheKey(theDoor)
	print("have the key :", theDoor.group)
	if theDoor.group == 3000 then
		print("have the key white")
		return key_White.picked
	elseif theDoor.group == 2000 then
		return key_Red.picked
	elseif theDoor.group == 1000 then
		return key_Green.picked
	end
end

function isOnKey()
	if player.x == key_White.x and player.y == key_White.y then
		key_White.picked = true
		print("key white picked up")
	elseif player.x == key_Green.x and player.y == key_Green.y then
		key_Green.picked = true
	elseif player.x == key_Red.x and player.y == key_Red.y then
		key_Red.picked = true
	end

end

function love.keypressed(key)
	if key == "escape" then
		love.event.push("quit")
	elseif key == " " then
		love.generate()
	elseif key == "r" then
		print(player.x)
		print(player.y)
		print(d:getTile(player.x,player.y).id)
	elseif key == "left" then
		if d:getTile(player.x - 1,player.y).id ~= tile.id.wall and d:getTile(player.x - 1,player.y).id ~= tile.id.lock then
			player.x = player.x - 1
			isOnKey()
		elseif d:getTile(player.x - 1,player.y).id == tile.id.lock and haveTheKey(d:getTile(player.x - 1,player.y)) then
			d:setTile(player.x - 1,player.y, tile.new(tile.id.floor, 0))
			player.x = player.x - 1
		end
	elseif key == "right" then
		if d:getTile(player.x + 1,player.y).id ~= tile.id.wall and d:getTile(player.x + 1,player.y).id ~= tile.id.lock then
			player.x = player.x + 1
			isOnKey()
		elseif d:getTile(player.x + 1,player.y).id == tile.id.lock and haveTheKey(d:getTile(player.x + 1,player.y)) then
			d:setTile(player.x + 1,player.y, tile.new(tile.id.floor, 0))
			player.x = player.x + 1
		end
	elseif key == "up" then
		if d:getTile(player.x ,player.y - 1).id ~= tile.id.wall and d:getTile(player.x ,player.y - 1).id ~= tile.id.lock then
			player.y = player.y - 1
			isOnKey()
		elseif d:getTile(player.x ,player.y - 1).id == tile.id.lock and haveTheKey(d:getTile(player.x ,player.y - 1)) then
			d:setTile(player.x ,player.y - 1, tile.new(tile.id.floor, 0))
			player.y = player.y - 1
		end	
	elseif key == "down" then
		if d:getTile(player.x ,player.y + 1).id ~= tile.id.wall and d:getTile(player.x ,player.y + 1).id ~= tile.id.lock then
			player.y = player.y + 1
			isOnKey()
		elseif d:getTile(player.x ,player.y + 1).id == tile.id.lock and haveTheKey(d:getTile(player.x ,player.y + 1)) then
			d:setTile(player.x ,player.y + 1, tile.new(tile.id.floor, 0))
			player.y = player.y + 1
		end
	end
end