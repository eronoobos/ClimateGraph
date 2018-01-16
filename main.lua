require "common"
require "climate"

-- local TerrainDictionary = {
-- 	[terrainGrass] = { points = {}, features = { featureNone, featureForest, featureJungle, featureMarsh, featureFallout } },
-- 	[terrainPlains] = { points = {}, features = { featureNone, featureForest, featureFallout } },
-- 	[terrainDesert] = { points = {}, features = { featureNone, featureOasis, featureFallout }, specialFeature = featureOasis },
-- 	[terrainTundra] = { points = {}, features = { featureNone, featureForest, featureFallout } },
-- 	[terrainSnow] = { points = {}, features = { featureNone, featureFallout } },
-- }

-- local FeatureDictionary = {
-- 	[featureNone] = { points = {}, percent = 100, limitRatio = -1, hill = true },
-- 	[featureForest] = { points = {}, percent = 100, limitRatio = 0.85, hill = true },
-- 	[featureJungle] = { points = {}, percent = 100, limitRatio = 0.85, hill = true, terrainType = terrainPlains },
-- 	[featureMarsh] = { points = {}, percent = 100, limitRatio = 0.33, hill = false },
-- 	[featureOasis] = { points = {}, percent = 2.4, limitRatio = 0.01, hill = false },
-- 	[featureFallout] = { points = {}, disabled = true, percent = 0, limitRatio = 0.75, hill = true },
-- }

local terrainRegions = {
	{ name = "grassland", dictName = "terrainGrass", targetArea = 0.36, highT = true, highR = true, noLowR = true, noLowT = true,
		points = {
			-- {t = 100, r = 75},
			{t = 75, r = 100}
		},
		relations = {
			-- plains = {t = 1, r = 1},
			desert = {t = -1, r = 1},
			tundra = {n = -1},
		},
		subRegionNames = {"none", "forest", "jungle", "marsh"},
		remainderString = "features = { featureNone, featureForest, featureJungle, featureMarsh, featureFallout }",
		color = {0, 127, 0}
	},
	{ name = "plains", dictName = "terrainPlains", targetArea = 0.26, noLowT = true, noLowR = true,
		points = {
			-- {t = 75, r = 50},
			{t = 50, r = 75}
		},
		relations = {
			-- grassland = {t = -1, r = -1},
			desert = {r = 1},
			tundra = {t = 1} 
		},
		subRegionNames = {"none", "forest"},
		remainderString = "features = { featureNone, featureForest, featureFallout }",
		color = {127, 127, 0}
	},
	{ name = "desert", dictName = "terrainDesert", targetArea = 0.195, lowR = true, noHighR = true,
		points = {
			-- {t = 25, r = 0},
			{t = 80, r = 0}
		},
		relations = {
			plains = {r = -1},
			tundra = {t = 1},
			grassland = {t = 1, r = -1},
		},
		subRegionNames = {"none", "oasis"},
		remainderString = "features = { featureNone, featureOasis, featureFallout }, specialFeature = featureOasis",
		color = {127, 127, 63}
	},
	{ name = "tundra", dictName = "terrainTundra", targetArea = 0.13, contiguous = true, noHighT = true,
		points = {
			{t = 3, r = 25},
			-- {t = 1, r = 75}
		},
		relations = {
			desert = {t = -1},
			plains = {t = -1},
			snow = {t = 1},
			grassland = {n = -1},
		},
		subRegionNames = {"none", "forest"},
		remainderString = "features = { featureNone, featureForest, featureFallout }",
		color = {63, 63, 63}
	},
	{ name = "snow", dictName = "terrainSnow", targetArea = 0.065, lowT = true, contiguous = true, noHighT = true,
		points = {
			{t = 0, r = 25},
			-- {t = 0, r = 70},
		},
		subRegionNames = {"none"},
		remainderString = "features = { featureNone, featureFallout }",
		relations = {
			tundra = {t = -1},
			plains = {n = -1},
		},
		color = {127, 127, 127}
	},
}

-- 

local featureRegions = {
	{ name = "none", dictName = "featureNone", targetArea = 0.73,
		points = {
			{t = 60, r = 40},
			-- {t = 55, r = 45},
		},
		relations = {},
		containedBy = { "grassland", "plains", "desert", "tundra", "snow" },
		dontEqualizeSuperAreas = true,
		remainderString = "percent = 100, limitRatio = -1, hill = true",
		color = {255, 255, 255, 0}
	},
	{ name = "forest", dictName = "featureForest", targetArea = 0.17, highR = true, noLowR = true,
		points = {
			{t = 45, r = 60},
			-- {t = 25, r = 40},
		},
		relations = {},
		containedBy = { "grassland", "plains", "tundra" },
		remainderString = "percent = 100, limitRatio = 0.85, hill = true",
		color = {255, 255, 0, 127}
	},
	{ name = "jungle", dictName = "featureJungle", targetArea = 0.1, highR = true, highT = true, noLowR = true, noLowT = true,
		points = {
			{t = 100, r = 100},
			-- {t = 90, r = 90},
		},
		containedBy = { "grassland" },
		remainderString = "percent = 100, limitRatio = 0.85, hill = true, terrainType = terrainPlains",
		relations = {},
		color = {0, 255, 0, 127}
	},
	--[[
	{ name = "marsh", targetArea = 0.02, highR = true,
		points = {
			{t = 40, r = 75},
		},
		containedBy = { "grassland" },
		relations = {},
		color = {0, 0, 255, 127}
	},
	{ name = "oasis", targetArea = 0.01,
		points = {
			{t = 90, r = 0}
		},
		containedBy = { "desert" },
		relations = {},
		color = {255, 0, 0, 127}
	},
	]]--
}

nullFeatureRegions = {
	{ name = "none", targetArea = 1.0,
		points = {
			{t = 50, r = 50},
		},
		relations = {},
		containedBy = { "grassland", "plains", "desert", "tundra", "snow" },
		color = {255, 255, 255, 0}
	},
}

local myClimate
local brushRegion
local brushRadius = 4
local brush = CreateBrush(brushRadius)
local paused

function love.load()
    love.window.setMode(displayMult * 100 + 200, displayMult * 100 + 100, {resizable=false, vsync=false})
    myClimate = Climate(terrainRegions, featureRegions)
    brushRegion = myClimate.regions[1]
end

function love.keyreleased(key)
	-- print(key)
	local ascii = string.byte(key)
	if key == "c" or key == "s" then
		local output = ""
		if key == "c" then
			-- save points to clipboard
			love.system.setClipboardText( output )
		elseif key == "s" then
			-- save points to file
			local success = love.filesystem.write( "points.txt", output )
			if success then print('points.txt written') end
		end
	elseif key == "o" then
		local block = ""
		love.system.setClipboardText( block )
	elseif ascii >= 49 and ascii <= 57 then
		-- numbers select regions to paint
		local num = tonumber(key)
		if num <= 5 then
			brushRegion = myClimate.regions[num] or brushRegion
		else
			num = num - 5
			brushRegion = myClimate.subRegions[num] or brushRegion
		end
		print(brushRegion.name)
	elseif key == '=' or key == '+' then
		brushRadius = mMin(25, brushRadius + 1)
		brush = CreateBrush(brushRadius)
		print(brushRadius)
	elseif key == '-' or key == '_' then
		brushRadius = mMax(0, brushRadius - 1)
		brush = CreateBrush(brushRadius)
		print(brushRadius)
	elseif key == "space" then
		paused = not paused
	-- elseif key == "f" then
		-- myClimate = Climate(nil, featureRegions, myClimate)
	elseif key == "up" then
		myClimate:SetPolarExponent(myClimate.polarExponent+0.1)
	elseif key == "down" then
		myClimate:SetPolarExponent(myClimate.polarExponent-0.1)
	elseif key == "right" then
		myClimate.temperatureMin = myClimate.temperatureMin + 5
		myClimate:ResetLatitudes()
	elseif key == "left" then
		myClimate.temperatureMin = myClimate.temperatureMin - 5
		myClimate:ResetLatitudes()
	elseif key == "pagedown" then
		myClimate.temperatureMax = myClimate.temperatureMax + 5
		myClimate:ResetLatitudes()
	elseif key == "pageup" then
		myClimate.temperatureMax = myClimate.temperatureMax - 5
		myClimate:ResetLatitudes()
	elseif key == "." then
		myClimate:SetRainfallMidpoint(myClimate.rainfallMidpoint + 1)
	elseif key == "," then
		myClimate:SetRainfallMidpoint(myClimate.rainfallMidpoint - 1)
	elseif key == "l" or key == "v" then
		-- load points from file
		local lines
		if key == "l" then
			if love.filesystem.exists( "points.txt" ) then
				print('points.txt exists')
				lines = {}
				for line in love.filesystem.lines("points.txt") do
					tInsert(lines, line)
				end
			end
		elseif key == "v" then
			local clipText = love.system.getClipboardText()
			lines = clipText:split("\n")
		end
		if lines then
			myClimate.pointSet = PointSet(myClimate)
			myClimate.subPointSet = PointSet(myClimate, nil, true)
			for i, line in pairs(lines) do
				local words = splitIntoWords(line)
				if #words > 1 then
					local regionName = words[1]
					local tr = {}
					for i, n in pairs(words[2]:split(",")) do tInsert(tr, n) end
					if #tr > 1 then
						local t, r = tonumber(tr[1]), tonumber(tr[2])
						print(regionName, t, r, type(regionName), type(t), type(r))
						local region = myClimate.subRegionsByName[regionName] or myClimate.superRegionsByName[regionName]
						local pointSet
						if region then
							print('got region')
							if myClimate.subRegionsByName[regionName] then
								pointSet = myClimate.subPointSet
								print("sub")
							elseif myClimate.superRegionsByName[regionName] then
								pointSet = myClimate.pointSet
								print("super")
							end
							local point = Point(region, t, r)
							pointSet:AddPoint(point)
						end
					end
				end
			end
			print('points loaded')
			print(#myClimate.pointSet.points, #myClimate.subPointSet.points)
		end
	end
end

local buttonPointSets = { 'pointSet', 'subPointSet' }
local mousePress = {}

function love.mousepressed(x, y, button)
	local t, r = DisplayToGrid(x, y)
	if love.keyboard.isDown( 'lctrl' ) then
		-- select a region to paint by clicking on it
	else
		-- paint region
		myClimate.graph:PaintRegion(brushRegion, t, r, brush)
	end
	mousePress[button] = {x = x, y = y}
end

function love.mousereleased(x, y, button)
	mousePress[button] = nil
end

function love.mousemoved(x, y, dx, dy, istouch)
	for button, point in pairs(mousePress) do
		local t, r = DisplayToGrid(x, y)
		myClimate.graph:PaintRegion(brushRegion, t, r, brush)
		-- local pressT, pressR = DisplayToGrid(mousePress[button].x, mousePress[button].y)
	end
end

function love.update(dt)
   love.window.setTitle( myClimate.iterations .. " " .. myClimate.generation .. " " .. mFloor(myClimate.distance or 0) .. myClimate.mutationStrength )
end

function love.draw()
	for t, rains in pairs(myClimate.graph.grid) do
		for r, pixel in pairs(rains) do
			local x, y = t*displayMult, displayMultHundred-r*displayMult
			love.graphics.setColor( pixel.region.color )
			love.graphics.rectangle("fill", x, y, displayMult, displayMult)
			love.graphics.setColor( pixel.subRegion.color )
			love.graphics.rectangle("fill", x, y, displayMult, displayMult)
			if pixel.latitude then
				love.graphics.setColor( 127, 0, 0 )
				love.graphics.rectangle("fill", x, y, displayMult, displayMult)
			end
		end
	end
	local y = 0
	for name, region in pairs(myClimate.regionsByName) do
		if region.containedBy then
			love.graphics.setColor( 255, 255, 127 )
		else
			love.graphics.setColor( 127, 255, 255 )
		end
		love.graphics.print(region.name .. "\n" .. (region.latitudeArea or "nil") .. "/" .. mFloor(region.targetLatitudeArea) .. "\n" .. (region.area or "nil") .. "/" .. mFloor(region.targetArea) .. "\n", displayMultHundred+70, y)
		y = y + 50
	end
	love.graphics.setColor(255, 0, 0)
	love.graphics.print(mFloor(myClimate.distance or "nil"), 10, displayMultHundred + 70)
	love.graphics.setColor(255, 0, 255)
	love.graphics.print("polar exponent: " .. myClimate.polarExponent .. "   minimum temperature: " .. myClimate.temperatureMin .. "   maximum temperature: " .. myClimate.temperatureMax .. "   rainfall midpoint: " .. myClimate.rainfallMidpoint, 10, displayMultHundred + 50)
end