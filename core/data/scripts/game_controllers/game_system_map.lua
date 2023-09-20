local Class           = require("class")
local Dialogs         = require('dialogs')
local Inspect         = require('inspect')
local KDTree          = require('kdtree')
local SystemFile      = require('system_file')
local Utils           = require('utils')
local Vector          = require('vector')

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil;

GameSystemMap.System = SystemFile:loadSystem('sol.json.cfg')

GameSystemMap.Camera = {
    ["Parent"]  = nil,
    ["Movement"]  = Vector(),
    ["Position"] = Vector(731316619172.03, -266842595861.88, 0),
    ["Zoom"] = 1.0,
    ["StartZoom"] = 1.0,
    ["TargetZoom"] = 1.0,
    ["ZoomSpeed"] = 0.10,
    ["ZoomExp"] = 9,
    ["TargetZoomTime"] = os.clock(),
    ["LastZoomDirection"] = 0,
    ["ScreenOffset"] = {}
}

function GameSystemMap.Camera:init(width, height)
    self.ScreenOffset = Vector(width, height) / 2
    self.Zoom = 1000.0 * math.exp(self.ZoomExp)
    self.StartZoom = self.Zoom
    self.TargetZoom = self.Zoom
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

function GameSystemMap.Camera:zoom(direction)
    local current_time = os.clock()
    self.TargetZoom = self.Zoom

    if self.LastZoomDirection == direction or current_time > self.TargetZoomTime then
        self.ZoomExp = math.min(math.max(self.ZoomExp + direction*0.5, 0), 21.0)
        self.TargetZoomTime = current_time + self.ZoomSpeed
        self.TargetZoom = 1000.0 * math.exp(self.ZoomExp)
    end

    self.StartZoom = self.Zoom
    self.LastZoomDirection = direction

    ba.println("Zoom: " .. Inspect({current_time, self.TargetZoomTime, self.TargetZoom, self.ZoomExp}))
end

function GameSystemMap.Camera:update()
    self.Position = self.Position + self.Movement

    --a parabolic zoom progression seems to look more smooth than a linear one
    local zoom_progress = 1.0 - math.pow(math.min((os.clock()-self.TargetZoomTime) / self.ZoomSpeed, 0.0), 2.0)
    --ba.println("GameSystemMap.Camera:zoomUpdate: " .. Inspect({ os.date(), self.Zoom, self.TargetZoom, os.clock(), self.TargetZoomTime, zoom_progress }))
    self.Zoom = Utils.Math.lerp(self.StartZoom, self.TargetZoom, zoom_progress)
end

GameSystemMap.ObjectKDTree = KDTree()

local add_system_object_to_tree
add_system_object_to_tree = function(body, parent)
    local world_position = Vector()

    if parent then
        world_position.x = 1
        world_position = world_position * body.SemiMajorAxis * 149597870700.0
        world_position = world_position:rotate(0, math.rad(body.MeanAnomalyEpoch), 0) + parent.WorldPosition
    end

    body.WorldPosition = world_position

    GameSystemMap.ObjectKDTree:addObject(world_position, body)

    if not body.Satellites then
        return
    end

    for _, satellite in pairs(body.Satellites) do
        add_system_object_to_tree(satellite, body)
    end
end

function GameSystemMap:update()
    GameSystemMap.Camera:update()
    self.ObjectKDTree:initFrame()

    GameState.Ships:forEach(function(curr_ship)
        self.ObjectKDTree:addObject(curr_ship.System.Position, curr_ship)
    end)
end

function GameSystemMap.isShipEncounter(ship1, ship2)
    local dist = ship2.System.Position - ship1.System.Position

    return dist:getMagnitude() < 100000;
end

function GameSystemMap:selectShip(mouse)
    if self.SelectedShip ~= nil then
        self.SelectedShip.IsSelected = false
        self.SelectedShip = nil
    end

    local world_pos = self.Camera:getWorldCoords(mouse)
    local nearest = self.ObjectKDTree:findNearest(world_pos, math.pow(40 * self.Camera.Zoom, 2))
    if nearest then
        self.SelectedShip = nearest[1]
        self.SelectedShip.IsSelected = true
        ba.println("Selected ship: " .. self.SelectedShip.Name)
    end
end

function GameSystemMap:moveShip(mouse)
    if self.SelectedShip ~= nil then
        if self.SelectedShip.Team.Name == 'Friendly' then
            local world_pos = self.Camera:getWorldCoords(mouse)
            local nearest = self.ObjectKDTree:findNearest(world_pos, math.pow(40 * self.Camera.Zoom, 2))
            if nearest then
                self.SelectedShip.System.Position = nearest[1].System.Position:copy()
            else
                self.SelectedShip.System.Position = world_pos
            end
        end

        self.SelectedShip.IsSelected = false
        self.SelectedShip = nil
    end
end

function GameSystemMap.processEncounters()
    if GameState.MissionLoaded and ba.getCurrentGameState().Name == 'GS_STATE_BRIEFING' then
        ba.println("Quick-starting game")
        ui.ShipWepSelect.initSelect()
        ui.ShipWepSelect.resetSelect()
        ui.Briefing.commitToMission()
        ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME_QUICK"])
    end

    GameState.Ships:forEach(function(ship1)
        if ship1.Team.Name == 'Friendly' then
            --ba.println("Ship1: " .. inspect({ship1.Name}))
            GameState.Ships:forEach(function(ship2)
                --ba.println("Ship2: " .. inspect({ship2.Name}))
                if ship1.Name ~= ship2.Name and ship2.Team.Name ~= 'Friendly' then
                    if not GameState.MissionLoaded and GameSystemMap.isShipEncounter(ship1, ship2) then
                        GameMission:setupMission(ship1, ship2)
                    end
                end
            end)
        end
    end)
end

return GameSystemMap