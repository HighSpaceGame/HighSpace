local Class     = require("class")
local Inspect   = require("inspect")
local Utils     = require("utils")

GameMission = Class()

GameMission.TacticalMode = false
GameMission.TacticalCamera = nil
GameMission.SelectedShips = {}

function GameMission:init()
    --RocketUiSystem.skip_ui["GS_STATE_GAME_PLAY"] = true
    --ba.println("Skipping state set: " .. inspect(RocketUiSystem.skip_ui))
end

function GameMission:switchCamera()
    if self.TacticalMode then
        ba.println("camera: " .. Inspect(self.TacticalCamera))
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

function GameMission:showTacticalView()
    return (self.TacticalMode and ba.getCurrentGameState().Name == "GS_STATE_GAME_PLAY")
end

function GameMission:toggleMode()
    self.TacticalMode = not self.TacticalMode

    self:switchCamera()
    RocketUiSystem.SkipUi["GS_STATE_GAME_PLAY"] = not self.TacticalMode
    hu.HUDDrawn = not self.TacticalMode
    io.setCursorHidden(not self.TacticalMode)
    if self.TacticalMode then
        ui.enableInput(RocketUiSystem.Context)
    else
        ui.disableInput()
    end
end

function GameMission:selectShips(selFrom, selTo)
    self.SelectedShips = {}
    for ship_name, ship in pairs(GameState.Ships) do
        if ship.MissionShipInstance then
            local x, y = ship.MissionShipInstance.Position:getScreenCoords()
            if Utils.Math.isInsideBox({ ["X"] = x, ["Y"] = y}, selFrom, selTo) then
                self.SelectedShips[ship_name] = ship
                ba.println("Selecting: " .. Inspect({ ship.Name, tostring(ship.MissionShipInstance.Target), ship.MissionShipInstance.Target:getBreedName(), ship.MissionShipInstance.Target:isValid() }))
            end
        end
    end
end

function GameMission:giveRightClickCommand(targetCursor)
    local order = nil
    local target = nil
    for _, ship in pairs(GameState.Ships) do
        if ship.MissionShipInstance then
            local x1, y1, x2, y2 = gr.drawTargetingBrackets(ship.MissionShipInstance, false)
            if Utils.Math.isInsideBox(targetCursor, { ["X"] = x1, ["Y"] = y1}, { ["X"] = x2, ["Y"] = y2}) then
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
        ba.println("Giving Order: " .. Inspect({ order, target.Name }))
    else
        local vec = gr.getVectorFromCoords(targetCursor.X, targetCursor.Y, 0, true) - GameMission.TacticalCamera.Position
        local vec_size = 1.0 / math.abs(vec.y) * math.abs(GameMission.TacticalCamera.Position.y)
        vec = GameMission.TacticalCamera.Position + vec * vec_size
        target = mn.createWaypoint(vec)
        order = ORDER_WAYPOINTS_ONCE
        ba.println("Giving Move Order: " .. Inspect({ target, target:getList().Name, vec.x, vec.y, vec.z }))
    end

    for _, ship in pairs(self.SelectedShips) do
        if target and ship.MissionShipInstance and ship.MissionShipInstance ~= target then
            ship.MissionShipInstance:clearOrders()
            ship.MissionShipInstance:giveOrder(order, target)
        end
    end
end

engine.addHook("On Ship Death Started", function()
    ba.println("Ship Died: " .. Inspect({ hv.Ship, hv.Killer, hv.Hitpos }))
    if GameState.Ships[hv.Ship.Name] then
        GameState.Ships[hv.Ship.Name] = nil
    end
end, {}, function()
    return false
end)

engine.addHook("On Ship Depart", function()
    ba.println("Ship Departed: " .. Inspect({ hv.Ship, hv.JumpNode, hv.Method }))
    if GameState.Ships[hv.Ship.Name] then
        GameState.Ships[hv.Ship.Name].Health = hv.Ship.HitpointsLeft / hv.Ship.HitpointsMax
    end
end, {}, function()
    return false
end)

engine.addHook("On Mission About To End", function()
    ba.println("Mission About To End")
    for si = 1, #mn.Ships do
        local mn_ship = mn.Ships[si]
        local g_ship = GameState.Ships[mn_ship.Name]
        if g_ship then
            ba.println("Setting ship health: " .. Inspect({ mn_ship.Name, mn_ship.HitpointsLeft, mn_ship.HitpointsMax, mn_ship.HitpointsLeft / mn_ship.HitpointsMax }))
            g_ship.Health = mn_ship.HitpointsLeft / mn_ship.HitpointsMax
        end
    end
end, {}, function()
    return false
end)

engine.addHook("On Key Pressed", function()
    ba.println("Key pressed: " .. hv.Key)
    if ba.getCurrentGameState().Name == "GS_STATE_GAME_PLAY" and hv.Key == "Enter" then
        GameMission:toggleMode()
    end
end, {}, function()
    return false
end)

return GameMission