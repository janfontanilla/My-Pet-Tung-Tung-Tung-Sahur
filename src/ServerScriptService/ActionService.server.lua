--!strict
-- ActionService.server.lua
-- Walk (pet follows owner), Carry (welded to RightHand), and Steal Time.

local PathfindingService = game:GetService("PathfindingService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Remotes   = require(Shared:WaitForChild("Remotes"))
local PetConfig = require(Shared:WaitForChild("PetConfig"))

-- Forward reference to PetService API (loaded once it's required by the
-- engine; we hop services to avoid require cycles).
local PetService
task.spawn(function()
	-- ServerScriptService runs as scripts not modules, so we reach PetService
	-- via _G if it published itself. To keep things simple we re-implement
	-- the small bits we need here.
end)

-- Per-pet action state
type State = "idle" | "walk" | "carry"
local activeState:  { [number]: State } = {}
local carryWelds:   { [number]: WeldConstraint } = {}
local leashBeams:   { [number]: Beam } = {}
local leashAttachs: { [number]: { Attachment } } = {}
-- Per-victim cooldown across all attackers
local stealCooldown: { [number]: number } = {}

local function getPet(userId: number): Model?
	local folder = workspace:FindFirstChild("Pets")
	if not folder then return nil end
	return folder:FindFirstChild("Pet_" .. userId) :: Model?
end

----------------------------------------------------------------
-- WALK: follow owner with a visible leash
----------------------------------------------------------------
local function attachLeash(player: Player, pet: Model)
	local char = player.Character
	if not char then return end
	local body = pet:FindFirstChild("Body") :: BasePart?
	local hand = char:FindFirstChild("RightHand") :: BasePart?
	if not body or not hand then return end

	local handAtt = Instance.new("Attachment")
	handAtt.Name = "LeashAttach_Owner"
	handAtt.Parent = hand

	local petAtt = Instance.new("Attachment")
	petAtt.Name = "LeashAttach_Pet"
	petAtt.Position = Vector3.new(0, body.Size.Y / 2, 0)
	petAtt.Parent = body

	local beam = Instance.new("Beam")
	beam.Attachment0 = handAtt
	beam.Attachment1 = petAtt
	beam.Width0 = 0.08
	beam.Width1 = 0.08
	beam.FaceCamera = true
	beam.Color = ColorSequence.new(Color3.fromRGB(80, 50, 20))
	beam.Transparency = NumberSequence.new(0.1)
	beam.Segments = 4
	beam.Parent = body

	leashBeams[player.UserId] = beam
	leashAttachs[player.UserId] = { handAtt, petAtt }
end

local function detachLeash(userId: number)
	local beam = leashBeams[userId]
	if beam then beam:Destroy() end
	leashBeams[userId] = nil
	local atts = leashAttachs[userId]
	if atts then
		for _, a in ipairs(atts) do a:Destroy() end
	end
	leashAttachs[userId] = nil
end

local function startWalk(player: Player)
	activeState[player.UserId] = "walk"
	local pet = getPet(player.UserId)
	if pet then attachLeash(player, pet) end
	task.spawn(function()
		while activeState[player.UserId] == "walk" do
			pet = getPet(player.UserId)
			local char = player.Character
			if not pet or not char then break end
			local petHrp = pet:FindFirstChild("HumanoidRootPart") :: BasePart?
			local petHum = pet:FindFirstChildOfClass("Humanoid")
			local ownerHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not petHrp or not petHum or not ownerHrp then break end

			-- Walk to a position just behind+right of the owner ("at heel")
			local heel = ownerHrp.CFrame * CFrame.new(2, 0, 3) -- right & behind
			local dist = (heel.Position - petHrp.Position).Magnitude
			if dist > 2.5 then
				local ok, path = pcall(function()
					local p = PathfindingService:CreatePath({
						AgentRadius = 2,
						AgentHeight = 5,
						AgentCanJump = true,
					})
					p:ComputeAsync(petHrp.Position, heel.Position)
					return p
				end)
				if ok and path and path.Status == Enum.PathStatus.Success then
					for _, wp in ipairs(path:GetWaypoints()) do
						if activeState[player.UserId] ~= "walk" then break end
						petHum:MoveTo(wp.Position)
						petHum.MoveToFinished:Wait()
					end
				else
					petHum:MoveTo(heel.Position)
				end
			end
			task.wait(1 / PetConfig.WalkUpdateHz)
		end
	end)
end

local function stopWalk(player: Player)
	if activeState[player.UserId] == "walk" then
		activeState[player.UserId] = "idle"
		detachLeash(player.UserId)
	end
end

----------------------------------------------------------------
-- CARRY: weld to player's right hand
----------------------------------------------------------------
local function startCarry(player: Player)
	local char = player.Character
	if not char then return end
	local pet = getPet(player.UserId)
	if not pet then return end
	local body = pet:FindFirstChild("Body") :: BasePart?
	local hand = char:FindFirstChild(PetConfig.CarryAttachment) :: BasePart?
	if not body or not hand then return end

	-- Disable humanoid movement while carried
	local hum = pet:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = true
		hum.WalkSpeed = 0
	end
	body.CanCollide = false

	-- Stand the pet upright on top of the player's right hand, facing forward
	-- relative to the hand. The hand's local +Y is "up" through the wrist.
	local liftY = body.Size.Y / 2 + hand.Size.Y / 2
	body.CFrame = hand.CFrame
		* CFrame.new(0, liftY, 0)
		* CFrame.Angles(0, math.pi, 0) -- face same way as player

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = hand
	weld.Parent = body
	carryWelds[player.UserId] = weld
	activeState[player.UserId] = "carry"
end

local function stopCarry(player: Player)
	local w = carryWelds[player.UserId]
	if w then
		w:Destroy()
		carryWelds[player.UserId] = nil
	end
	local pet = getPet(player.UserId)
	if pet then
		local body = pet:FindFirstChild("Body") :: BasePart?
		if body then body.CanCollide = true end
		local hum = pet:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.PlatformStand = false
			hum.WalkSpeed = PetConfig.WalkSpeed
		end
	end
	activeState[player.UserId] = "idle"
end

----------------------------------------------------------------
-- Remote: DoAction (walk | carry | idle)
----------------------------------------------------------------
Remotes.event("DoAction").OnServerEvent:Connect(function(player, actionId)
	if type(actionId) ~= "string" then return end
	local prev = activeState[player.UserId] or "idle"
	-- Toggle: clicking the same action again returns to idle.
	if actionId == prev then
		actionId = "idle"
	end
	-- Always cancel both first
	if prev == "walk" then stopWalk(player) end
	if prev == "carry" then stopCarry(player) end

	if actionId == "walk" then
		startWalk(player)
	elseif actionId == "carry" then
		startCarry(player)
	else
		activeState[player.UserId] = "idle"
	end
end)

----------------------------------------------------------------
-- Remote: StealTime (any player)
----------------------------------------------------------------
-- Lazy PetService grab from _G (set by PetService.server.lua below).
local function petSvc()
	return _G.PetService
end

local function tryTransfer(attackerId: number, victimId: number, seconds: number): boolean
	local svc = petSvc()
	if not svc then return false end

	local now = os.time()
	if (stealCooldown[victimId] or 0) > now then return false end
	stealCooldown[victimId] = now + PetConfig.StealCooldown

	local victimRec = svc.getRecord(victimId)
	if victimRec then
		-- Online victim: subtract from in-memory bonus
		victimRec.bonusSeconds = victimRec.bonusSeconds - seconds
		local hypo = (os.time() - victimRec.bornAtUnix) + victimRec.bonusSeconds
		if hypo < 0 then
			victimRec.bonusSeconds = victimRec.bonusSeconds - hypo
			seconds = seconds + hypo -- only transfer what we actually drained
		end
	else
		-- Offline victim: write through DataStore (clamped inside helper)
		svc.applyAgeDeltaOffline(victimId, -seconds)
	end

	local attackerRec = svc.getRecord(attackerId)
	if attackerRec then
		attackerRec.bonusSeconds = attackerRec.bonusSeconds + seconds
	else
		svc.applyAgeDeltaOffline(attackerId, seconds)
	end
	return true
end

Remotes.event("StealTime").OnServerEvent:Connect(function(player, targetUserId)
	if type(targetUserId) ~= "number" then return end
	if targetUserId == player.UserId then return end

	-- Proximity check: attacker must be within 12 studs of the victim's pet (if spawned)
	-- or 12 studs of the victim's character. We allow stealing from offline victims
	-- only via the AOE admin variant later; here require either a spawned pet or victim.
	local victim = Players:GetPlayerByUserId(targetUserId)
	local attacker = player.Character
	local attackerHrp = attacker and attacker:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not attackerHrp then return end

	local targetPet = getPet(targetUserId)
	local victimChar = victim and victim.Character
	local targetPos: Vector3?
	if targetPet then
		local b = targetPet:FindFirstChild("Body") :: BasePart?
		if b then targetPos = b.Position end
	end
	if not targetPos and victimChar then
		local h = victimChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if h then targetPos = h.Position end
	end
	if not targetPos then return end
	if (attackerHrp.Position - targetPos).Magnitude > 12 then return end

	tryTransfer(player.UserId, targetUserId, PetConfig.StealPerTick)
end)

-- Hook ProximityPrompts on every existing/new pet so attackers can hold to steal.
local function hookPet(model: Instance)
	if not model:IsA("Model") then return end
	if not string.match(model.Name, "^Pet_(%d+)$") then return end
	local ownerId = tonumber(string.match(model.Name, "^Pet_(%d+)$"))
	if not ownerId then return end
	local body = model:FindFirstChild("Body")
	local prompt = body and body:FindFirstChild("StealPrompt") :: ProximityPrompt?
	if not prompt then return end
	-- Server-side: ignore self-triggers. (Client also hides the prompt for
	-- the owner via HideOwnStealPrompt.client.lua.)
	prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered.UserId == ownerId then return end
		tryTransfer(playerWhoTriggered.UserId, ownerId, PetConfig.StealPerTick)
	end)
end

local petsFolder = workspace:FindFirstChild("Pets")
if petsFolder then
	for _, m in ipairs(petsFolder:GetChildren()) do hookPet(m) end
	petsFolder.ChildAdded:Connect(hookPet)
end
workspace.ChildAdded:Connect(function(c)
	if c.Name == "Pets" then
		for _, m in ipairs(c:GetChildren()) do hookPet(m) end
		c.ChildAdded:Connect(hookPet)
	end
end)

-- Expose the steal helper for AdminService's "Steal All..." AOE wrapper
_G.ActionService = {
	tryTransfer = tryTransfer,
	getPet      = getPet,
}
