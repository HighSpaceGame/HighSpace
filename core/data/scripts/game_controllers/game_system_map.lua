local Class     = require("class")
local Dialogs   = require('dialogs')
local Inspect   = require('inspect')
local SystemFile    = require('system_file')
local Utils     = require('utils')
local Vector     = require('vector')

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil;

GameSystemMap.System = SystemFile:loadSystem('sol.json.cfg')

GameSystemMap.Camera = {
    ["Parent"]  = nil,
    ["Movement"]  = Vector(),
    ["Position"] = Vector(731316619172.03, -250842595861.88, 0),
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
    self.ScreenOffset = ba.createVector(width, height, 0) / 2
    self.Zoom = 1000.0 * math.exp(self.ZoomExp)
    self.StartZoom = self.Zoom
    self.TargetZoom = self.Zoom
end

function GameSystemMap.Camera:getScreenCoords(position)
    local screen_pos = (position - self.Position) / self.Zoom
    screen_pos.y = -screen_pos.y

    return screen_pos + self.ScreenOffset
end

function GameSystemMap.Camera:getWorldCoords(screen_pos)
    local world_pos = Vector()
    world_pos:fromFS2Vector(screen_pos - self.ScreenOffset)
    world_pos.y = -world_pos.y
    world_pos = world_pos * self.Zoom + self.Position

    return world_pos
end

function GameSystemMap.Camera:setMovement(camera_movement)
    self.Movement = camera_movement * self.Zoom * 4
    ba.println("GameSystemMap.Camera:setMovement: " .. Inspect({ ["X"] = camera_movement.x, ["Y"] = camera_movement.y}))
end

function GameSystemMap.Camera:zoom(direction)
    local current_time = os.clock()
    self.TargetZoom = self.Zoom

    if self.LastZoomDirection == direction or current_time > self.TargetZoomTime then
        self.ZoomExp = math.max(self.ZoomExp + direction*0.5, 0)
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

function GameSystemMap:isOverShip(ship, x, y)
    local dist = self.Camera:getScreenCoords(ship.System.Position) - Vector(x, y, 0)

    return dist:getMagnitude() < 40;
end

function GameSystemMap.isShipEncounter(ship1, ship2)
    local dist = ship2.System.Position - ship1.System.Position

    return dist:getMagnitude() < 100000;
end

function GameSystemMap:shipUnderScreenCoords(mouseX, mouseY)
    local found_ship

    GameState.Ships:forEach(function(ship)
        if GameSystemMap:isOverShip(ship, mouseX, mouseY) then
            found_ship = ship
            ba.println("Found ship under coords: " .. Inspect({ ship.Name, mouseX, mouseY }))
            return
        end
    end)

    return found_ship
end

function GameSystemMap:selectShip(mouseX, mouseY)
    if GameSystemMap.SelectedShip ~= nil then
        GameState.Ships:get(GameSystemMap.SelectedShip).IsSelected = false
        GameSystemMap.SelectedShip = nil
    end

    local ship = self:shipUnderScreenCoords(mouseX, mouseY)
    if ship then
        GameSystemMap.SelectedShip = ship.Name
        ship.IsSelected = true
        ba.println("Selected ship: " .. ship.Name)
    end
end

function GameSystemMap:moveShip(mouseX, mouseY)
    if self.SelectedShip ~= nil then
        local ship = GameState.Ships:get(GameSystemMap.SelectedShip)
        if ship.Team.Name == 'Friendly' then
            local target_ship = self:shipUnderScreenCoords(mouseX, mouseY)

            if target_ship then
                ship.System.Position = target_ship.System.Position:copy()
            else
                ship.System.Position = self.Camera:getWorldCoords(ba.createVector(mouseX, mouseY))
            end
        end

        ship.IsSelected = false
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