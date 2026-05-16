--!strict
-- PetService.server.lua
-- Authoritative server module for pet lifecycle: load/save, spawn, age, customization.
--
-- Age model (Phase B): wall-clock and offline-accruing.
--   Age = (os.time() - bornAtUnix) + bonusSeconds
-- `bornAtUnix` is set once at first spawn. `bonusSeconds` is the only mutable
-- bucket and is used by Steal Time (Phase E.b) to add/subtract age without
-- rewriting bornAtUnix.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Catalog   = require(Shared:WaitForChild("Catalog"))
local PetConfig = require(Shared:WaitForChild("PetConfig"))
local Remotes   = require(Shared:WaitForChild("Remotes"))

local petStore = DataStoreService:GetDataStore("Pets_v1")

local PetService = {}

-- userId -> live record (mirrors DataStore between saves)
local liveRecords: { [number]: PetRecord } = {}
-- userId -> spawned Model in workspace.Pets (only present while tool is equipped)
local liveModels:  { [number]: Model } = {}
-- userId -> the summon Tool in the player's Backpack
local liveTools:   { [number]: Tool } = {}

export type PetRecord = {
	name: string,
	colorId: string,
	faceId: string,
	hatId: string,
	hideName: boolean,
	bornAtUnix: number,
	bonusSeconds: number,
	hasAdmin: boolean,
	lastStealByVictim: { [number]: number }, -- victimUserId -> os.time of last steal AGAINST them by anyone
}

----------------------------------------------------------------
-- Defaults
----------------------------------------------------------------
local function newRecord(): PetRecord
	return {
		name              = "",            -- empty triggers the first-spawn name modal
		colorId           = "gray",
		faceId            = "smile_basic",
		hatId             = "none",
		hideName          = false,
		bornAtUnix        = os.time(),
		bonusSeconds      = 0,
		hasAdmin          = false,
		lastStealByVictim = {},
	}
end

----------------------------------------------------------------
-- Public helpers (consumed by other server modules)
----------------------------------------------------------------
function PetService.getRecord(userId: number): PetRecord?
	return liveRecords[userId]
end

function PetService.getModel(userId: number): Model?
	return liveModels[userId]
end

function PetService.computeAgeSeconds(rec: PetRecord): number
	return math.max(0, (os.time() - rec.bornAtUnix) + rec.bonusSeconds)
end

local function formatAge(totalSeconds: number): string
	local s = math.floor(totalSeconds)
	local days  = math.floor(s / 86400); s = s % 86400
	local hours = math.floor(s / 3600);  s = s % 3600
	local mins  = math.floor(s / 60);    s = s % 60
	return string.format("%02d:%02d:%02d:%02d", days, hours, mins, s)
end
PetService.formatAge = formatAge

----------------------------------------------------------------
-- DataStore
----------------------------------------------------------------
local function loadRecord(userId: number): PetRecord
	local key = "pet_" .. userId
	local ok, data = pcall(function()
		return petStore:GetAsync(key)
	end)
	if ok and type(data) == "table" then
		-- merge against defaults so future fields don't crash old records
		local rec = newRecord()
		for k, v in pairs(data) do
			(rec :: any)[k] = v
		end
		return rec
	end
	return newRecord()
end

local function saveRecord(userId: number, rec: PetRecord)
	local key = "pet_" .. userId
	pcall(function()
		petStore:UpdateAsync(key, function()
			return rec
		end)
	end)
end

-- For offline victims: write directly to the DataStore without a live record.
function PetService.applyAgeDeltaOffline(victimUserId: number, deltaSeconds: number)
	local key = "pet_" .. victimUserId
	pcall(function()
		petStore:UpdateAsync(key, function(old)
			if type(old) ~= "table" then return old end
			old.bonusSeconds = (old.bonusSeconds or 0) + deltaSeconds
			-- clamp so Age stays >= 0
			local hypo = (os.time() - (old.bornAtUnix or os.time())) + old.bonusSeconds
			if hypo < 0 then
				old.bonusSeconds = old.bonusSeconds - hypo  -- nudge back to 0
			end
			return old
		end)
	end)
end

----------------------------------------------------------------
-- Spawning
----------------------------------------------------------------
local function ensurePetsFolder(): Folder
	local f = workspace:FindFirstChild("Pets")
	if not f then
		f = Instance.new("Folder")
		f.Name = "Pets"
		f.Parent = workspace
	end
	return f
end

local function buildPlaceholderModel(): Model
	-- If PetConfig.PetMeshId is filled in, use a MeshPart with that asset.
	-- Otherwise fall back to a gray Slate placeholder so the game is playable
	-- before any asset upload.
	local model = Instance.new("Model")
	model.Name = "Pet"

	local hasMesh = type(PetConfig.PetMeshId) == "string"
		and PetConfig.PetMeshId ~= ""
		and PetConfig.PetMeshId ~= "rbxassetid://0"

	local body: BasePart
	if hasMesh then
		-- PetConfig.PetMeshId is expected to be an *asset* id pointing at a
		-- Model that contains the Tung Tung Tung Sahur mesh. InsertService
		-- loads the model and we grab the first MeshPart inside.
		local idNum = tonumber(string.match(PetConfig.PetMeshId, "%d+"))
		local ok, loaded
		if idNum then
			ok, loaded = pcall(function()
				return game:GetService("InsertService"):LoadAsset(idNum)
			end)
		end

		local found: BasePart?
		if ok and loaded then
			-- Walk the loaded tree, find the first BasePart (MeshPart preferred)
			for _, desc in ipairs(loaded:GetDescendants()) do
				if desc:IsA("MeshPart") or desc:IsA("Part") then
					found = desc
					if desc:IsA("MeshPart") then break end
				end
			end
		end

		if found then
			-- Clone so the original loaded model can be discarded
			local mesh = found:Clone()
			mesh.Anchored = false
			mesh.CanCollide = true
			mesh.Massless = false
			mesh.Size = mesh.Size * PetConfig.PetScale
			body = mesh
			if loaded then loaded:Destroy() end
		else
			warn("[PetService] Could not find a MeshPart inside asset", PetConfig.PetMeshId, "- using placeholder")
			local part = Instance.new("Part")
			part.Size = Vector3.new(4, 5, 3)
			part.Material = Enum.Material.Slate
			part.Color = Color3.fromRGB(110, 110, 110)
			body = part
		end
	else
		body = Instance.new("Part")
		body.Size = Vector3.new(4, 5, 3)
		body.Material = Enum.Material.Slate
		body.Color = Color3.fromRGB(110, 110, 110)
	end
	body.Name = "Body"
	body.Anchored = false
	body.CanCollide = true
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model
	model.PrimaryPart = body

	local face = Instance.new("Decal")
	face.Name = "FaceDecal"
	face.Face = Enum.NormalId.Front
	face.Texture = "" -- set when a face is applied
	face.Parent = body

	local hatAttach = Instance.new("Attachment")
	hatAttach.Name = "HatAttachment"
	-- Tune for the Tung mesh: nudge right to center on his head, lower onto
	-- his scalp instead of floating above. Adjust here if hats look off.
	hatAttach.Position = Vector3.new(0.3, body.Size.Y / 2 - 0.4, 0)
	hatAttach.Parent = body

	-- ProximityPrompt for Steal Time (Phase E.b). Any other player can hold this
	-- to drain `StealPerTick` seconds from this pet's age.
	-- The prompt is *enabled per-client* by a LocalScript so the owner never
	-- sees their own prompt.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal Time"
	prompt.ObjectText = "Pet"
	prompt.HoldDuration = PetConfig.StealHoldSeconds
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	-- We don't use a Humanoid for locomotion; ActionService moves the pet
	-- with a LinearVelocity since the Tung mesh isn't an R6/R15 rig.
	-- Pre-create the mover instances; ActionService toggles their Enabled.
	local moveAttach = Instance.new("Attachment")
	moveAttach.Name = "MoveAttach"
	moveAttach.Parent = body

	local linearVel = Instance.new("LinearVelocity")
	linearVel.Name = "WalkVelocity"
	linearVel.Attachment0 = moveAttach
	linearVel.MaxForce = math.huge
	linearVel.VectorVelocity = Vector3.zero
	linearVel.Enabled = false
	linearVel.Parent = body

	local alignOrient = Instance.new("AlignOrientation")
	alignOrient.Name = "FaceForward"
	alignOrient.Attachment0 = moveAttach
	alignOrient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrient.MaxTorque = math.huge
	alignOrient.Responsiveness = 20
	alignOrient.Enabled = false
	alignOrient.Parent = body

	-- Floating UI: Age + Name billboard
	local bb = Instance.new("BillboardGui")
	bb.Name = "InfoBillboard"
	bb.Adornee = body
	bb.Size = UDim2.new(0, 220, 0, 80)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = body

	local ageLabel = Instance.new("TextLabel")
	ageLabel.Name = "AgeLabel"
	ageLabel.BackgroundTransparency = 1
	ageLabel.Size = UDim2.new(1, 0, 0.5, 0)
	ageLabel.Position = UDim2.new(0, 0, 0, 0)
	ageLabel.Font = Enum.Font.FredokaOne
	ageLabel.TextScaled = true
	ageLabel.TextColor3 = Color3.new(1, 1, 1)
	ageLabel.TextStrokeTransparency = 0
	ageLabel.Text = "Age: 00:00:00:00"
	ageLabel.Parent = bb

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "OwnerLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.5, 0)
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Text = ""
	nameLabel.Parent = bb

	return model
end

local function applyVisuals(model: Model, rec: PetRecord, ownerName: string)
	local body = model:FindFirstChild("Body") :: BasePart?
	if not body then return end

	-- Color tint: MeshPart with a TextureID ignores BasePart.Color visually.
	-- Workaround: use a Highlight instance as a glow tint. Default white +
	-- transparent = no effect; any other color overlays the mesh.
	local colorEntry = Catalog.ColorById[rec.colorId]
	if colorEntry then
		body.Color = colorEntry.color
		local existing = model:FindFirstChild("ColorTint") :: Highlight?
		if not existing then
			existing = Instance.new("Highlight")
			existing.Name = "ColorTint"
			existing.Adornee = body
			existing.DepthMode = Enum.HighlightDepthMode.Occluded
			existing.FillTransparency = 0.55
			existing.OutlineTransparency = 1
			existing.Parent = model
		end
		if rec.colorId == "white" then
			existing.FillTransparency = 1 -- effectively off
		else
			existing.FillTransparency = 0.55
			existing.FillColor = colorEntry.color
		end
	end

	local faceEntry = Catalog.FaceById[rec.faceId]
	local decal = body:FindFirstChild("FaceDecal") :: Decal?
	if decal and faceEntry then
		decal.Texture = faceEntry.decal
	end

	-- Hat: remove any existing hat, then attach the new one.
	for _, child in ipairs(model:GetChildren()) do
		if child.Name == "HatMesh" then child:Destroy() end
	end
	local hatEntry = Catalog.HatById[rec.hatId]
	if hatEntry and hatEntry.id ~= "none" then
		-- Look for a pre-imported template under ReplicatedStorage.Assets.Hats
		-- named the same as the catalog id. Falls back to InsertService for
		-- assets the place owner actually owns.
		local hatTemplate: Instance? = nil
		local hatsFolder = game:GetService("ReplicatedStorage")
			:FindFirstChild("Assets") and game:GetService("ReplicatedStorage").Assets:FindFirstChild("Hats")
		if hatsFolder then
			hatTemplate = hatsFolder:FindFirstChild(hatEntry.id)
		end

		if not hatTemplate
			and type(hatEntry.accessory) == "string"
			and hatEntry.accessory ~= ""
			and hatEntry.accessory ~= "rbxassetid://0"
		then
			local idNum = tonumber(string.match(hatEntry.accessory, "%d+"))
			if idNum then
				local ok, loadedOrErr = pcall(function()
					return game:GetService("InsertService"):LoadAsset(idNum)
				end)
				if not ok then
					warn("[PetService] LoadAsset failed for hat", hatEntry.id, "(id", idNum, "):", loadedOrErr,
						"-- drop the model into ReplicatedStorage.Assets.Hats named '" .. hatEntry.id .. "' to fix")
				else
					hatTemplate = loadedOrErr :: Instance
				end
			end
		end

		if hatTemplate then
			local mesh: BasePart? = nil
			for _, d in ipairs(hatTemplate:GetDescendants()) do
				if d:IsA("MeshPart") then mesh = d :: BasePart; break end
			end
			if not mesh then
				if hatTemplate:IsA("BasePart") then
					mesh = hatTemplate :: BasePart
				else
					for _, d in ipairs(hatTemplate:GetDescendants()) do
						if d:IsA("BasePart") then mesh = d :: BasePart; break end
					end
				end
			end
			if mesh then
				local hatPart = mesh:Clone()
				hatPart.Name = "HatMesh"
				hatPart.Anchored = false
				hatPart.CanCollide = false
				hatPart.Massless = true
				local hatAttachInBody = body:FindFirstChild("HatAttachment") :: Attachment?
				if hatAttachInBody then
					hatPart.CFrame = hatAttachInBody.WorldCFrame
				else
					hatPart.CFrame = body.CFrame * CFrame.new(0, body.Size.Y / 2 + hatPart.Size.Y / 2, 0)
				end
				hatPart.Parent = model
				local w = Instance.new("WeldConstraint")
				w.Part0 = hatPart
				w.Part1 = body
				w.Parent = hatPart
			else
				warn("[PetService] No BasePart found in template for hat", hatEntry.id)
			end
			-- Only destroy if we created the tree (InsertService); not if it's a child of ReplicatedStorage
			if hatTemplate.Parent and not hatTemplate:IsDescendantOf(game:GetService("ReplicatedStorage")) then
				hatTemplate:Destroy()
			end
		end
	end

	-- Billboard text + visibility
	local bb = body:FindFirstChild("InfoBillboard") :: BillboardGui?
	if bb then
		bb.Enabled = not rec.hideName
		local nameLabel = bb:FindFirstChild("OwnerLabel") :: TextLabel?
		if nameLabel then
			local displayName = (rec.name ~= "" and rec.name) or ownerName
			nameLabel.Text = displayName
		end
	end
end
PetService.applyVisuals = applyVisuals

local function spawnPetForPlayer(player: Player, rec: PetRecord)
	-- Despawn any existing instance first (e.g. re-equip)
	local existing = liveModels[player.UserId]
	if existing then
		existing:Destroy()
		liveModels[player.UserId] = nil
	end

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local model = buildPlaceholderModel()
	model.Name = "Pet_" .. player.UserId
	local body = model:FindFirstChild("Body") :: BasePart
	body.CFrame = hrp.CFrame * CFrame.new(PetConfig.SpawnOffset)
	model.Parent = ensurePetsFolder()

	liveModels[player.UserId] = model
	applyVisuals(model, rec, player.Name)
end

local function despawnPetForPlayer(userId: number)
	local model = liveModels[userId]
	if model then
		model:Destroy()
	end
	liveModels[userId] = nil
end

local function buildSummonTool(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Tung Tung Tung Sahur"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Summon your Tung Tung Tung Sahur (press 1)"

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Material = Enum.Material.Slate
	handle.Color = Color3.fromRGB(110, 110, 110)
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool

	return tool
end

local function giveSummonTool(player: Player)
	-- Remove any stale instance (re-spawn case)
	local existing = liveTools[player.UserId]
	if existing then
		existing:Destroy()
	end

	local tool = buildSummonTool()
	tool.Parent = player:WaitForChild("Backpack")
	liveTools[player.UserId] = tool

	tool.Equipped:Connect(function()
		local rec = liveRecords[player.UserId]
		if rec then
			spawnPetForPlayer(player, rec)
			-- Auto-start walk so Tung follows you on a leash immediately.
			task.defer(function()
				local svc = _G.ActionService
				if svc and svc.startWalk then
					svc.startWalk(player)
				end
			end)
		end
	end)
	tool.Unequipped:Connect(function()
		local svc = _G.ActionService
		if svc and svc.stopWalk then
			svc.stopWalk(player)
		end
		despawnPetForPlayer(player.UserId)
	end)
end

----------------------------------------------------------------
-- First-spawn name flow
----------------------------------------------------------------
local function filterName(player: Player, raw: string): string
	if type(raw) ~= "string" then return "" end
	raw = string.sub(raw, 1, PetConfig.NameMaxLength)
	local ok, filtered = pcall(function()
		local res = TextService:FilterStringAsync(raw, player.UserId)
		return res:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(filtered) == "string" and #filtered > 0 then
		return filtered
	end
	return "..."
end

----------------------------------------------------------------
-- Player lifecycle
----------------------------------------------------------------
local function onPlayerAdded(player: Player)
	local rec = loadRecord(player.UserId)
	liveRecords[player.UserId] = rec

	-- Give the summon Tool every time the character (re)spawns. Backpack
	-- contents reset on death/respawn so we re-add it.
	local function provision()
		giveSummonTool(player)
	end
	player.CharacterAdded:Connect(provision)
	if player.Character then
		provision()
	end

	-- Show the name modal on every server join. Client receives the
	-- current saved name as a prefill so the user can just hit OK to keep it.
	task.defer(function()
		Remotes.event("RequestName"):FireClient(player, rec.name)
	end)
end

local function onPlayerRemoving(player: Player)
	local rec = liveRecords[player.UserId]
	if rec then
		saveRecord(player.UserId, rec)
	end
	liveRecords[player.UserId] = nil
	despawnPetForPlayer(player.UserId)
	local tool = liveTools[player.UserId]
	if tool then
		tool:Destroy()
	end
	liveTools[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

----------------------------------------------------------------
-- Remote handlers (Phase B subset: name + GetPetState)
-- Color / Face / Hat / Hide / Action / Steal / Admin land in their own phases.
----------------------------------------------------------------
Remotes.event("SetName").OnServerEvent:Connect(function(player, raw)
	local rec = liveRecords[player.UserId]
	if not rec then return end
	local clean = filterName(player, tostring(raw or ""))
	if #clean == 0 then return end
	rec.name = clean
	local model = liveModels[player.UserId]
	if model then
		applyVisuals(model, rec, player.Name)
	end
end)

Remotes.event("SetColor").OnServerEvent:Connect(function(player, colorId)
	local rec = liveRecords[player.UserId]
	if not rec then return end
	if type(colorId) ~= "string" then return end
	if not Catalog.ColorById[colorId] then return end
	rec.colorId = colorId
	local model = liveModels[player.UserId]
	if model then
		applyVisuals(model, rec, player.Name)
	end
end)

Remotes.event("SetFace").OnServerEvent:Connect(function(player, faceId)
	local rec = liveRecords[player.UserId]
	if not rec then return end
	if type(faceId) ~= "string" then return end
	if not Catalog.FaceById[faceId] then return end
	rec.faceId = faceId
	local model = liveModels[player.UserId]
	if model then
		applyVisuals(model, rec, player.Name)
	end
end)

Remotes.event("SetHat").OnServerEvent:Connect(function(player, hatId)
	local rec = liveRecords[player.UserId]
	if not rec then return end
	if type(hatId) ~= "string" then return end
	if not Catalog.HatById[hatId] then return end
	rec.hatId = hatId
	local model = liveModels[player.UserId]
	if model then
		applyVisuals(model, rec, player.Name)
	end
end)

Remotes.event("ToggleHideName").OnServerEvent:Connect(function(player)
	local rec = liveRecords[player.UserId]
	if not rec then return end
	rec.hideName = not rec.hideName
	local model = liveModels[player.UserId]
	if model then
		applyVisuals(model, rec, player.Name)
	end
end)

Remotes.func("GetPetState").OnServerInvoke = function(player)
	local rec = liveRecords[player.UserId]
	if not rec then return nil end
	return {
		name         = rec.name,
		colorId      = rec.colorId,
		faceId       = rec.faceId,
		hatId        = rec.hatId,
		hideName     = rec.hideName,
		ageSeconds   = PetService.computeAgeSeconds(rec),
		hasAdmin     = rec.hasAdmin,
	}
end

----------------------------------------------------------------
-- Heartbeat: update Age billboard for every live pet
----------------------------------------------------------------
local lastTick = 0
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastTick < 1 then return end -- once per second is plenty for DD:HH:MM:SS
	lastTick = now

	for userId, model in pairs(liveModels) do
		local rec = liveRecords[userId]
		if rec and model.Parent then
			local body = model:FindFirstChild("Body") :: BasePart?
			if body then
				local bb = body:FindFirstChild("InfoBillboard") :: BillboardGui?
				if bb then
					local ageLabel = bb:FindFirstChild("AgeLabel") :: TextLabel?
					if ageLabel then
						ageLabel.Text = "Age: " .. formatAge(PetService.computeAgeSeconds(rec))
					end
				end
			end
		end
	end
end)

----------------------------------------------------------------
-- Autosave loop
----------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(PetConfig.AutoSaveSec)
		for userId, rec in pairs(liveRecords) do
			saveRecord(userId, rec)
		end
	end
end)

-- Flush on shutdown
game:BindToClose(function()
	for userId, rec in pairs(liveRecords) do
		saveRecord(userId, rec)
	end
end)

-- Publish for other server scripts (ActionService, AdminService)
_G.PetService = PetService
