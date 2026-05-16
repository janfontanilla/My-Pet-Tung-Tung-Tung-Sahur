--!strict
-- HideOwnStealPrompt.client.lua
-- The StealPrompt on a pet body should be invisible to the pet's owner.
-- We watch the workspace.Pets folder and toggle prompt.Enabled per-client.

local Players = game:GetService("Players")
local me = Players.LocalPlayer

local function hookPet(petModel: Instance)
	if not petModel:IsA("Model") then return end
	local ownerId = tonumber(string.match(petModel.Name, "^Pet_(%d+)$"))
	if not ownerId then return end

	local function applyVisibility(prompt: ProximityPrompt)
		prompt.Enabled = (ownerId ~= me.UserId)
	end

	local body = petModel:WaitForChild("Body", 5)
	if not body then return end
	local prompt = body:WaitForChild("StealPrompt", 5) :: ProximityPrompt?
	if prompt then applyVisibility(prompt) end
	body.ChildAdded:Connect(function(c)
		if c:IsA("ProximityPrompt") and c.Name == "StealPrompt" then
			applyVisibility(c)
		end
	end)
end

local pets = workspace:WaitForChild("Pets", 30)
if pets then
	for _, p in ipairs(pets:GetChildren()) do hookPet(p) end
	pets.ChildAdded:Connect(hookPet)
end
