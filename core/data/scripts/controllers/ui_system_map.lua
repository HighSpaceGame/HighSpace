local class                              = require("class")
local inspect                            = require('inspect')
local GameState                          = require('game_state')
local GrSystemMap                        = require('gr_system_map')
local UIController                       = require('ui_controller')
local SystemMapController                = class(UIController)()

local draw_map = nil

function SystemMapController:initialize(document)
    self.document  = document

    ba.println("SystemMapController:init()")

    draw_map = {
        tex = nil,
    }

    local system_map = self.document:GetElementById("system-map")
    draw_map.tex = gr.createTexture(system_map.offset_width, system_map.offset_height)
    draw_map.url = ui.linkTexture(draw_map.tex)
    draw_map.draw = true

    local aniEl = self.document:CreateElement("img")
    aniEl:SetAttribute("src", draw_map.url)
    system_map:ReplaceChild(aniEl, system_map.first_child)

    -- This hook is only necessary because of the direct draw calls (i.e. drawMap) we use in this view. Views that can be
    -- implemented in libRocket only don't need an onFrame hook
    engine.addHook("On Frame", function()
        if ba.getCurrentGameState().Name == "GS_STATE_BRIEFING" then
            GrSystemMap.drawMap(self.mouse.x, self.mouse.y, GameState.ships, draw_map.tex)
        end
    end, {}, function()
        return false
    end)
end

function SystemMapController:wheel(event, _, _)
    GrSystemMap.cam_dist = GrSystemMap.cam_dist * (1+event.parameters.wheel_delta * 0.1)
end

function SystemMapController:mouseDown(event, _, _)
    if event.parameters.button == self.MOUSE_BUTTON_LEFT then
        ba.println("selecting ship: " .. inspect(self.mouse))
        GameState.selectShip(self.mouse.x, self.mouse.y)
    elseif event.parameters.button == self.MOUSE_BUTTON_RIGHT then
        GameState.moveShip(self.mouse.x, self.mouse.y)
    end
end

function SystemMapController:mouseMove(event, document, element)
    self:storeMouseMove(event, document, element)
end

-- Placeholder for when we actually use keys
function SystemMapController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE or event.parameters.key_identifier == rocket.key_identifier.PAUSE then
        event:StopPropagation()
    end
end

return SystemMapController
