local Class     = require("class")
local Dialogs   = require('dialogs')
local Inspect   = require('inspect')
local Utils     = require('utils')

GameState = Class()

local new_game_ships = {
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

GameState.Ships = {}

GameState.MissionLoaded = false;

local showing_dialog = false

function GameState.showDialog(title, text, textClass)
    local dialog = Dialogs.new()
    dialog:title(title)
    dialog:text(text)
    dialog:textClass(textClass)
    dialog:button(Dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Okay", -1), "", string.sub(ba.XSTR("Okay", -1), 1, 1))
    showing_dialog = true
    dialog:show(RocketUiSystem.Context):continueWith(function(response)
        showing_dialog = false
        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    end)
end

function GameState.checkGameOver()
    if showing_dialog then
        return
    end

    local ship_count = {
        ["Friendly"] = 0,
        ["Hostile"] = 0,
    }
    for _, ship in pairs(GameState.Ships) do
        ship_count[ship.Team.Name] = ship_count[ship.Team.Name]+1
    end

    if ship_count["Friendly"] <= 0 then
        GameState.showDialog(ba.XSTR("Game Over", -1), ba.XSTR("You LOSE!", -1), "lose_text")
    elseif ship_count["Hostile"] <= 0 then
        GameState.showDialog(ba.XSTR("Game Over", -1), ba.XSTR("You WIN!", -1), "win_text")
    end
end

function GameState:initMissionShip(ship)
    local center = ba.createVector(0,0,6000)

    if ship.Team.Name == "Friendly" then
        center = ba.createVector(-1000,0,6000)
    else
        center = ba.createVector(1000,0,6000)
    end
    ship.MissionShipInstance = mn.createShip(ship.Name, tb.ShipClasses[ship.Class], nil, center, ship.Team)
    --ship.MissionShipInstance = mn.createShip(ship.Name, tb.ShipClasses[ship.Class], nil, center:randomInSphere(1000, true, false), ship.Team)
    --ship.MissionShipInstance:giveOrder(ORDER_ATTACK_ANY)
    GameMission.Ships[ship.Name] = ship

    if ship.Health == nil then
        ship.Health = 1.0
    else
        ship.MissionShipInstance.HitpointsLeft = ship.MissionShipInstance.HitpointsMax * ship.Health
    end
end

--Called from ui_system-sct.lua
function GameState.stateChanged()
    local state = hv.NewState or ba.getCurrentGameState()
    ba.println("Starting State: " .. Inspect({ state.Name, hv.OldState.Name}))

    if state.Name == "GS_STATE_BRIEFING" then
        GameState.checkGameOver()
    elseif state.Name == "GS_STATE_START_GAME" and hv.OldState.Name == "GS_STATE_MAIN_MENU" then
        ba.println("Setting up new game")
        GameState.Ships = Utils.Table.copy(new_game_ships)
        ba.println("Template table: " .. Inspect(new_game_ships))
        ba.println("Game state table: " .. Inspect(GameState.Ships))
    elseif state.Name == "GS_STATE_DEBRIEF" then
        GameState.MissionLoaded = false
        ba.println("Mission over")
        ba.println("Switching STATES: GS_EVENT_CMD_BRIEF")
        ba.postGameEvent(ba.GameEvents["GS_EVENT_CMD_BRIEF"])
    end
end

return GameState