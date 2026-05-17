--!strict
-- Keyboard input → normalized control axes. Same layout as the Three.js build:
--   W/S        throttle up/down
--   A/D        roll
--   ↑/↓        pitch (Up = nose up)
--   ←/→ or Q/E rudder
--   Space      guns,  F missile,  R reset,  V view toggle

local UserInputService = game:GetService("UserInputService")

local Input = {}
Input.__index = Input

function Input.new()
	local self = setmetatable({}, Input)
	self.keys = {} :: { [Enum.KeyCode]: boolean }
	self.actions = {} :: { string }

	UserInputService.InputBegan:Connect(function(io, processed)
		if processed then
			return
		end
		if io.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		local fresh = not self.keys[io.KeyCode]
		self.keys[io.KeyCode] = true
		if fresh then
			if io.KeyCode == Enum.KeyCode.R then
				table.insert(self.actions, "reset")
			elseif io.KeyCode == Enum.KeyCode.V then
				table.insert(self.actions, "toggleView")
			elseif io.KeyCode == Enum.KeyCode.F then
				table.insert(self.actions, "fireMissile")
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(io)
		if io.UserInputType == Enum.UserInputType.Keyboard then
			self.keys[io.KeyCode] = nil
		end
	end)
	UserInputService.WindowFocusReleased:Connect(function()
		table.clear(self.keys)
	end)

	return self
end

local function ax(self: any, pos: Enum.KeyCode, neg: Enum.KeyCode): number
	local p = self.keys[pos] and 1 or 0
	local n = self.keys[neg] and 1 or 0
	return p - n
end

function Input:axes()
	local yaw = ax(self, Enum.KeyCode.Right, Enum.KeyCode.Left)
		+ ax(self, Enum.KeyCode.E, Enum.KeyCode.Q)
	if yaw > 1 then
		yaw = 1
	elseif yaw < -1 then
		yaw = -1
	end
	return {
		pitch = ax(self, Enum.KeyCode.Up, Enum.KeyCode.Down),
		roll = ax(self, Enum.KeyCode.D, Enum.KeyCode.A),
		yaw = yaw,
		throttle = ax(self, Enum.KeyCode.W, Enum.KeyCode.S),
		firingGuns = self.keys[Enum.KeyCode.Space] == true,
	}
end

function Input:drainActions(): { string }
	local out = self.actions
	self.actions = {}
	return out
end

return Input
