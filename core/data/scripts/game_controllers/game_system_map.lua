local Class     = require("class")
local Dialogs   = require('dialogs')
local Inspect   = require('inspect')
local Utils     = require('utils')

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil;

function GameSystemMap.isOverShip(ship, x, y)
    local dist = ba.createVector(ship.Position.x - x, ship.Position.y - y)
    return dist:getMagnitude() < 40;
end

function GameSystemMap.selectShip(mouseX, mouseY)
    if GameSystemMap.SelectedShip ~= nil then
        GameState.Ships[GameSystemMap.SelectedShip].IsSelected = false
        GameSystemMap.SelectedShip = nil
    end

    for shipName, ship in pairs(GameState.Ships) do
        if GameSystemMap.isOverShip(ship, mouseX, mouseY) then
            GameSystemMap.SelectedShip = shipName
            GameState.Ships[shipName].IsSelected = true
            ba.println("Selected ship: " .. ship.Name)
            return
        end
    end
end

function GameSystemMap.moveShip(mouseX, mouseY)
    if GameSystemMap.SelectedShip ~= nil then
        local ship = GameState.Ships[GameSystemMap.SelectedShip]
        if ship.Team.Name == 'Friendly' then
            ship.Position.x = mouseX
            ship.Position.y = mouseY
        end

        GameState.Ships[GameSystemMap.SelectedShip].IsSelected = false
        GameSystemMap.SelectedShip = nil
    end
end

function GameSystemMap.processEncounters()
    if GameState.MissionLoaded and ba.getCurrentGameState().Name == 'GS_STATE_BRIEFING' then
        ba.println("Quick-starting game")
        ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME_QUICK"])
    end

    for _, ship1 in pairs(GameState.Ships) do
        if ship1.Team.Name == 'Friendly' then
            --ba.println("Ship1: " .. inspect({ship1.Name}))
            for _, ship2 in pairs(GameState.Ships) do
                --ba.println("Ship2: " .. inspect({ship2.Name}))
                if ship1.Name ~= ship2.Name and ship2.Team.Name ~= 'Friendly' then
                    if not GameState.MissionLoaded and GameSystemMap.isOverShip(ship2, ship1.Position.x, ship1.Position.y) then
                        ba.println("Loading mission" .. Inspect(ba.getCurrentGameState()))
                        GameState.MissionLoaded = mn.loadMission("BeamsFree.fs2")
                        ba.println("Mission loaded: " .. Inspect({ GameState.MissionLoaded, ba.getCurrentGameState() }))

                        if GameState.MissionLoaded then
                            GameMission.Ships = {}
                            GameState:initMissionShip(ship1)
                            GameState:initMissionShip(ship2)

                            ba.println("Ships Created: " .. Inspect(GameState.Ships))
                        end
                    end
                end
            end
        end
    end
end

return GameSystemMap