local class                                      = require("class")
local inspect                                    = require('inspect')

GameMissionTactical = class()

GameMissionTactical.TacticalMode = false
GameMissionTactical.TacticalCamera = nil
GameMissionTactical.SelectedShips = {}

function GameMissionTactical:init()
    --RocketUiSystem.skip_ui["GS_STATE_GAME_PLAY"] = true
    --ba.println("Skipping state set: " .. inspect(RocketUiSystem.skip_ui))
end

function GameMissionTactical:switchCamera()
    if self.TacticalMode then
        ba.println("camera: " .. inspect(self.TacticalCamera))
        if not self.TacticalCamera or not self.TacticalCamera:isValid() then
            self.TacticalCamera = gr.createCamera("TactMapCamera", ba.createVector(0, 3000, 6000), ba.createOrientationFromVectors(ba.createVector(0, -1, 0)))
        end

        self.TacticalCamera.Position = ba.createVector(0, 3000, 6000)
        self.TacticalCamera.Orientation = ba.createOrientationFromVectors(ba.createVector(0, -1, 0))
        --self.TacticalCamera.Position = ba.createVector(cam_x, cam_dist*math.cos(cam_angle), cam_dist*math.sin(cam_angle) + cam_y)
        --self.TacticalCamera.Orientation = ba.createOrientationFromVectors(ba.createVector(0, -cam_dist*math.cos(cam_angle), -cam_dist*math.sin(cam_angle)))
        gr.setCamera(self.TacticalCamera)
    else
        gr.setCamera()
    end
end

function GameMissionTactical:showTacticalView()
    return (self.TacticalMode and ba.getCurrentGameState().Name == "GS_STATE_GAME_PLAY")
end

function GameMissionTactical:toggleMode()
    self.TacticalMode = not self.TacticalMode

    self:switchCamera()
    RocketUiSystem.skip_ui["GS_STATE_GAME_PLAY"] = not self.TacticalMode
    hu.HUDDrawn = not self.TacticalMode
    io.setCursorHidden(not self.TacticalMode)
    if self.TacticalMode then
        ui.enableInput(RocketUiSystem.context)
    else
        ui.disableInput()
    end
end

function GameMissionTactical:selectShips(selFrom, selTo)
    self.SelectedShips = {}
    for ship_name, ship in pairs(GameState.ships) do
        if ship.MissionShipInstance then
            local x, y = ship.MissionShipInstance.Position:getScreenCoords()
            if x > selFrom.x and y > selFrom.y and x < selTo.x and y < selTo.y then
                self.SelectedShips[ship_name] = ship
            end
        end
    end
end

return GameMissionTactical