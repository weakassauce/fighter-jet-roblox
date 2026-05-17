--!strict
-- Minimal HUD: airspeed, altitude, heading, throttle bar, AoA, stall light.

local Players = game:GetService("Players")

local function makeLabel(parent: Instance, text: string, pos: UDim2): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(159, 255, 166)
	l.TextStrokeTransparency = 0.4
	l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	l.Font = Enum.Font.Code
	l.TextSize = 18
	l.Size = UDim2.fromOffset(220, 22)
	l.Position = pos
	l.Text = text
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local Hud = {}
Hud.__index = Hud

function Hud.new()
	local self = setmetatable({}, Hud)
	local plr = Players.LocalPlayer
	local pg = plr:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "FighterHud"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = pg

	self.gui = gui
	self.speed = makeLabel(gui, "IAS 0 kt", UDim2.new(0, 24, 0, 24))
	self.alt = makeLabel(gui, "ALT 0 ft", UDim2.new(0, 24, 0, 48))
	self.heading = makeLabel(gui, "HDG 000°", UDim2.new(0, 24, 0, 72))
	self.aoa = makeLabel(gui, "AoA 0.0°", UDim2.new(0, 24, 0, 96))
	self.thr = makeLabel(gui, "THR 75%", UDim2.new(0, 24, 0, 120))

	-- Centered crosshair
	local cross = Instance.new("Frame")
	cross.AnchorPoint = Vector2.new(0.5, 0.5)
	cross.Position = UDim2.fromScale(0.5, 0.5)
	cross.Size = UDim2.fromOffset(32, 32)
	cross.BackgroundTransparency = 1
	cross.Parent = gui
	local function bar(p: UDim2, s: UDim2)
		local b = Instance.new("Frame")
		b.BackgroundColor3 = Color3.fromRGB(159, 255, 166)
		b.BorderSizePixel = 0
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = p
		b.Size = s
		b.Parent = cross
	end
	bar(UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(2, 14))
	bar(UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(14, 2))

	-- Stall warning panel (initially hidden)
	local stall = Instance.new("TextLabel")
	stall.AnchorPoint = Vector2.new(0.5, 0)
	stall.Position = UDim2.new(0.5, 0, 0.55, 0)
	stall.Size = UDim2.fromOffset(180, 28)
	stall.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	stall.BorderSizePixel = 0
	stall.Text = "STALL"
	stall.Font = Enum.Font.GothamBold
	stall.TextSize = 18
	stall.TextColor3 = Color3.fromRGB(0, 0, 0)
	stall.Visible = false
	stall.Parent = gui
	self.stallPanel = stall

	return self
end

function Hud:update(flight: any)
	local speed = flight.velocity.Magnitude
	-- Treat 1 stud ≈ 0.28 m → knots ~= studs/s * 0.544
	self.speed.Text = string.format("IAS %d kt", math.floor(speed * 0.544))
	self.alt.Text = string.format("ALT %d ft", math.floor(flight.position.Y * 0.92))

	local fwd = flight:forward()
	local heading = math.deg(math.atan2(fwd.X, -fwd.Z))
	if heading < 0 then
		heading += 360
	end
	self.heading.Text = string.format("HDG %03d°", math.floor(heading))
	self.aoa.Text = string.format("AoA %.1f°", math.deg(flight.aoa))
	self.thr.Text = string.format("THR %d%%", math.floor(flight.throttle * 100 + 0.5))

	if flight.stalled or flight.nearStall then
		local flash = math.sin(os.clock() * (flight.stalled and 10 or 5)) > 0
		self.stallPanel.Visible = flash
		self.stallPanel.Text = flight.stalled and "STALL" or "STALL WARN"
		self.stallPanel.BackgroundColor3 = flight.stalled
			and Color3.fromRGB(255, 50, 50)
			or Color3.fromRGB(255, 170, 0)
	else
		self.stallPanel.Visible = false
	end
end

return Hud
