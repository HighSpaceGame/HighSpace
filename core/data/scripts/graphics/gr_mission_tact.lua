local inspect                            = require('inspect')
local GrCommon                           = require('gr_common')

local gr_mission_tact = {}

function gr_mission_tact.drawSelectionBox(from, mouseState)
    if mouseState.buttons[0] and from then
        gr.setColor(0, 255, 0, 255)
        gr.drawRectangle(from.x, from.y, mouseState.x, mouseState.y, false)
    end
end

function gr_mission_tact.drawSelectionBrackets()
    for _, ship in pairs(GameMissionTactical.SelectedShips) do
        gr.setColor(ship.Team:getColor())
        gr.drawTargetingBrackets(ship.MissionShipInstance)
    end
end

return gr_mission_tact
