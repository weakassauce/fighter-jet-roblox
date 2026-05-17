-- Build a MeshPart from raw vertex+triangle data using EditableMesh.
-- This lets us embed a GLB-derived mesh inside the Rojo project — no Roblox
-- upload required.

local AssetService = game:GetService("AssetService")

local JetMeshBuilder = {}

type MeshData = {
	vertices: { { number } },  -- { {x, y, z}, ... }
	triangles: { { number } }, -- { {v1, v2, v3}, ... } (1-indexed)
}

local function makeEditableMesh()
	-- The exact constructor name has evolved across engine versions.
	if (AssetService :: any).CreateEditableMesh then
		return (AssetService :: any):CreateEditableMesh()
	elseif (AssetService :: any).CreateEditableMeshAsync then
		return (AssetService :: any):CreateEditableMeshAsync()
	else
		error("EditableMesh API not available in this engine version")
	end
end

local function createMeshPart(em: any): MeshPart
	-- Newest API takes Content; older accepts the EditableMesh directly.
	local Content_ = (_G :: any).Content or (getfenv() :: any).Content
	if Content_ and (Content_ :: any).fromObject then
		local content = (Content_ :: any).fromObject(em)
		return AssetService:CreateMeshPartAsync(content, {
			CollisionFidelity = Enum.CollisionFidelity.Hull,
		})
	end
	return (AssetService :: any):CreateMeshPartAsync(em)
end

local function setVertexColor(em: any, vid: number, c: { number })
	local color = Color3.new(c[1], c[2], c[3])
	-- Try a few signatures used across engine versions
	if em.SetVertexColor then
		pcall(function() em:SetVertexColor(vid, color) end)
	end
	if em.SetVertexColorAlpha then
		pcall(function() em:SetVertexColorAlpha(vid, 1) end)
	end
end

function JetMeshBuilder.build(data: any, name: string?): MeshPart
	local em = makeEditableMesh()
	local hasColors = data.colors ~= nil and #data.colors == #data.vertices

	local ids = table.create(#data.vertices)
	for i, v in ipairs(data.vertices) do
		ids[i] = em:AddVertex(Vector3.new(v[1], v[2], v[3]))
		if hasColors then
			setVertexColor(em, ids[i], data.colors[i])
		end
	end
	for _, tri in ipairs(data.triangles) do
		em:AddTriangle(ids[tri[1]], ids[tri[2]], ids[tri[3]])
	end

	local meshPart = createMeshPart(em)
	meshPart.Name = name or "JetMesh"
	meshPart.Anchored = true
	meshPart.CanCollide = false
	meshPart.CanQuery = false
	meshPart.CanTouch = false
	meshPart.Massless = true
	-- SmoothPlastic + white tint lets vertex colors come through cleanly,
	-- without the metallic sheen washing them out.
	meshPart.Material = Enum.Material.SmoothPlastic
	meshPart.Color = Color3.fromRGB(255, 255, 255)
	-- Some engine versions need this flipped to make vertex colors render
	if (meshPart :: any).UsePartColor ~= nil then
		(meshPart :: any).UsePartColor = false
	end
	return meshPart
end

return JetMeshBuilder
