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

function GrMissionTact.drawGrid()
    local base = 4.0
    local size = math.pow(base, math.floor(math.max(2.0, math.log(GameMission.TacticalCamera.Zoom)/math.log(base))))*10
    local thickness = size / 6000
    local step = size/20
    local snap_x = math.floor(GameMission.TacticalCamera.Target.x / step)*step
    local snap_z = math.floor(GameMission.TacticalCamera.Target.z / step)*step
    gr.setColor(128, 128, 0)
    for i = 1, 39 do
        gr.draw3dLine(ba.createVector(snap_x-size + i*step, 0, snap_z-size), ba.createVector(snap_x-size + i*step, 0, snap_z+size), false, thickness)
        gr.draw3dLine(ba.createVector(snap_x-size, 0, snap_z-size + i*step), ba.createVector(snap_x+size, 0, snap_z-size + i*step), false, thickness)
    end
end

return GrMissionTact
