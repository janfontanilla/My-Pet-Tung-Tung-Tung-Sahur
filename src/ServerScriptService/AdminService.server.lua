--!strict
-- AdminService.server.lua (reference 07)
-- Developer-product paywall + ability handlers.

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Catalog   = require(Shared:WaitForChild("Catalog"))
local Remotes   = require(Shared:WaitForChild("Remotes"))
local PetConfig = require(Shared:WaitForChild("PetConfig"))

-- Wait briefly for PetService to publish
local function petSvc()
	return _G.PetService
end
local function actionSvc()
	return _G.ActionService
end

----------------------------------------------------------------
-- ProcessReceipt
----------------------------------------------------------------
MarketplaceService.ProcessReceipt = function(receiptInfo)
	if receiptInfo.ProductId ~= Catalog.AdminProductId then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local svc = petSvc()
	if not svc then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local rec = svc.getRecord(receiptInfo.PlayerId)
	if not rec then return Enum.ProductPurchaseDecision.NotProcessedYet end
	rec.hasAdmin = true
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

----------------------------------------------------------------
-- Ability handlers
----------------------------------------------------------------
local function getPet(userId: number): Model?
	local svc = actionSvc()
	if svc then return svc.getPet(userId) end
	local folder = workspace:FindFirstChild("Pets")
	return folder and folder:FindFirstChild("Pet_" .. userId) :: Model?
end

local invisibleState: { [number]: boolean } = {}
local speedBoostState: { [number]: boolean } = {}

local function abilityInvisible(player: Player)
	local pet = getPet(player.UserId); if not pet then return end
	local body = pet:FindFirstChild("Body") :: BasePart?
	if not body then return end
	invisibleState[player.UserId] = not invisibleState[player.UserId]
	if invisibleState[player.UserId] then
		body.Transparency = 1
		body.CanCollide = false
	else
		body.Transparency = 0
		body.CanCollide = true
	end
end

local function abilitySpeedBoost(player: Player)
	local pet = getPet(player.UserId); if not pet then return end
	local hum = pet:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	speedBoostState[player.UserId] = not speedBoostState[player.UserId]
	if speedBoostState[player.UserId] then
		hum.WalkSpeed = PetConfig.WalkSpeed + 10
	else
		hum.WalkSpeed = PetConfig.WalkSpeed
	end
end

local function abilityPullOutAll(player: Player)
	local pet = getPet(player.UserId); if not pet then return end
	local body = pet:FindFirstChild("Body") :: BasePart?
	if not body then return end
	for i = 1, PetConfig.PullOutAllCount do
		local clone = pet:Clone()
		clone.Name = "PetClone_" .. player.UserId .. "_" .. i
		-- Strip the StealPrompt so clones can't be stolen from
		local cb = clone:FindFirstChild("Body") :: BasePart?
		if cb then
			local sp = cb:FindFirstChild("StealPrompt")
			if sp then sp:Destroy() end
			cb.CFrame = body.CFrame * CFrame.new(math.random(-8, 8), 0, math.random(-8, 8))
		end
		clone.Parent = body.Parent
		task.delay(30, function()
			if clone and clone.Parent then clone:Destroy() end
		end)
	end
end

local function abilityStealAll(player: Player)
	local svc = actionSvc()
	if not svc then return end
	local me = getPet(player.UserId)
	if not me then return end
	local body = me:FindFirstChild("Body") :: BasePart?
	if not body then return end
	local myPos = body.Position

	local pets = workspace:FindFirstChild("Pets")
	if not pets then return end
	for _, model in ipairs(pets:GetChildren()) do
		if model ~= me and model:IsA("Model") then
			local mb = model:FindFirstChild("Body") :: BasePart?
			if mb and (mb.Position - myPos).Magnitude <= PetConfig.StealAllRadius then
				local ownerId = tonumber(string.match(model.Name, "^Pet_(%d+)$"))
				if ownerId and ownerId ~= player.UserId then
					svc.tryTransfer(player.UserId, ownerId, PetConfig.StealPerTick)
				end
			end
		end
	end
end

local ABILITIES = {
	invisible    = abilityInvisible,
	speed_boost  = abilitySpeedBoost,
	pull_out_all = abilityPullOutAll,
	steal_all    = abilityStealAll,
}

----------------------------------------------------------------
-- Remote: DoAdminAbility
----------------------------------------------------------------
Remotes.event("DoAdminAbility").OnServerEvent:Connect(function(player, abilityId)
	if type(abilityId) ~= "string" then return end
	local svc = petSvc()
	if not svc then return end
	local rec = svc.getRecord(player.UserId)
	if not rec then return end

	if not rec.hasAdmin then
		-- Not owned -> prompt purchase (client-side gets a parallel call from AdminPanel)
		if Catalog.AdminProductId and Catalog.AdminProductId > 0 then
			MarketplaceService:PromptProductPurchase(player, Catalog.AdminProductId)
		end
		return
	end

	local fn = ABILITIES[abilityId]
	if fn then fn(player) end
end)
