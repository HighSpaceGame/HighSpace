local GrCommon = {}

local loadTexture = function(filename, link)
    local texInfo = { ["Texture"] = gr.loadTexture(filename, true, true) }
    texInfo.Height = texInfo.Texture:getHeight()
    texInfo.Width  = texInfo.Texture:getWidth()

    if link then
        texInfo.Url    = ui.linkTexture(texInfo.Texture)
    end

    return texInfo
end

GrCommon.IconMap = {
    ["Terran"] = {
        ["Fighter"] = loadTexture("iconT-fighter", true),
        ["Bomber"] = loadTexture("icont-bomber", true),
        ["Cruiser"] = loadTexture("icont-cruiser", true),
        ["Corvette"] = loadTexture("iconT-vette", true),
        ["Capital"] = loadTexture("icont-cap", true),
        ["Super Cap"] = loadTexture("icont-super", true),
        ["Transport"] = loadTexture("icont-transport", true),
    },
    ["Vasudan"] = {
        ["Fighter"] = loadTexture("iconV-fighter", true),
        ["Bomber"] = loadTexture("iconv-bomber", true),
        ["Cruiser"] = loadTexture("iconv-cruiser", true),
        ["Corvette"] = loadTexture("iconV-vette", true),
        ["Capital"] = loadTexture("iconv-cap", true),
        ["Transport"] = loadTexture("iconv-transport", true),
    },
    ["Shivan"] = {
        ["Fighter"] = loadTexture("iconS-fighter", true),
        ["Bomber"] = loadTexture("icons-bomber", true),
        ["Cruiser"] = loadTexture("icons-cruiser", true),
        ["Corvette"] = loadTexture("iconS-vette", true),
        ["Capital"] = loadTexture("icons-cap", true),
        ["Super Cap"] = loadTexture("icons-super", true),
        ["Transport"] = loadTexture("icons-transport", true),
    },
}

GrCommon.WaypointIcon = loadTexture("waypoint", true)
GrCommon.TargetIcon =  loadTexture("target", true)

GrCommon.TeamSelectedColors = {
    ["Friendly"] = {["R"] = 0, ["G"] = 255, ["B"] = 255},
    ["Hostile"] = {["R"] = 255, ["G"] = 255, ["B"] = 0},
}

function GrCommon.getIconForShip(ship)
    if GrCommon.IconMap[ship.Species] and GrCommon.IconMap[ship.Species][ship.Type] then
        return GrCommon.IconMap[ship.Species][ship.Type]
    end

    ba.println("ICON NOT FOUND: " .. ship.Species .. " " .. ship.Type)
    return nil
end

return GrCommon