require "common"

Pixel = class(function(a, graph, temp, rain, region, subRegion, latitude)
	a.graph = graph
	a.temp = temp
	a.rain = rain
	a.region = region
	a.subRegion = subRegion
	a.latitude = latitude

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
	myRegion.area = myRegion.area - 1
	region.area = region.area + 1
	if oldComboRegion then
		oldComboRegion.area = oldComboRegion.area - 1
	end
	if comboRegion then
		comboRegion.area = comboRegion.area + 1
	end
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