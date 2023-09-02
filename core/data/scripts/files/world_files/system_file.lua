local Class       = require("class")
local Inspect     = require("inspect")
local Json       = require("dkjson")
local Utils         = require('utils')

local SystemFile = Class()

local loadTextures
loadTextures = function(system)
    system.Texture = gr.loadTexture(system.Texture, true)

    if system.Satellites then
        for _, satellite in pairs(system.Satellites) do
            loadTextures(satellite)
        end
    end
end

function SystemFile:loadSystem(filename)
    local system_file = cf.openFile(filename, "r", "data/config")
    if not system_file:isValid() then
        ba.error("Could not open system file: " .. filename)
        return
    end

    local system_data = Json.decode(system_file:read("*a"))
    for _, star in pairs(system_data.SolarSystem.Stars) do
        loadTextures(star)
    end

    ba.println("loadSystem: " .. Inspect({ system_data }))

    system_file:close()

    return system_data.SolarSystem
end

return SystemFile