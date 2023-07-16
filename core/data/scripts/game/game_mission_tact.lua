local class                                      = require("class")
local inspect                                    = require("inspect")
local Utils                                      = require("utils")

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
            if Utils.math.isInsideBox({["x"] = x, ["y"] = y}, selFrom, selTo) then
                self.SelectedShips[ship_name] = ship
                ba.println("Selecting: " .. inspect({ ship.Name, tostring(ship.MissionShipInstance.Target), ship.MissionShipInstance.Target:getBreedName(), ship.MissionShipInstance.Target:isValid() }))
            end
        end
    end
end

function GameMissionTactical:giveRightClickCommand(targetCursor)
    local order = nil
    local target = nil
    for _, ship in pairs(GameState.ships) do
        if ship.MissionShipInstance then
            local x1, y1, x2, y2 = gr.drawTargetingBrackets(ship.MissionShipInstance, false)
            if Utils.math.isInsideBox(targetCursor, {["x"] = x1, ["y"] = y1}, {["x"] = x2, ["y"] = y2}) then
                target = ship
                break
            end
        end
    end

    if target then
        if target.Team.Name == "Friendly" then
            order = ORDER_GUARD
        elseif target.Team.Name == "Hostile" then
            order = ORDER_ATTACK
        end

        target = target.MissionShipInstance
        ba.println("Giving Order: " .. inspect({ order, target.Name }))
    else
        local vec = gr.getVectorFromCoords(targetCursor.x, targetCursor.y, 0, true) - GameMissionTactical.TacticalCamera.Position
        local vec_size = 1.0 / math.abs(vec.y) * math.abs(GameMissionTactical.TacticalCamera.Position.y)
        vec = GameMissionTactical.TacticalCamera.Position + vec * vec_size
        target = mn.createWaypoint(vec)
        order = ORDER_WAYPOINTS_ONCE
        ba.println("Giving Move Order: " .. inspect({ target, target:getList().Name, vec.x, vec.y, vec.z }))
    end

    for _, ship in pairs(self.SelectedShips) do
        if target and ship.MissionShipInstance and ship.MissionShipInstance ~= target then
            ship.MissionShipInstance:clearOrders()
            ship.MissionShipInstance:giveOrder(order, target)
        end
    end
end

return GameMissionTactical