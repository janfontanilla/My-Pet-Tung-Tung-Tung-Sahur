--!strict
-- NameModal.client.lua
-- First-spawn naming popup (reference 01).
-- Shown when the server fires `RequestName`. Blocks input until OK pressed.

local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Remotes   = require(Shared:WaitForChild("Remotes"))
local PetConfig = require(Shared:WaitForChild("PetConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local function build(): (ScreenGui, TextBox, TextButton)
	local gui = Instance.new("ScreenGui")
	gui.Name = "NameModal"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.Enabled = false
	gui.Parent = playerGui

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.4
	dim.BorderSizePixel = 0
	dim.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(560, 340)
	panel.BackgroundTransparency = 1
	panel.Parent = dim

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 90)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.Text = "Name Your Tung Tung Tung Sahur!"
	title.Parent = panel

	local input = Instance.new("TextBox")
	input.Name = "NameBox"
	input.Position = UDim2.new(0, 0, 0, 110)
	input.Size = UDim2.new(1, 0, 0, 100)
	input.BackgroundColor3 = Color3.new(1, 1, 1)
	input.Font = Enum.Font.FredokaOne
	input.TextScaled = true
	input.TextColor3 = Color3.fromRGB(120, 120, 120)
	input.PlaceholderText = "Name..."
	input.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
	input.Text = ""
	input.ClearTextOnFocus = false
	input.Parent = panel
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 24)
	inputCorner.Parent = input

	local ok = Instance.new("TextButton")
	ok.Name = "OkButton"
	ok.AnchorPoint = Vector2.new(0.5, 0)
	ok.Position = UDim2.new(0.5, 0, 0, 230)
	ok.Size = UDim2.fromOffset(280, 90)
	ok.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	ok.AutoButtonColor = true
	ok.Font = Enum.Font.FredokaOne
	ok.TextScaled = true
	ok.TextColor3 = Color3.new(1, 1, 1)
	ok.TextStrokeTransparency = 0
	ok.TextStrokeColor3 = Color3.new(0, 0, 0)
	ok.Text = "OK!"
	ok.Parent = panel
	local okCorner = Instance.new("UICorner")
	okCorner.CornerRadius = UDim.new(0, 24)
	okCorner.Parent = ok

	return gui, input, ok
end

local gui, input, ok = build()

local function submit()
	local text = string.sub(input.Text, 1, PetConfig.NameMaxLength)
	text = (text:gsub("^%s+", ""):gsub("%s+$", ""))
	if #text == 0 then return end
	Remotes.event("SetName"):FireServer(text)
	gui.Enabled = false
end

ok.Activated:Connect(submit)
input.FocusLost:Connect(function(enterPressed)
	if enterPressed then submit() end
end)

Remotes.event("RequestName").OnClientEvent:Connect(function()
	input.Text = ""
	gui.Enabled = true
	input:CaptureFocus()
end)
