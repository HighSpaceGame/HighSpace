local Class     = require("class")
local Inspect   = require("inspect")
local Ship       = require('ship')
local ShipGroup  = require('ship_group')
local ShipList   = require('ship_list')
local Utils      = require('utils')
local Wing       = require('wing')

GameMission = Class()

GameMission.TacticalMode = false
GameMission.Ships = ShipList() -- a seperate list to avoid iterating over ships from outside the mission scope
GameMission.SelectedShips = {}
GameMission.TacticalCamera = {
    ["Movement"]  = ba.createVector(0, 0, 0),
    -- we should be able to manipulate the Camera matrix directly, but somewhere along the way, it's getting value-copied
    ["Orientation"] = ba.createOrientationFromVectors(ba.createVector(0, -1, 0)),
    ["Target"] = ba.createVector(0, 0, 6000),
    ["Zoom"] = 3000,
    ["Instance"] = nil,
}

function GameMission.TacticalCamera:rotateBy(pitch, heading)
    self.Orientation.p = self.Orientation.p + pitch
    self.Orientation.h = self.Orientation.h + heading
end

function GameMission.TacticalCamera:setMovement(camera_movement)
    local cam_mov_right = GameMission.TacticalCamera.Orientation:unrotateVector(ba.createVector(1, 0 ,0))
    local cam_mov_front = cam_mov_right:getCrossProduct(ba.createVector(0, 1 ,0)) * camera_movement.z

    self.Movement = (cam_mov_right * camera_movement.x + cam_mov_front) * self.Zoom / 100
    --ba.println("moveCamera: " .. Inspect({ ["X"] = x, ["Y"] = y}))
end

function GameMission.TacticalCamera:zoom(zoom)
    ba.println("TacticalCamera:zoom: " .. Inspect({ zoom }))
    self.Zoom = self.Zoom * zoom
end

function GameMission.TacticalCamera:update()
    self.Target = self.Target + self.Movement
    self.Instance.Orientation = self.Orientation
    self.Instance.Position = self.Target - self.Instance.Orientation:getFvec() * self.Zoom
end

function GameMission:init()
    --RocketUiSystem.skip_ui["GS_STATE_GAME_PLAY"] = true
    --ba.println("Skipping state set: " .. inspect(RocketUiSystem.skip_ui))
end

function GameMission:initMissionShip(ship)
    local center = ba.createVector(0,0,6000)

    if ship.Team.Name == "Friendly" then
        center = ba.createVector(-1000,0,0)
    else
        center = ba.createVector(1000,0,6000)
    end

    local mission_ship = {}
    function mission_ship:init(curr_ship)
        ba.println("mission_ship:init: " .. Inspect(curr_ship.Name))
        if curr_ship:is_a(ShipGroup) then
            curr_ship:forEach(function(group_ship)
                self:init(group_ship)
                center.x = center.x + 100
            end)
        elseif curr_ship:is_a(Ship) then
            if curr_ship.Team.Name == 'Hostile' then
                curr_ship.Mission.Instance = mn.createShip(curr_ship.Name, tb.ShipClasses[curr_ship.Class], ba.createOrientationFromVectors(ba.createVector(0, 0, -1)), center, curr_ship.Team)
                curr_ship.Mission.Instance:giveOrder(ORDER_ATTACK_SHIP_CLASS, nil, nil, 1, tb.ShipClasses['GTC Aeolus'])
            else
                curr_ship.Mission.Instance = mn.createShip(curr_ship.Name, tb.ShipClasses[curr_ship.Class], nil, center:randomInSphere(1000, true, false), curr_ship.Team)
            end

            ba.println("GameMission.Ships: " .. Inspect(GameMission.Ships))
            GameMission.Ships:add(curr_ship)

            if curr_ship.Health == nil then
                curr_ship.Health = 1.0
            else
                curr_ship.Mission.Instance.HitpointsLeft = curr_ship.Mission.Instance.HitpointsMax * curr_ship.Health
            end
        end
    end

    mission_ship:init(ship)
end

function GameMission:switchCamera()
    if self.TacticalMode then
        ba.println("camera: " .. Inspect(self.TacticalCamera))
        if not self.TacticalCamera.Instance or not self.TacticalCamera.Instance:isValid() then
            self.TacticalCamera.Instance = gr.createCamera("TactMapCamera", ba.createVector(0, 3000, 6000), ba.createOrientationFromVectors(ba.createVector(0, -1, 0)))
        end

        self.TacticalCamera.Instance.Position = ba.createVector(0, 3000, 6000)
        self.TacticalCamera.Instance.Orientation = ba.createOrientationFromVectors(ba.createVector(0, -1, 0))
        gr.setCamera(self.TacticalCamera.Instance)
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
    self.Ships:forEach(function(ship)
        if ship.Mission.Instance then
            local x, y = ship.Mission.Instance.Position:getScreenCoords()
            if Utils.Math.isInsideBox({ ["X"] = x, ["Y"] = y}, selFrom, selTo) then
                self.SelectedShips[ship.Name] = ship
                ba.println("Selecting: " .. Inspect({ ship.Name, tostring(ship.Mission.Instance.Target), ship.Mission.Instance.Target:getBreedName(), ship.Mission.Instance.Target:isValid() }))
            end
        end
    end)
end

function GameMission:giveRightClickCommand(targetCursor)
    local order = nil
    local target = nil
    self.Ships:forEach(function(ship)
        if ship.Mission.Instance then
            local x1, y1, x2, y2 = gr.drawTargetingBrackets(ship.Mission.Instance, false)
            if Utils.Math.isInsideBox(targetCursor, { ["X"] = x1, ["Y"] = y1}, { ["X"] = x2, ["Y"] = y2}) then
                target = ship
                return false
            end
        end
    end)

    if target then
        if target.Team.Name == "Friendly" then
            order = ORDER_GUARD
        elseif target.Team.Name == "Hostile" then
            order = ORDER_ATTACK
        end

        target = target.Mission.Instance
        ba.println("Giving Order: " .. Inspect({ order, target.Name }))
    else
        local vec = gr.getVectorFromCoords(targetCursor.X, targetCursor.Y, 0, true) - GameMission.TacticalCamera.Instance.Position
        local vec_size = 1.0 / math.abs(vec.y) * math.abs(GameMission.TacticalCamera.Instance.Position.y)
        vec = GameMission.TacticalCamera.Instance.Position + vec * vec_size
        target = mn.createWaypoint(vec)
        order = ORDER_WAYPOINTS_ONCE
        ba.println("Giving Move Order: " .. Inspect({ target, target:getList().Name, vec.x, vec.y, vec.z }))
    end

    for _, ship in pairs(self.SelectedShips) do
        if target and ship.Mission.Instance and ship.Mission.Instance ~= target and ship.Mission.Instance.Team.Name == "Friendly" then
            ship.Mission.Instance:clearOrders()
            ship.Mission.Instance:giveOrder(order, target)
            ship.Order = {["Type"] = order, ["Target"] = target}
        end
    end
end

engine.addHook("On Ship Death Started", function()
    ba.println("Ship Died: " .. Inspect({ hv.Ship, hv.Killer, hv.Hitpos }))
    GameState.Ships:remove(hv.Ship.Name)
    GameMission.Ships:remove(hv.Ship.Name)
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

engine.addHook("On Waypoints Done", function()
    ba.println("On Waypoints Done: " .. hv.Ship.Name)
    local g_ship = GameState.Ships[hv.Ship.Name]
    if g_ship then
        g_ship.Order = nil
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