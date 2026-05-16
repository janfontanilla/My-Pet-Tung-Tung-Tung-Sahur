--!strict
-- HatsPanel.client.lua (reference 08)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("Catalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local UI = script.Parent
local PanelBase = require(UI:WaitForChild("PanelBase"))

local _gui, body = PanelBase.create("hats", "Hats")

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.fromScale(1, 1)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromScale(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = body

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(180, 180)
grid.CellPadding = UDim2.fromOffset(10, 10)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = scroll

for i, hat in ipairs(Catalog.Hats) do
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = i
	btn.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.FredokaOne
	btn.TextScaled = true
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = hat.name
	btn.Parent = scroll

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	btn.Activated:Connect(function()
		Remotes.event("SetHat"):FireServer(hat.id)
	end)
end
