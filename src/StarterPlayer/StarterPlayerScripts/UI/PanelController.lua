--!strict
-- PanelController.lua
-- Tiny pub/sub so the right-side menu and each panel agree on which panel
-- (if any) is currently open. Opening one panel implicitly closes the others.

local PanelController = {}

local current: string? = nil
local listeners: { (panelId: string?) -> () } = {}

function PanelController.open(panelId: string)
	if current == panelId then
		current = nil -- toggle off if clicking same tile
	else
		current = panelId
	end
	for _, fn in ipairs(listeners) do
		task.spawn(fn, current)
	end
end

function PanelController.close()
	if current == nil then return end
	current = nil
	for _, fn in ipairs(listeners) do
		task.spawn(fn, nil)
	end
end

function PanelController.subscribe(fn: (panelId: string?) -> ()): () -> ()
	table.insert(listeners, fn)
	return function()
		for i, f in ipairs(listeners) do
			if f == fn then
				table.remove(listeners, i)
				return
			end
		end
	end
end

function PanelController.current(): string?
	return current
end

return PanelController
