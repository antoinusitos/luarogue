function love.load(args)
	math.randomseed(os.time())
	dungeon = require("dungeon")
	tile = require("tile")
	tileSize = 20
	d = dungeon.new()
	
	d:generate()
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
			else
				love.graphics.setColor(255, 160, 154)
			end
			love.graphics.rectangle("fill", i*tileSize, j*tileSize, tileSize, tileSize)
			love.graphics.setColor(0, 0, 0)
			--love.graphics.print(d:getTile(i,j).group, i*tileSize, j*tileSize)
		end
	end
end

function love.keypressed(key)
	if key == "escape" then
		love.event.push("quit")
	elseif key == " " then
		d = dungeon.new()
		d:generate()
	elseif key == "s" then
		
	end
end