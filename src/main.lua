function love.load(args)
	math.randomseed(os.time())
	dungeon = require("dungeon")
	tile = require("tile")
	thePlayer = require("player")
	npc = require("NPC")
	tileSize = 20
	d = dungeon.new()
	
	d:generate()
	
	player = thePlayer.new()
	player.img = love.graphics.newImage("image/floda.png")
	
	d:placePlayer(player)

	NPCsTabListOfNPCs = {}
	insertNPC()
	NPCsTabListOfNPCs = d:placeNPC(NPCsTabListOfNPCs)
	
	n_list = {
		{x = 1, y = 0},
		{x = -1, y = 0},
		{x = 0, y = 1},
		{x = 0, y = -1}
	}
	--d:lockDoors()
end

function love.update(dt)
end

function insertNPC()
	for _,salle in ipairs(d.secretRooms) do
		rand = math.floor((math.random()*4))
		if rand == 0 then
			rand = -2
		elseif rand == 1 then
			rand = -1
		elseif rand == 2 then
			rand = 1
		elseif rand == 3 then
			rand = 2
		end

		newNPC = npc.new(rand)

		table.insert(NPCsTabListOfNPCs,newNPC)
	end
end

function love.draw()
	for i=1,d.w do
		for j=1,d.h do
			if d:getTile(i,j).id==tile.id.floor then
				love.graphics.setColor(64, 50, 255)
			elseif d:getTile(i,j).id==tile.id.wall then
				love.graphics.setColor(160, 160, 54)
			elseif d:getTile(i,j).id==tile.id.candidate then
				love.graphics.setColor(64, 50, 255)
			elseif d:getTile(i,j).id==tile.id.lock then
				love.graphics.setColor(0, 255, 0)
			elseif d:getTile(i,j).id==tile.id.hidden then
				love.graphics.setColor(160, 160, 54)
			else
				love.graphics.setColor(255, 160, 154)
			end
			love.graphics.rectangle("fill", i*tileSize, j*tileSize, tileSize, tileSize)
			love.graphics.setColor(0, 0, 0)
		end
	end
	--[[for _,v in ipairs(d.roomList) do
		local radius = math.min(v.dimensions.height, v.dimensions.width)
		love.graphics.setColor(255, 0, 0)
		love.graphics.circle("fill", (v.dimensions.X+v.dimensions.width/2 )*tileSize,(v.dimensions.Y+v.dimensions.height/2)*tileSize , (radius/2)*tileSize)
	end
	for _,v in ipairs(d.roomList) do
		
		love.graphics.setColor(0, 0, 255)
		
		for _,k in ipairs(v.neighbors) do
			for _,o in ipairs(d.roomList) do
				if(o.id == k.id) then
					love.graphics.line((v.dimensions.X+v.dimensions.width/2 )*tileSize,(v.dimensions.Y+v.dimensions.height/2)*tileSize ,(o.dimensions.X+o.dimensions.width/2 )*tileSize,(o.dimensions.Y+o.dimensions.height/2)*tileSize  )
				end
			end
		end
	end]]--





	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(player.img, player.x*tileSize, player.y*tileSize)
	for _,NPC in ipairs(NPCsTabListOfNPCs) do
		if(NPC.hide == false) then
			love.graphics.draw(NPC.img,NPC.x*tileSize, NPC.y*tileSize)
		end
	end
end

function love.keypressed(key)
	if key == "escape" then
		love.event.push("quit")
	elseif key == " " then
		d = dungeon.new()
		d:generate()
		d:placePlayer(player)
		player.keys = 1
		NPCsTabListOfNPCs = {}
		insertNPC()
		NPCsTabListOfNPCs = d:placeNPC(NPCsTabListOfNPCs)
		--d:lockDoors()
	elseif key == "r" then
		print(player.x)
		print(player.y)
		print(d:getTile(player.x,player.y).id)
	elseif key == "left" then
		if d:getTile(player.x - 1,player.y).id ~= tile.id.wall and d:getTile(player.x - 1,player.y).id ~= (tile.id.lock and tile.id.hidden) then
			player.x = player.x - 1
		elseif d:getTile(player.x - 1,player.y).id == tile.id.lock and player.keys > 0 then
			d:setTile(player.x - 1,player.y, tile.new(tile.id.floor, 0))
			player.x = player.x - 1
			player.keys = player.keys - 1
			print(player.keys)
		end
	elseif key == "right" then
		if d:getTile(player.x + 1,player.y).id ~= tile.id.wall and d:getTile(player.x + 1,player.y).id ~= (tile.id.lock and tile.id.hidden) then
			player.x = player.x + 1
		elseif d:getTile(player.x + 1,player.y).id == tile.id.lock and player.keys > 0 then
			d:setTile(player.x + 1,player.y, tile.new(tile.id.floor, 0))
			player.x = player.x + 1
			player.keys = player.keys - 1
			print(player.keys)
		end
	elseif key == "up" then
		if d:getTile(player.x ,player.y - 1).id ~= tile.id.wall and d:getTile(player.x ,player.y - 1).id ~= (tile.id.lock and tile.id.hidden) then
			player.y = player.y - 1
		elseif d:getTile(player.x ,player.y - 1).id == tile.id.lock and player.keys > 0 then
			d:setTile(player.x ,player.y - 1, tile.new(tile.id.floor, 0))
			player.y = player.y - 1
			player.keys = player.keys - 1
			print(player.keys)
		end	
	elseif key == "down" then
		if d:getTile(player.x ,player.y + 1).id ~= tile.id.wall and d:getTile(player.x ,player.y + 1).id ~= (tile.id.lock and tile.id.hidden) then
			player.y = player.y + 1
		elseif d:getTile(player.x ,player.y + 1).id == tile.id.lock and player.keys > 0 then
			d:setTile(player.x ,player.y + 1, tile.new(tile.id.floor, 0))
			player.y = player.y + 1
			player.keys = player.keys - 1
			print(player.keys)
		end
	
	elseif key == "x" then
		for _,direction in ipairs(n_list) do
			if d:getTile(player.x+direction.x, player.y+direction.y).id == tile.id.hidden then
				d:unHidden(d:getTile(player.x+direction.x, player.y+direction.y).group)
			end
		end
	end
end