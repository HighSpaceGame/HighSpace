local Class                              = require("class")
local Inspect                            = require('inspect')
local GrSystemMap                        = require('gr_system_map')
local UIController                       = require('ui_controller')
local SystemMapUIController = Class(UIController)()

local draw_map = nil

function SystemMapUIController:initialize(document)
    self.Document = document

    ba.println("SystemMapController:init()")

    draw_map = {
        Tex = nil,
    }

    local system_map = self.Document:GetElementById("system-map")
    draw_map.Tex = gr.createTexture(system_map.offset_width, system_map.offset_height)
    draw_map.Url = ui.linkTexture(draw_map.Tex)
    draw_map.Draw = true

    local ani_el = self.Document:CreateElement("img")
    ani_el:SetAttribute("src", draw_map.Url)
    system_map:ReplaceChild(ani_el, system_map.first_child)
end

function SystemMapUIController:wheel(event, _, _)
    --placeholder
    --GrSystemMap.cam_dist = GrSystemMap.cam_dist * (1+event.parameters.wheel_delta * 0.1)
end

function SystemMapUIController:mouseDown(event, _, _)
    if event.parameters.button == self.MOUSE_BUTTON_LEFT then
        ba.println("selecting ship: " .. Inspect(self.Mouse))
        GameSystemMap.selectShip(self.Mouse.X, self.Mouse.Y)
    elseif event.parameters.button == self.MOUSE_BUTTON_RIGHT then
        GameSystemMap.moveShip(self.Mouse.X, self.Mouse.Y)
    end
end

function SystemMapUIController:mouseMove(event, document, element)
    self:storeMouseMove(event, document, element)
end

-- Placeholder for when we actually use keys
function SystemMapUIController:keyDown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE or event.parameters.key_identifier == rocket.key_identifier.PAUSE then
        event:StopPropagation()
    end
end

-- This hook is only necessary because of the direct draw calls (i.e. drawMap) we use in this view. Views that can be
-- implemented in libRocket only don't need an onFrame hook
engine.addHook("On Frame", function()
    if ba.getCurrentGameState().Name == "GS_STATE_BRIEFING" then
        GrSystemMap.drawMap(SystemMapUIController.Mouse.X, SystemMapUIController.Mouse.Y, GameState.Ships, draw_map.Tex)
    end
end, {}, function()
    return false
end)

return SystemMapUIController
