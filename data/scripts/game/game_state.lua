local inspect                            = require('inspect')

local game_state = {}

game_state.ships = {
    {
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GTC Leviathan',
        ['Position'] = {['x'] = 200, ['y'] = 200},
        ['Team'] = mn.Teams['Friendly'],
        ['Name'] = 'Trinity',
        ['IsSelected'] = false,
    },
    {
        ['Species'] = 'Shivan',
        ['Type'] = 'Corvette',
        ['Class'] = 'SCv Moloch',
        ['Position'] = {['x'] = 100, ['y'] = 100},
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Abraxis',
        ['IsSelected'] = false,
    },
    {
        ['Species'] = 'Shivan',
        ['Type'] = 'Cruiser',
        ['Class'] = 'SC Cain',
        ['Position'] = {['x'] = 300, ['y'] = 100},
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Alhazred',
        ['IsSelected'] = false,
    },
}

game_state.missionLoaded = false;
game_state.selected_ship = -1;

function game_state.isOverShip(si, x, y)
    local ship = game_state.ships[si]

    local dist = ba.createVector(ship.Position.x - x, ship.Position.y - y)
    return dist:getMagnitude() < 40;
end

function game_state.selectShip(mouseX, mouseY)
    if game_state.selected_ship > 0 then
        game_state.ships[game_state.selected_ship].IsSelected = false
        game_state.selected_ship = -1
    end

    for si = 1, #game_state.ships do
        if game_state.isOverShip(si, mouseX, mouseY) then
            game_state.selected_ship = si
            game_state.ships[si].IsSelected = true
            ba.println("Selected ship: " .. game_state.ships[si].Name)
            return
        end
    end
end

function game_state.moveShip(mouseX, mouseY)
    if game_state.selected_ship > 0 then
        local ship = game_state.ships[game_state.selected_ship]
        if ship.Species == 'Terran' then
            ship.Position.x = mouseX
            ship.Position.y = mouseY
        end

        game_state.ships[game_state.selected_ship].IsSelected = false
        game_state.selected_ship = -1
    end
end

function game_state.processEncounters()
    if game_state.missionLoaded and ba.getCurrentGameState().Name == 'GS_STATE_BRIEFING' then
        ba.println("Quick-starting game")
        ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME_QUICK"])
    end

    for sif = 1, #game_state.ships do
        local ship1 = game_state.ships[sif]
        if ship1.Species == 'Terran' then
            for sih = 1, #game_state.ships do
                local ship2 = game_state.ships[sih]
                if sif ~= sih and ship2.Species ~= 'Terran' then
                    if not game_state.missionLoaded and game_state.isOverShip(sih, ship1.Position.x, ship1.Position.y) then
                        for f = 1, #ba.GameEvents do
                            ba.println(inspect(ba.GameEvents[f]))
                        end
                        ba.println("Loading mission" .. inspect(ba.getCurrentGameState()))
                        game_state.missionLoaded = mn.loadMission("BeamsFree.fs2")
                        ba.println("Mission loaded: " .. inspect({ missionLoaded, ba.getCurrentGameState() }))

                        if game_state.missionLoaded then
                            local center = ba.createVector(0,0,6000)

                            ship1.MissionShipInstance = mn.createShip(ship1.Name, tb.ShipClasses[ship1.Class], nil, center:randomInSphere(1000, true, false), ship1.Team)
                            ship1.MissionShipInstance:giveOrder(ORDER_ATTACK_ANY)
                            ship2.MissionShipInstance = mn.createShip(ship2.Name, tb.ShipClasses[ship2.Class], nil, center:randomInSphere(1000, true, false), ship2.Team)
                            ship2.MissionShipInstance:giveOrder(ORDER_ATTACK_ANY)
                        end
                    end
                end
            end
        end
    end
end

return game_state