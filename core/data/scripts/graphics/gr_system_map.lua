local gr_common                          = require('gr_common')
local Inspect                            = require('inspect')
local Ship                               = require('ship')
local ShipGroup                          = require('ship_group')
local Utils                              = require('utils')
local Vector                             = require('vector')

local gr_system_map = {}

local function drawTexture(texture, text, screen_position, width, height)
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

local function drawOrbit(body, body_screen_position_diff, screen_size)
    local alpha = 255

    if body.Parent then
        local parent_screen_position = GameSystemMap.Camera:getScreenCoords(body.Parent.System.Position)
        local screen_position_diff = (parent_screen_position - body_screen_position_diff):getMagnitude()
        alpha = math.min(screen_position_diff / 30, 1.0)
        alpha = 1.0 - (1.0 - alpha)*2
        alpha = math.max(255 * math.min(screen_size, 10) / 10, 128) * alpha

        if screen_position_diff < 20000 then
            if screen_position_diff < 4 then
                return 0
            end

            local r,g,b = gr.getColor()
            local orbit_alpha = Utils.Math.lerp(128, 0, math.max((screen_position_diff - 10000) / 10000, 0.0))
            --ba.println("gr_system:drawAstral: " .. Inspect({body.Name, orbit_alpha, screen_position_diff}))
            gr.setColor(r, g, b, orbit_alpha)
            gr.drawCircle(screen_position_diff, parent_screen_position.x, parent_screen_position.y, false)
        end
    end

    return alpha
end

local function drawAstralHandler(_, object, _, _, _)
    --ba.println("gr_system_map.drawSystem(system): " .. Inspect(system.Stars))
    local screen_position = GameSystemMap.Camera:getScreenCoords(object.System.Position)
    local screen_size = object.Radius / GameSystemMap.Camera.Zoom * 2

    gr.setColor(255, 255, 255)
    local alpha = drawOrbit(object, screen_position, screen_size)

    if alpha > 0 and GameSystemMap.Camera:isOnScreen(screen_position, 2000) then
        gr.setColor(255, 255, 255, alpha)
        gr.CurrentFont = gr.Fonts["font01"]
        screen_size = math.max(screen_size, 10)
        drawTexture(object:getIcon().Texture, object.Name, screen_position, screen_size, screen_size)
    end
end

local function drawShipHandler(obj_idx, object, obj_count, screen_position, rel_screen_position)
    local icon = object:getIcon()
    local icon_width, icon_height = icon.Width, icon.Height
    local text = object:getMapDisplayName()

    if obj_count > 1 then
        --TODO: different text for different object types?
        text =  obj_count .. " ships"
        if obj_idx > 1 then
            text = ""
            rel_screen_position:rotate(0, math.rad(360 / obj_count), 0)
        end

        icon_width, icon_height = icon_width/4, icon_height/4
        screen_position = screen_position + rel_screen_position
    end

    --ba.println("ships_screen_map:drawCluster: " .. Inspect({rel_screen_position, screen_position}))
    local r,g,b = object.Team:getColor()
    if object.IsSelected then
        r,g,b = gr_common.TeamSelectedColors[object.Team.Name]()
    end

    gr.setColor(r,g,b)
    if obj_idx == 1 then
        drawOrbit(object, screen_position, icon_width)
        gr.setColor(r,g,b) -- reset color in case the orbit was half-transparent
    end

    --ba.println("ships_screen_map:draw: " .. Inspect({ship.Name, GameSystemMap.Camera.ScreenOffset.x, GameSystemMap.Camera.ScreenOffset.y, screen_position.x, screen_position.y, screen_sector.x, screen_sector.y}))
    drawTexture(icon.Texture, text, screen_position, icon_width, icon_height)

    if object.System.Destination then
        if object.System.Destination.Subspace then
            gr.setLineWidth(4)
            gr.setColor(r,128,255)
        end

        local screen_position_dest = GameSystemMap.Camera:getScreenCoords(object.System.Destination.Position + object.System.Destination.Parent.System.Position)
        gr.drawLine(screen_position.x, screen_position.y, screen_position_dest.x, screen_position_dest.y)
        gr.drawCircle(5, screen_position_dest.x, screen_position_dest.y, true)
        gr.setLineWidth(1)
    end
end

local drawHandler
local drawHandlers = {
    ["Astral"] = drawAstralHandler,
    ["Ship"] = drawShipHandler,
}

function gr_system_map:drawCluster(cluster)
    for group_name, object_group in pairs(cluster.Groups) do
        table.sort(object_group.Objects, function (o1, o2) return o1.Name < o2.Name end )
        local rel_screen_position = Vector(0, -15)
        local screen_position = GameSystemMap.Camera:getScreenCoords(object_group.AvgPosition)
        for obj_idx, object in ipairs(object_group.Objects) do
            drawHandler = drawHandlers[group_name] and drawHandlers[group_name] or drawAstralHandler
            --ba.println("ships_screen_map:drawMap clusterShip: " .. Inspect({group_name, obj_idx, object.Name, screen_position.x, screen_position.y, cluster.AvgPosition.x, cluster.AvgPosition.y}))
            drawHandler(obj_idx, object, #object_group.Objects, screen_position, rel_screen_position)
        end
    end
end

function gr_system_map.drawMap(mousePos, subspace, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

    if GameSystemMap.SelectedShip and GameSystemMap.SelectedShip.Team.Name == 'Friendly' then
        local r,g,b,a = gr_common.TeamSelectedColors[GameSystemMap.SelectedShip.Team.Name]()
        g = subspace and 128 or 255
        gr.setColor(r,g,b,a)

        if GameSystemMap.ShipMoveDummy.Parent then
            local dummy_orbit_pos = GameSystemMap.Camera:getScreenCoords(GameSystemMap.ShipMoveDummy.Parent.System.Position)
            gr.drawCircle(GameSystemMap.ShipMoveDummy.SemiMajorAxis / GameSystemMap.Camera.Zoom, dummy_orbit_pos.x, dummy_orbit_pos.y, false)
            gr.drawCircle(5, mousePos.x, mousePos.y, true)
        end

        local screen_position = GameSystemMap.Camera:getScreenCoords(GameSystemMap.SelectedShip.System.Position)
        if not GameSystemMap.Camera:isOnScreen(screen_position) then
            screen_position = screen_position - mousePos
            screen_position = screen_position:normalize() * 2000
            screen_position = screen_position + mousePos
        end

        gr.setLineWidth(subspace and 4 or 1)
        gr.drawLine(screen_position.x, screen_position.y, mousePos.x, mousePos.y)
        gr.setLineWidth(1)
    end

    local screen_objects = GameSystemMap.ObjectKDTree:findObjectsWithin(
            GameSystemMap.Camera.Position,
            2000 * GameSystemMap.Camera.Zoom,
            40 * GameSystemMap.Camera.Zoom,
            nil,
            'Category'
    )

    for cidx, cluster in ipairs(screen_objects) do
        --ba.println("ships_screen_map:drawMap cluster: " .. Inspect({cidx, #cluster.Objects.All, cluster.Objects.All[1].Name}))
        gr_system_map:drawCluster(cluster)
    end

    --GameSystemMap.ObjectKDTree:draw() -- TODO: for debugging, do not commit uncommented
    gr.setTarget()
end

return gr_system_map
