local Class          = require("class")
local GameObject     = require("game_object")
local GrCommon       = require("gr_common")
local Inspect        = require('inspect')
local Utils          = require('utils')

local Ship = Class(GameObject)

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
    self.Species = Utils.Game.getMandatoryProperty(properties, 'Species')
    self.Type = Utils.Game.getMandatoryProperty(properties, 'Type')
    self.Class = Utils.Game.getMandatoryProperty(properties, 'Class')
    self.Team = Utils.Game.getMandatoryProperty(properties, 'Team')
    self.Category = 'Ship'
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