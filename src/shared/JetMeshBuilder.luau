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

function JetMeshBuilder.build(data: MeshData, name: string?): MeshPart
	local em = makeEditableMesh()
	local ids = table.create(#data.vertices)
	for i, v in ipairs(data.vertices) do
		ids[i] = em:AddVertex(Vector3.new(v[1], v[2], v[3]))
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
	meshPart.Material = Enum.Material.Metal
	meshPart.Color = Color3.fromRGB(120, 130, 145)
	return meshPart
end

return JetMeshBuilder
