require "common"
require "pixel"

Graph = class(function(a, climate, fillRegion, fillSubRegion)
	a.climate = climate
	local grid = {}
	for t = climate.temperatureMin, climate.temperatureMax do
		local rains = {}
		for r = climate.rainfallMin, climate.rainfallMax do
			local pixel = Pixel(a, t, r, fillRegion, fillSubRegion)
			rains[r] = pixel
		end
		grid[t] = rains
	end
	a.grid = grid
	fillRegion.area = 10000
	fillSubRegion.area = 10000
	fillRegion.latitudeArea = 91
	fillSubRegion.latitudeArea = 91
	print(fillRegion.name, fillSubRegion.name)
end)

function Graph:PixelAt(temp, rain)
	-- print(temp, rain, self.grid, self.grid[temp])
	if not self.grid[temp] then return end
	return self.grid[temp][rain]
end

function Graph:Export()
	-- local out = "return {\n"
	local out = "{\n"
	for t, rains in pairs(self.grid) do
		out = out .. "\t[" .. t .. "] = { " 
		for r, pixel in pairs(rains) do
			out = out .. "[" .. r .. "]={" .. pixel.region.code .. "," .. pixel.subRegion.code .. "}"
			if r ~= #rains then
				out = out .. ", "
			end
		end
		out = out .. " }"
		if t ~= #self.grid then
			out = out .. ","
		end
		out = out .. "\n"
	end
	out = out .. "}"
	return out
end

function Graph:Import(exGrid)
	for t, rains in pairs(exGrid) do
		for r, p in pairs(rains) do
			local pixel = self.grid[t][r]
			local region = self.climate.superRegionsByCode[p[1]]
			local subRegion = self.climate.subRegionsByCode[p[2]]
			pixel:SetRegion(region)
			pixel:SetRegion(subRegion)
		end
	end
	print("grid imported")
end

function Graph:PaintRegion(region, temp, rain, brush)
	local list
	if not region then list = {} end
	local pixel = self:PixelAt(temp, rain)
	if pixel then
		if region then
			pixel:SetRegion(region)
		else
			tInsert(list, pixel)
		end
	end
	if brush then
		for b, bristle in pairs(brush) do
			for mx = -1, 1, 2 do
				for my = -1, 1, 2 do
					local t = temp + (bristle.x * mx)
					local r = rain + (bristle.y * my)
					local p = self:PixelAt(t, r)
					if p then
						if region then
							p:SetRegion(region)
						else
							tInsert(list, p)
						end
					end
				end
			end
		end
	end
	if not region then return list end
end