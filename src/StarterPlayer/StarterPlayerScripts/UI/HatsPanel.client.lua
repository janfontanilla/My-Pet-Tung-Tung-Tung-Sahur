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
	local btn = Instance.new("ImageButton")
	btn.LayoutOrder = i
	btn.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
	btn.AutoButtonColor = true
	btn.ScaleType = Enum.ScaleType.Fit
	btn.Parent = scroll

	-- Asset thumbnail via rbxthumb:// — works for any asset id
	if hat.accessory and type(hat.accessory) == "string" then
		local idNum = string.match(hat.accessory, "%d+")
		if idNum and idNum ~= "0" then
			btn.Image = string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", idNum)
		end
	end

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -4)
	label.Size = UDim2.new(1, -8, 0, 32)
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = hat.name
	label.Parent = btn

	local lcorner = Instance.new("UICorner")
	lcorner.CornerRadius = UDim.new(0, 6)
	lcorner.Parent = label

	btn.Activated:Connect(function()
		Remotes.event("SetHat"):FireServer(hat.id)
	end)
end
