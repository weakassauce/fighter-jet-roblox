--!strict
-- Chase + cockpit camera. Chase camera follows tightly with world-up so rolls
-- don't dizzy the player. Cockpit cam uses jet up so the canopy view banks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local CAM = Config.CAMERA

local Camera = {}
Camera.__index = Camera

function Camera.new(viewport: Camera)
	local self = setmetatable({}, Camera)
	self.viewport = viewport
	self.view = "chase" :: "chase" | "cockpit"
	self.camUp = Vector3.new(0, 1, 0)
	self.pos = Vector3.new()
	self.initialized = false
	viewport.CameraType = Enum.CameraType.Scriptable
	return self
end

function Camera:toggleView()
	self.view = if self.view == "chase" then "cockpit" else "chase"
end

local function lerpVec(a: Vector3, b: Vector3, t: number): Vector3
	return a:Lerp(b, t)
end

function Camera:update(dt: number, flight: any)
	local offset = if self.view == "chase" then CAM.chaseOffset else CAM.cockpitOffset
	-- Convert body-frame offset (x=right, y=up, z=behind) into world via flight.cframe
	local worldOffset = flight:right() * offset.X
		+ flight:up() * offset.Y
		+ -flight:forward() * offset.Z

	local desired = flight.position + worldOffset
	if not self.initialized then
		self.pos = desired
		self.initialized = true
	else
		local k = if self.view == "chase" then 1 - math.exp(-dt * CAM.chaseLerp) else 1
		self.pos = lerpVec(self.pos, desired, k)
	end

	local lookAhead = if self.view == "chase" then CAM.chaseLookAhead else CAM.cockpitLookAhead
	local target = flight.position + flight:forward() * lookAhead

	local upTarget = if self.view == "chase" then Vector3.new(0, 1, 0) else flight:up()
	self.camUp = lerpVec(self.camUp, upTarget, 1 - math.exp(-dt * 6))

	self.viewport.CFrame = CFrame.lookAt(self.pos, target, self.camUp)
end

return Camera
