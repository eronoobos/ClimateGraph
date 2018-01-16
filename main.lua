require "common"
require "climate"

local terrainRegions = {
	{ name = "grassland", dictName = "terrainGrass", code = 0, targetArea = 0.36, highT = true, highR = true, noLowR = true, noLowT = true,
		relations = {
			-- plains = {t = 1, r = 1},
			desert = {t = -1, r = 1},
			tundra = {n = -1},
		},
		subRegionNames = {"none", "forest", "jungle", "marsh"},
		remainderString = "features = { featureNone, featureForest, featureJungle, featureMarsh, featureFallout }",
		color = {0, 127, 0}
	},
	{ name = "plains", dictName = "terrainPlains", code = 1, targetArea = 0.26, noLowT = true, noLowR = true,
		relations = {
			-- grassland = {t = -1, r = -1},
			desert = {r = 1},
			tundra = {t = 1} 
		},
		subRegionNames = {"none", "forest"},
		remainderString = "features = { featureNone, featureForest, featureFallout }",
		color = {127, 127, 0}
	},
	{ name = "desert", dictName = "terrainDesert", code = 2, targetArea = 0.195, lowR = true, noHighR = true,
		relations = {
			plains = {r = -1},
			tundra = {t = 1},
			grassland = {t = 1, r = -1},
		},
		subRegionNames = {"none", "oasis"},
		remainderString = "features = { featureNone, featureOasis, featureFallout }, specialFeature = featureOasis",
		color = {127, 127, 63}
	},
	{ name = "tundra", dictName = "terrainTundra", code = 3, targetArea = 0.13, contiguous = true, noHighT = true,
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
	{ name = "snow", dictName = "terrainSnow", code = 4, targetArea = 0.065, lowT = true, contiguous = true, noHighT = true,
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
	{ name = "none", dictName = "featureNone", code = -1, targetArea = 0.73,
		relations = {},
		containedBy = { "grassland", "plains", "desert", "tundra", "snow" },
		dontEqualizeSuperAreas = true,
		remainderString = "percent = 100, limitRatio = -1, hill = true",
		color = {255, 255, 255, 0}
	},
	{ name = "forest", dictName = "featureForest", code = 5, targetArea = 0.17, highR = true, noLowR = true,
		relations = {},
		containedBy = { "grassland", "plains", "tundra" },
		remainderString = "percent = 100, limitRatio = 0.85, hill = true",
		color = {0, 127, 127, 255}
	},
	{ name = "jungle", dictName = "featureJungle", code = 1, targetArea = 0.1, highR = true, highT = true, noLowR = true, noLowT = true,
		containedBy = { "grassland" },
		remainderString = "percent = 100, limitRatio = 0.85, hill = true, terrainType = terrainPlains",
		relations = {},
		color = {0, 0, 127, 255}
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
local brushHighlight = {}
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
		local output = myClimate.graph:Export()
		if key == "c" then
			-- save grid to clipboard
			love.system.setClipboardText( output )
		elseif key == "s" then
			-- save grid to file
			local success = love.filesystem.write( "grid.lua", output )
			if success then print('grid.lua written') end
		end
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
		local t, r = DisplayToGrid(love.mouse.getX(), love.mouse.getY())
		brushHighlight = myClimate.graph:PaintRegion(nil, t, r, brush)
	elseif key == '-' or key == '_' then
		brushRadius = mMax(0, brushRadius - 1)
		brush = CreateBrush(brushRadius)
		print(brushRadius)
		local t, r = DisplayToGrid(love.mouse.getX(), love.mouse.getY())
		brushHighlight = myClimate.graph:PaintRegion(nil, t, r, brush)
	elseif key == "space" then
		paused = not paused
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
		-- load grid from file
		local chunk
		if key == "l" then
			if love.filesystem.exists( "grid.lua" ) then
				print('grid.lua exists')
				chunk = love.filesystem.load( "grid.lua" )
			end
		elseif key == "v" then
			local clipText = love.system.getClipboardText()
			chunk = loadstring(clipText)
		end
		if chunk then
			print("got chunk")
			local grid = chunk()
			if grid then
				print("got grid table")
				myClimate.graph:Import(grid)
			end
		end
	end
end

local buttonPointSets = { 'pointSet', 'subPointSet' }
local mousePress = {}

function love.mousepressed(x, y, button)
	local t, r = DisplayToGrid(x, y)
	if love.keyboard.isDown( 'lctrl' ) or love.keyboard.isDown( 'rctrl' ) then
		-- select a region to paint by clicking on it
		local pixel = myClimate.graph:PixelAt(t, r)
		if pixel then
			if button == 1 then
				-- select region
				brushRegion = pixel.region
			elseif button == 2 then
				-- select subregion
				brushRegion = pixel.subRegion
			end
		end
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
	local t, r = DisplayToGrid(x, y)
	brushHighlight = myClimate.graph:PaintRegion(nil, t, r, brush)
	for button, point in pairs(mousePress) do
		myClimate.graph:PaintRegion(brushRegion, t, r, brush)
		-- local pressT, pressR = DisplayToGrid(mousePress[button].x, mousePress[button].y)
	end
end

function love.update(dt)
   love.window.setTitle( myClimate.iterations .. " " .. myClimate.generation .. " " .. mFloor(myClimate.distance or 0) .. myClimate.mutationStrength )
end

function love.draw()
	love.graphics.setLineWidth(1)
	love.graphics.setLineStyle("rough")
	for t, rains in pairs(myClimate.graph.grid) do
		for r, pixel in pairs(rains) do
			local x, y = t*displayMult, displayMultHundred-r*displayMult
			love.graphics.setColor( pixel.region.color )
			love.graphics.rectangle("fill", x, y, displayMult, displayMult)
			love.graphics.setColor( pixel.subRegion.color )
			love.graphics.rectangle("fill", x, y, displayMultHalf, displayMultHalf)
			love.graphics.rectangle("fill", x+displayMultHalf, y+displayMultHalf, displayMultHalf, displayMultHalf)
			if pixel.latitude then
				love.graphics.setColor( 127, 0, 0 )
				love.graphics.rectangle("fill", x+displayMultHalf, y, displayMultHalf, displayMultHalf)
				love.graphics.rectangle("fill", x, y+displayMultHalf, displayMultHalf, displayMultHalf)
			end
		end
	end
	for h, pixel in pairs(brushHighlight) do
		local x, y = pixel.temp*displayMult, displayMultHundred-pixel.rain*displayMult
		love.graphics.setColor( 0, 0, 0 )
		love.graphics.rectangle("line", x, y, displayMult, displayMult)
	end
	local y = 0
	for name, region in pairs(myClimate.regionsByName) do
		if brushRegion == region then
			love.graphics.setColor( 255, 255, 255 )
		elseif region.isCombo then
			love.graphics.setColor( 255, 127, 127 )
		elseif region.isSub then
			love.graphics.setColor( 255, 127, 255 )
		else
			love.graphics.setColor( 127, 255, 255 )
		end
		love.graphics.print(name .. "\n" .. (region.latitudeArea or "nil") .. "/" .. mCeil(region.targetLatitudeArea) .. "\n" .. (region.area or "nil") .. "/" .. mFloor(region.targetArea) .. "\n", displayMultHundred+70, y)
		if region.isCombo then
			love.graphics.setColor(region.region.color)
			love.graphics.rectangle("fill", displayMultHundred+25, y, 30, 30)
			love.graphics.setColor(region.subRegion.color)
			love.graphics.rectangle("fill", displayMultHundred+25, y, 15, 15)
			love.graphics.rectangle("fill", displayMultHundred+25+15, y+15, 15, 15)
		else
			love.graphics.setColor(region.color)
			love.graphics.rectangle("fill", displayMultHundred+25, y, 30, 30)
		end
		y = y + 50
	end
	love.graphics.setColor(255, 0, 0)
	love.graphics.print(mFloor(myClimate.distance or "nil"), 10, displayMultHundred + 70)
	love.graphics.setColor(255, 0, 255)
	love.graphics.print("polar exponent: " .. myClimate.polarExponent .. "   minimum temperature: " .. myClimate.temperatureMin .. "   maximum temperature: " .. myClimate.temperatureMax .. "   rainfall midpoint: " .. myClimate.rainfallMidpoint, 10, displayMultHundred + 50)
	love.graphics.setColor(0, 0, 0)
	-- love.graphics.circle("line", love.mouse.getX(), love.mouse.getY()+displayMult, (brushRadius+0.5)*displayMult, mMax(12,6*brushRadius))
end