--!strict
-- Builds a fighter-jet Model. If ReplicatedStorage.Shared.PlayerJet (or
-- EnemyJet) exists — e.g. a GLB imported via Studio and saved as .rbxm —
-- that asset is cloned and normalized. Otherwise we build a placeholder
-- from primitives. Local forward is -Z (matches Roblox CFrame.LookVector).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JetModel = {}

local TARGET_LENGTH = 28 -- studs along longest axis

-- Take an imported asset (Model or BasePart) and prepare it for flight:
-- wrap in a Model with PrimaryPart set, anchor + no-collide everything,
-- center the bounding box at origin, flip Y=π (TRELLIS GLBs face +Z by
-- default), and scale to TARGET_LENGTH along the longest axis.
local function normalizeAsset(template: Instance, name: string, length: number): Model
	local model: Model
	if template:IsA("Model") then
		model = template:Clone() :: Model
	elseif template:IsA("BasePart") then
		model = Instance.new("Model")
		local part = template:Clone()
		part.Parent = model
		model.PrimaryPart = part :: BasePart
	else
		-- Folder or other container — collect any BaseParts found.
		model = Instance.new("Model")
		for _, child in ipairs(template:GetDescendants()) do
			if child:IsA("BasePart") then
				local p = child:Clone()
				p.Parent = model
				if not model.PrimaryPart then
					model.PrimaryPart = p
				end
			end
		end
	end
	model.Name = name

	-- Configure every BasePart for jet use
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end

	-- Ensure a PrimaryPart for any code that wants it
	if not model.PrimaryPart then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				model.PrimaryPart = d
				break
			end
		end
	end
	assert(model.PrimaryPart, "imported asset has no BasePart")

	-- Center bounding box at origin
	local pivot, size = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() - pivot.Position)

	-- Flip 180° around Y so TRELLIS's +Z nose points toward -Z (Roblox forward)
	model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.pi, 0))

	-- Scale to TARGET_LENGTH on longest axis (pivot is at origin, so this scales around center)
	local longest = math.max(size.X, size.Y, size.Z)
	if longest > 0 and model.ScaleTo then
		model:ScaleTo(length / longest)
	end

	return model
end

local function makePart(name: string, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function wedge(name: string, size: Vector3, color: Color3): WedgePart
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = size
	w.Color = color
	w.Material = Enum.Material.Metal
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	return w
end

local function buildPlaceholder(name: string?, color: Color3?, accent: Color3?): Model
	local jet = Instance.new("Model")
	jet.Name = name or "PlayerJet"

	local bodyColor = color or Color3.fromRGB(96, 110, 130)
	local accentColor = accent or Color3.fromRGB(220, 90, 50)

	-- Fuselage (long block)
	local fuselage = makePart("Fuselage", Vector3.new(2.6, 2.4, 28), bodyColor)
	fuselage.Parent = jet

	-- Nose cone (wedge pointing forward = -Z)
	local nose = wedge("Nose", Vector3.new(2.6, 2.4, 7), bodyColor)
	nose.CFrame = CFrame.new(0, 0, -17.5) * CFrame.Angles(0, math.pi, 0)
	nose.Parent = jet

	-- Canopy (small dark wedge on top toward nose)
	local canopy = wedge("Canopy", Vector3.new(2.0, 1.2, 5), Color3.fromRGB(40, 50, 70))
	canopy.Material = Enum.Material.Glass
	canopy.Reflectance = 0.25
	canopy.CFrame = CFrame.new(0, 1.7, -6) * CFrame.Angles(0, math.pi, 0)
	canopy.Parent = jet

	-- Main wings (left + right)
	local wingL = makePart("WingL", Vector3.new(14, 0.5, 7), bodyColor)
	wingL.CFrame = CFrame.new(-7.5, -0.3, 1)
	wingL.Parent = jet
	local wingR = makePart("WingR", Vector3.new(14, 0.5, 7), bodyColor)
	wingR.CFrame = CFrame.new(7.5, -0.3, 1)
	wingR.Parent = jet

	-- Horizontal stabilizers
	local stabL = makePart("StabL", Vector3.new(6, 0.4, 3), bodyColor)
	stabL.CFrame = CFrame.new(-3.5, 0.2, 12)
	stabL.Parent = jet
	local stabR = makePart("StabR", Vector3.new(6, 0.4, 3), bodyColor)
	stabR.CFrame = CFrame.new(3.5, 0.2, 12)
	stabR.Parent = jet

	-- Vertical tail fin
	local tail = makePart("Tail", Vector3.new(0.4, 4, 4), bodyColor)
	tail.CFrame = CFrame.new(0, 2.6, 12)
	tail.Parent = jet

	-- Engine glow (neon part behind)
	local engine = makePart("EngineGlow", Vector3.new(1.6, 1.6, 0.4), Color3.fromRGB(255, 170, 60))
	engine.Material = Enum.Material.Neon
	engine.CFrame = CFrame.new(0, 0, 14.1)
	engine.Parent = jet

	-- Tail accent stripe
	local stripe = makePart("Stripe", Vector3.new(0.5, 3.5, 0.6), accentColor)
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.CFrame = CFrame.new(0, 2.6, 13.7)
	stripe.Parent = jet

	jet.PrimaryPart = fuselage
	return jet
end

-- Try to source a model from ReplicatedStorage.Shared by name (e.g. "PlayerJet"
-- saved from a Studio GLB import). Returns nil if not present.
local function findAsset(assetName: string): Instance?
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if not shared then
		return nil
	end
	local asset = shared:FindFirstChild(assetName)
	if asset and (asset:IsA("Model") or asset:IsA("BasePart") or asset:IsA("Folder")) then
		return asset
	end
	return nil
end

function JetModel.build(name: string?, color: Color3?, accent: Color3?): Model
	local label = name or "PlayerJet"
	-- Prefer imported assets named "PlayerJet" / "EnemyJet" under Shared.
	-- (Drop a .rbxm into src/shared/ with that name to use a real GLB asset.)
	local source = findAsset(label)
	if source then
		return normalizeAsset(source, label, TARGET_LENGTH)
	end
	return buildPlaceholder(label, color, accent)
end

return JetModel
