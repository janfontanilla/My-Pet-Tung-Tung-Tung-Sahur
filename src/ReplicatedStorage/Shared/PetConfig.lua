--!strict
-- PetConfig.lua
-- Tunable numbers + asset placeholders. No game state lives here.

local PetConfig = {}

-- Pet model — fill in after uploading the Tung Tung Tung Sahur mesh + texture.
PetConfig.PetMeshId    = "rbxassetid://138151705692565"
PetConfig.PetTextureId = "rbxassetid://0" -- TODO_TUNG_TEXTURE_ID (optional)
PetConfig.PetScale     = Vector3.new(1, 1, 1)

-- Spawning
PetConfig.SpawnOffset = Vector3.new(4, -1, 0) -- relative to owner's HumanoidRootPart

-- Locomotion
PetConfig.WalkSpeed     = 14   -- studs/sec while WALK action is active
PetConfig.WalkUpdateHz  = 4    -- pathfinding repath rate

-- Carry
PetConfig.CarryAttachment = "RightHand" -- name of the player character part to weld to

-- Age (wall-clock, accrues offline) — see PLAN.md Phase B
PetConfig.AgeFormat   = "DD:HH:MM:SS"
PetConfig.AutoSaveSec = 60

-- Steal Time (Phase E.b)
PetConfig.StealPerTick      = 60   -- seconds transferred per successful steal
PetConfig.StealHoldSeconds  = 2    -- ProximityPrompt hold duration
PetConfig.StealCooldown     = 30   -- per-victim, in seconds
PetConfig.StealAllRadius    = 60   -- studs, AOE for admin Steal All

-- Admin
PetConfig.PullOutAllCount = 5

-- UI
PetConfig.NameMaxLength = 20

return PetConfig
