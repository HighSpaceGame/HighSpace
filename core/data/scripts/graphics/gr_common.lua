local GrCommon = {}

GrCommon.IconMap = {
    ["Terran"] = {
        ["Fighter"] = {["Texture"] = gr.loadTexture("iconT-fighter", true, true),},
        ["Bomber"] = {["Texture"] = gr.loadTexture("icont-bomber", true, true),},
        ["Cruiser"] = {["Texture"] = gr.loadTexture("icont-cruiser", true, true),},
        ["Corvette"] = {["Texture"] = gr.loadTexture("iconT-vette", true, true),},
        ["Capital"] = {["Texture"] = gr.loadTexture("icont-cap", true, true),},
        ["Super Cap"] = {["Texture"] = gr.loadTexture("icont-super", true, true),},
        ["Transport"] = {["Texture"] = gr.loadTexture("icont-transport", true, true),},
    },
    ["Vasudan"] = {
        ["Fighter"] = {["Texture"] = gr.loadTexture("iconV-fighter", true, true),},
        ["Bomber"] = {["Texture"] = gr.loadTexture("iconv-bomber", true, true),},
        ["Cruiser"] = {["Texture"] = gr.loadTexture("iconv-cruiser", true, true),},
        ["Corvette"] = {["Texture"] = gr.loadTexture("iconV-vette", true, true),},
        ["Capital"] = {["Texture"] = gr.loadTexture("iconv-cap", true, true),},
        ["Transport"] = {["Texture"] = gr.loadTexture("iconv-transport", true, true),},
    },
    ["Shivan"] = {
        ["Fighter"] = {["Texture"] = gr.loadTexture("iconS-fighter", true, true),},
        ["Bomber"] = {["Texture"] = gr.loadTexture("icons-bomber", true, true),},
        ["Cruiser"] = {["Texture"] = gr.loadTexture("icons-cruiser", true, true),},
        ["Corvette"] = {["Texture"] = gr.loadTexture("iconS-vette", true, true),},
        ["Capital"] = {["Texture"] = gr.loadTexture("icons-cap", true, true),},
        ["Super Cap"] = {["Texture"] = gr.loadTexture("icons-super", true, true),},
        ["Transport"] = {["Texture"] = gr.loadTexture("icons-transport", true, true),},
    },
}

for species, shipTypes in pairs(GrCommon.IconMap) do
    for type, texInfo in pairs(shipTypes) do
        GrCommon.IconMap[species][type].Height = texInfo.Texture:getHeight()
        GrCommon.IconMap[species][type].Width  = texInfo.Texture:getWidth()
        GrCommon.IconMap[species][type].Url    = ui.linkTexture(GrCommon.IconMap[species][type].Texture)
    end
end

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