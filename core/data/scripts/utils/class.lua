---------------------------------------------------------------
-------- functions for OOP              --------
-------------------------------------------------------------
-- Copied from http://lua-users.org/wiki/SimpleLuaClasses
local function class(base, init)
    local c = {} -- a new class instance
    if not init and type(base) == 'function' then
        init = base
        base = nil
    elseif type(base) == 'table' then
        -- our new class is a shallow copy of the base class!
        for i, v in pairs(base) do
            c[i] = v
        end
    end

    if (base) then
        c._base = base
        if not base._subc then
            base._subc = {}
        end
        table.insert(base._subc, c) -- Lets the superclass know of its subclasses
    end

    -- the class will be the metatable for all its objects,
    -- and they will look up their methods in it.
    c.__index = c

    -- expose a constructor which can be called by <classname>(<args>)
    local mt  = {}
    c.init    = init
    mt.__call = function(class_tbl, ...)
        local obj = {}
        setmetatable(obj, class_tbl)

        local t = class_tbl
        local b_init
        b_init = function(bt, ...)
            if bt._base then
                b_init(bt._base, ...)
                if bt._base.init then
                    bt._base.init(obj, ...)
                end
            end
        end
        b_init(t, ...)

        if class_tbl.init then
            class_tbl.init(obj, ...)
        end
        return obj
    end

    c.is_a    = function(self, klass)
        local m = getmetatable(self)

        while m do
            if m == klass then
                return true
            end
            m = m._base
        end

        return false
    end

    setmetatable(c, mt)

    return c
end

return class
