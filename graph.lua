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
	a.borders = {}
	a.borderList = {}
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

function Graph:GetBorder(aRegion, bRegion)
	local border
	if self.borders[aRegion] then
		border = self.borders[aRegion][bRegion]
		if border then return border end
	end
	border = {
		regions = {aRegion, bRegion},
		pixels = {},
	}
	self.borders[aRegion] = self.borders[aRegion] or {}
	self.borders[bRegion] = self.borders[bRegion] or {}
	self.borders[aRegion][bRegion] = border
	self.borders[bRegion][aRegion] = border
	tInsert(self.borderList, border)
	return border
end

function Graph:RemoveBorder(border)
	for i, pixel in pairs(border.pixels) do
		pixel.haveBorder[border] = nil
	end
	self.borders[border.regions[1]][border.regions[2]] = nil
	self.borders[border.regions[2]][border.regions[1]] = nil
	for i, border in pairs(self.borderList) do
		if border == border then
			tRemove(self.borderList, i)
			break
		end
	end
end

function Graph:BalanceBorder(border, privilegedRegion)
	if not border then return end
	if #border.pixels == 0 then return end
	local region = privilegedRegion
	if not region then
		local deficit1 = border.regions[1].targetArea - border.regions[1].area
		local deficit2 = border.regions[2].targetArea - border.regions[2].area
		if deficit1 > deficit2 then
			region = border.regions[1]
		else
			region = border.regions[2]
		end
	end
	if region.isCombo then
		local pixBuf = tDuplicate(border.pixels)
		local pixel
		repeat
			pixel = tRemoveRandom(pixBuf)
		until #pixBuf == 0 or pixel.region ~= region.region or pixel.subRegion ~= region.subRegion
		-- print(#pixBuf, #border.pixels, pixel, "combo")
		if pixel then
			-- print("set pixel combo", region.name)
			pixel:SetRegion(region.region)
			pixel:SetRegion(region.subRegion)
		end
	else
		local pixBuf = tDuplicate(border.pixels)
		local pixel
		repeat
			pixel = tRemoveRandom(pixBuf)
		until #pixBuf == 0 or (pixel.region ~= region and pixel.subRegion ~= region)
		-- print(#pixBuf, #border.pixels, pixel)
		if pixel then
			-- print("set pixel", region.name)
			pixel:SetRegion(region)
		end
	end
end

function Graph:BalanceOneBorder()
	local mostImbalance = 0
	local neediestBorder
	local privilegedRegion
	-- for i, border in pairs(self.borderList) do
	-- 	local imbalance = mAbs( (border.regions[1].area - border.regions[1].targetArea) - (border.regions[2].area - border.regions[2].targetArea) )
	-- 	if #border.pixels ~= 0 and imbalance > mostImbalance then
	-- 		mostImbalance = imbalance
	-- 		neediestBorder = border
	-- 	end
	-- end
	for i, region in pairs(self.climate.comboRegions) do
		local deficit = region.targetArea - region.area
		local imbalance = deficit
		-- print(region.name, deficit, region.targetArea, region.area)
		if imbalance > mostImbalance then
			if self.borders[region] then
				mostImbalance = imbalance
				privilegedRegion = region
				local possibilities = {}
				local thisBorder
				for borderingRegion, border in pairs(self.borders[region]) do
					if #border.pixels ~= 0 then
						local borderingDeficit = borderingRegion.targetArea - borderingRegion.area
						if (deficit > 0 and borderingDeficit < 0) or (deficit < 0 and borderingDeficit > 0) then
							thisBorder = border
							break
						else
							tInsert(possibilities, border)
						end
					end
				end
				neediestBorder = thisBorder or tGetRandom(possibilities)
			end
		end
	end
	-- neediestBorder = tGetRandom(self.borderList)
	if neediestBorder then
		-- print(neediestBorder, mostImbalance, neediestBorder.regions[1].name, neediestBorder.regions[2].name, #neediestBorder.pixels, privilegedRegion.name)
		self:BalanceBorder(neediestBorder, privilegedRegion)
	end
end