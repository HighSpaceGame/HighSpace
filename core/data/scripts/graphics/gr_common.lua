local GrCommon = {}

GrCommon.TeamSelectedColors = {
    ["Friendly"] = {["R"] = 0, ["G"] = 255, ["B"] = 255},
    ["Hostile"] = {["R"] = 255, ["G"] = 255, ["B"] = 0},
}

function GrCommon.loadTexture(filename, link)
    local texInfo = { ["Texture"] = gr.loadTexture(filename, true, true) }
    texInfo.Height = texInfo.Texture:getHeight()
    texInfo.Width  = texInfo.Texture:getWidth()

    if link then
        texInfo.Url    = ui.linkTexture(texInfo.Texture)
    end

    return texInfo
end

GrCommon.WaypointIcon = GrCommon.loadTexture("waypoint", true)
GrCommon.TargetIcon =  GrCommon.loadTexture("target", true)

return GrCommon