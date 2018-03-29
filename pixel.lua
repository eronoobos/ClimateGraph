require "common"

Pixel = class(function(a, graph, temp, rain, region, subRegion, latitude)
	a.graph = graph
	a.temp = temp
	a.rain = rain
	a.region = region
	a.subRegion = subRegion
	if region and subRegion then
		a.comboRegion = region.comboRegions[subRegion]
	end
	a.latitude = latitude
	a.borderPair = {}
	a.haveBorder = {}

	a.climate = graph.climate
end)

function Pixel:SetRegion(region)
	local myRegion
	local comboRegion
	if region.isSub then
		if not region.superRegions[self.region] then return end
		myRegion = self.subRegion
		comboRegion = self.region.comboRegions[region]
	else
		myRegion = self.region
		comboRegion = region.comboRegions[self.subRegion]
	end
	if region == myRegion then return end
	local oldComboRegion = self.region.comboRegions[self.subRegion]
	self:RemoveFromRegion(myRegion)
	self:AddToRegion(region)
	if oldComboRegion then
		self:RemoveFromRegion(oldComboRegion)
	end
	if comboRegion then
		self:AddToRegion(comboRegion)
	end
	self.comboRegion = comboRegion
	if self.latitude then
		myRegion.latitudeArea = myRegion.latitudeArea - 1
		region.latitudeArea = region.latitudeArea + 1
		if oldComboRegion then
			oldComboRegion.latitudeArea = oldComboRegion.latitudeArea - 1
		end
		if comboRegion then
			comboRegion.latitudeArea = comboRegion.latitudeArea + 1
		end
	end
	if region.isSub then
		self.subRegion = region
	else
		self.region = region
		if not region.subRegions[self.subRegion] then
			self:SetRegion(self.climate.regionsByName["none"])
		end
	end
end

function Pixel:AddToRegion(region)
	if not region then return end
	tInsert(region.pixels, self)
	region.area = region.area + 1
end

function Pixel:RemoveFromRegion(region)
	if not region then return end
	for i, pixel in pairs(region.pixels) do
		if pixel == self then
			tRemove(region.pixels, i)
			break
		end
	end
	region.area = region.area - 1
end