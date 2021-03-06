﻿-- This file is subject to copyright - contact swampservers@gmail.com for more information.
function noop()
end

function call(fn, ...)
    fn(...)
end

function call_async(fn, ...)
    local arg = {...}

    timer.Simple(0, function()
        fn(unpack(arg))
    end)
end

--auto pcall
function apcall(fn, ...)
    local succ, err = pcall(fn, ...)

    if not succ then
        ErrorNoHalt(err)
    end
end

-- function For(tab, callback)
--     local out = {}
--     for k,v in pairs(tab) do
--         k,v = callback(k,v)
--         if k~=nil then
--             if v~=nil then
--                 out[k]=v
--             else
--                 table.insert(out,k)
--             end
--         end
--     end
--     return out
-- end
function For(tab, callback)
    local out = {}

    for _, v in ipairs(tab) do
        v = callback(v)

        if v ~= nil then
            table.insert(out, v)
        end
    end

    return out
end

local vec = FindMetaTable("Vector")
local vec__baseadd = vec__baseadd or vec.__add
local vec__basesub = vec__basesub or vec.__sub
local vec__basediv = vec__basediv or vec.__div
local vec__baseNormalize = vec__baseNormalize or vec.Normalize

vec.__add = function(a, b)
    if isnumber(b) then
        return Vector(a.x + b, a.y + b, a.z + b)
    else
        return vec__baseadd(a, b)
    end
end

vec.__sub = function(a, b)
    if isnumber(b) then
        return Vector(a.x - b, a.y - b, a.z - b)
    else
        return vec__basesub(a, b)
    end
end

vec.__div = function(a, b)
    if isvector(b) then
        return Vector(a.x / b.x, a.y / b.y, a.z / b.z)
    else
        return vec__basediv(a, b)
    end
end

function vec:Normalize()
    vec__baseNormalize(self)
    return self
end

function vec:Mean()
    return (self.x + self.y + self.z) / 3
end

function vec:Pow(y)
    return Vector(math.pow(self.x, y), math.pow(self.y, y), math.pow(self.z, y))
end

function vec:Max(o)
    return Vector(math.max(self.x, o.x), math.max(self.y, o.y), math.max(self.z, o.z))
end

function vec:Min(o)
    return Vector(math.min(self.x, o.x), math.min(self.y, o.y), math.min(self.z, o.z))
end

function vec:Clamp(min, max)
    return Vector(math.Clamp(self.x, min.x, max.x), math.Clamp(self.y, min.y, max.y), math.Clamp(self.z, min.z, max.z))
end

BLACK = Color(0, 0, 0, 255)
WHITE = Color(255, 255, 255, 255)

function table.sub(tab, a, b)
    local out = {}

    for i = a, b do
        table.insert(out, tab[i])
    end

    return out
end

function table.ireduce(tab, fn)
    local out = nil

    for i, v in ipairs(tab) do
        if out == nil then
            out = v
        else
            out = fn(out, v)
        end
    end

    return out
end

function table.isum(tab)
    return table.ireduce(tab, function(a, b) return a + b end)
end

function table.imax(tab)
    return table.ireduce(tab, math.max)
end

function table.imin(tab)
    return table.ireduce(tab, math.min)
end

-- function table.repeated(val,n)
--     local out = {}
--     for i=1,n do
--         table.insert(out, val)
--     end
--     return out  
-- end
-- WORKING SETGLOBAL* BECAUSE GARRYS VERSION UNSETS ITSELF RANDOMLY THANKS A LOT GARRY
glbls = glbls or {}

function GetG(k)
    return glbls[k]
end

if SERVER then
    util.AddNetworkString("Glbl")

    hook.Add("PlayerInitialSpawn", "globalsync", function(ply)
        net.Start("Glbl")
        net.WriteTable(glbls)
        net.Send(ply)
    end)

    timer.Create("KEEP IT REAL", 2, 0, function()
        local glblents = {}

        for k, v in pairs(glbls) do
            if isentity(v) then
                glblents[k] = v
            end
        end

        net.Start("Glbl", true)
        net.WriteTable(glblents)
        net.Broadcast()
    end)

    function SetG(k, v)
        if glbls[k] == v then return end
        net.Start("Glbl")

        net.WriteTable({
            [k] = v
        })

        net.Broadcast()
        glbls[k] = v
    end
else
    net.Receive("Glbl", function()
        local t = net.ReadTable()

        for k, v in pairs(t) do
            glbls[k] = v
        end
    end)
end



function defaultdict(constructor)
    return setmetatable({}, {
        __index = function(tab,key)
            tab[key] = constructor(key)
            return tab[key]
        end
    })
end

local EntClass = FindMetaTable("Entity").GetClass
local EntIndex = FindMetaTable("Entity").EntIndex

hook.Add("OnEntityCreated", "Ents_OnEntityCreated", function( v )
    local idx = EntIndex(v)
    if idx > 0 then --Filter CS ents and worldspawn
        Ents[EntClass(v)][idx] = v
    end
end)

hook.Add("NetworkEntityCreated","Ents_NetworkEntityCreated", function( v )
    local idx = EntIndex(v)
    if idx > 0 then
        Ents[EntClass(v)][idx] = v
    end
end)

hook.Add("EntityRemoved", "Ents_EntityRemoved", function( v )
    local idx = EntIndex(v)
    if idx > 0 then
        Ents[EntClass(v)][idx] = nil
    end
end)

function _SetupEnts()
    local _Ents = defaultdict(function() return {} end)

    for i,v in ipairs(ents.GetAll()) do
        local idx = EntIndex(v)
        if idx > 0 then
            _Ents[EntClass(v)][idx] = v
        end
    end

    return _Ents
end

Ents = Ents or _SetupEnts()

function _TestEnts()
    local ShouldBe = _SetupEnts()
    
    local classcount = 0
    for k,v in pairs(Ents) do
        if table.Count(v) > 0 then
            classcount=classcount+1
            local sv = ShouldBe[k]
            assert(sv)
            assert(table.Count(v) == table.Count(sv))
            for k2,v2 in pairs(v) do
                local sv2 = sv[k2]
                assert(sv2)
                assert(v2==sv2)
                assert(IsValid(v2))
            end
        end
    end 
    assert(classcount == table.Count(ShouldBe))
    print("ENTS OK")
end

-- timer.Create("TestTheEnts",5,0,function()
    -- if SERVER or LocalPlayer():Nick()=="Joker Gaming" 
    -- then _TestEnts() end
-- end)

