local Class          = require("class")
local GrCommon       = require("gr_common")
local Inspect        = require('inspect')
local Satellite      = require('satellite')
local Utils          = require('utils')

local Ship = Class(Satellite)

local icon_map = {
    ["Terran"] = {
        ["Fighter"] = GrCommon.loadTexture("iconT-fighter", true),
        ["Bomber"] = GrCommon.loadTexture("icont-bomber", true),
        ["Cruiser"] = GrCommon.loadTexture("icont-cruiser", true),
        ["Corvette"] = GrCommon.loadTexture("iconT-vette", true),
        ["Capital"] = GrCommon.loadTexture("icont-cap", true),
        ["Super Cap"] = GrCommon.loadTexture("icont-super", true),
        ["Transport"] = GrCommon.loadTexture("icont-transport", true),
    },
    ["Vasudan"] = {
        ["Fighter"] = GrCommon.loadTexture("iconV-fighter", true),
        ["Bomber"] = GrCommon.loadTexture("iconv-bomber", true),
        ["Cruiser"] = GrCommon.loadTexture("iconv-cruiser", true),
        ["Corvette"] = GrCommon.loadTexture("iconV-vette", true),
        ["Capital"] = GrCommon.loadTexture("iconv-cap", true),
        ["Transport"] = GrCommon.loadTexture("iconv-transport", true),
    },
    ["Shivan"] = {
        ["Fighter"] = GrCommon.loadTexture("iconS-fighter", true),
        ["Bomber"] = GrCommon.loadTexture("icons-bomber", true),
        ["Cruiser"] = GrCommon.loadTexture("icons-cruiser", true),
        ["Corvette"] = GrCommon.loadTexture("iconS-vette", true),
        ["Capital"] = GrCommon.loadTexture("icons-cap", true),
        ["Super Cap"] = GrCommon.loadTexture("icons-super", true),
        ["Transport"] = GrCommon.loadTexture("icons-transport", true),
    },
}

local class_name_map = {
    ["Terran"] = {
        ["Fighter"] = 'GTT',
        ["Bomber"] = 'GTB',
        ["Cruiser"] = 'GTC',
        ["Corvette"] = 'GTCv',
        ["Capital"] = 'GTD',
        ["Super Cap"] = 'GTVA',
        ["Transport"] = 'GTT',
    },
    ["Vasudan"] = {
        ["Fighter"] = 'PVF',
        ["Bomber"] = 'PVB',
        ["Cruiser"] = 'PVC',
        ["Corvette"] = 'PVCv',
        ["Capital"] = 'PVD',
        ["Transport"] = 'PVD',
    },
    ["Shivan"] = {
        ["Fighter"] = 'SF',
        ["Bomber"] = 'SB',
        ["Cruiser"] = 'SC',
        ["Corvette"] = 'SCv',
        ["Capital"] = 'SD',
        ["Super Cap"] = 'SJ',
        ["Transport"] = 'ST',
    },
}

function Ship:init(properties)
    ba.println("Ship:init: " .. Inspect(properties.Name))
    self.Species = Utils.Game.getMandatoryProperty(properties, 'Species')
    self.Type = Utils.Game.getMandatoryProperty(properties, 'Type')
    self.Class = Utils.Game.getMandatoryProperty(properties, 'Class')
    self.Team = Utils.Game.getMandatoryProperty(properties, 'Team')
    self.Category = 'Ship'

    if properties.System then
        self.System.Destination = nil
        self.System.Speed = Utils.Game.getMandatoryProperty(properties.System, 'Speed')
        self.System.SubspaceSpeed = Utils.Game.getMandatoryProperty(properties.System, 'SubspaceSpeed')
    end
end

function Ship:update()
    if self.System.Destination then
        local movement = (self.System.Destination - self.System.Position):normalize()
        movement = movement * (GameState.CurrentTime - self.System.UpdateTime) * self.System.Speed
        if movement:getSqrMagnitude() > (self.System.Destination - self.System.Position):getSqrMagnitude() then
            movement = self.System.Destination - self.System.Position
            self.System.Destination = nil
        end

        self.System.Position = self.System.Position + movement
    else
        Ship._base.update(self)
    end

    local nearest = GameSystemMap.ObjectKDTree:findNearest(self.System.Position, self.SemiMajorAxis,
            function(objects) return objects[1] and objects[1].Category == 'Astral' end
    )
    self.Parent = nearest and nearest[1] or self.Parent
    self:recalculateOrbit()
    self:recalculateOrbitParent()
    self.System.UpdateTime = GameState.CurrentTime
end

function Ship:getIcon()
    return icon_map[self.Species][self.Type]
end

function Ship:copy()
    return Ship(self)
end

function Ship:getMapDisplayName()
    return class_name_map[self.Species][self.Type] .. ' ' .. self.Name
end

return Ship