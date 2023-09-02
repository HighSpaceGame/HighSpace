local gr_common                          = require('gr_common')
local Inspect                            = require('inspect')
local Utils                              = require('utils')
local Vector                             = require('vector')

local gr_system_map = {}

local drawTexture = function(texture, text, screen_position, width, height)
    --ba.println("gr_system_map.drawTexture(texture, world_position): " .. Inspect({ screen_position.x, screen_position.y }))
    gr.drawImageCentered(texture, screen_position.x, screen_position.y, width, height, 0, 0, 1, 1, 1, true)

    if text then
        local text_width = gr.getStringWidth(text)
        gr.drawString(
                text,
                screen_position.x - text_width/2,
                screen_position.y - height - gr.CurrentFont.Height - 12
        )
    end
end

function gr_system_map.drawSystem(body, parent)
    --ba.println("gr_system_map.drawSystem(system): " .. Inspect(system.Stars))
    local world_position = Vector()

    if parent then
        world_position.x = 1
        world_position = world_position * body.SemiMajorAxis * 149597870700.0
        world_position = world_position:rotate(0, math.rad(body.MeanAnomalyEpoch), 0) + parent.WorldPosition
    end

    body.WorldPosition = world_position

    local screen_size = body.Radius / GameSystemMap.Camera.Zoom * 2
    local screen_position = GameSystemMap.Camera:getScreenCoords(world_position)
    local alpha = 255

    if parent then
        local parent_screen_position = GameSystemMap.Camera:getScreenCoords(parent.WorldPosition)
        local screen_position_diff = (parent_screen_position - screen_position):getMagnitude()
        alpha = math.min(screen_position_diff / 30, 1.0)
        alpha = 1.0 - (1.0 - alpha)*2
        alpha = math.max(255 * math.min(screen_size, 10) / 10, 128) * alpha

        if screen_position_diff < 20000 then
            if screen_position_diff < 4 then
                return
            end

            local orbit_alpha = Utils.Math.lerp(128, 0, math.max((screen_position_diff - 10000) / 10000, 0.0))
            gr.setColor(255, 255, 255, orbit_alpha)
            gr.drawCircle(screen_position_diff, parent_screen_position.x, parent_screen_position.y, false)
        end
    end

    gr.setColor(255, 255, 255, alpha)
    gr.CurrentFont = gr.Fonts["font01"]
    screen_size = math.max(screen_size, 10)
    drawTexture(body.Texture, body.Name, screen_position, screen_size, screen_size)

    if not body.Satellites then
        return
    end

    for _, satellite in pairs(body.Satellites) do
        gr_system_map.drawSystem(satellite, body)
    end
end

local ships_screen_map = {
    ["Sectors"] = {},
}

function ships_screen_map:addShip(ship)
    local screen_position = GameSystemMap.Camera:getScreenCoords(ship.System.Position)

    if not GameSystemMap.Camera:isOnScreen(screen_position) then
        return
    end

    local screen_sector = GameSystemMap.Camera.ScreenOffset / 5
    local min_dist = math.min(screen_sector.x, screen_sector.y)
    screen_sector.x, screen_sector.y = screen_position.x / min_dist + 1.5, screen_position.y / min_dist + 1.5
    screen_sector:floor()
    --ba.println("ships_screen_map:addToCurrentFrame: " .. Inspect({screen_sector}))

    local x, y = screen_sector.x, screen_sector.y
    for dx = screen_sector.x-1, screen_sector.x+1 do
        for dy = screen_sector.y-1, screen_sector.y+1 do
            local sector = dx > 0 and dy > 0 and self.Sectors[dx] and self.Sectors[dx][dy] or nil
            if sector then
                local dist = (screen_position - sector.AvgScreenPosition):getMagnitude()
                if dist < min_dist then
                    min_dist = dist
                    x, y = dx, dy
                end
            end
        end
    end

    --ba.println("gr_system_map.addToCurrentFrame: " .. Inspect({ship.Name, x, y, x, y}))

    self.Sectors[x] = self.Sectors[x] and self.Sectors[x] or {}
    self.Sectors[x][y] = self.Sectors[x][y] and self.Sectors[x][y] or {["Ships"] = {}}
    local sector = self.Sectors[x][y]

    table.insert(sector["Ships"], ship)
    local avg_pos = Vector(0,0)
    for _, iship in ipairs(sector["Ships"]) do
        avg_pos = avg_pos + iship.System.Position
    end

    sector["AvgScreenPosition"] = GameSystemMap.Camera:getScreenCoords(avg_pos / #sector["Ships"])
end

function ships_screen_map:draw()
    for _, x_frame in pairs(self.Sectors) do
        for _, xy_frame in pairs(x_frame) do
            local rel_screen_position = Vector(0, -15)
            for ship_idx, ship in ipairs(xy_frame.Ships) do
                local icon = gr_common.getIconForShip(ship)
                if icon then
                    local icon_width, icon_height = icon.Width, icon.Height
                    local text = ship:getMapDisplayName()
                    local screen_position = xy_frame.AvgScreenPosition

                    if #xy_frame.Ships > 1 then
                        text =  #xy_frame.Ships .. " ships"
                        if ship_idx > 1 then
                            text = ""
                            rel_screen_position:rotate(0, math.rad(360 / #xy_frame.Ships), 0)
                        end

                        icon_width, icon_height = icon.Width/4, icon.Height/4
                        screen_position = screen_position + rel_screen_position
                    end

                    --ba.println("ships_screen_map:draw ship: " .. Inspect({rel_screen_position, screen_position}))
                    gr.setColor(ship.Team:getColor())
                    if ship.IsSelected then
                        local selected_color = gr_common.TeamSelectedColors[ship.Team.Name]
                        gr.setColor(selected_color.R, selected_color.G, selected_color.B)
                    end

                    --ba.println("ships_screen_map:draw: " .. Inspect({ship.Name, GameSystemMap.Camera.ScreenOffset.x, GameSystemMap.Camera.ScreenOffset.y, screen_position.x, screen_position.y, screen_sector.x, screen_sector.y}))
                    drawTexture(icon.Texture, text, screen_position, icon_width, icon_height)
                end
            end
        end
    end

    self.Sectors = {}
end

function gr_system_map.drawMap(mousePos, ships, system, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

    for _, star in pairs(system.Stars) do
        gr_system_map.drawSystem(star)
    end

    ships:forEach(function(curr_ship)
        ships_screen_map:addShip(curr_ship)

        if curr_ship.IsSelected and curr_ship.Team.Name == 'Friendly' then
            local screen_position = GameSystemMap.Camera:getScreenCoords(curr_ship.System.Position)
            local color = gr_common.TeamSelectedColors[curr_ship.Team.Name]

            if not GameSystemMap.Camera:isOnScreen(screen_position) then
                screen_position = screen_position - mousePos
                screen_position = screen_position:normalize() * 2000
                screen_position = screen_position + mousePos
            end

            gr.setColor(color.R, color.G, color.B)
            gr.drawLine(screen_position.x, screen_position.y, mousePos.x, mousePos.y)
        end
    end)

    ships_screen_map:draw(mouseX, mouseY)
    gr.setTarget()
end

return gr_system_map
