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
    ['Taganrog Battle Group'] = ShipGroup({
        ['Name'] = 'Taganrog Battle Group',
        ['Team'] = mn.Teams['Friendly'],
        ['Species'] = 'Terran',
        ['Type'] = 'Group',
        ['Class'] = 'Group',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 1.0e+03, ['SubspaceSpeed'] = 1.0e+09,},
        ["SemiMajorAxis"] = 12.00056955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 1.387098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
        ['Ships'] = {
            ['Taganrog'] = Ship({
                ['Species'] = 'Terran',
                ['Type'] = 'Cruiser',
                ['Class'] = 'GMF Gunship',
                ['Team'] = mn.Teams['Friendly'],
                ['Name'] = 'Taganrog',
                ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 1.0e+03, ['SubspaceSpeed'] = 1.0e+09,},
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
                ['Species'] = 'Terran',
                ['Type'] = 'Wing',
                ['Class'] = 'Wing',
                ["SemiMajorAxis"] = 0.00056955529,
                ["MeanAnomalyEpoch"] = 174.79394829,
                ["OrbitalPeriod"] = 14.387098,
                ["Epoch"] = "2000-01-01T12:00:00",
                ["Radius"] = 100,
                ["Mass"] = 10000,
                ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 4.0e+03, ['SubspaceSpeed'] = 4.0e+09,},
                ['Ships'] = {
                    ['Alpha 1'] = Ship({
                        ['Species'] = 'Terran',
                        ['Type'] = 'Fighter',
                        ['Class'] = 'GTF Myrmidon',
                        ['Team'] = mn.Teams['Friendly'],
                        ['Name'] = 'Alpha 1',
                        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
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
                        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
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
                        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
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
                        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
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
    ['Alypius'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GTC Aeolus',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Alypius',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.10025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Kashin'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GTC Aeolus',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Kashin',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.20025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Onesimus'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GTC Aeolus',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Onesimus',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.30025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Optina'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GMC Escort',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Optina',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.40025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Murom'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GMC Escort',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Murom',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.50025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Zhidiata'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Cruiser',
        ['Class'] = 'GMC Escort',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Zhidiata',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.60025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Avvakum'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Transport',
        ['Class'] = 'GMD Pursuit',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Avvakum',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.70025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Ambrosius'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Transport',
        ['Class'] = 'GMD Pursuit',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Ambrosius',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.80025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Agapetus'] = Ship({
        ['Species'] = 'Terran',
        ['Type'] = 'Transport',
        ['Class'] = 'GMD Pursuit',
        ['Team'] = mn.Teams['Unknown'],
        ['Name'] = 'Agapetus',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.90025955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.087098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
    ['Abraxis'] = Ship({
        ['Species'] = 'Shivan',
        ['Type'] = 'Capital',
        ['Class'] = 'SD Demon',
        ['Team'] = mn.Teams['Hostile'],
        ['Name'] = 'Abraxis',
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
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
        ['System'] = {['Position'] = Vector(0, 0, 0), ['Speed'] = 10000, ['SubspaceSpeed'] = 100000000,},
        ["SemiMajorAxis"] = 0.00056955529,
        ["MeanAnomalyEpoch"] = 174.79394829,
        ["OrbitalPeriod"] = 0.587098,
        ["Epoch"] = "2000-01-01T12:00:00",
        ["Radius"] = 100,
        ["Mass"] = 10000,
    }),
}

GameState.CurrentTime = 0
GameState.LastUpdateTime = 0
GameState.FrameTimeDiff = 0
GameState.TimeSpeed = 0

GameState.System = {}

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
        ["Unknown"] = 0,
    }
    GameState.System:forEach(function(ship)
        ship_count[ship.Team.Name] = ship_count[ship.Team.Name]+1
    end, "Ship")

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
        ba.println("Adding: " .. Inspect(ship.Name))

        if ship.Name == "Abraxis" then
            GameState.System:get("Tethys"):add(ship:copy())
        elseif ship.Name == "Alhazred" then
            GameState.System:get("Tethys"):add(ship:copy())
        else
            GameMapGenerator.addShipToRandomOrbit(ship:copy(), GameState.System:get("Sol"))
        end
    end

    ba.println("Template table: " .. Inspect(new_game_ships))
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

function GameState.removeShip(ship)
    if type(ship) == 'string' then
        ship = GameState.System:get(ship)
    end

    GameMission.Ships:remove(ship.Name)  -- Remove from mission ships
    ship.Parent:remove(ship) -- Remove from system or group
end

return GameState