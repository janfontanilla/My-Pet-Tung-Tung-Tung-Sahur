--!strict
-- AdminPanel.client.lua (reference 07)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local UI = script.Parent
local PanelBase = require(UI:WaitForChild("PanelBase"))

local _gui, body = PanelBase.create("admin", "Admin")

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = body

for i, ab in ipairs(Catalog.AdminAbilities) do
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = i
	btn.Size = UDim2.new(1, 0, 0, 90)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.FredokaOne
	btn.TextScaled = true
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextStrokeTransparency = 0
	btn.Text = string.upper(ab.name)
	btn.Parent = body
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = btn

	btn.Activated:Connect(function()
		-- Server decides paywall vs grant
		Remotes.event("DoAdminAbility"):FireServer(ab.id)
	end)
end
