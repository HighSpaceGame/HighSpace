local Class     = require("class")
local Dialogs   = require('dialogs')
local Inspect   = require('inspect')
local Utils     = require('utils')
local Vector     = require('vector')

GameSystemMap = Class()

GameSystemMap.SelectedShip = nil;

GameSystemMap.System = {
    ["Stars"] = {
        ["1"] = {
            ["Name"] = "Sol",
            ["SemiMajorAxis"] = "0",
            ["OrbitalPeriod"] = "0",
            ["Mass"] = "1.9891e+30",
            ["MeanAnomalyEpoch"] = "0",
            ["Radius"] = "696342000",
            ["Texture"] = gr.loadTexture("iconnode", true),
            ["Satellites"] = {
                ["1"] = {
                    ["Name"] = "Jupiter",
                    ["SemiMajorAxis"] = "5.204267",
                    ["OrbitalPeriod"] = "4332.59",
                    ["Radius"] = "71492000",
                    ["Mass"] = "1.898e+27",
                    ["MeanAnomalyEpoch"] = "20.05983908",
                    ["Epoch"] = "2000-01-01T12:00:00",
                    ["Texture"] = gr.loadTexture("iconplanet", true),
                    ["Satellites"] = {
                        ["1"] = {
                            ["Name"] = "Io",
                            ["SemiMajorAxis"] = "0.00281955885",
                            ["OrbitalPeriod"] = "1.769138",
                            ["Mass"] = "893.2e+20",
                            ["MeanAnomalyEpoch"] = "342.021",
                            ["Epoch"] = "2000-01-01T12:00:00",
                            ["Radius"] = "1821600",
                            ["Texture"] = gr.loadTexture("iconplanet", true),
                        },
                        ["2"] = {
                            ["Name"] = "Europa",
                            ["SemiMajorAxis"] = "0.00448602642",
                            ["OrbitalPeriod"] = "3.551181",
                            ["Mass"] = "480e+20",
                            ["MeanAnomalyEpoch"] = "171.016",
                            ["Epoch"] = "2000-01-01T12:00:00",
                            ["Radius"] = "1821600",
                            ["Texture"] = gr.loadTexture("iconplanet", true),
                        },
                        ["3"] = {
                            ["Name"] = "Ganymede",
                            ["SemiMajorAxis"] = "0.00715518206",
                            ["OrbitalPeriod"] = "7.154553",
                            ["Mass"] = "1481.9e+20",
                            ["MeanAnomalyEpoch"] = "317.540",
                            ["Epoch"] = "2000-01-01T12:00:00",
                            ["Radius"] = "2631200",
                            ["Texture"] = gr.loadTexture("iconplanet", true),
                        },
                        ["4"] = {
                            ["Name"] = "Callisto",
                            ["SemiMajorAxis"] = "0.0125850722",
                            ["OrbitalPeriod"] = "16.689018",
                            ["Mass"] = "1075.9e+20",
                            ["MeanAnomalyEpoch"] = "181.408",
                            ["Epoch"] = "2000-01-01T12:00:00",
                            ["Radius"] = "2410300",
                            ["Texture"] = gr.loadTexture("iconplanet", true),
                        }
                    }
                }
            }
        }
    }
}

GameSystemMap.Camera = {
    ["Parent"]  = nil,
    ["Movement"]  = Vector(),
    ["Position"] = Vector(),
    ["Zoom"] = 1000.0,
    ["StartZoom"] = 1000.0,
    ["TargetZoom"] = 1000.0,
    ["ZoomSpeed"] = 0.10,
    ["ZoomExp"] = 1,
    ["TargetZoomTime"] = os.clock(),
    ["LastZoomDirection"] = 0,
    ["ScreenOffset"] = {}
}

function GameSystemMap.Camera:init(width, height)
    self.ScreenOffset = ba.createVector(width, height, 0) / 2
end

function GameSystemMap.Camera:getScreenCoords(position)
    local screen_pos = (position - self.Position) / self.Zoom
    screen_pos.y = -screen_pos.y

    return screen_pos + self.ScreenOffset
end

function GameSystemMap.Camera:getWorldCoords(screen_pos)
    local world_pos = screen_pos - self.ScreenOffset
    world_pos.y = -world_pos.y
    world_pos = world_pos * self.Zoom + self.Position

    return world_pos
end

function GameSystemMap.Camera:setMovement(camera_movement)
    self.Movement = camera_movement * self.Zoom * 4
    ba.println("GameSystemMap.Camera:setMovement: " .. Inspect({ ["X"] = camera_movement.x, ["Y"] = camera_movement.y}))
end

function GameSystemMap.Camera:zoom(direction)
    local current_time = os.clock()
    self.TargetZoom = self.Zoom

    if self.LastZoomDirection == direction or current_time > self.TargetZoomTime then
        self.ZoomExp = math.max(self.ZoomExp + direction*0.5, 0)
        self.TargetZoomTime = current_time + self.ZoomSpeed
        self.TargetZoom = 1000.0 * math.exp(self.ZoomExp)
    end

    self.StartZoom = self.Zoom
    self.LastZoomDirection = direction

    ba.println("Zoom: " .. Inspect({current_time, self.TargetZoomTime, self.TargetZoom, self.ZoomExp}))
end

function GameSystemMap.Camera:update()
    self.Position = self.Position + self.Movement

    --a parabolic zoom progression seems to look more smooth than a linear one
    local zoom_progress = 1.0 - math.pow(math.min((os.clock()-self.TargetZoomTime) / self.ZoomSpeed, 0.0), 2.0)
    --ba.println("GameSystemMap.Camera:zoomUpdate: " .. Inspect({ os.date(), self.Zoom, self.TargetZoom, os.clock(), self.TargetZoomTime, zoom_progress }))
    self.Zoom = Utils.Math.lerp(self.StartZoom, self.TargetZoom, zoom_progress)
end

function GameSystemMap:isOverShip(ship, x, y)
    local dist = self.Camera:getScreenCoords(ship.System.Position) - ba.createVector(x, y, 0)

    return dist:getMagnitude() < 40;
end

function GameSystemMap.isShipEncounter(ship1, ship2)
    local dist = ship2.System.Position - ship1.System.Position

    return dist:getMagnitude() < 40;
end

function GameSystemMap:selectShip(mouseX, mouseY)
    if GameSystemMap.SelectedShip ~= nil then
        GameState.Ships:get(GameSystemMap.SelectedShip).IsSelected = false
        GameSystemMap.SelectedShip = nil
    end

    GameState.Ships:forEach(function(ship)
        if GameSystemMap:isOverShip(ship, mouseX, mouseY) then
            GameSystemMap.SelectedShip = ship.Name
            ship.IsSelected = true
            ba.println("Selected ship: " .. ship.Name)
            return
        end
    end)
end

function GameSystemMap:moveShip(mouseX, mouseY)
    if self.SelectedShip ~= nil then
        local ship = GameState.Ships:get(GameSystemMap.SelectedShip)
        if ship.Team.Name == 'Friendly' then
            ship.System.Position = self.Camera:getWorldCoords(ba.createVector(mouseX, mouseY))
        end

        ship.IsSelected = false
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