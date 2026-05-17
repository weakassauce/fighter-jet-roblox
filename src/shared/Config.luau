--!strict
-- Tunables in one place. Roblox uses studs; we treat 1 stud ≈ 0.28 m to keep
-- numbers comparable to the Three.js sim while feeling right in-game.

local Config = {}

-- World
Config.WORLD = {
	startAltitude = 600, -- studs
	startSpeed = 250, -- studs/s
	groundSize = 8000,
	fogStart = 800,
	fogEnd = 8000,
}

-- Jet
Config.JET = {
	mass = 9000, -- kg-ish, just a scaling factor
	maxThrust = 380000, -- N-equivalent; tuned for stud-space
	-- Aerodynamics
	liftSlope = 5.5,
	stallAoA = 0.42, -- ~24°
	stallSpeed = 140,
	postStallLift = 0.55,
	parasiticDrag = 0.014,
	inducedDragK = 0.04,
	wingArea = 28,
	airDensity = 1.10,
	-- Control rates (rad/s at full deflection)
	pitchRate = 0.85,
	rollRate = 2.2,
	yawRate = 0.4,
	throttleResponse = 0.55,
	-- Damage
	maxHull = 100,
}

-- Cameras
Config.CAMERA = {
	chaseOffset = Vector3.new(0, 9, 38), -- right, up, behind in body frame
	cockpitOffset = Vector3.new(0, 2.4, -3),
	chaseLerp = 20,
	chaseLookAhead = 36,
	cockpitLookAhead = 600,
}

return Config
