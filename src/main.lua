function love.load(args)
	math.randomseed(os.time())
	dungeon = require("dungeon")
	tile = require("tile")
	thePlayer = require("player")
	tileSize = 20
	d = dungeon.new()
	
	d:generate()
	
	player = thePlayer.new()
	player.img = love.graphics.newImage("image/kingflanyoda.png")
	
	love.generate()
end

function love.update(dt)
end

function love.draw()
	for i=1,d.w do
		for j=1,d.h do
			if d:getTile(i,j).id==tile.id.floor then
				love.graphics.setColor(64, 50, 255)
			elseif d:getTile(i,j).id==tile.id.wall then
				love.graphics.setColor(160, 160, 54)
			elseif d:getTile(i,j).id==tile.id.candidate then
				love.graphics.setColor(255, 255,255)
			elseif d:getTile(i,j).id==tile.id.lock then
				love.graphics.setColor(0, 255, 0)
			else
				love.graphics.setColor(255, 160, 154)
			end
			love.graphics.rectangle("fill", i*tileSize, j*tileSize, tileSize, tileSize)
			love.graphics.setColor(0, 0, 0)
			love.graphics.print(d:getTile(i,j).group, i*tileSize, j*tileSize)
		end
	end
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(player.img, player.x*tileSize, player.y*tileSize)
end

function love.generate()
	d = dungeon.new()
	d:generate()
	d:placePlayer(player)
	d:placeLockedDoors(player)
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
		elseif d:getTile(player.x - 1,player.y).id == tile.id.lock and player.keys > 0 then
			d:setTile(player.x - 1,player.y, tile.new(tile.id.floor, 0))
			player.x = player.x - 1
			player.keys = player.keys - 1
			print(player.keys)
		end
	elseif key == "right" then
		if d:getTile(player.x + 1,player.y).id ~= tile.id.wall and d:getTile(player.x + 1,player.y).id ~= tile.id.lock then
			player.x = player.x + 1
		elseif d:getTile(player.x + 1,player.y).id == tile.id.lock and player.keys > 0 then
			d:setTile(player.x + 1,player.y, tile.new(tile.id.floor, 0))
			player.x = player.x + 1
			player.keys = player.keys - 1
			print(player.keys)
		end
	elseif key == "up" then
		if d:getTile(player.x ,player.y - 1).id ~= tile.id.wall and d:getTile(player.x ,player.y - 1).id ~= tile.id.lock then
			player.y = player.y - 1
		elseif d:getTile(player.x ,player.y - 1).id == tile.id.lock and player.keys > 0 then
			d:setTile(player.x ,player.y - 1, tile.new(tile.id.floor, 0))
			player.y = player.y - 1
			player.keys = player.keys - 1
			print(player.keys)
		end	
	elseif key == "down" then
		if d:getTile(player.x ,player.y + 1).id ~= tile.id.wall and d:getTile(player.x ,player.y + 1).id ~= tile.id.lock then
			player.y = player.y + 1
		elseif d:getTile(player.x ,player.y + 1).id == tile.id.lock and player.keys > 0 then
			d:setTile(player.x ,player.y + 1, tile.new(tile.id.floor, 0))
			player.y = player.y + 1
			player.keys = player.keys - 1
			print(player.keys)
		end
	end
end