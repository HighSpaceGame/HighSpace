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
    gr.setColor(64, 64, 0)
    for i = 1, 39 do
        gr.draw3dLine(ba.createVector(snap_x-size + i*step, 0, snap_z-size), ba.createVector(snap_x-size + i*step, 0, snap_z+size), false, thickness)
        gr.draw3dLine(ba.createVector(snap_x-size, 0, snap_z-size + i*step), ba.createVector(snap_x+size, 0, snap_z-size + i*step), false, thickness)
    end
end

function GrMissionTact.drawIconsIfShipsTooSmall()
    for _, ship in pairs(GameMission.Ships) do
        local x1, y1, x2, y2 = gr.drawTargetingBrackets(ship.MissionShipInstance, false, 0)
        local min_size = math.max(x2-x1, y2-y1)
        if min_size < 40 then
            local r, g, b = ship.Team:getColor()
            local alpha = 255 * (1 - min_size/40.0)
            gr.setColor(r, g, b, alpha)
            local icon = GrCommon.getIconForShip(ship)
            if icon then
                local x, y = ship.MissionShipInstance.Position:getScreenCoords()
                gr.drawImageCentered(icon.Texture, x, y, icon.Width, icon.Height, 0, 0, 1, 1, 1, true)
                gr.drawImageCentered(icon.Texture, x, y, icon.Width, icon.Height, 0, 0, 1, 1, 1, true)
            end

        end
    end
end

return GrMissionTact
