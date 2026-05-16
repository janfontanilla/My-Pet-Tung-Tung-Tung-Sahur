--!strict
-- PanelBase.lua
-- Shared builder + show/hide wiring so each panel script only has to fill
-- its own content.

local Players = game:GetService("Players")

local UI = script.Parent
local PanelController = require(UI:WaitForChild("PanelController"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local PanelBase = {}

function PanelBase.createMulti(panelIds: { string }, titleText: string): (ScreenGui, Frame)
	local gui, body = PanelBase._build(panelIds[1], titleText)
	PanelController.subscribe(function(current)
		local match = false
		for _, id in ipairs(panelIds) do
			if id == current then match = true; break end
		end
		gui.Enabled = match
	end)
	return gui, body
end

function PanelBase._build(panelId: string, titleText: string): (ScreenGui, Frame)
	local gui = Instance.new("ScreenGui")
	gui.Name = "Panel_" .. panelId
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20
	gui.Enabled = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -200, 0.5, 0)
	panel.Size = UDim2.fromOffset(420, 660)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 70)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0
	title.Text = string.upper(titleText)
	title.Parent = panel

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 12, 0, 80)
	body.Size = UDim2.new(1, -24, 1, -92)
	body.Parent = panel

	return gui, body
end

function PanelBase.create(panelId: string, titleText: string): (ScreenGui, Frame)
	local gui, body = PanelBase._build(panelId, titleText)
	PanelController.subscribe(function(current)
		gui.Enabled = (current == panelId)
	end)
	return gui, body
end

return PanelBase
