local Class      = require("class")
local Dialogs    = require('dialogs')
local Inspect    = require('inspect')
local Ship       = require('ship')
local ShipGroup  = require('ship_group')
local ShipList   = require('ship_list')
local StarSystem = require('star_system')
local SystemFile = require('system_file')
local Utils      = require('utils')
local Vector     = require('vector')
local Wing       = require('wing')

GameState = Class()

local new_game_ships = {
    ['Trinity Battle Group'] = ShipGroup({
        ['Name'] = 'Trinity Battle Group',
        ['Team'] = mn.Teams['Friendly'],
        ['System'] = {['Position'] = Vector(732316619172.03, -266742595861.88, 0), ['Speed'] = 1.0e+09, ['SubspaceSpeed'] = 1.0e+12,},
        ["SemiMajorAxis"] = 0.00056955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 1.387098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
        ['Ships'] = {
            ['Trinity'] = Ship({
                ['Species'] = 'Terran',
                ['Type'] = 'Cruiser',
                ['Class'] = 'GMF Gunship',
                ['Team'] = mn.Teams['Friendly'],
                ['Name'] = 'Trinity',
                ['System'] = {['Position'] = Vector(731316619172.03, -250842595861.88, 0), ['Speed'] = 1.0e+24, ['SubspaceSpeed'] = 1.0e+12,},
                ["SemiMajorAxis"] = 0.00056955529,
                ["MeanAnomalyEpoch"] = 174.79394829,
                ["OrbitalPeriod"] = 14.387098,
                ["Epoch"] = "2000-01-01T12:00:00",
                ["Radius"] = 100,
                ["Mass"] = 10000,
            }),
            ['Alpha'] = Wing({
                ['Name'] = 'Alpha',
                ['Team'] = mn.Teams['Friendly'],
                ["SemiMajorAxis"] = 0.00056955529,
                ["MeanAnomalyEpoch"] = 174.79394829,
                ["OrbitalPeriod"] = 14.387098,
                ["Epoch"] = "2000-01-01T12:00:00",
                ["Radius"] = 100,
                ["Mass"] = 10000,
                ['System'] = {['Position'] = Vector(731316619172.03, -250842595861.88, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
                ['Ships'] = {
                    ['Alpha 1'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 1',
                        ['System'] = {['Position'] = Vector(731316619172.03, -250842595861.88, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
                        ["SemiMajorAxis"] = 0.00056955529,
                        ["MeanAnomalyEpoch"] = 174.79394829,
                        ["OrbitalPeriod"] = 14.387098,
                        ["Epoch"] = "2000-01-01T12:00:00",
                        ["Radius"] = 100,
                        ["Mass"] = 10000,
                    }),
                    ['Alpha 2'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 2',
                        ['System'] = {['Position'] = Vector(731316619172.03, -250842595861.88, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
                        ["SemiMajorAxis"] = 0.00056955529,
                        ["MeanAnomalyEpoch"] = 174.79394829,
                        ["OrbitalPeriod"] = 14.387098,
                        ["Epoch"] = "2000-01-01T12:00:00",
                        ["Radius"] = 100,
                        ["Mass"] = 10000,
                    }),
                    ['Alpha 3'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 3',
                        ['System'] = {['Position'] = Vector(731316619172.03, -250842595861.88, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
                        ["SemiMajorAxis"] = 0.00056955529,
                        ["MeanAnomalyEpoch"] = 174.79394829,
                        ["OrbitalPeriod"] = 14.387098,
                        ["Epoch"] = "2000-01-01T12:00:00",
                        ["Radius"] = 100,
                        ["Mass"] = 10000,
                    }),
                    ['Alpha 4'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 4',
                        ['System'] = {['Position'] = Vector(731316619172.03, -250842595861.88, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
                        ["SemiMajorAxis"] = 0.00056955529,
                        ["MeanAnomalyEpoch"] = 174.79394829,
                        ["OrbitalPeriod"] = 14.387098,
                        ["Epoch"] = "2000-01-01T12:00:00",
                        ["Radius"] = 100,
                        ["Mass"] = 10000,
                    }),
                }
            }),
        }
    }),
    ['Abraxis'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Corvette',
        ['Class'] = 'GMC Escort',
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Abraxis',
        ['System'] = {['Position'] = Vector(731316619172.03, -267842595861.88, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.00025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Alhazred'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GMF Gunship',
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Alhazred',
        ['System'] = {['Position'] = Vector(730316619172.03, -266042595861.88, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.00056955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.587098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
}

GameState.CurrentTime = 0
GameState.TimeSpeed = 0

GameState.System = {}
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

function GameState.startNewGame()
    ba.println("Setting up new game")

    GameState.System = SystemFile:loadSystem('sol.json.cfg')

    GameState.MissionLoaded = false
    for _, ship in pairs(new_game_ships) do
        ba.println("Adding: " .. Inspect(ship))
        local new_ship = ship:copy()
        new_ship.ParentList = GameState.Ships
        GameState.Ships:add(new_ship)
    end

    GameState.System:get("Tethys"):add(GameState.Ships:get("Abraxis"))
    GameState.System:get("Saturn"):add(GameState.Ships:get("Alhazred"))
    GameState.System:get("Sol"):add(GameState.Ships:get("Trinity Battle Group"))

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