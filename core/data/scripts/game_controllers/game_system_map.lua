local Class           = require("class")
local Dialogs         = require('dialogs')
local Inspect         = require('inspect')
local KDTree          = require('kdtree')
local Ship            = require('ship')
local ShipGroup       = require('ship_group')
local SystemFile      = require('system_file')
local Utils           = require('utils')
local Vector          = require('vector')

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil;

GameSystemMap.System = SystemFile:loadSystem('sol.json.cfg')

GameSystemMap.CurrentTime = 0
GameSystemMap.TimeSpeed = 0

ba.println("loadSystem: " .. Inspect({ GameSystemMap.System }))

GameSystemMap.Camera = {
    ["Parent"]  = nil,
    ["Movement"]  = Vector(),
    ["Position"] = Vector(731316619172.03, -266842595861.88, 0),
    ["RelPosition"] = Vector(731316619172.03, -266842595861.88, 0),
    ["TargetRelPosition"] = nil,
    ["TargetMoveTime"] = time.getCurrentTime(),
    ["TargetMoveSpeed"] = 3.0,
    ["Zoom"] = 1.0,
    ["StartZoom"] = 1.0,
    ["TargetZoom"] = 1.0,
    ["ZoomSpeed"] = 1.0,
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
    self.Parent = GameSystemMap.System.Stars[1]
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
        local target_move_progress = 1.0 + math.min(((time.getCurrentTime()-self.TargetMoveTime):getSeconds() - self.TargetMoveSpeed) / self.TargetMoveSpeed, 0.0)
        --ba.println("GameSystemMap.Camera:target_move_progress: " .. Inspect({ (time.getCurrentTime() - self.TargetMoveTime):getSeconds(), target_move_progress }))
        self.RelPosition.x = Utils.Math.lerp(self.RelPosition.x, self.TargetRelPosition.x, target_move_progress)
        self.RelPosition.y = Utils.Math.lerp(self.RelPosition.y, self.TargetRelPosition.y, target_move_progress)
    end

    self.RelPosition = self.RelPosition + self.Movement
    self.Position = self.Parent.System.Position + self.RelPosition

    --a parabolic zoom progression seems to look more smooth than a linear one
    local zoom_progress = 1.0 - math.pow(math.min(((time.getCurrentTime()-self.TargetZoomTime):getSeconds() - self.ZoomSpeed) / self.ZoomSpeed, 0.0), 2.0)
    --ba.println("GameSystemMap.Camera:zoomUpdate: " .. Inspect({ (time.getCurrentTime() - start_zoom):getSeconds(), self.Zoom, self.TargetZoom, (self.TargetZoomTime - start_zoom):getSeconds(), zoom_progress }))
    self.Zoom = Utils.Math.lerp(self.StartZoom, self.TargetZoom, zoom_progress)
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
    self.CurrentTime = self.CurrentTime + (time.getCurrentTime() - last_update_time):getSeconds() * self.TimeSpeed
    last_update_time = time.getCurrentTime()

    self.System:update()
    GameSystemMap.Camera:update()
    self.ObjectKDTree:initFrame()

    for _, star in pairs(self.System.Stars) do
        add_system_object_to_tree(star)
    end

    GameState.Ships:forEach(function(curr_ship)
        self.ObjectKDTree:addObject(curr_ship.System.Position, curr_ship)
    end)
end

function GameSystemMap.isShipEncounter(ship1, ship2)
    local dist = ship2.System.Position - ship1.System.Position

    return dist:getMagnitude() < 100000;
end

function GameSystemMap:onLeftClick(mouse)
    local world_pos = self.Camera:getWorldCoords(mouse)
    local nearest = self.ObjectKDTree:findNearest(world_pos, 40 * self.Camera.Zoom)
    ba.println("GameSystemMap:onLeftClick: " .. Inspect({mouse.x, mouse.y, world_pos.x, world_pos.y, nearest and nearest[1] and nearest[1].Name }))
    if not nearest or not nearest[1] then
        return
    end

    if nearest[1]:is_a(Ship) or nearest[1]:is_a(ShipGroup) then
        if self.SelectedShip ~= nil then
            self.SelectedShip.IsSelected = false
            self.SelectedShip = nil
        end

        self.SelectedShip = nearest[1]
        self.SelectedShip.IsSelected = true
        ba.println("Selected ship: " .. self.SelectedShip.Name)
    else
        self.Camera.Parent = nearest[1]
        while self.Camera.Parent.Parent and (self.Camera.Parent.System.Position - self.Camera.Parent.Parent.System.Position):getSqrMagnitude() < math.pow(40 * self.Camera.Zoom, 2) do
            self.Camera.Parent = self.Camera.Parent.Parent
        end

        self.Camera.RelPosition = self.Camera.Position - nearest[1].System.Position
        self.Camera.TargetRelPosition = Vector(0,0)
        self.Camera.TargetMoveTime = time.getCurrentTime()
    end
end

function GameSystemMap:moveShip(mouse)
    if self.SelectedShip ~= nil then
        if self.SelectedShip.Team.Name == 'Friendly' then
            local world_pos = self.Camera:getWorldCoords(mouse)
            local nearest = self.ObjectKDTree:findNearest(world_pos, 40 * self.Camera.Zoom)
            if nearest then
                self.SelectedShip.System.Position = nearest[1].System.Position:copy()
            else
                self.SelectedShip.System.Position = world_pos
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