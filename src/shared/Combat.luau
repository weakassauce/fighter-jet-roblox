--!strict
-- Combat / weapons / enemy tunables.

local Combat = {}

Combat.GUNS = {
	rateOfFire = 16,        -- rounds per second
	muzzleSpeed = 1600,     -- studs/s
	spread = 0.0035,
	range = 3200,
	damage = 8,
}

Combat.MISSILE = {
	speed = 800,
	acceleration = 400,
	maxSpeed = 1800,
	turnRate = 2.4,
	fuse = 12,
	damage = 70,
	lockCone = math.cos(0.5), -- ~28°
	lockRange = 9000,
	lockTime = 1.4,           -- seconds in cone to acquire full lock
}

Combat.ENEMIES = {
	count = 4,
	speed = 300,            -- studs/s
	turnRate = 0.7,
	gunRange = 1500,
	hull = 60,
}

return Combat
