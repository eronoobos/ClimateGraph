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
	if region.isSub then
		myRegion = self.subRegion
	else
		myRegion = self.region
	end
	if region == myRegion then return end
	myRegion.area = myRegion.area - 1
	region.area = region.area + 1
	if self.latitude then
		myRegion.latitudeArea = myRegion.latitudeArea - 1
		region.latitudeArea = region.latitudeArea + 1
	end
	if region.isSub then
		self.subRegion = region
	else
		self.region = region
	end
end