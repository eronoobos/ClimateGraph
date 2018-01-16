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

function Pixel:SetRegionOrSubRegion(fieldString, region)
	if region == self[fieldString] then return end
	local myRegion = self[fieldString]
	myRegion.area = myRegion.area - 1
	region.area = region.area + 1
	if self.latitude then
		myRegion.latitudeArea = myRegion.latitudeArea - 1
		region.latitudeArea = region.latitudeArea + 1
	end
	self[fieldString] = region
end

function Pixel:SetRegion(region)
	self:SetRegionOrSubRegion("region", region)
end

function Pixel:SetSubRegion(subRegion)
	self:SetRegionOrSubRegion("subRegion", subRegion)
end