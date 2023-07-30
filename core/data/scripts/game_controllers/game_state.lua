local Class     = require("class")
local Dialogs   = require('dialogs')
local Inspect   = require('inspect')
local Ship      = require('ship')
local ShipList  = require('ship_list')
local Utils     = require('utils')

GameState = Class()

local new_game_ships = {
    ['Trinity'] = {
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GTC Aeolus',
        ['Team'] = mn.Teams['Friendly'],
        ['Name'] = 'Trinity',
        ['System'] = {['Position'] = ba.createVector(200, 200, 0),}
    },
    ['Abraxis'] = {
        ['Species'] = 'Shivan',
        ['Type'] = 'Corvette',
        ['Class'] = 'SCv Moloch',
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Abraxis',
        ['System'] = {['Position'] = ba.createVector(100, 100, 0),}
    },
    ['Alhazred'] = {
        ['Species'] = 'Shivan',
        ['Type'] = 'Cruiser',
        ['Class'] = 'SC Cain',
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Alhazred',
        ['System'] = {['Position'] = ba.createVector(300, 100, 0),}
    },
}

GameState.Ships = ShipList()

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
    GameState.Ships:forEach(function(ship)
        ship_count[ship.Team.Name] = ship_count[ship.Team.Name]+1
    end)

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
    ship.Mission.Instance = mn.createShip(ship.Name, tb.ShipClasses[ship.Class], nil, center, ship.Team)
    --ship.Mission.Instance = mn.createShip(ship.Name, tb.ShipClasses[ship.Class], nil, center:randomInSphere(1000, true, false), ship.Team)
    --ship.Mission.Instance:giveOrder(ORDER_ATTACK_ANY)
    GameMission.Ships[ship.Name] = ship

    if ship.Health == nil then
        ship.Health = 1.0
    else
        ship.Mission.Instance.HitpointsLeft = ship.Mission.Instance.HitpointsMax * ship.Health
    end
end

function GameState.startNewGame()
    ba.println("Setting up new game")

    for _, ship_props in pairs(new_game_ships) do
        GameState.Ships:add(Ship(ship_props))
    end

    ba.println("Template table: " .. Inspect(new_game_ships))
    ba.println("Game state table: " .. Inspect(GameState.Ships))
end

--Called from ui_system-sct.lua
function GameState.stateChanged()
    local state = hv.NewState or ba.getCurrentGameState()
    ba.println("Starting State: " .. Inspect({ state.Name, hv.OldState.Name}))

    if state.Name == "GS_STATE_BRIEFING" then
        GameState.checkGameOver()
    elseif state.Name == "GS_STATE_START_GAME" and hv.OldState.Name == "GS_STATE_MAIN_MENU" then
        GameState.startNewGame()
    elseif state.Name == "GS_STATE_DEBRIEF" then
        GameState.MissionLoaded = false
        ba.println("Mission over")
        ba.println("Switching STATES: GS_EVENT_CMD_BRIEF")
        ba.postGameEvent(ba.GameEvents["GS_EVENT_CMD_BRIEF"])
    end
end

return GameState