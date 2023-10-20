local Class           = require("class")
local Dialogs         = require('dialogs')
local Inspect         = require('inspect')
local KDTree          = require('kdtree')
local Ship            = require('ship')
local ShipGroup       = require('ship_group')
local Utils           = require('utils')
local Vector          = require('vector')

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil;

ba.println("loadSystem: " .. Inspect({ GameState.System }))

GameSystemMap.Camera = {
    ["Parent"]  = nil,
    ["Movement"]  = Vector(),
    ["Position"] = Vector(),
    ["RelPosition"] = Vector(),
    ["TargetRelPosition"] = nil,
    ["TargetMoveTime"] = time.getCurrentTime(),
    ["TargetMoveSpeed"] = 3.0,
    ["Zoom"] = 1.0,
    ["StartZoom"] = 1.0,
    ["TargetZoom"] = 1.0,
    ["ZoomSpeed"] = 3.0,
    ["ZoomExp"] = 9,
    ["TargetZoomTime"] = time.getCurrentTime(),
    ["LastZoomDirection"] = 0,
    ["ScreenOffset"] = {}
}

function GameSystemMap.Camera:init(width, height)
    self.ScreenOffset = Vector(width, height) / 2
    self.Zoom = 1000.0 * math.exp(self.ZoomExp)
    self.StartZoom = self.Zoom
    self.TargetZoom = self.Zoom
    self.Parent = GameState.System:get("Sol")
end

function GameSystemMap.Camera:getScreenCoords(position)
    local screen_pos = (position - self.Position) / self.Zoom
    screen_pos.y = -screen_pos.y

    return screen_pos + self.ScreenOffset
end

function GameSystemMap.Camera:isOnScreen(position, margin)
    margin = margin or 0
    return (position.x + margin > 0 and position.y + margin > 0 and position.x - margin < self.ScreenOffset.x*2 and position.y - margin < self.ScreenOffset.y*2)
end

function GameSystemMap.Camera:getWorldCoords(screen_pos)
    local world_pos = screen_pos - self.ScreenOffset
    world_pos.y = -world_pos.y
    world_pos = world_pos * self.Zoom + self.Position

    return world_pos
end

function GameSystemMap.Camera:setMovement(camera_movement)
    self.Movement = camera_movement * self.Zoom * 4
    ba.println("GameSystemMap.Camera:setMovement: " .. Inspect({ ["x"] = camera_movement.x, ["y"] = camera_movement.y}))
end

function GameSystemMap.Camera:zoom(direction)
    local current_time = time.getCurrentTime()
    self.TargetZoom = self.Zoom

    if self.LastZoomDirection == direction or (current_time - self.TargetZoomTime):getSeconds() > self.ZoomSpeed then
        self.ZoomExp = math.min(math.max(self.ZoomExp + direction*0.5, 0), 21.0)
        self.TargetZoomTime = current_time
        self.TargetZoom = 1000.0 * math.exp(self.ZoomExp)
    end

    self.StartZoom = self.Zoom
    self.LastZoomDirection = direction

    --ba.println("Zoom: " .. Inspect({(current_time - start_zoom):getSeconds(), (self.TargetZoomTime - start_zoom):getSeconds(), self.TargetZoom, self.ZoomExp}))
end

function GameSystemMap.Camera:update()
    if self.Movement.x ~= 0 or self.Movement.y ~= 0 then
        self.TargetRelPosition = nil
    end

    if self.TargetRelPosition then
        local target_move_progress = math.min((time.getCurrentTime()-self.TargetMoveTime):getSeconds() / self.TargetMoveSpeed, 1.0)
        --ba.println("GameSystemMap.Camera:target_move_progress: " .. Inspect({ (time.getCurrentTime() - self.TargetMoveTime):getSeconds(), target_move_progress }))
        self.RelPosition.x = Utils.Math.lerp(self.RelPosition.x, self.TargetRelPosition.x, target_move_progress)
        self.RelPosition.y = Utils.Math.lerp(self.RelPosition.y, self.TargetRelPosition.y, target_move_progress)
    end

    self.RelPosition = self.RelPosition + self.Movement
    self.Position = self.Parent.System.Position + self.RelPosition

    --a parabolic zoom progression seems to look more smooth than a linear one
    local zoom_progress = math.min((time.getCurrentTime()-self.TargetZoomTime):getSeconds() / self.ZoomSpeed, 1.0)
    --ba.println("GameSystemMap.Camera:zoomUpdate: " .. Inspect({ (time.getCurrentTime() - self.TargetZoomTime):getSeconds(), self.Zoom, self.TargetZoom, zoom_progress }))
    self.Zoom = Utils.Math.lerp(self.Zoom, self.TargetZoom, zoom_progress)
end

GameSystemMap.ObjectKDTree = KDTree()

local function add_system_object_to_tree(body)
    GameSystemMap.ObjectKDTree:addObject(body.System.Position, body)

    if not body.Satellites then
        return
    end

    for _, satellite in pairs(body.Satellites) do
        add_system_object_to_tree(satellite)
    end
end

local last_update_time = time.getCurrentTime()
function GameSystemMap:update()
    --ba.println("update: " .. Inspect({ os.clock(), os.time(), (time.getCurrentTime() - start):getSeconds(), tonumber(time.getCurrentTime()) }))
    GameState.CurrentTime = GameState.CurrentTime + (time.getCurrentTime() - last_update_time):getSeconds() * GameState.TimeSpeed
    last_update_time = time.getCurrentTime()

    GameState.System:update()
    GameSystemMap.Camera:update()
    self.ObjectKDTree:initFrame()

    for _, star in pairs(GameState.System.Stars) do
        add_system_object_to_tree(star)
    end
end

function GameSystemMap.isShipEncounter(ship1, ship2)
    local dist = ship2.System.Position - ship1.System.Position

    return dist:getMagnitude() < 100000;
end

local function leftClickAstralHandler(object)
    GameSystemMap.Camera.Parent = object
    while GameSystemMap.Camera.Parent.Parent and (GameSystemMap.Camera.Parent.System.Position - GameSystemMap.Camera.Parent.Parent.System.Position):getSqrMagnitude() < math.pow(40 * GameSystemMap.Camera.Zoom, 2) do
        GameSystemMap.Camera.Parent = GameSystemMap.Camera.Parent.Parent
    end

    GameSystemMap.Camera.RelPosition = GameSystemMap.Camera.Position - object.System.Position
    GameSystemMap.Camera.TargetRelPosition = Vector(0,0)
    GameSystemMap.Camera.TargetMoveTime = time.getCurrentTime()
end

local function leftClickShipHandler(object)
    GameSystemMap.SelectedShip = object
    GameSystemMap.SelectedShip.IsSelected = true
    ba.println("Selected ship: " .. GameSystemMap.SelectedShip.Name)
end

local leftClickHandler
local leftClickHandlers = {
    ["Astral"] = leftClickAstralHandler,
    ["Ship"] = leftClickShipHandler,
}

function GameSystemMap:onLeftClick(mouse)
    local world_pos = self.Camera:getWorldCoords(mouse)
    local nearest = self.ObjectKDTree:findNearest(world_pos, 40 * self.Camera.Zoom)
    ba.println("GameSystemMap:onLeftClick: " .. Inspect({mouse.x, mouse.y, world_pos.x, world_pos.y, nearest and nearest[1] and nearest[1].Name }))

    if self.SelectedShip and (not nearest or not nearest[1] or nearest[1].Category == "Ship") then
        self.SelectedShip.IsSelected = false
        self.SelectedShip = nil
    end

    if not nearest or not nearest[1] then
        return
    end

    leftClickHandler = leftClickHandlers[nearest[1].Category] and leftClickHandlers[nearest[1].Category] or leftClickAstralHandler
    leftClickHandler(nearest[1])
end

function GameSystemMap:moveShip(mouse)
    if self.SelectedShip ~= nil then
        if self.SelectedShip.Team.Name == 'Friendly' then
            local world_pos = self.Camera:getWorldCoords(mouse)
            local nearest = self.ObjectKDTree:findNearest(world_pos, 40 * self.Camera.Zoom,
                    function(objects) return objects and objects[1].Category == 'Ship' end
            )
            if nearest then
                self.SelectedShip.System.Destination = nearest[1].System.Position:copy()
            else
                self.SelectedShip.System.Destination = world_pos
            end
        end

        self.SelectedShip.IsSelected = false
        self.SelectedShip = nil
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
                    if not GameState.MissionLoaded and GameSystemMap.isShipEncounter(ship1, ship2) then
                        GameMission:setupMission(ship1, ship2)
                    end
                end
            end)
        end
    end)
end

return GameSystemMap