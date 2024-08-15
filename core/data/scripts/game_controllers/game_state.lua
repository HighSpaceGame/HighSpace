local Class      = require("class")
local Dialogs    = require('dialogs')
local Inspect    = require('inspect')
local SystemFile = require('system_file')

GameState = Class()


GameState.CurrentTime = 0
GameState.LastUpdateTime = 0
GameState.FrameTimeDiff = 0
GameState.TimeSpeed = 0

GameState.System = {}

GameState.MissionLoaded = false

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
    GameState.System:remove(ship) -- Remove from system or group
end

return GameState