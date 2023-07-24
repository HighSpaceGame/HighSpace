local Inspect                            = require('inspect')
local GrCommon                           = require('gr_common')

local GrMissionTact = {}

function GrMissionTact.drawSelectionBox(from, mouseState)
    if mouseState.Buttons[UI_CONST.MOUSE_BUTTON_LEFT] and from then
        gr.setColor(0, 255, 0, 255)
        gr.drawRectangle(from.X, from.Y, mouseState.X, mouseState.Y, false)
    end
end

function GrMissionTact.drawSelectionBrackets()
    for _, ship in pairs(GameMission.SelectedShips) do
        gr.setColor(ship.Team:getColor())
        gr.drawTargetingBrackets(ship.MissionShipInstance)
    end
end

return GrMissionTact
