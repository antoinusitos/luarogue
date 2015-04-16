local connection_mt = {}
local connection = {}

function connection.new()
	self = setmetatable({}, {__index = connection_mt})
	
	self.data = {}
	
	return self
end

function connection_mt:isConnected(a,b)
	if self.data[a] then
		for i,v in pairs(self.data[a]) do
			if v == b then
				return true
			end
		end
	end
end

function connection_mt:connect(a,b)
	if not self.data[a] then
		self.data[a] = {}
	end
	if not self.data[b] then
		self.data[b] = {}
	end
	if not self:isConnected(a,b) then
		table.insert(self.data[a],b)
		table.insert(self.data[b],a)
		for i,v in ipairs(self.data[a]) do
			self:connect(v,b)
		end
		for i,v in ipairs(self.data[b]) do
			self:connect(v,a)
		end
	end
end

return connection