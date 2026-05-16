--!strict
-- NameColorPanel.client.lua (reference 05)
-- Color swatch grid + HIDE toggle. Name input removed (per user request).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Catalog   = require(Shared:WaitForChild("Catalog"))
local Remotes   = require(Shared:WaitForChild("Remotes"))

local UI = script.Parent
local PanelBase = require(UI:WaitForChild("PanelBase"))

local _gui, body = PanelBase.create("color", "Color")

-- Color swatch grid
local swatches = Instance.new("Frame")
swatches.Position = UDim2.fromOffset(0, 0)
swatches.Size = UDim2.new(1, 0, 0, 220)
swatches.BackgroundTransparency = 1
swatches.Parent = body

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromOffset(50, 50)
grid.CellPadding = UDim2.fromOffset(8, 8)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.FillDirectionMaxCells = 5
grid.Parent = swatches

for i, entry in ipairs(Catalog.Colors) do
	local btn = Instance.new("TextButton")
	btn.LayoutOrder = i
	btn.Text = ""
	btn.BackgroundColor3 = entry.color
	btn.AutoButtonColor = true
	btn.Parent = swatches
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	btn.Activated:Connect(function()
		Remotes.event("SetColor"):FireServer(entry.id)
	end)
end

