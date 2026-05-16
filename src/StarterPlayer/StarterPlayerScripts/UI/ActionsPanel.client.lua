--!strict
-- ActionsPanel.client.lua (reference 06)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local UI = script.Parent
local PanelBase = require(UI:WaitForChild("PanelBase"))

local _gui, body = PanelBase.create("actions", "Actions")

local function tile(name: string, label: string, color: Color3, order: number): TextButton
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(180, 180)
	b.BackgroundColor3 = color
	b.AutoButtonColor = true
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextStrokeTransparency = 0
	b.Text = label
	b.Name = name
	b.Parent = body
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = b
	return b
end

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 12)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = body

local walk = tile("walk", "WALK", Color3.fromRGB(80, 160, 220), 1)
local carry = tile("carry", "CARRY", Color3.fromRGB(200, 140, 80), 2)

walk.Activated:Connect(function()
	Remotes.event("DoAction"):FireServer("walk")
end)
carry.Activated:Connect(function()
	Remotes.event("DoAction"):FireServer("carry")
end)
