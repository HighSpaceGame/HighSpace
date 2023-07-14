local class                              = require("class")
local dialogs                            = require('dialogs')
local inspect                            = require('inspect')
local utils                              = require('utils')

GameState = class()

GameState.new_game_ships = {
    ['Trinity'] = {
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GTC Aeolus',
        ['Position'] = {['x'] = 200, ['y'] = 200},
        ['Team'] = mn.Teams['Friendly'],
        ['Name'] = 'Trinity',
        ['IsSelected'] = false,
    },
    ['Abraxis'] = {
        ['Species'] = 'Shivan',
        ['Type'] = 'Corvette',
        ['Class'] = 'SCv Moloch',
        ['Position'] = {['x'] = 100, ['y'] = 100},
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Abraxis',
        ['IsSelected'] = false,
    },
    ['Alhazred'] = {
        ['Species'] = 'Shivan',
        ['Type'] = 'Cruiser',
        ['Class'] = 'SC Cain',
        ['Position'] = {['x'] = 300, ['y'] = 100},
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Alhazred',
        ['IsSelected'] = false,
    },
}

GameState.ships = {}

GameState.missionLoaded = false;
GameState.selected_ship = nil;

function GameState.isOverShip(ship, x, y)
    local dist = ba.createVector(ship.Position.x - x, ship.Position.y - y)
    return dist:getMagnitude() < 40;
end

function GameState.selectShip(mouseX, mouseY)
    if GameState.selected_ship ~= nil then
        GameState.ships[GameState.selected_ship].IsSelected = false
        GameState.selected_ship = nil
    end

    for shipName, ship in pairs(GameState.ships) do
        if GameState.isOverShip(ship, mouseX, mouseY) then
            GameState.selected_ship = shipName
            GameState.ships[shipName].IsSelected = true
            ba.println("Selected ship: " .. ship.Name)
            return
        end
    end
end

function GameState.moveShip(mouseX, mouseY)
    if GameState.selected_ship ~= nil then
        local ship = GameState.ships[GameState.selected_ship]
        if ship.Team.Name == 'Friendly' then
            ship.Position.x = mouseX
            ship.Position.y = mouseY
        end

        GameState.ships[GameState.selected_ship].IsSelected = false
        GameState.selected_ship = nil
    end
end

function GameState:initMissionShip(ship)
    local center = ba.createVector(0,0,6000)
    ship.MissionShipInstance = mn.createShip(ship.Name, tb.ShipClasses[ship.Class], nil, center:randomInSphere(1000, true, false), ship.Team)
    ship.MissionShipInstance:giveOrder(ORDER_ATTACK_ANY)

    if ship.Health == nil then
        ship.Health = 1.0
    else
        ship.MissionShipInstance.HitpointsLeft = ship.MissionShipInstance.HitpointsMax * ship.Health
    end
end

function GameState.processEncounters()
    if GameState.missionLoaded and ba.getCurrentGameState().Name == 'GS_STATE_BRIEFING' then
        ba.println("Quick-starting game")
        ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME_QUICK"])
    end

    for _, ship1 in pairs(GameState.ships) do
        if ship1.Team.Name == 'Friendly' then
            --ba.println("Ship1: " .. inspect({ship1.Name}))
            for _, ship2 in pairs(GameState.ships) do
                --ba.println("Ship2: " .. inspect({ship2.Name}))
                if ship1.Name ~= ship2.Name and ship2.Team.Name ~= 'Friendly' then
                    if not GameState.missionLoaded and GameState.isOverShip(ship2, ship1.Position.x, ship1.Position.y) then
                        ba.println("Loading mission" .. inspect(ba.getCurrentGameState()))
                        GameState.missionLoaded = mn.loadMission("BeamsFree.fs2")
                        ba.println("Mission loaded: " .. inspect({ GameState.missionLoaded, ba.getCurrentGameState() }))

                        if GameState.missionLoaded then
                            GameState:initMissionShip(ship1)
                            GameState:initMissionShip(ship2)

                            ba.println("Ships Created: " .. inspect(GameState.ships))
                        end
                    end
                end
            end
        end
    end
end

local showingDialog = false

function GameState.showDialog(title, text, textClass)
    local test_dialog = dialogs.new()
    test_dialog:title(title)
    test_dialog:text(text)
    test_dialog:textClass(textClass)
    test_dialog:button(dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Okay", -1), "", string.sub(ba.XSTR("Okay", -1), 1, 1))
    showingDialog = true
    test_dialog:show(RocketUiSystem.context):continueWith(function(response)
        showingDialog = false
        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    end)
end

function GameState.checkGameOver()
    if showingDialog then
        return
    end

    local ship_count = {
        ["Friendly"] = 0,
        ["Hostile"] = 0,
    }
    for _, ship in pairs(GameState.ships) do
        ship_count[ship.Team.Name] = ship_count[ship.Team.Name]+1
    end

    if ship_count["Friendly"] <= 0 then
        GameState.showDialog(ba.XSTR("Game Over", -1), ba.XSTR("You LOSE!", -1), "lose_text")
    elseif ship_count["Hostile"] <= 0 then
        GameState.showDialog(ba.XSTR("Game Over", -1), ba.XSTR("You WIN!", -1), "win_text")
    end
end

function GameState.stateChanged()
    local state = hv.NewState or ba.getCurrentGameState()
    ba.println("Starting State: " .. inspect({state.Name, hv.OldState.Name}))

    if state.Name == "GS_STATE_BRIEFING" then
        GameState.checkGameOver()
    elseif state.Name == "GS_STATE_START_GAME" and hv.OldState.Name == "GS_STATE_MAIN_MENU" then
        ba.println("Setting up new game")
        GameState.ships = utils.table.copy(GameState.new_game_ships)
        ba.println("Template table: " .. inspect(GameState.new_game_ships))
        ba.println("Game state table: " .. inspect(GameState.ships))
    elseif state.Name == "GS_STATE_DEBRIEF" then
        GameState.missionLoaded = false
        ba.println("Mission over")
        ba.println("Switching STATES: GS_EVENT_CMD_BRIEF")
        ba.postGameEvent(ba.GameEvents["GS_EVENT_CMD_BRIEF"])
    end
end

engine.addHook("On Ship Death Started", function()
    ba.println("Ship Died: " .. inspect({ hv.Ship, hv.Killer, hv.Hitpos }))
    if GameState.ships[hv.Ship.Name] then
        GameState.ships[hv.Ship.Name] = nil
    end
end, {}, function()
    return false
end)

engine.addHook("On Ship Depart", function()
    ba.println("Ship Departed: " .. inspect({ hv.Ship, hv.JumpNode, hv.Method }))
    if GameState.ships[hv.Ship.Name] then
        GameState.ships[hv.Ship.Name].Health = hv.Ship.HitpointsLeft / hv.Ship.HitpointsMax
    end
end, {}, function()
    return false
end)

engine.addHook("On Mission About To End", function()
    ba.println("Mission About To End")
    for si = 1, #mn.Ships do
        local mn_ship = mn.Ships[si]
        local g_ship = GameState.ships[mn_ship.Name]
        if g_ship then
            ba.println("Setting ship health: " .. inspect({ mn_ship.Name, mn_ship.HitpointsLeft, mn_ship.HitpointsMax, mn_ship.HitpointsLeft / mn_ship.HitpointsMax }))
            g_ship.Health = mn_ship.HitpointsLeft / mn_ship.HitpointsMax
        end
    end
end, {}, function()
    return false
end)

engine.addHook("On Key Pressed", function()
    ba.println("Key pressed: " .. hv.Key)
    if ba.getCurrentGameState().Name == "GS_STATE_GAME_PLAY" and hv.Key == "Enter" then
        GameMissionTactical:toggleMode()
    end
end, {}, function()
    return false
end)

engine.addHook("On Frame", function()
    if ba.getCurrentGameState().Name == "GS_STATE_BRIEFING" then
        GameState.processEncounters()
    end
end, {}, function()
    return false
end)

return GameState