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
-- Per-victim cooldown across all attackers
local stealCooldown: { [number]: number } = {}

local function getPet(userId: number): Model?
	local folder = workspace:FindFirstChild("Pets")
	if not folder then return nil end
	return folder:FindFirstChild("Pet_" .. userId) :: Model?
end

----------------------------------------------------------------
-- WALK: follow owner via PathfindingService
----------------------------------------------------------------
local function startWalk(player: Player)
	activeState[player.UserId] = "walk"
	task.spawn(function()
		while activeState[player.UserId] == "walk" do
			local pet = getPet(player.UserId)
			local char = player.Character
			if not pet or not char then break end
			local petHrp = pet:FindFirstChild("HumanoidRootPart") :: BasePart?
			local petHum = pet:FindFirstChildOfClass("Humanoid")
			local ownerHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not petHrp or not petHum or not ownerHrp then break end

			-- Only move if we're more than 6 studs away
			local dist = (ownerHrp.Position - petHrp.Position).Magnitude
			if dist > 6 then
				local ok, path = pcall(function()
					local p = PathfindingService:CreatePath({
						AgentRadius = 2,
						AgentHeight = 5,
						AgentCanJump = true,
					})
					p:ComputeAsync(petHrp.Position, ownerHrp.Position)
					return p
				end)
				if ok and path and path.Status == Enum.PathStatus.Success then
					for _, wp in ipairs(path:GetWaypoints()) do
						if activeState[player.UserId] ~= "walk" then break end
						petHum:MoveTo(wp.Position)
						petHum.MoveToFinished:Wait()
					end
				else
					-- Fallback: walk straight toward owner
					petHum:MoveTo(ownerHrp.Position)
				end
			end
			task.wait(1 / PetConfig.WalkUpdateHz)
		end
	end)
end

local function stopWalk(player: Player)
	if activeState[player.UserId] == "walk" then
		activeState[player.UserId] = "idle"
		local pet = getPet(player.UserId)
		local hum = pet and pet:FindFirstChildOfClass("Humanoid")
		if hum then hum:MoveTo(hum.Parent and (hum.Parent :: any).PrimaryPart.Position or Vector3.zero) end
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
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		hum.WalkSpeed = 0
	end

	body.CFrame = hand.CFrame * CFrame.new(0, 1, 0)
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
	local hum = pet and pet:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = PetConfig.WalkSpeed
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
	prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered.UserId == ownerId then return end -- can't steal from yourself
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
