--!strict
-- Remotes.lua
-- Lazily creates and returns the RemoteEvent / RemoteFunction objects under
-- ReplicatedStorage.Remotes. Both server and client require this module so
-- they agree on names. The server is the only authority for state changes
-- triggered by these remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local EVENT_NAMES = {
	"RequestName",       -- server -> client: please show the first-spawn name modal
	"SetName",           -- client -> server: rename pet
	"SetColor",          -- client -> server: pick color by id
	"SetFace",           -- client -> server: pick face by id
	"SetHat",            -- client -> server: pick hat by id
	"ToggleHideName",    -- client -> server: flip billboard visibility
	"DoAction",          -- client -> server: walk / carry / idle
	"StealTime",         -- client -> server: request to steal from targetUserId
	"DoAdminAbility",    -- client -> server: invisible / speed_boost / pull_out_all / steal_all
	"PetAgeUpdate",      -- server -> client: per-pet age tick for UI smoothing
}

local FUNCTION_NAMES = {
	"GetPetState",       -- client -> server: returns the caller's persisted pet record
}

local Remotes = {}

local folder: Folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) :: Folder
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, name in ipairs(EVENT_NAMES) do
		if not folder:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
	end
	for _, name in ipairs(FUNCTION_NAMES) do
		if not folder:FindFirstChild(name) then
			local fn = Instance.new("RemoteFunction")
			fn.Name = name
			fn.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

function Remotes.event(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

function Remotes.func(name: string): RemoteFunction
	return folder:WaitForChild(name) :: RemoteFunction
end

return Remotes
