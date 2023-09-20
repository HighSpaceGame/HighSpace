local Class     = require("class")
local Inspect   = require('inspect')
local Utils     = require('utils')
local Vector     = require('vector')

local KDTree = Class()

KDTree._last_frame = {}
KDTree.Quadrants = {}
KDTree.AvgPosition = Vector(0,0)
KDTree.SplitPoint = Vector(0,0)
KDTree.NumChildObjects = 0
KDTree.Objects = {}
KDTree.Parent = nil
KDTree.Level = 0

function KDTree:init(parent, level, idx)
    --ba.println("Vector:init")

    self._last_frame = {}
    self.Quadrants = {}
    self.ObjPosition = Vector(0,0)
    self.AvgPosition = Vector(0,0)
    self.SplitPoint = Vector(0,0)
    self.NumChildObjects = 0
    self.Objects = {}
    self.Parent = parent
    self.Level = level and level or 0
    self.Index = idx or 0
end

function KDTree:getQuadrantIndex(position)
    local rel_position = position - self.SplitPoint
    return (rel_position.x > 0 and 2 or 0) + (rel_position.y > 0 and 1 or 0)
end

function KDTree:initFrame()
    self._last_frame = KDTree()
    self._last_frame.Objects = self.Objects
    self._last_frame.Quadrants = self.Quadrants
    self._last_frame.SplitPoint = self.SplitPoint
    self._last_frame.AvgPosition = self.AvgPosition

    for _, quadrant in pairs(self.Quadrants) do
        --ba.println("KDTree:draw: going into quadrant " .. Inspect({ idx, quadrant.Level, quadrant.NumChildObjects, #quadrant.Objects, quadrant.Objects[1] and quadrant.Objects[1].Name or 'none' }))
        quadrant.Parent = self._last_frame
    end

    self.Quadrants = {}
    self.Objects = {}
    self.NumChildObjects = 0
end

function KDTree:addObject(position, object, last_frame_quadrant)
    if self.Level == 0 then
        last_frame_quadrant = self._last_frame
    end

    if last_frame_quadrant then
        self.SplitPoint = last_frame_quadrant.AvgPosition:copy()
    end

    local idx = self:getQuadrantIndex(position)

    --ba.println("KDTree:addObject: checking quadrant..." .. Inspect({self.Level, object.Name, position.x, position.y, idx, #self.Objects, not not self.Quadrants[idx]}))
    if #self.Objects > 0 then
        --ba.println("KDTree:addObject: quadrant already has object or children, jumping in..." .. Inspect({self.Level, object.Name, position.x, position.y, idx, #self.Objects, not not self.Quadrants[idx]}))
        if not self.Quadrants[idx] then
            self.Quadrants[idx] = KDTree(self, self.Level+1, idx)
        end

        if last_frame_quadrant and (last_frame_quadrant.SplitPoint - self.SplitPoint):getSqrMagnitude() < 4 and last_frame_quadrant.Quadrants[idx] then
            last_frame_quadrant = last_frame_quadrant.Quadrants[idx]
        else
            last_frame_quadrant = nil
        end

        self.Quadrants[idx]:addObject(position, object, last_frame_quadrant)
        --ba.println("KDTree:addObject: SplitPoint." .. Inspect({self.Level, object.Name, self.SplitPoint.x, self.SplitPoint.y, self.AvgPosition.x, self.AvgPosition.y}))
        --ba.println("KDTree:addObject: AvgPosition." .. Inspect({self.Level, object.Name, position.x, position.y, self.AvgPosition.x, self.AvgPosition.y}))
        return
    end

    table.insert(self.Objects, object)
    self.NumChildObjects = self.NumChildObjects + 1
    self.AvgPosition = position:copy()
    self.ObjPosition = position:copy()
    --ba.println("KDTree:addObject: added object to quadrant." .. Inspect({self.Level, object.Name, position.x, position.y, #self.Objects}))

    local parent = self.Parent
    while parent do
        --ba.println("KDTree:addObject: parent.AvgPosition." .. Inspect({parent.Level, object.Name, position.x, position.y, parent.AvgPosition.x, parent.AvgPosition.y}))
        parent.AvgPosition = parent.AvgPosition * parent.NumChildObjects
        --ba.println("KDTree:addObject: parent.AvgPosition." .. Inspect({parent.Level, object.Name, position.x, position.y, parent.AvgPosition.x, parent.AvgPosition.y}))
        parent.NumChildObjects = parent.NumChildObjects + 1
        parent.AvgPosition = (parent.AvgPosition + position) / parent.NumChildObjects
        --ba.println("KDTree:addObject: parent.AvgPosition." .. Inspect({parent.Level, object.Name, position.x, position.y, parent.AvgPosition.x, parent.AvgPosition.y}))
        parent = parent.parent
    end

    --ba.println("KDTree:addObject: SplitPoint." .. Inspect({self.Level, object.Name, self.SplitPoint.x, self.SplitPoint.y, self.AvgPosition.x, self.AvgPosition.y}))
    --ba.println("KDTree:addObject: AvgPosition." .. Inspect({self.Level, object.Name, position.x, position.y, self.AvgPosition.x, self.AvgPosition.y}))
end

local coord_on_onsite = function(coord_dist, max_distance_sqr, quadrant_condition)
    if quadrant_condition then
        return (coord_dist * math.abs(coord_dist) - max_distance_sqr < 0)
    else
        return (coord_dist * math.abs(coord_dist) + max_distance_sqr >= 0)
    end
end

function KDTree:isInside(position, max_distance_sqr)
    if not self.Parent or not max_distance_sqr then
        return true
    end

    return coord_on_onsite(position.x - self.Parent.SplitPoint.x, max_distance_sqr, self.Index / 2 < 1)
       and coord_on_onsite(position.y - self.Parent.SplitPoint.y, max_distance_sqr, self.Index % 2 < 1)
end

function KDTree:findNearest(position, max_distance_sqr)
    --[[
    ba.println("KDTree:findNearestObjects: " .. Inspect({
        self.Index, self.Level, self:isInside(position, max_distance_sqr),
        position.x, position.y,
        self.Parent and self.Parent.SplitPoint.x or 0, self.Parent and self.Parent.SplitPoint.y or 0, max_distance_sqr or 'none',
        self.Objects[1] and self.Objects[1].Name or 'none',
        self.ObjPosition.x, self.ObjPosition.y
    }))
    ]]--

    if not self:isInside(position, max_distance_sqr) then
        return nil, nil
    end

    local q_result, q_dist_sqr = nil, (position - self.ObjPosition):getSqrMagnitude()
    local result

    if not max_distance_sqr or q_dist_sqr < max_distance_sqr then
        max_distance_sqr = q_dist_sqr
        result = self.Objects
    end

    for qidx, quadrant in pairs(self.Quadrants) do
        q_result, q_dist_sqr = quadrant:findNearest(position, max_distance_sqr)
        ba.println("KDTree:findNearestObjects q: " .. Inspect({
            self.Index, self.Level, qidx, max_distance_sqr, q_dist_sqr
        }))
        if q_dist_sqr and q_dist_sqr < max_distance_sqr then
            result = q_result
            max_distance_sqr = q_dist_sqr
        end
    end

    return result, max_distance_sqr
end

function KDTree:findObjectsWithin(position, radius_sqr, cluster_dist_sqr, found_objects)
    --[[
    ba.println("KDTree:findNearestObjects: " .. Inspect({
        self.Index, self.Level, is_inside,
        position.x, position.y,
        self.Parent and self.Parent.SplitPoint.x or 0, self.Parent and self.Parent.SplitPoint.y or 0, max_distance_sqr,
        self.Objects[1] and self.Objects[1].Name or 'none',
        self.ObjPosition.x, self.ObjPosition.y
    }))
    ]]--
    if not found_objects then
        found_objects = {}
    end

    if not self:isInside(position, radius_sqr) then
        return found_objects
    end

    --ba.println("KDTree:findObjectsWithin:." .. Inspect({self.Level, position.x, position.y, self.ObjPosition.x, self.ObjPosition.y, (position - self.ObjPosition):getSqrMagnitude(), radius_sqr}))
    if (position - self.ObjPosition):getSqrMagnitude() < radius_sqr then
        local added = false
        if cluster_dist_sqr then
            for _, cluster in ipairs(found_objects) do
                if (self.ObjPosition - cluster.AvgPosition):getSqrMagnitude() < cluster_dist_sqr then
                    cluster.AvgPosition = cluster.AvgPosition * #cluster.Objects
                    --ba.println("KDTree:addObject: parent.AvgPosition." .. Inspect({parent.Level, object.Name, position.x, position.y, parent.AvgPosition.x, parent.AvgPosition.y}))
                    table.insert(cluster.Objects, self.Objects[1])
                    cluster.AvgPosition = (cluster.AvgPosition + self.ObjPosition) / #cluster.Objects
                    added = true
                    break
                end
            end
        end

        if not added then
            table.insert(found_objects, { ["Objects"] = { self.Objects[1] }, ["AvgPosition"] = self.ObjPosition })
        end
        --ba.println("KDTree:findObjectsWithin added object:" .. Inspect({self.Objects[1].Name}))
    end

    for _, quadrant in pairs(self.Quadrants) do
        quadrant:findObjectsWithin(position, radius_sqr, cluster_dist_sqr, found_objects)
    end

    return found_objects
end

function KDTree:draw()
    gr.setColor(75*self.Level, 0, 255)
    local split_point_screen = GameSystemMap.Camera:getScreenCoords(self.SplitPoint)
    if self.Parent then
        local p_split_point_screen = GameSystemMap.Camera:getScreenCoords(self.Parent.SplitPoint)
        if p_split_point_screen.x < split_point_screen.x then
            gr.drawLine(p_split_point_screen.x, split_point_screen.y, 1000, split_point_screen.y)
        else
            gr.drawLine(-1000, split_point_screen.y, p_split_point_screen.x, split_point_screen.y)
        end

        if p_split_point_screen.y < split_point_screen.y then
            gr.drawLine(split_point_screen.x, p_split_point_screen.y, split_point_screen.x, 1000)
        else
            gr.drawLine(split_point_screen.x, -1000, split_point_screen.x, p_split_point_screen.y)
        end
    else
        gr.drawLine(-1000, split_point_screen.y, 1000, split_point_screen.y)
        gr.drawLine(split_point_screen.x, -1000, split_point_screen.x, 1000)
    end


    --ba.println("KDTree:draw: " .. Inspect({ self.Level, self.NumChildObjects, #self.Objects, self.Objects[1] and self.Objects[1].Name or 'none' }))
    for idx, quadrant in pairs(self.Quadrants) do
        --ba.println("KDTree:draw: going into quadrant " .. Inspect({ idx, quadrant.Level, quadrant.NumChildObjects, #quadrant.Objects, quadrant.Objects[1] and quadrant.Objects[1].Name or 'none' }))
        quadrant:draw()
    end
end

return KDTree