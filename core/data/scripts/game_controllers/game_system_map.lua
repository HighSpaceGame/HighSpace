local Class     = require("class")
local Dialogs   = require('dialogs')
local Inspect   = require('inspect')
local Utils     = require('utils')

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil;

GameSystemMap.Camera = {
    ["Parent"]  = nil,
    ["Movement"]  = ba.createVector(0, 0, 0),
    ["Position"] = ba.createVector(0, 0, 0),
    ["Zoom"] = 1,
    ["ScreenOffset"] = {}
}

function GameSystemMap.Camera:init(width, height)
    self.ScreenOffset = ba.createVector(width, height, 0) / 2
end

function GameSystemMap.Camera:getScreenCoords(position)
    local screen_pos = (position - self.Position) / self.Zoom
    screen_pos.y = -screen_pos.y

    return screen_pos + self.ScreenOffset
end

function GameSystemMap.Camera:getWorldCoords(screen_pos)
    local world_pos = screen_pos - self.ScreenOffset
    world_pos.y = -world_pos.y
    world_pos = world_pos * self.Zoom + self.Position

    return world_pos
end

function GameSystemMap.Camera:setMovement(camera_movement)
    self.Movement = camera_movement * self.Zoom * 4
    ba.println("GameSystemMap.Camera:setMovement: " .. Inspect({ ["X"] = camera_movement.x, ["Y"] = camera_movement.y}))
end

function GameSystemMap.Camera:zoom(zoom)
    ba.println("GameSystemMap.Camera:zoom: " .. Inspect({ zoom }))
    self.Zoom = self.Zoom * zoom
end

function GameSystemMap.Camera:update()
    self.Position = self.Position + self.Movement
end

function GameSystemMap:isOverShip(ship, x, y)
    local dist = self.Camera:getScreenCoords(ship.System.Position) - ba.createVector(x, y, 0)

    return dist:getMagnitude() < 40;
end

function GameSystemMap.isShipEncounter(ship1, ship2)
    local dist = ship2.System.Position - ship1.System.Position

    return dist:getMagnitude() < 40;
end

function GameSystemMap:selectShip(mouseX, mouseY)
    if GameSystemMap.SelectedShip ~= nil then
        GameState.Ships:get(GameSystemMap.SelectedShip).IsSelected = false
        GameSystemMap.SelectedShip = nil
    end

    GameState.Ships:forEach(function(ship)
        if GameSystemMap:isOverShip(ship, mouseX, mouseY) then
            GameSystemMap.SelectedShip = ship.Name
            ship.IsSelected = true
            ba.println("Selected ship: " .. ship.Name)
            return
        end
    end)
end

function GameSystemMap:moveShip(mouseX, mouseY)
    if self.SelectedShip ~= nil then
        local ship = GameState.Ships:get(GameSystemMap.SelectedShip)
        if ship.Team.Name == 'Friendly' then
            ship.System.Position = self.Camera:getWorldCoords(ba.createVector(mouseX, mouseY))
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