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

	-- Optional footstep sound. Replace SoundId in PetConfig if you want a
	-- custom "tung" SFX; if left default, this just plays Roblox's bonk.
	local step = body:FindFirstChild("StepSound") :: Sound?
	if not step then
		step = Instance.new("Sound")
		step.Name = "StepSound"
		step.SoundId = "rbxasset://sounds/impact_water.mp3"
		step.Volume = 0.4
		step.RollOffMaxDistance = 40
		step.Parent = body
	end

	task.spawn(function()
		local stepStart = os.clock()
		local lastStepPhase = 0
		while activeState[player.UserId] == "walk" do
			local char = player.Character
			local ownerHrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not ownerHrp or not body.Parent then break end

			-- Target heel position: 2 studs right & 3 behind owner
			local heel = ownerHrp.CFrame * CFrame.new(2, 0, 3)
			local toHeel = heel.Position - body.Position
			toHeel = Vector3.new(toHeel.X, 0, toHeel.Z)
			local dist = toHeel.Magnitude

			local moving = dist > 1.5
			if moving then
				local dir = toHeel.Unit
				vel.VectorVelocity = dir * PetConfig.WalkSpeed
				-- Stepping animation: bob up/down + rock left/right at ~2Hz.
				-- We bake the bob into the orientation CFrame by feeding a
				-- rocked lookAt; the up/down is achieved with a tiny rotation
				-- around the local right axis ("nodding" forward as he steps).
				local t = (os.clock() - stepStart) * 6 -- step rate
				local nod  = math.sin(t) * math.rad(10)  -- forward/back rock
				local sway = math.cos(t * 2) * math.rad(6) -- side-to-side
				local base = CFrame.lookAt(Vector3.zero, dir)
				orient.CFrame = base * CFrame.Angles(nod, 0, sway)
				-- Play a step sound on each downbeat (sin crossing 0 going down)
				local phase = math.floor(t / math.pi)
				if phase ~= lastStepPhase then
					lastStepPhase = phase
					if step then step:Play() end
				end
			else
				vel.VectorVelocity = Vector3.zero
				-- Idle: gently settle upright, no bob
				local fwd = body.CFrame.LookVector
				orient.CFrame = CFrame.lookAt(Vector3.zero, Vector3.new(fwd.X, 0, fwd.Z).Unit)
			end
			task.wait(0.05) -- 20Hz for smooth bob
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
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hand = char:FindFirstChild("RightHand") :: BasePart?
		or char:FindFirstChild("Right Arm") :: BasePart?
	if not body or not hrp or not hand then return end

	-- Disable mover constraints while carried
	local vel = body:FindFirstChild("WalkVelocity") :: LinearVelocity?
	local orient = body:FindFirstChild("FaceForward") :: AlignOrientation?
	if vel then vel.Enabled = false; vel.VectorVelocity = Vector3.zero end
	if orient then orient.Enabled = false end
	body.CanCollide = false
	body.Massless = true

	-- Attach Tung relative to the HumanoidRootPart (which has stable
	-- world-up orientation) rather than the hand bone (which twists with
	-- player animations). Position him above the right hand's world spot.
	local liftY = (body.Size.Y * 0.5) + 0.2

	local motor = Instance.new("Motor6D")
	motor.Name = "CarryMotor"
	motor.Part0 = hrp
	motor.Part1 = body
	-- HRP-local: 1.5 to the right, slightly above shoulder height, slightly
	-- in front. Tung faces the same direction the player is facing.
	motor.C0 = CFrame.new(1.5, 1.0 + liftY, -0.5)
	motor.C1 = CFrame.new(0, 0, 0)
	motor.Parent = hrp
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
