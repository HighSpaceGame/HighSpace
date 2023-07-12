local class                                      = require("class")
local inspect                                    = require('inspect')

local MissionTacticalGameController              = class()

MissionTacticalGameController.ShowTacticalView = false
MissionTacticalGameController.TacticalCamera = nil

function MissionTacticalGameController:init()
    --RocketUiSystem.skip_ui["GS_STATE_GAME_PLAY"] = true
    --ba.println("Skipping state set: " .. inspect(RocketUiSystem.skip_ui))
end

function MissionTacticalGameController:switchCamera()
    if self.ShowTacticalView then
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

function MissionTacticalGameController:toggleMode()
    self.ShowTacticalView = not self.ShowTacticalView

    self:switchCamera()
    RocketUiSystem.skip_ui["GS_STATE_GAME_PLAY"] = not self.ShowTacticalView
    hu.HUDDrawn = not self.ShowTacticalView
    io.setCursorHidden(not self.ShowTacticalView)
    if self.ShowTacticalView then
        ui.enableInput(RocketUiSystem.context)
    else
        ui.disableInput()
    end
end


return MissionTacticalGameController