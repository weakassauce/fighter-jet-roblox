--!strict
-- Flight model: thrust, lift, drag, gravity, stall, body-frame angular control.
-- The jet's primary Part is Anchored; we drive its CFrame ourselves each frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local JET = Config.JET
local WORLD = Config.WORLD

local Flight = {}
Flight.__index = Flight

local function clamp(v, lo, hi)
	if v < lo then
		return lo
	end
	if v > hi then
		return hi
	end
	return v
end

function Flight.new(model: Model)
	local primary = assert(model.PrimaryPart, "jet model needs PrimaryPart")
	local self = setmetatable({}, Flight)
	self.model = model
	self.primary = primary
	self.position = Vector3.new(0, WORLD.startAltitude, 0)
	self.cframe = CFrame.new(self.position) -- forward = -Z by default
	self.velocity = self.cframe.LookVector * WORLD.startSpeed
	self.throttle = 0.75
	self.throttleTarget = 0.75
	self.hull = JET.maxHull
	self.aoa = 0
	self.stalled = false
	self.nearStall = false
	self.dead = false
	self.gLoad = 1
	return self
end

function Flight:reset()
	self.position = Vector3.new(0, WORLD.startAltitude, 0)
	self.cframe = CFrame.new(self.position)
	self.velocity = self.cframe.LookVector * WORLD.startSpeed
	self.throttle = 0.75
	self.throttleTarget = 0.75
	self.hull = JET.maxHull
	self.stalled = false
	self.nearStall = false
	self.dead = false
	self.gLoad = 1
end

function Flight:forward(): Vector3
	return self.cframe.LookVector
end
function Flight:up(): Vector3
	return self.cframe.UpVector
end
function Flight:right(): Vector3
	return self.cframe.RightVector
end

function Flight:takeDamage(d: number)
	self.hull -= d
	if self.hull <= 0 then
		self.dead = true
	end
end

function Flight:update(dt: number, controls: { [string]: number })
	if self.dead then
		return
	end

	-- Throttle
	self.throttleTarget = clamp(self.throttleTarget + controls.throttle * dt * 0.6, 0, 1)
	self.throttle += (self.throttleTarget - self.throttle)
		* math.min(1, dt * JET.throttleResponse * 4)

	-- Control authority scales with airspeed (sluggish at low speed)
	local speed = self.velocity.Magnitude
	local ctrlAuthority = clamp(speed / 80, 0.18, 1.0)
	local pitchAng = controls.pitch * JET.pitchRate * dt * ctrlAuthority
	local rollAng = controls.roll * JET.rollRate * dt * ctrlAuthority
	local yawAng = controls.yaw * JET.yawRate * dt * ctrlAuthority

	-- Apply body-frame rotations (CFrame.Angles is intrinsic in YXZ; we
	-- compose roll/pitch/yaw separately and right-multiply for body frame).
	local rot = CFrame.Angles(0, 0, -rollAng)
		* CFrame.Angles(pitchAng, 0, 0)
		* CFrame.Angles(0, yawAng, 0)
	self.cframe = CFrame.new(self.position) * (self.cframe - self.cframe.Position) * rot

	-- Weathervaning: nudge nose toward velocity vector
	if speed > 5 then
		local vDir = self.velocity.Unit
		local fwd = self:forward()
		local axisVec = fwd:Cross(vDir)
		local dotFV = math.clamp(fwd:Dot(vDir), -1, 1)
		local misalign = math.acos(dotFV)
		if axisVec.Magnitude > 1e-6 and misalign > 0.01 then
			local axisN = axisVec.Unit
			local step = math.min(misalign, 0.5 * dt * (speed / 100))
			local q = CFrame.fromAxisAngle(axisN, step)
			-- premultiply (world-frame rotation): rotation about world axis applied to current cf
			self.cframe = CFrame.new(self.position) * q * (self.cframe - self.cframe.Position)
		end
	end

	local fwd = self:forward()
	local up = self:up()

	-- AoA: angle between velocity and forward, signed in pitch plane
	local aoa = 0
	if speed > 1 then
		local vDir = self.velocity.Unit
		local dotF = math.clamp(vDir:Dot(fwd), -1, 1)
		aoa = math.acos(dotF)
		if vDir:Dot(up) > 0 then
			aoa = -aoa
		end
	end
	self.aoa = aoa

	-- Energy-based stall
	local absAoA = math.abs(aoa)
	local speedFactor = math.min(1, speed / JET.stallSpeed)
	local effectiveStallAoA = JET.stallAoA + speedFactor * 0.4
	self.stalled = absAoA > effectiveStallAoA
	self.nearStall = absAoA > effectiveStallAoA * 0.75
	local cl
	if self.stalled then
		cl = JET.liftSlope * effectiveStallAoA * JET.postStallLift
			* (aoa >= 0 and 1 or -1)
	else
		cl = JET.liftSlope * aoa
	end

	local q = 0.5 * JET.airDensity * speed * speed
	local liftMag = cl * q * JET.wingArea
	local dragCoef = JET.parasiticDrag + JET.inducedDragK * cl * cl
	local dragMag = dragCoef * q * JET.wingArea

	-- Forces in world space
	local force = Vector3.zero
	-- Thrust along forward
	force += fwd * (JET.maxThrust * self.throttle)
	-- Drag opposes velocity
	if speed > 0.1 then
		force += self.velocity * (-dragMag / speed)
	end
	-- Lift perpendicular to velocity, in body-up plane
	if speed > 1 then
		local vDir = self.velocity.Unit
		local liftDir = up - vDir * up:Dot(vDir)
		if liftDir.Magnitude > 1e-6 then
			force += liftDir.Unit * liftMag
		end
	end
	-- Gravity (workspace gravity is in studs/s²)
	force += Vector3.new(0, -workspace.Gravity * JET.mass, 0)

	local accel = force / JET.mass
	self.velocity += accel * dt
	self.position += self.velocity * dt

	-- G-load (just the magnitude relative to weight)
	if speed > 1 then
		self.gLoad = liftMag / (JET.mass * workspace.Gravity)
	end

	-- Cheap ground floor
	if self.position.Y < 5 then
		self.position = Vector3.new(self.position.X, 5, self.position.Z)
		if self.velocity.Y < 0 then
			local impact = -self.velocity.Y
			self.hull -= impact * 0.1
			if self.hull <= 0 then
				self.dead = true
			end
			self.velocity = Vector3.new(self.velocity.X * 0.95, 0, self.velocity.Z * 0.95)
		end
	end

	-- Apply to model rigidly via PivotTo (moves all anchored parts together).
	self.cframe = CFrame.new(self.position) * (self.cframe - self.cframe.Position)
	self.model:PivotTo(self.cframe)
end

return Flight
