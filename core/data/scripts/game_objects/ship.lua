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
    self.Name = Utils.Game.getMandatoryProperty(properties, 'Name')
end

return Ship