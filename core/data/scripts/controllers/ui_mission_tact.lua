local class                              = require("class")
local UIController                       = require('ui_controller')
local GrMissionTact                      = require('gr_mission_tact')
local MissionTacticalController          = class(UIController)()

MissionTacticalController.selectionFrom = nil

function MissionTacticalController:initialize(document)
    self.document  = document

    engine.addHook("On Frame", function()
        if ba.getCurrentGameState().Name == "GS_STATE_GAME_PLAY" then
            GrMissionTact.drawSelection(self.selectionFrom, self.mouse)

            for _, ship in pairs(GameMissionTactical.SelectedShips) do
                gr.drawTargetingBrackets(ship.MissionShipInstance)
            end
        end
    end, {}, function()
        return false
    end)
end

function MissionTacticalController:wheel(event, _, _)
    --placeholder
    --SystemMapDrawing.cam_dist = SystemMapDrawing.cam_dist * (1+event.parameters.wheel_delta * 0.1)
end

function MissionTacticalController:mouseDown(event, document, element)
    self:storeMouseDown(event, document, element)

    if event.parameters.button == UIController.MOUSE_BUTTON_LEFT then
        self.selectionFrom = { ["x"] = self.mouse.x, ["y"] = self.mouse.y }
    end
end

function MissionTacticalController:mouseUp(event, document, element)
    self:storeMouseUp(event, document, element)

    if not self.mouse.buttons[UIController.MOUSE_BUTTON_LEFT] then
        GameMissionTactical:selectShips(self.selectionFrom, { ["x"] = self.mouse.x, ["y"] = self.mouse.y })

        self.selectionFrom = nil
    end
end

function MissionTacticalController:mouseMove(event, document, element)
    self:storeMouseMove(event, document, element)
end

function MissionTacticalController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.RETURN then
        event:StopPropagation()

        GameMissionTactical:toggleMode()
    end
end

return MissionTacticalController
