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
	myRegion.area = myRegion.area - 1
	region.area = region.area + 1
	if oldComboRegion then
		oldComboRegion.area = oldComboRegion.area - 1
	end
	if comboRegion then
		comboRegion.area = comboRegion.area + 1
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
	for pixel, border in pairs(self.borderPair) do
		pixel.haveBorder[border] = nil
		for ii, pix in pairs(border.pixels) do
			if pix == pixel then
				tRemove(border.pixels, ii)
				break
			end
		end
		for ii, pix in pairs(border.pixels) do
			if pix == self then
				tRemove(border.pixels, ii)
				break
			end
		end
		pixel.borderPair[self] = nil
	end
	self.borderPair = {}
	self.haveBorder = {}
	local borderRegion = self.comboRegion or self.region
	for t = -1, 1 do
		for r = -1, 1 do
			if not (t == 0 and r == 0) then
				local nPix = self.graph:PixelAt(self.temp + t, self.rain + r)
				if nPix then
					local nPixBorReg = nPix.comboRegion or nPix.region
					if nPixBorReg and nPixBorReg ~= borderRegion then
						local border = self.graph:GetBorder(nPixBorReg, borderRegion)
						if not self.haveBorder[border] then
							self.haveBorder[border] = true
							tInsert(border.pixels, self)
						end
						if not nPix.haveBorder[border] then
							nPix.haveBorder[border] = true
							tInsert(border.pixels, nPix)
						end
						self.borderPair[nPix] = border
						nPix.borderPair[self] = border
					end
				end
			end
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