require "common"
require "pixel"

Graph = class(function(a, fillRegion, fillSubRegion)
	local grid = {}
	for t = 1, 100 do
		local rains = {}
		for r = 1, 100 do
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
end)

function Graph:PixelAt(temp, rain)
	-- print(temp, rain, self.grid, self.grid[temp])
	return self.grid[temp][rain]
end