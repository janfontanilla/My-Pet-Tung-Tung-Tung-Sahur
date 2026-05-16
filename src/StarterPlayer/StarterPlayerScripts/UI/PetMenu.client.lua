--!strict
-- PetMenu.client.lua
-- Right-side vertical menu (reference 02). 6 tiles:
-- Faces / Name / Color / Actions / Admin / Hats.
-- Clicking a tile toggles the matching panel via PanelController.

local Players          = game:GetService("Players")

local UI = script.Parent
local PanelController = require(UI:WaitForChild("PanelController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local TILES = {
	{ id = "faces",   label = "Faces"   },
	{ id = "name",    label = "Name"    },
	{ id = "color",   label = "Color"   },
	{ id = "actions", label = "Actions" },
	{ id = "admin",   label = "Admin"   },
	{ id = "hats",    label = "Hats"    },
}

local gui = Instance.new("ScreenGui")
gui.Name = "PetMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = playerGui

local column = Instance.new("Frame")
column.Name = "Column"
column.AnchorPoint = Vector2.new(1, 0.5)
column.Position = UDim2.new(1, -16, 0.5, 0)
column.Size = UDim2.fromOffset(170, 660)
column.BackgroundTransparency = 1
column.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.Parent = column

local tileButtons: { [string]: TextButton } = {}

for i, entry in ipairs(TILES) do
	local btn = Instance.new("TextButton")
	btn.Name = entry.id
	btn.LayoutOrder = i
	btn.Size = UDim2.fromOffset(160, 100)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.BackgroundTransparency = 0.25
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.FredokaOne
	btn.TextScaled = true
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextStrokeTransparency = 0
	btn.TextStrokeColor3 = Color3.new(0, 0, 0)
	btn.Text = entry.label .. " >"
	btn.Parent = column

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = btn

	btn.Activated:Connect(function()
		PanelController.open(entry.id)
	end)

	tileButtons[entry.id] = btn
end

-- Visually mark which tile is open
PanelController.subscribe(function(current)
	for id, btn in pairs(tileButtons) do
		if id == current then
			btn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
			btn.BackgroundTransparency = 0
		else
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			btn.BackgroundTransparency = 0.25
		end
	end
end)
