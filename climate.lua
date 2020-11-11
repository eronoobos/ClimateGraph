require "common"
require "graph"
require "pixel"

Climate = class(function(a, regions, subRegions, parentClimate)
	a.temperatureMin = 0
	a.temperatureMax = 99
	a.polarExponent = 1.2
	a.rainfallMidpoint = 49.5

	a.polarExponentMultiplier = 90 ^ a.polarExponent
	if a.rainfallMidpoint > 49.5 then
		a.rainfallPlusMinus = 99 - a.rainfallMidpoint
	else
		a.rainfallPlusMinus = a.rainfallMidpoint
	end
	a.rainfallMin = a.rainfallMidpoint - a.rainfallPlusMinus
	a.rainfallMax = a.rainfallMidpoint + a.rainfallPlusMinus

	a.totalLatitudes = 91

	a.iterations = 0
	a.generation = 0
	a.distance = 10000
	a.barrenIterations = 0
	a.nearestString = ""
	a.regions = regions
	a.subRegions = subRegions
	a.regionsByName = {}
	a.subRegionsByName = {}
	a.superRegionsByName = {}
	a.subRegionsByCode = {}
	a.superRegionsByCode = {}
	a.comboRegions = {}
	if regions then
		for i, region in pairs(regions) do
			region.abbreviation = string.sub(region.name, 1, 1)
			region.area = 0
			region.pixels = {}
			region.latitudeArea = 0
			region.targetFraction = region.targetArea
			region.targetLatitudeArea = region.targetArea * a.totalLatitudes
			region.targetArea = region.targetArea * 10000
			region.isSub = false
			a.regionsByName[region.name] = region
			a.superRegionsByName[region.name] = region
			a.superRegionsByCode[region.code] = region
		end
	end
	if subRegions then
		for i, region in pairs(subRegions) do
			region.abbreviation = string.sub(region.name, 1, 1)
			region.isSub = true
			region.area = 0
			region.pixels = {}
			region.latitudeArea = 0
			region.targetFraction = region.targetArea
			region.targetLatitudeArea = region.targetArea * a.totalLatitudes
			region.targetArea = region.targetArea * 10000
			a.regionsByName[region.name] = region
			a.subRegionsByName[region.name] = region
			a.subRegionsByCode[region.code] = region
		end
	elseif parentClimate then
		a.generation = parentClimate.generation + 1
		a.distance = parentClimate.distance
		a.graph = parentClimate.graph
		a.regions = parentClimate.regions
		a.superRegionsByName = parentClimate.superRegionsByName
		for i, region in pairs(parentClimate.regions) do
			a.regionsByName[region.name] = region
		end
	end

	for i, subRegion in pairs(subRegions) do
		for ii, regionName in pairs(subRegion.containedBy) do
			local superRegion = a.regionsByName[regionName]
			if superRegion then
				subRegion.superRegions = subRegion.superRegions or {}
				subRegion.superRegions[superRegion] = true
				superRegion.subRegions = superRegion.subRegions or {}
				superRegion.subRegions[subRegion] = true
			end
		end
	end
	for i, region in pairs(a.regions) do
		region.remainingArea = region.targetArea
		for subRegion, yes in pairs(region.subRegions) do
			local targetArea
			if subRegion.overlapTargetArea and subRegion.overlapTargetArea[region.name] then
				targetArea = mFloor(subRegion.overlapTargetArea[region.name] * 10000)
				subRegion.overlapTargetArea[region.name] = targetArea
			elseif #subRegion.containedBy == 1 then
				targetArea = subRegion.targetArea
			end
			if targetArea then
				print(region.remainingArea, targetArea, region.name, subRegion.name)
				region.remainingArea = region.remainingArea - targetArea
			end
		end
	end
	for i, region in pairs(a.regions) do
		region.subRegions = {}
		region.comboRegions = {}
		for ii, subRegionName in pairs(region.subRegionNames) do
			local subRegion = a.regionsByName[subRegionName]
			if subRegion then
				region.subRegions[subRegion] = true
				local targetArea
				if subRegion.overlapTargetArea and subRegion.overlapTargetArea[region.name] then
					targetArea = subRegion.overlapTargetArea[region.name]
				else
					targetArea = mMin(region.remainingArea, subRegion.targetArea)
				end
				local targetFraction = targetArea / 10000
				local comboRegion = {
					region = region,
					subRegion = subRegion,
					name = region.name .. "+" .. subRegion.name,
					abbreviation = region.abbreviation .. subRegion.abbreviation,
					area = 0,
					pixels = {},
					latitudeArea = 0,
					targetFraction = targetFraction,
					targetArea = targetArea,
					targetLatitudeArea = targetFraction * subRegion.targetLatitudeArea,
					isCombo = true
				}
				if subRegionName ~= "none" then
					a.regionsByName[region.name .. ':' .. subRegion.name] = comboRegion
				else
					comboRegion.name = region.name
				end
				tInsert(a.comboRegions, comboRegion)
				region.comboRegions[subRegion] = comboRegion
			end
		end
	end

	if not parentClimate and regions and subRegions then
		a.graph = Graph(a, regions[1], subRegions[1])
	end

	local protoLatitudes = {}
	for l = 0, mFloor(90/latitudeResolution) do
		local latitude = l * latitudeResolution
		local t, r = a:GetTemperature(latitude, true), a:GetRainfall(latitude, true)
		tInsert(protoLatitudes, { latitude = latitude, t = t, r = r })
	end
	local currentLtr
	local goodLtrs = {}
	local pseudoLatitudes = {}
	local pseudoLatitude = 90
	while #protoLatitudes > 0 do
		local ltr = tRemove(protoLatitudes)
		if not currentLtr then
			currentLtr = ltr
		else
			local dist = mSqrt(TempRainDist(currentLtr.t, currentLtr.r, ltr.t, ltr.r))
			if dist > 3.33 then currentLtr = ltr end
		end
		if not goodLtrs[currentLtr] then
			goodLtrs[currentLtr] = true
			local t = mFloor(currentLtr.t)
			local r = mFloor(currentLtr.r)
			local pixel = a.graph:PixelAt(t, r)
			pseudoLatitudes[pseudoLatitude] = { temperature = t, rainfall = r, pixel = pixel }
			print(t, r)
			pixel.latitude = pseudoLatitude
			pseudoLatitude = pseudoLatitude - 1
		end
	end
	print(pseudoLatitude)
	a.pseudoLatitudes = pseudoLatitudes
end)

function Climate:GiveRegionsExcessAreas(regions)
	for i, region in pairs(regions) do
		region.excessLatitudeArea = region.latitudeArea - region.targetLatitudeArea
		region.excessArea = region.area - region.targetArea
	end
end

function Climate:GetTemperature(latitude, noFloor)
	local temp
	if self.pseudoLatitudes and self.pseudoLatitudes[latitude] then
		temp = self.pseudoLatitudes[latitude].temperature
	else
		local rise = self.temperatureMax - self.temperatureMin
		local distFromPole = (90 - latitude) ^ self.polarExponent
		temp = (rise / self.polarExponentMultiplier) * distFromPole + self.temperatureMin
	end
	if noFloor then return temp end
	return mFloor(temp)
end

function Climate:GetRainfall(latitude, noFloor)
	local rain
	if self.pseudoLatitudes and self.pseudoLatitudes[latitude] then
		rain = self.pseudoLatitudes[latitude].rainfall
	else
		rain = self.rainfallMidpoint + (self.rainfallPlusMinus * mCos(latitude * (mPi/29)))
	end
	if noFloor then return rain end
	return mFloor(rain)
end

function Climate:SetPolarExponent(pExponent)
	self.polarExponent = pExponent
	self.polarExponentMultiplier = 90 ^ pExponent
	self:ResetLatitudes()
end

function Climate:SetRainfallMidpoint(rMidpoint)
	self.rainfallMidpoint = rMidpoint
	if self.rainfallMidpoint > 49.5 then
		self.rainfallPlusMinus = 99 - self.rainfallMidpoint
	else
		self.rainfallPlusMinus = self.rainfallMidpoint
	end
	self.rainfallMin = self.rainfallMidpoint - self.rainfallPlusMinus
	self.rainfallMax = self.rainfallMidpoint + self.rainfallPlusMinus
	self:ResetLatitudes()
end

function Climate:ResetLatitudes()
	print(self.pseudoLatitudes, #self.pseudoLatitudes)
	local foundCount = 0
	for pseudoLatitude, trp in pairs(self.pseudoLatitudes) do
		local pixel = trp.pixel or self.graph:PixelAt(trp.temperature, trp.rainfall)
		if pixel then
			pixel.latitude = nil
			self.graph.grid[trp.temperature][trp.rainfall].latitude = nil
			foundCount = foundCount + 1
		end
	end
	print(foundCount)
	self.pseudoLatitudes = nil
	local pseudoLatitudes
	local minDist = 3.33
	local iterations = 0
	repeat
		local protoLatitudes = {}
		for l = 0, mFloor(90/latitudeResolution) do
			local latitude = l * latitudeResolution
			local t, r = self:GetTemperature(latitude, true), self:GetRainfall(latitude, true)
			tInsert(protoLatitudes, { latitude = latitude, t = t, r = r })
		end
		local currentLtr
		local goodLtrs = {}
		pseudoLatitudes = {}
		local pseudoLatitude = 90
		while #protoLatitudes > 0 do
			local ltr = tRemove(protoLatitudes)
			if not currentLtr then
				currentLtr = ltr
			else
				local dist = mSqrt(TempRainDist(currentLtr.t, currentLtr.r, ltr.t, ltr.r))
				if dist > minDist then currentLtr = ltr end
			end
			if not goodLtrs[currentLtr] then
				goodLtrs[currentLtr] = true
				local t = mFloor(currentLtr.t)
				local r = mFloor(currentLtr.r)
				local pixel = self.graph:PixelAt(t, r)
				if pixel then
					pixel.latitude = pseudoLatitude
				end
				pseudoLatitudes[pseudoLatitude] = { temperature = t, rainfall = r, pixel = pixel }
				pseudoLatitude = pseudoLatitude - 1
			end
		end
		print(pseudoLatitude)
		local change = mAbs(pseudoLatitude+1)^1.5 * 0.005
		if pseudoLatitude < -1 then
			minDist = minDist + change
		elseif pseudoLatitude > -1 then
			minDist = minDist - change
		end
		iterations = iterations + 1
	until pseudoLatitude == -1 or iterations > 100
	self.pseudoLatitudes = pseudoLatitudes
	self.totalLatitudes = 91
end