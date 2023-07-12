local class                              = require("class")
local GameState                          = require('game_state')
local UIController                       = require('ui_controller')
local MissionTacticalController          = class(UIController)


function MissionTacticalController:init()
    engine.addHook("On Frame", function()
        if ba.getCurrentGameState().Name == "GS_STATE_GAME_PLAY" then
            gr.drawSphere(100, ba.createVector(0,0,6000))
        end
    end, {}, function()
        return false
    end)
end

function MissionTacticalController:initialize(document)
    self.document  = document
end

function MissionTacticalController:wheel(event, _, _)
    --placeholder
    --SystemMapDrawing.cam_dist = SystemMapDrawing.cam_dist * (1+event.parameters.wheel_delta * 0.1)
end

function MissionTacticalController:mouseDown(event, document, element)
    self:storeMouseDown(event, document, element)
end

function MissionTacticalController:mouseUp(event, document, element)
    self:storeMouseUp(event, document, element)
end

function MissionTacticalController:mouseMove(event, document, element)
    self:storeMouseMove(event, document, element)
end

function MissionTacticalController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.RETURN then
        event:StopPropagation()

        GameState.MissionTactical:toggleMode()
    end
end

return MissionTacticalController
