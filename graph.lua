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
	local fillComboRegion = fillRegion.comboRegions[fillSubRegion]
	fillComboRegion.area = 10000
	fillRegion.latitudeArea = 91
	fillSubRegion.latitudeArea = 91
	print(fillRegion.name, fillSubRegion.name)
end)

function Graph:PixelAt(temp, rain)
	-- print(temp, rain, self.grid, self.grid[temp])
	if not self.grid[temp] then return end
	return self.grid[temp][rain]
end

function Graph:Export(codeKey)
	codeKey = codeKey or "code"
	-- local out = "return {\n"
	local out = "{\n"
	for t, rains in pairs(self.grid) do
		out = out .. "\t[" .. t .. "] = { " 
		for r, pixel in pairs(rains) do
			out = out .. "[" .. r .. "]={" .. pixel.region[codeKey] .. "," .. pixel.subRegion[codeKey] .. "}"
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

function Graph:Import(exGrid, codeKey)
	codeKey = codeKey or "code"
	for t, rains in pairs(exGrid) do
		for r, p in pairs(rains) do
			local pixel = self.grid[t][r]
			for i, reg in pairs(self.climate.regions) do
				if reg[codeKey] == p[1] then
					region = reg
					break
				end
			end
			pixel:SetRegion(region)
		end
	end
	for t, rains in pairs(exGrid) do
		for r, p in pairs(rains) do
			local pixel = self.grid[t][r]
			for i, subReg in pairs(self.climate.subRegions) do
				if subReg[codeKey] == p[2] then
					subRegion = subReg
					break
				end
			end
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

function Graph:BalanceByPixel()
	-- find the region with the most excessive pixels
	local mostImbalance = 0
	local neediestRegion
	for i, region in pairs(self.climate.comboRegions) do
		local deficit = region.targetArea - region.area
		local imbalance = -deficit
		-- print(region.name, deficit, region.targetArea, region.area)
		if imbalance > mostImbalance then
			mostImbalance = imbalance
			neediestRegion = region
		end
	end
	-- find the pixel in that region with the most neighbors of another region
	local mostOthers
	local bestPixel
	local bestPixelOthers
	for i, pixel in pairs(neediestRegion.pixels) do
		local others = 0
		local otherPixels = {}
		for t = -1, 1 do
			for r = -1, 1 do
				if not (t == 0 and r == 0) then
					local nPix = self:PixelAt(pixel.temp + t, pixel.rain + r)
					if nPix and (nPix.region ~= pixel.region or nPix.subRegion ~= pixel.subRegion) then
						others = others + 1
						tInsert(otherPixels, nPix)
					end
				end
			end
		end
		if others ~= 0 and (not mostOthers or others > mostOthers) then
			mostOthers = others
			bestPixel = pixel
			bestPixelOthers = otherPixels
			if others >= 7 then
				break
			end
		end
	end
	-- flip the pixel to one of the nearby regions
	if bestPixel then
		local otherPixel = tGetRandom(bestPixelOthers)
		bestPixel:SetRegion(otherPixel.region)
		bestPixel:SetRegion(otherPixel.subRegion)
	end
end