local Class          = require("class")
local GameObject     = require("game_object")
local Inspect        = require('inspect')
local Utils          = require('utils')

local Ship = Class(GameObject)

function Ship:init(properties)
    self.Species = Utils.Game.getMandatoryProperty(properties, 'Species')
    self.Type = Utils.Game.getMandatoryProperty(properties, 'Type')
    self.Class = Utils.Game.getMandatoryProperty(properties, 'Class')
    self.Team = Utils.Game.getMandatoryProperty(properties, 'Team')
end

function Ship:copy()
    return Ship(self)
end

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

function Ship:getMapDisplayName()
    return class_name_map[self.Species][self.Type] .. ' ' .. self.Name
end

return Ship