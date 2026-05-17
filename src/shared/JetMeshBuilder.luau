-- Build a MeshPart from raw vertex+triangle data using EditableMesh.
-- Tries multiple API shapes since they've shifted across Roblox versions.

local AssetService = game:GetService("AssetService")

local JetMeshBuilder = {}

local function tryCalls(label, attempts)
	local errs = {}
	for _, a in ipairs(attempts) do
		local name, fn = a[1], a[2]
		local ok, result = pcall(fn)
		if ok and result then
			print(("[JetMeshBuilder] %s via: %s"):format(label, name))
			return result
		end
		table.insert(errs, ("%s -> %s"):format(name, tostring(result)))
	end
	error(("[JetMeshBuilder] all %s attempts failed:\n  %s"):format(label, table.concat(errs, "\n  ")))
end

local function makeEditableMesh()
	-- Modern API needs Content.none / Content reference; older just calls
	-- CreateEditableMesh() directly.
	local Content_ = rawget(getfenv(), "Content")

	return tryCalls("EditableMesh create", {
		{ "CreateEditableMesh()", function() return AssetService:CreateEditableMesh() end },
		{ "CreateEditableMeshAsync(Content.none)", function()
			return AssetService:CreateEditableMeshAsync((Content_ and Content_.none) or nil)
		end },
		{ "CreateEditableMeshAsync()", function() return AssetService:CreateEditableMeshAsync() end },
	})
end

local function makeMeshPart(em)
	local Content_ = rawget(getfenv(), "Content")
	local wrapped: any
	if Content_ and Content_.fromObject then
		wrapped = Content_.fromObject(em)
	end

	return tryCalls("MeshPart create", {
		{ "CreateMeshPartAsync(content, options)", function()
			if not wrapped then error("no Content wrapper") end
			return AssetService:CreateMeshPartAsync(wrapped, { CollisionFidelity = Enum.CollisionFidelity.Hull })
		end },
		{ "CreateMeshPartAsync(content)", function()
			if not wrapped then error("no Content wrapper") end
			return AssetService:CreateMeshPartAsync(wrapped)
		end },
		{ "CreateMeshPartAsync(em, options)", function()
			return AssetService:CreateMeshPartAsync(em, { CollisionFidelity = Enum.CollisionFidelity.Hull })
		end },
		{ "CreateMeshPartAsync(em)", function() return AssetService:CreateMeshPartAsync(em) end },
	})
end

local function setVertexColor(em: any, vid: number, c: { number })
	local color = Color3.new(c[1], c[2], c[3])
	if em.SetVertexColor then
		pcall(function() em:SetVertexColor(vid, color) end)
	end
	if em.SetColor then
		pcall(function() em:SetColor(vid, color) end)
	end
	-- Try newer attribute-style API as well
	if em.SetAttribute then
		pcall(function() em:SetAttribute(vid, "Color", color) end)
	end
end

function JetMeshBuilder.build(data: any, name: string?): MeshPart
	local em = makeEditableMesh()
	local hasColors = data.colors ~= nil and #data.colors == #data.vertices
	print(("[JetMeshBuilder] building: %d verts, %d tris, colors=%s")
		:format(#data.vertices, #data.triangles, tostring(hasColors)))

	local ids = table.create(#data.vertices)
	for i, v in ipairs(data.vertices) do
		ids[i] = em:AddVertex(Vector3.new(v[1], v[2], v[3]))
		if hasColors then
			setVertexColor(em, ids[i], data.colors[i])
		end
	end
	for _, tri in ipairs(data.triangles) do
		pcall(function()
			em:AddTriangle(ids[tri[1]], ids[tri[2]], ids[tri[3]])
		end)
	end

	local meshPart = makeMeshPart(em)
	meshPart.Name = name or "JetMesh"
	meshPart.Anchored = true
	meshPart.CanCollide = false
	meshPart.CanQuery = false
	meshPart.CanTouch = false
	meshPart.Massless = true
	meshPart.Material = Enum.Material.SmoothPlastic
	meshPart.Color = Color3.fromRGB(255, 255, 255)
	if (meshPart :: any).UsePartColor ~= nil then
		(meshPart :: any).UsePartColor = false
	end
	if (meshPart :: any).UseVertexColors ~= nil then
		(meshPart :: any).UseVertexColors = true
	end
	return meshPart
end

return JetMeshBuilder
