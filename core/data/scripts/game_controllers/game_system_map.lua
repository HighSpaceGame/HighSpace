local Class           = require("class")
local Dialogs         = require("dialogs")
local Inspect         = require("inspect")
local KDTree          = require("kdtree")
local Ship            = require("ship")
local ShipGroup       = require("ship_group")
local ShipList        = require("ship_list")
local Utils           = require("utils")
local Vector          = require("vector")
local Wing            = require("wing")

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil
GameSystemMap.SelectedGroupShips = ShipList()

ba.println("loadSystem: " .. Inspect({ GameState.System }))

GameSystemMap.ShipMoveDummy = Ship({
    ["Species"] = "Terran",
    ["Type"] = "Cruiser",
    ["Class"] = "GMF Gunship",
    ["Team"] = mn.Teams["Friendly"],
    ["Name"] = "Ship Movement Dummy",
    ["System"] = {["Position"] = Vector(731316619172.03, -250842595861.88, 0), ["Speed"] = 1.0e+24, ["SubspaceSpeed"] = 1.0e+12,},
    ["SemiMajorAxis"] = 0,
    ["MeanAnomalyEpoch"] = 0,
    ["OrbitalPeriod"] = 0,
    ["Epoch"] = "2000-01-01T12:00:00",
    ["Radius"] = 0,
    ["Mass"] = 0,
})

function GameSystemMap.ShipMoveDummy:recalculateOrbitParent()
    if self.Parent and self.Parent.Parent then
        if Utils.Math.hasEscapedFromOrbit(self.SemiMajorAxis, self.Parent.SemiMajorAxis, self.Parent.Mass, self.Parent.Parent.Mass) then
            self.Parent = self.Parent.Parent
            self:recalculateOrbit()
            self:recalculateOrbitParent()
        end
    end
end

GameSystemMap.Camera = {
    ["Parent"]  = nil,
    ["Movement"]  = Vector(),
    ["Position"] = Vector(),
    ["RelPosition"] = Vector(),
    ["TargetRelPosition"] = nil,
    ["TargetMoveTime"] = time.getCurrentTime(),
    ["TargetMoveSpeed"] = 3.0,
    ["Zoom"] = 1.0,
    ["StartZoom"] = 1.0,
    ["TargetZoom"] = 1.0,
    ["ZoomSpeed"] = 3.0,
    ["ZoomExp"] = 9,
    ["TargetZoomTime"] = time.getCurrentTime(),
    ["LastZoomDirection"] = 0,
    ["ScreenOffset"] = {}
}

function GameSystemMap.Camera:init(width, height)
    ba.println("GameSystemMap.Camera:init: " .. Inspect({ width, height }))
    if self.IsInitialized then
        return
    end

    self.ScreenOffset = Vector(width, height) / 2
    self.ZoomExp = 17
    self.Zoom = 1000.0 * math.exp(self.ZoomExp)
    self.StartZoom = self.Zoom
    self.TargetZoom = self.Zoom

    self.Parent = GameState.System:get("Taganrog").Parent
    self.IsInitialized = true
end

function GameSystemMap.Camera:getScreenCoords(position)
    local screen_pos = (position - self.Position) / self.Zoom
    screen_pos.y = -screen_pos.y

    return screen_pos + self.ScreenOffset
end

function GameSystemMap.Camera:isOnScreen(position, margin)
    margin = margin or 0
    return (position.x + margin > 0 and position.y + margin > 0 and position.x - margin < self.ScreenOffset.x*2 and position.y - margin < self.ScreenOffset.y*2)
end

function GameSystemMap.Camera:getWorldCoords(screen_pos)
    local world_pos = screen_pos - self.ScreenOffset
    world_pos.y = -world_pos.y
    world_pos = world_pos * self.Zoom + self.Position

    return world_pos
end

function GameSystemMap.Camera:setMovement(camera_movement)
    self.Movement = camera_movement * self.Zoom * 4
    ba.println("GameSystemMap.Camera:setMovement: " .. Inspect({ ["x"] = camera_movement.x, ["y"] = camera_movement.y}))
end

function GameSystemMap.Camera:setTarget(object)
    GameSystemMap.Camera.Parent = object

    GameSystemMap.Camera.RelPosition = GameSystemMap.Camera.Position - object.System.Position
    GameSystemMap.Camera.TargetRelPosition = Vector(0,0)
    GameSystemMap.Camera.TargetMoveTime = time.getCurrentTime()
end

function GameSystemMap.Camera:zoom(direction)
    local current_time = time.getCurrentTime()
    self.TargetZoom = self.Zoom

    if self.LastZoomDirection == direction or (current_time - self.TargetZoomTime):getSeconds() > self.ZoomSpeed then
        self.ZoomExp = math.min(math.max(self.ZoomExp + direction*0.5, 0), 21.0)
        self.TargetZoomTime = current_time
        self.TargetZoom = 1000.0 * math.exp(self.ZoomExp)
    end

    self.StartZoom = self.Zoom
    self.LastZoomDirection = direction

    ba.println("Zoom: " .. Inspect({self.StartZoom, self.TargetZoom, self.ZoomExp}))
end

function GameSystemMap.Camera:update()
    if self.Movement.x ~= 0 or self.Movement.y ~= 0 then
        self.TargetRelPosition = nil
    end

    if self.TargetRelPosition then
        local target_move_progress = math.min((time.getCurrentTime()-self.TargetMoveTime):getSeconds() / self.TargetMoveSpeed, 1.0)
        --ba.println("GameSystemMap.Camera:target_move_progress: " .. Inspect({ (time.getCurrentTime() - self.TargetMoveTime):getSeconds(), target_move_progress }))
        self.RelPosition.x = Utils.Math.lerp(self.RelPosition.x, self.TargetRelPosition.x, target_move_progress)
        self.RelPosition.y = Utils.Math.lerp(self.RelPosition.y, self.TargetRelPosition.y, target_move_progress)
    end

    self.RelPosition = self.RelPosition + self.Movement
    self.Position = self.Parent.System.Position + self.RelPosition

    --a parabolic zoom progression seems to look more smooth than a linear one
    local zoom_progress = math.min((time.getCurrentTime()-self.TargetZoomTime):getSeconds() / self.ZoomSpeed, 1.0)
    --ba.println("GameSystemMap.Camera:zoomUpdate: " .. Inspect({ (time.getCurrentTime() - self.TargetZoomTime):getSeconds(), self.Zoom, self.TargetZoom, zoom_progress }))
    self.Zoom = Utils.Math.lerp(self.Zoom, self.TargetZoom, zoom_progress)
end

GameSystemMap.ObjectKDTree = KDTree()

local function add_system_object_to_tree(body)
    GameSystemMap.ObjectKDTree:addObject(body.System.Position, body)

    if not body.Satellites then
        return
    end

    for _, satellite in pairs(body.Satellites) do
        add_system_object_to_tree(satellite)
    end
end

local last_update_ts = time.getCurrentTime()
function GameSystemMap:update()
    --ba.println("update: " .. Inspect({ os.clock(), os.time(), (time.getCurrentTime() - start):getSeconds(), tonumber(time.getCurrentTime()) }))
    GameState.LastUpdateTime = GameState.CurrentTime
    GameState.CurrentTime = GameState.CurrentTime + (time.getCurrentTime() - last_update_ts):getSeconds() * GameState.TimeSpeed
    GameState.FrameTimeDiff = GameState.CurrentTime - GameState.LastUpdateTime
    last_update_ts = time.getCurrentTime()

    GameState.System:update()
    self.Camera:update()

    self.ObjectKDTree:initFrame()
    for _, star in pairs(GameState.System.Stars) do
        add_system_object_to_tree(star)
    end

    self:processEncounters()
end

function GameSystemMap.isShipEncounter(ship1, ship2)
    local dist = ship2.System.Position - ship1.System.Position

    return ship1.Name ~= ship2.Name and dist:getMagnitude() < 100000;
end

local function leftClickAstralHandler(object)
    GameSystemMap.Camera.Parent = object
    while GameSystemMap.Camera.Parent.Parent and (GameSystemMap.Camera.Parent.System.Position - GameSystemMap.Camera.Parent.Parent.System.Position):getSqrMagnitude() < math.pow(40 * GameSystemMap.Camera.Zoom, 2) do
        GameSystemMap.Camera.Parent = GameSystemMap.Camera.Parent.Parent
    end

    GameSystemMap.Camera:setTarget(object)
end

local function leftClickShipHandler(object)
    ba.println("leftClickShipHandler: " .. Inspect({GameSystemMap.SelectedShip and GameSystemMap.SelectedShip.Name or "Nil", object and object.Name or "Nil"}))
    if GameSystemMap.SelectedShip then
        GameSystemMap.SelectedShip.System.IsSelected = false
        if GameSystemMap.SelectedShip == object then
            GameSystemMap.Camera:setTarget(object)
        end
    end

    GameSystemMap.SelectedShip = object
    GameSystemMap.SelectedShip.System.IsSelected = true
    ba.println("Selected ship: " .. GameSystemMap.SelectedShip.Name)
end

local leftClickHandler
local leftClickHandlers = {
    ["Astral"] = leftClickAstralHandler,
    ["Ship"] = leftClickShipHandler,
}

function GameSystemMap:onLeftClick(mouse)
    local world_pos = self.Camera:getWorldCoords(mouse)
    local nearest = self.ObjectKDTree:findNearest(world_pos, 40 * self.Camera.Zoom)
    ba.println("GameSystemMap:onLeftClick: " .. Inspect({mouse.x, mouse.y, world_pos.x, world_pos.y, nearest and nearest[1] and nearest[1].Name }))

    if self.SelectedShip and (not nearest or not nearest[1]) then
        self.SelectedShip.System.IsSelected = false
        self.SelectedShip = nil
    end

    if not nearest or not nearest[1] then
        return
    end

    leftClickHandler = leftClickHandlers[nearest[1].Category] and leftClickHandlers[nearest[1].Category] or leftClickAstralHandler
    leftClickHandler(nearest[1])
end

function GameSystemMap:toggleGroupSelection(ship)
    if GameSystemMap.SelectedGroupShips:get(ship.Name) then
        GameSystemMap.SelectedGroupShips:remove(ship.Name)
    else
        GameSystemMap.SelectedGroupShips:add(ship)
    end
end

function GameSystemMap:updateShipMoveDummy(mouse)
    local world_pos = self.Camera:getWorldCoords(mouse)
    self.ShipMoveDummy.System.Position = world_pos
    local nearest = self.ObjectKDTree:findNearest(world_pos, nil,
            function(objects) return objects and objects[1].Category == "Astral" end
    )
    if nearest then
        self.ShipMoveDummy.Parent = nearest[1]
        self.ShipMoveDummy:recalculateOrbit()
        self.ShipMoveDummy:recalculateOrbitParent()
    end
end

function GameSystemMap:splitIfGroupSubselected()
    if self.SelectedShip and self.SelectedShip:is_a(ShipGroup) then
        local split_ships = self.SelectedShip:split(self.SelectedGroupShips)
        if split_ships then
            self.SelectedShip = split_ships
            self.SelectedGroupShips:clear()
        end
    end
end

local mergedShips = {}
function GameSystemMap:mergeShips(ship1, ship2)
    if not mergedShips[ship1.Name] and not mergedShips[ship2.Name] then
        ba.println("Merging: " .. Inspect({ship1.Name, ship2.Name}))

        mergedShips[ship1.Name] = 1
        mergedShips[ship2.Name] = 1

        ShipGroup.join(ship1, ship2)
    end
end

function GameSystemMap:moveShip(mouse, subspace)
    self:splitIfGroupSubselected()
    if self.SelectedShip then
        if self.SelectedShip.Team.Name == "Friendly" then
            self.SelectedShip.System.IsInSubspace = subspace

            local world_pos = self.Camera:getWorldCoords(mouse)
            local nearest = self.ObjectKDTree:findNearest(world_pos, 40 * self.Camera.Zoom,
                    function(objects) return objects and objects[1].Category == "Ship" end
            )
            if nearest then
                self.SelectedShip.System.Destination = { ["Position"] = nearest[1].System.Position - nearest[1].Parent.System.Position }
                self.SelectedShip.System.Destination.Parent = nearest[1].Parent
            else
                self.SelectedShip.System.Destination = { ["Position"] = self.ShipMoveDummy.System.Position:copy() }
                self.SelectedShip.System.Destination.Subspace = subspace

                if self.ShipMoveDummy.Parent then
                    self.SelectedShip.System.Destination.Parent = self.ShipMoveDummy.Parent
                    self.SelectedShip.System.Destination.Position = self.ShipMoveDummy.System.Position - self.ShipMoveDummy.Parent.System.Position
                end
            end
        end

        self.SelectedShip.System.IsSelected = false
        self.SelectedShip = nil
    end
end

function GameSystemMap:checkCollision(ship, planet)
    if (planet.System.Position - ship.System.Position):getSqrMagnitude() <= planet.Radius*planet.Radius then
        -- We"re assuming the colliding planet is the ship"s parent, which should be the case, but that"s the assumption I check if there"s some freaky bug in the future
        ship.SemiMajorAxis = planet.Radius + 10
        ship.System.Destination = nil
    end

    if not ship.System.Destination then
        return
    end

    local speed = ship:getCurrentSpeed()
    local destination = ship.System.Destination.Parent.System.Position + ship.System.Destination.Position
    local velocity = (destination - ship.System.Position)
    local max_time = (velocity / speed):getMagnitude()
    velocity = velocity / max_time

    local a = speed*speed
    local rel_position = ship.System.Position - planet.System.Position

    local b = 2 * (velocity.x * rel_position.x + velocity.y * rel_position.y)
    local c = rel_position:getSqrMagnitude() - planet.Radius*planet.Radius
    local delta = b*b - 4*a*c

    if delta >= 0 then
        local t1 = (-b - math.sqrt(delta)) / (2*a)
        local t2 = (-b + math.sqrt(delta)) / (2*a)
        t1 = t1 >= 0 and t1 < GameState.FrameTimeDiff and t1 or nil
        t2 = t2 >= 0 and t2 < GameState.FrameTimeDiff and t2 or nil

        local res = t1 and t2 and math.min(t1, t2) or (t1 or t2)
        if res and (velocity*res):getSqrMagnitude() > 0.000001 then
            ba.println("Collisions found: " .. Inspect({planet.Name, res, ship.System.Position.x, ship.System.Position.y}))
            ship.System.Position = ship.System.Position + velocity * res
            ship:recalculateOrbit()
            ship.SemiMajorAxis = ship.SemiMajorAxis + 10
            ship.System.Destination = nil
            ba.println("Collisions found: " .. Inspect({planet.Name, ship.System.Position.x, ship.System.Position.y}))
        end
    end
end

function GameSystemMap:processEncounters()
    if GameState.MissionLoaded and ba.getCurrentGameState().Name == "GS_STATE_BRIEFING" then
        ba.println("Quick-starting game")
        GameState.TimeSpeed = 0
        ui.ShipWepSelect.initSelect()
        ui.ShipWepSelect.resetSelect()
        ui.Briefing.commitToMission()
        ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME_QUICK"])
    end

    mergedShips = {}
    GameState.System:forEach(function(ship1)
        local near_objects = GameSystemMap.ObjectKDTree:findObjectsWithin(ship1.System.Position, ship1.Parent.Radius + ship1:getCurrentSpeed() * GameState.FrameTimeDiff)
        --ba.println("Checking Collisions: " .. Inspect({ship1.Name, #near_objects, ship1.Parent.Radius + ship1:getCurrentSpeed() * GameState.FrameTimeDiff}))
        for _, cluster in ipairs(near_objects) do
            local object = cluster.Groups["All"].Objects[1]

            if object.Category == "Ship" then
                if GameSystemMap.isShipEncounter(ship1, object) then
                    if ship1.Team.Name == object.Team.Name then
                        self:mergeShips(ship1, object)
                        return false
                    else
                        if ship1.Team.Name == "Unknown" or object.Team.Name == "Unknown" then
                            if ship1.Team.Name == "Friendly" or object.Team.Name == "Friendly" then
                                -- One of those is redundant but we don't know which
                                ship1.Team = mn.Teams["Friendly"]
                                object.Team = mn.Teams["Friendly"]

                                self:mergeShips(ship1, object)
                            else
                                ba.error("Encounter with 'Unknown' team not handled yet.")
                            end
                        elseif not GameState.MissionLoaded then
                            GameMission:setupMission(ship1, object)
                        end
                    end
                end
            elseif object.Category == "Astral" then
                --ba.println("checkCollision: " .. Inspect({ship1.Name, object.Name, nil and "0 true" or "0 false"}))
                self:checkCollision(ship1, object)
            end
        end
    end, "Ship")
end

return GameSystemMap