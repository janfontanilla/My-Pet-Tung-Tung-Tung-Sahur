--!strict
-- Catalog.lua
-- Single source of truth for every list in the game.
-- Adding content = edit this file + drop asset into ReplicatedStorage/Assets.

local Catalog = {}

----------------------------------------------------------------
-- Colors (Reference 05)
----------------------------------------------------------------
Catalog.Colors = {
	{ id = "white",  color = Color3.fromRGB(255, 255, 255) },
	{ id = "yellow", color = Color3.fromRGB(255, 220,  60) },
	{ id = "orange", color = Color3.fromRGB(255, 140,  30) },
	{ id = "red",    color = Color3.fromRGB(230,  50,  50) },
	{ id = "purple", color = Color3.fromRGB(170, 110, 220) },
	{ id = "pink",   color = Color3.fromRGB(255, 110, 220) },
	{ id = "cyan",   color = Color3.fromRGB( 70, 190, 255) },
	{ id = "blue",   color = Color3.fromRGB( 40,  90, 230) },
	{ id = "green",  color = Color3.fromRGB( 70, 210,  80) },
	{ id = "gray",   color = Color3.fromRGB(110, 110, 110) },
}

----------------------------------------------------------------
-- Faces (Reference 04) — replace `decal` with real Roblox asset IDs
----------------------------------------------------------------
Catalog.Faces = {
	{ id = "smile_basic",  name = "Smile",        decal = "rbxassetid://0" },
	{ id = "smile_blush",  name = "Blush",        decal = "rbxassetid://0" },
	{ id = "eyes_blue",    name = "Blue Eyes",    decal = "rbxassetid://0" },
	{ id = "clown",        name = "Clown",        decal = "rbxassetid://0" },
	{ id = "anime_pink",   name = "Anime",        decal = "rbxassetid://0" },
	{ id = "scared",       name = "Scared",       decal = "rbxassetid://0" },
	{ id = "derp",         name = "Derp",         decal = "rbxassetid://0" },
	{ id = "shock",        name = "Shock",        decal = "rbxassetid://0" },
	{ id = "smug",         name = "Smug",         decal = "rbxassetid://0" },
	{ id = "evil",         name = "Evil",         decal = "rbxassetid://0" },
	{ id = "cat",          name = "Cat",          decal = "rbxassetid://0" },
	{ id = "wink_blush",   name = "Wink",         decal = "rbxassetid://0" },
	{ id = "tongue_heart", name = "Tongue Heart", decal = "rbxassetid://0" },
	{ id = "pirate",       name = "Pirate",       decal = "rbxassetid://0" },
}

----------------------------------------------------------------
-- Hats (Reference 08)
-- `accessory` is a Roblox *Asset ID* (a model containing a hat mesh).
-- PetService:applyVisuals calls InsertService:LoadAsset, finds the first
-- MeshPart inside the loaded tree, clones + welds it to the pet's
-- HatAttachment. Toolbox hat asset IDs work directly.
-- Format: "rbxassetid://<id>"  (or leave "rbxassetid://0" to disable)
----------------------------------------------------------------
Catalog.Hats = {
	{ id = "none",            name = "None",           accessory = nil },
	{ id = "top_hat",         name = "Top Hat",        accessory = "rbxassetid://11870310728" },
	{ id = "party_hat",       name = "Party Hat",      accessory = "rbxassetid://14695628027" },
	{ id = "cowboy",          name = "Cowboy",         accessory = "rbxassetid://17075928250" },
	{ id = "fedora",          name = "Fedora",         accessory = "rbxassetid://48181949" },
	{ id = "chef",            name = "Chef",           accessory = "rbxassetid://7184746056" },
	{ id = "pirate",          name = "Pirate Hat",     accessory = "rbxassetid://16965440" },
	{ id = "cone",            name = "Cone",           accessory = "rbxassetid://14639265964" },
	{ id = "chicken",         name = "Chicken",        accessory = "rbxassetid://14535334140" },
	{ id = "king",            name = "King",           accessory = "rbxassetid://13484479112" },
	{ id = "money",           name = "Money",          accessory = "rbxassetid://3664143815" },
	{ id = "ice_cream",       name = "Ice Cream Cone", accessory = "rbxassetid://15073309753" },
	{ id = "squid",           name = "Squid",          accessory = "rbxassetid://103775086" },
	{ id = "santa",           name = "Santa",          accessory = "rbxassetid://0" },
	{ id = "viking",          name = "Viking",         accessory = "rbxassetid://0" },
	{ id = "red_cap",         name = "Red Cap",        accessory = "rbxassetid://0" },
	{ id = "glasses_3d",      name = "3D Glasses",     accessory = "rbxassetid://0" },
	{ id = "shutter_shades",  name = "Shutter Shades", accessory = "rbxassetid://0" },
	{ id = "crown",           name = "Crown",          accessory = "rbxassetid://0" },
	{ id = "headphones",      name = "Headphones",     accessory = "rbxassetid://0" },
	{ id = "nerd_glasses",    name = "Nerd Glasses",   accessory = "rbxassetid://0" },
	{ id = "burger",          name = "Burger",         accessory = "rbxassetid://0" },
	{ id = "ny_cap",          name = "NY Cap",         accessory = "rbxassetid://0" },
	{ id = "banana",          name = "Banana",         accessory = "rbxassetid://0" },
}

----------------------------------------------------------------
-- Admin abilities (Reference 07)
----------------------------------------------------------------
Catalog.AdminAbilities = {
	{ id = "invisible",    name = "Invisible"     },
	{ id = "speed_boost",  name = "+10 Speed"     },
	{ id = "pull_out_all", name = "Pull Out All"  },
	{ id = "steal_all",    name = "Steal All..."  },
}

-- Roblox Developer Product for the Admin Pack. Fill in after creating it
-- in Studio: Game Settings -> Monetization -> Developer Products.
Catalog.AdminProductId = 0 -- TODO_ADMIN_PRODUCT_ID

----------------------------------------------------------------
-- Lookup helpers
----------------------------------------------------------------
local function indexById(list)
	local map = {}
	for _, entry in ipairs(list) do
		map[entry.id] = entry
	end
	return map
end

Catalog.ColorById        = indexById(Catalog.Colors)
Catalog.FaceById         = indexById(Catalog.Faces)
Catalog.HatById          = indexById(Catalog.Hats)
Catalog.AdminAbilityById = indexById(Catalog.AdminAbilities)

return Catalog
