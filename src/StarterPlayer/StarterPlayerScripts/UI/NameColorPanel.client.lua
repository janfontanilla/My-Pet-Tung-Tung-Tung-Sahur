--!strict
-- NameColorPanel.client.lua (reference 05)
-- TextBox to rename + 2x5 color swatch grid + HIDE toggle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Catalog   = require(Shared:WaitForChild("Catalog"))
local Remotes   = require(Shared:WaitForChild("Remotes"))
local PetConfig = require(Shared:WaitForChild("PetConfig"))

local UI = script.Parent
local PanelBase = require(UI:WaitForChild("PanelBase"))

-- Listens to BOTH the "name" and "color" tiles since the reference panel
-- combines them.
local _gui, body = PanelBase.createMulti({ "name", "color" }, "Name & Color")

-- Name input
local input = Instance.new("TextBox")
input.Size = UDim2.new(1, 0, 0, 70)
input.Position = UDim2.fromOffset(0, 0)
input.BackgroundColor3 = Color3.new(1, 1, 1)
input.Font = Enum.Font.FredokaOne
input.TextScaled = true
input.TextColor3 = Color3.fromRGB(120, 120, 120)
input.PlaceholderText = "Name..."
input.Text = ""
input.ClearTextOnFocus = false
input.Parent = body
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 16)
inputCorner.Parent = input

input.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	local txt = string.sub(input.Text, 1, PetConfig.NameMaxLength)
	txt = (txt:gsub("^%s+", ""):gsub("%s+$", ""))
	if #txt > 0 then
		Remotes.event("SetName"):FireServer(txt)
	end
end)

-- Color swatch grid (2 rows x 5 cols)
local swatches = Instance.new("Frame")
swatches.Position = UDim2.fromOffset(0, 90)
swatches.Size = UDim2.new(1, -110, 0, 220)
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

-- HIDE toggle
local hide = Instance.new("TextButton")
hide.AnchorPoint = Vector2.new(1, 0)
hide.Position = UDim2.new(1, 0, 0, 90)
hide.Size = UDim2.fromOffset(100, 100)
hide.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
hide.Font = Enum.Font.FredokaOne
hide.TextScaled = true
hide.TextColor3 = Color3.new(1, 1, 1)
hide.Text = "HIDE"
hide.Parent = body
local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 12)
hideCorner.Parent = hide

hide.Activated:Connect(function()
	Remotes.event("ToggleHideName"):FireServer()
end)
