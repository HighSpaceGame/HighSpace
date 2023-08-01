local Class      = require("class")
local Dialogs    = require('dialogs')
local Inspect    = require('inspect')
local Ship       = require('ship')
local ShipGroup  = require('ship_group')
local ShipList   = require('ship_list')
local Utils      = require('utils')
local Wing       = require('wing')

GameState = Class()

local new_game_ships = {
    ['Trinity Battle Group'] = ShipGroup({
        ['Name'] = 'Trinity Battle Group',
        ['Team'] = mn.Teams['Friendly'],
        ['System'] = {['Position'] = ba.createVector(200, 200, 0),},
        ['Ships'] = {
            ['Trinity'] = Ship({
                ['Species'] = 'Terran',
                ['Type'] = 'Cruiser',
                ['Class'] = 'GTC Aeolus',
                ['Team'] = mn.Teams['Friendly'],
                ['Name'] = 'Trinity',
                ['System'] = {['Position'] = ba.createVector(200, 200, 0),},
            }),
            ['Alpha'] = Wing({
                ['Name'] = 'Alpha',
                ['Team'] = mn.Teams['Friendly'],
                ['Ships'] = {
                    ['Alpha 1'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 1',
                        ['System'] = {['Position'] = ba.createVector(200, 200, 0),},
                    }),
                    ['Alpha 2'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 2',
                        ['System'] = {['Position'] = ba.createVector(200, 200, 0),},
                    }),
                    ['Alpha 3'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 3',
                        ['System'] = {['Position'] = ba.createVector(200, 200, 0),},
                    }),
                    ['Alpha 4'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 4',
                        ['System'] = {['Position'] = ba.createVector(200, 200, 0),},
                    }),
                }
            }),
        }
    }),
    ['Abraxis'] = Ship({
        ['Species'] = 'Shivan',
        ['Type'] = 'Corvette',
        ['Class'] = 'SCv Moloch',
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Abraxis',
        ['System'] = {['Position'] = ba.createVector(100, 100, 0),}
    }),
    ['Alhazred'] = Ship({
        ['Species'] = 'Shivan',
        ['Type'] = 'Cruiser',
        ['Class'] = 'SC Cain',
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Alhazred',
        ['System'] = {['Position'] = ba.createVector(300, 100, 0),}
    }),
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

    local mission_ship = {}
    function mission_ship:init(curr_ship)
        ba.println("mission_ship:init: " .. Inspect(curr_ship.Name))
        if curr_ship:is_a(ShipGroup) then
            curr_ship:forEach(function(group_ship)
                self:init(group_ship)
                center.x = center.x + 100
            end)
        elseif curr_ship:is_a(Ship) then
            curr_ship.Mission.Instance = mn.createShip(curr_ship.Name, tb.ShipClasses[curr_ship.Class], nil, center, curr_ship.Team)
            --curr_ship.Mission.Instance = mn.createShip(curr_ship.Name, tb.ShipClasses[curr_ship.Class], nil, center:randomInSphere(1000, true, false), curr_ship.Team)
            --curr_ship.Mission.Instance:giveOrder(ORDER_ATTACK_ANY)
            ba.println("GameMission.Ships: " .. Inspect(GameMission.Ships))
            GameMission.Ships:add(curr_ship)

            if curr_ship.Health == nil then
                curr_ship.Health = 1.0
            else
                curr_ship.Mission.Instance.HitpointsLeft = curr_ship.Mission.Instance.HitpointsMax * curr_ship.Health
            end
        end
    end

    mission_ship:init(ship)
end

function GameState.startNewGame()
    ba.println("Setting up new game")

    for _, ship_props in pairs(new_game_ships) do
        ba.println("Adding: " .. Inspect(ship_props))
        GameState.Ships:add(ship_props:clone())
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