local Class       = require("class")
local Inspect     = require("inspect")
local Ship          = require('ship')
local ShipGroup     = require('ship_group')
local ShipList      = require('ship_list')
local Utils         = require('utils')
local Wing          = require('wing')

local MissionFile = Class()

MissionFile.TacticalMode = false
MissionFile.Wings = {}

local ships_added = 0

function MissionFile:addShip(file_mission, ship)
    if ship:is_a(Wing) then
        ba.println("Found Wing: " .. ship.Name)
        table.insert(self.Wings, ship)
        ship:forEach(function(group_ship)
            self:addShip(file_mission, group_ship)
        end)
        ba.println("createMissionFile WINGS: " .. Inspect({ self.Wings }))
        return
    elseif ship:is_a(ShipGroup) then
        ba.println("Found ShipGroup: " .. ship.Name)
        ship:forEach(function(group_ship)
            self:addShip(file_mission, group_ship)
        end)
        return
    end

    ba.println("Adding Ship: " .. Inspect(ship.Name))

    local z_pos = 0
    local z_rot = 1

    if ship.Team.Name == "Hostile" then
        z_pos = 6000
        z_rot = -1
    end

    local template_filename = "mn_" .. string.lower(ship.Class):gsub(" ", "_")
    local ship_template = require(template_filename)

    file_mission:write(ship_template.instantiate(
            ship.Name, ship.Team.Name, 100 * ships_added, 0, z_pos, z_rot
    ))

    ships_added = ships_added + 1
end

function MissionFile:addWing(file_mission, wing)
    file_mission:write("$Name: " .. wing.Name .. "\n")
    file_mission:write("$Waves: 1" .. "\n")
    file_mission:write("$Wave Threshold: 0" .. "\n")
    file_mission:write("$Special Ship: 0" .. "\n")
    file_mission:write("$Arrival Location: Hyperspace" .. "\n")
    file_mission:write("$Arrival Cue: ( true )" .. "\n")
    file_mission:write("$Departure Location: Hyperspace" .. "\n")
    file_mission:write("$Departure Cue: ( false )" .. "\n")
    file_mission:write("$Ships: ( ")

    wing:forEach(function(ship)
        file_mission:write(string.format('"%s" ', ship.Name))
    end)

    file_mission:write(")" .. "\n")
    file_mission:write("+Hotkey: 0" .. "\n")
    file_mission:write("+Flags: ( )" .. "\n")
end

function MissionFile:createMissionFile(template, team1, team2)
    self.Wings = {}

    if not parse.readFileText(template, "data/missions") then
        ba.error("Could not open mission template: " .. template)
    end

    local file_mission = cf.openFile("encounter.fs2", "w", "data/missions")
    ba.println("createMissionFile: " .. Inspect({ file_mission:getPath(), file_mission:isValid(), team1, team2 }))

    while not parse.optionalString("#Objects") do
        local line = parse.getString()
        ba.println("writing line: " .. line)
        file_mission:write(line .. "\n")
    end

    file_mission:write("\n#Objects\n")
    self:addShip(file_mission, team1)
    self:addShip(file_mission, team2)

    ba.println("createMissionFile WINGS: " .. Inspect({ self.Wings }))
    file_mission:write("\n#Wings\n")
    for _, wing in ipairs(self.Wings) do
        self:addWing(file_mission, wing)
    end

    while not parse.optionalString("#End") do
        local line = parse.getString()
        ba.println("writing line: " .. line)
        file_mission:write(line .. "\n")
    end

    file_mission:write("\n#End")

    file_mission:flush()
    file_mission:close()
end

return MissionFile