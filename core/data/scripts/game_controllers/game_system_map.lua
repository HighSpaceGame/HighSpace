local Class     = require("class")
local Dialogs   = require('dialogs')
local Inspect   = require('inspect')
local Utils     = require('utils')

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil;

function GameSystemMap.isOverShip(ship, x, y)
    local dist = ba.createVector(ship.System.Position.x - x, ship.System.Position.y - y)
    return dist:getMagnitude() < 40;
end

function GameSystemMap.selectShip(mouseX, mouseY)
    if GameSystemMap.SelectedShip ~= nil then
        GameState.Ships:get(GameSystemMap.SelectedShip).IsSelected = false
        GameSystemMap.SelectedShip = nil
    end

    GameState.Ships:forEach(function(ship)
        if GameSystemMap.isOverShip(ship, mouseX, mouseY) then
            GameSystemMap.SelectedShip = ship.Name
            ship.IsSelected = true
            ba.println("Selected ship: " .. ship.Name)
            return
        end
    end)
end

function GameSystemMap.moveShip(mouseX, mouseY)
    if GameSystemMap.SelectedShip ~= nil then
        local ship = GameState.Ships:get(GameSystemMap.SelectedShip)
        if ship.Team.Name == 'Friendly' then
            ship.System.Position.x = mouseX
            ship.System.Position.y = mouseY
        end

        ship.IsSelected = false
        GameSystemMap.SelectedShip = nil
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
                    if not GameState.MissionLoaded and GameSystemMap.isOverShip(ship2, ship1.System.Position.x, ship1.System.Position.y) then
                        GameMission:setupMission(ship1, ship2)
                    end
                end
            end)
        end
    end)
end

return GameSystemMap