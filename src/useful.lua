local useful = {}


function useful.printPretty(thing, depth)
	local depth = depth or 0
	if type(thing)~="table" then
		error(thing.." is not a table.")
	end
	for k,v in pairs(thing) do
		if type(k)~="number" or math.floor(k)~=k then
			for i=1,depth do
				io.write("\t")
			end
			io.write(k.." = ")
			if type(v)=="table" then
				print("{")
				useful.printPretty(v,depth+1)
				for i=1,depth do
					io.write("\t")
				end
				print("}")
			else
				print(v)
			end
		end
	end
	for i,v in ipairs(thing) do
		for i=1,depth do
			io.write("\t")
		end
		io.write(i.." = ")
		if type(v)=="table" then
			print("{")
			useful.printPretty(v,depth+1)
			for i=1,depth do
				io.write("\t")
			end
			print("}")
		else
			print(v)
		end
	end
end
return useful