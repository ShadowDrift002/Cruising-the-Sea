--// Realistic Day/Night Cycle: 4 min day + 4 min night
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local DAY_LENGTH = 240    -- seconds (06:00 -> 18:00)
local NIGHT_LENGTH = 240  -- seconds (18:00 -> 06:00)
local SUNRISE, SUNSET = 6, 18
local START_TIME = 7

local function getOrCreate(className, parent)
	local obj = parent:FindFirstChildOfClass(className)
	if not obj then
		obj = Instance.new(className)
		obj.Parent = parent
	end
	return obj
end

local atmosphere = getOrCreate("Atmosphere", Lighting)
local sky = getOrCreate("Sky", Lighting)
local sunRays = getOrCreate("SunRaysEffect", Lighting)
local bloom = getOrCreate("BloomEffect", Lighting)

sky.StarCount = 3000
sky.CelestialBodiesShown = true
Lighting.GeographicLatitude = 20
bloom.Intensity = 0.3
bloom.Size = 24
bloom.Threshold = 1.5

local function C(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Keyframes by hour of day
local K = {
	{t = 0,  b = 0.2, amb = C(15,18,35),    out = C(30,35,65),    top = C(0,0,0),       exp = 0.1,  atm = C(10,15,35),    decay = C(5,8,20),     dens = 0.30, haze = 1.0, glare = 0,   rays = 0},
	{t = 5,  b = 0.3, amb = C(25,28,50),    out = C(45,50,85),    top = C(0,0,0),       exp = 0.1,  atm = C(30,35,70),    decay = C(30,25,50),   dens = 0.32, haze = 1.2, glare = 0,   rays = 0},
	{t = 6,  b = 1.5, amb = C(90,70,70),    out = C(140,100,90),  top = C(255,150,80),  exp = 0.2,  atm = C(255,170,120), decay = C(255,110,60), dens = 0.40, haze = 1.8, glare = 0.4, rays = 0.15},
	{t = 7,  b = 2.5, amb = C(100,95,95),   out = C(150,140,130), top = C(255,210,160), exp = 0.2,  atm = C(200,190,190), decay = C(220,170,120), dens = 0.35, haze = 1.2, glare = 0.2, rays = 0.1},
	{t = 12, b = 3,   amb = C(120,120,125), out = C(170,175,185), top = C(0,0,0),       exp = 0,    atm = C(199,215,235), decay = C(106,112,125), dens = 0.30, haze = 0.8, glare = 0,   rays = 0.05},
	{t = 17, b = 2.5, amb = C(110,100,95),  out = C(160,150,140), top = C(255,220,170), exp = 0.1,  atm = C(220,200,180), decay = C(230,170,110), dens = 0.35, haze = 1.2, glare = 0.2, rays = 0.1},
	{t = 18, b = 1.5, amb = C(90,60,70),    out = C(140,90,90),   top = C(255,120,70),  exp = 0.2,  atm = C(255,140,90),  decay = C(255,90,50),   dens = 0.40, haze = 1.8, glare = 0.4, rays = 0.15},
	{t = 19, b = 0.6, amb = C(40,35,60),    out = C(70,60,100),   top = C(120,60,90),   exp = 0.1,  atm = C(90,70,110),   decay = C(90,50,80),   dens = 0.35, haze = 1.5, glare = 0,   rays = 0},
	{t = 24, b = 0.2, amb = C(15,18,35),    out = C(30,35,65),    top = C(0,0,0),       exp = 0.1,  atm = C(10,15,35),    decay = C(5,8,20),     dens = 0.30, haze = 1.0, glare = 0,   rays = 0},
}

local function lerp(a, b, t)
	if typeof(a) == "Color3" then
		return a:Lerp(b, t)
	end
	return a + (b - a) * t
end

local function applyLighting(hour)
	local a, b = K[1], K[2]
	for i = 1, #K - 1 do
		if hour >= K[i].t and hour <= K[i + 1].t then
			a, b = K[i], K[i + 1]
			break
		end
	end

	local alpha = (hour - a.t) / (b.t - a.t)
	alpha = alpha * alpha * (3 - 2 * alpha) -- smoothstep

	Lighting.Brightness = lerp(a.b, b.b, alpha)
	Lighting.Ambient = lerp(a.amb, b.amb, alpha)
	Lighting.OutdoorAmbient = lerp(a.out, b.out, alpha)
	Lighting.ColorShift_Top = lerp(a.top, b.top, alpha)
	Lighting.ExposureCompensation = lerp(a.exp, b.exp, alpha)

	atmosphere.Color = lerp(a.atm, b.atm, alpha)
	atmosphere.Decay = lerp(a.decay, b.decay, alpha)
	atmosphere.Density = lerp(a.dens, b.dens, alpha)
	atmosphere.Haze = lerp(a.haze, b.haze, alpha)
	atmosphere.Glare = lerp(a.glare, b.glare, alpha)
	atmosphere.Offset = 0.25

	sunRays.Intensity = lerp(a.rays, b.rays, alpha)
	sunRays.Spread = 0.8
end

local clock = START_TIME
Lighting.ClockTime = clock
applyLighting(clock)

RunService.Heartbeat:Connect(function(dt)
	local isDay = clock >= SUNRISE and clock < SUNSET
	local hoursPerSecond = 12 / (isDay and DAY_LENGTH or NIGHT_LENGTH)

	clock = (clock + dt * hoursPerSecond) % 24
	Lighting.ClockTime = clock
	applyLighting(clock)
end)
