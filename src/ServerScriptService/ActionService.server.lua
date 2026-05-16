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
local function findHandPart(char: Model): BasePart?
	-- R15 first, then R6 fallback (R6 calls it "Right Arm")
	local r15 = char:FindFirstChild("RightHand") :: BasePart?
	if r15 then return r15 end
	local r6 = char:FindFirstChild("Right Arm") :: BasePart?
	if r6 then return r6 end
	-- last resort: torso/HRP so the leash is at least visible
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function attachLeash(player: Player, pet: Model)
	local char = player.Character
	if not char then return end
	local body = pet:FindFirstChild("Body") :: BasePart?
	local hand = findHandPart(char)
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
	beam.Width0 = 0.25
	beam.Width1 = 0.25
	beam.FaceCamera = true
	beam.LightEmission = 0.2
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(Color3.fromRGB(120, 70, 30))
	beam.Transparency = NumberSequence.new(0)
	beam.Segments = 6
	beam.Parent = workspace -- Beam must be in workspace, not nested under a moving Part

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
	if not pet then return end
	attachLeash(player, pet)

	local body = pet:FindFirstChild("Body") :: BasePart?
	local vel = body and body:FindFirstChild("WalkVelocity") :: LinearVelocity?
	local orient = body and body:FindFirstChild("FaceForward") :: AlignOrientation?
	if not body or not vel or not orient then return end
	vel.Enabled = true
	orient.Enabled = true

	task.spawn(function()
		while activeState[player.UserId] == "walk" do
			local char = player.Character
			local ownerHrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not ownerHrp or not body.Parent then break end

			-- Target heel position: 2 studs right & 3 behind owner
			local heel = ownerHrp.CFrame * CFrame.new(2, 0, 3)
			local toHeel = heel.Position - body.Position
			-- Stay grounded on Y
			toHeel = Vector3.new(toHeel.X, 0, toHeel.Z)
			local dist = toHeel.Magnitude
			if dist > 1.5 then
				local dir = toHeel.Unit
				vel.VectorVelocity = dir * PetConfig.WalkSpeed
				-- Face the direction we're walking
				orient.CFrame = CFrame.lookAt(Vector3.zero, dir)
			else
				vel.VectorVelocity = Vector3.zero
			end
			task.wait(0.1)
		end
		if vel.Parent then vel.Enabled = false; vel.VectorVelocity = Vector3.zero end
		if orient.Parent then orient.Enabled = false end
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
	local hand = char:FindFirstChild("RightHand") :: BasePart?
		or char:FindFirstChild("Right Arm") :: BasePart?
	if not body or not hand then return end

	-- Disable mover constraints while carried
	local vel = body:FindFirstChild("WalkVelocity") :: LinearVelocity?
	local orient = body:FindFirstChild("FaceForward") :: AlignOrientation?
	if vel then vel.Enabled = false; vel.VectorVelocity = Vector3.zero end
	if orient then orient.Enabled = false end
	body.CanCollide = false
	body.Massless = true

	-- Sit Tung on top of the player's hand. The mesh's pivot can be anywhere
	-- inside the bounding box, so use Size.Y/2 PLUS a buffer so feet clear
	-- the wrist visually. Position him slightly forward of the wrist too.
	local liftY = (body.Size.Y * 0.5) + (hand.Size.Y * 0.5) + 0.2

	local motor = Instance.new("Motor6D")
	motor.Name = "CarryMotor"
	motor.Part0 = hand
	motor.Part1 = body
	-- C0/C1 control offset & rotation. Tung faces same way the hand "points"
	-- forward, sitting on the wrist.
	motor.C0 = CFrame.new(0, liftY, 0) * CFrame.Angles(0, 0, 0)
	motor.C1 = CFrame.new(0, 0, 0)
	motor.Parent = hand
	carryWelds[player.UserId] = motor :: any

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
		if body then
			body.CanCollide = true
			body.Massless = false
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

-- Expose internals for cross-script use (PetService auto-walk, AdminService steal_all)
_G.ActionService = {
	tryTransfer = tryTransfer,
	getPet      = getPet,
	startWalk   = startWalk,
	stopWalk    = stopWalk,
	startCarry  = startCarry,
	stopCarry   = stopCarry,
}
