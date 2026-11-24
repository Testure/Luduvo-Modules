--[=[
    @class Maid

    Utility class for holding a list of objects that can be cleaned up later with a single function call

    Written by Turing6.
]=]
local Maid = {}
Maid.__index = Maid

export type Maid = typeof(setmetatable({}, Maid))

local PossibleMethods = {"Destroy", "Disconnect", "Cancel"}

--[=[
    Creates a new Maid

    @function new
    @within Maid
    @return Maid
]=]
function Maid.new(): Maid
    local self = setmetatable({_data = {}}, Maid)

    return self
end

--[=[
    Adds an object to the Maid, then returns that object

    @method Add
    @within Maid
    @param object T
    @return T
]=]
function Maid.Add<T>(self: Maid, o: T): T
    table.insert(self._data, o)
    
    return o
end

--[=[
    Adds multiple objects to the Maid, then returns them

    @method AddMultiple
    @within Maid
    @param objects ...T
    @return ...T
]=]
function Maid.AddMultiple<T...>(self: Maid, ...: T...): T...
    local pack = {...}

    for _,v in pairs(pack) do
        table.insert(self._data, v)
    end

    return ...
end

--[=[
    Initiates a cleanup on this Maid.

    For every item added to this Maid since the last cleanup:

    if it is a `Instance`, call `:Destroy()` on it

    if it is a `SignalConnection`, call `:Disconnect()` on it

    if it is a `function`, call it with no arguments

    if it is a `thread`, close it

    if it is a `table`, call the first of the following functions on it (if available) `:Destroy()`, `:Disconnect()`, `:Cancel()`
    
    clears all values from the Maid

    @method Cleanup
    @within Maid
]=]
function Maid.Cleanup(self: Maid)
    for _,v in pairs(self._data) do
        if typeof(v) == "table" then
            local method = nil

            for _,i in pairs(PossibleMethods) do
                if v[i] then
                    method = v[i]
                    break
                end
                if v[string.lower(i)] then
                    method = v[string.lower(i)]
                    break
                end
            end

            if method then
                method(v)
            end
        elseif typeof(v) == "Instance" then
            v:Destroy()
        elseif typeof(v) == "SignalConnection" then
            v:Disconnect()
        elseif typeof(v) == "thread" then
            coroutine.close(v)
        elseif typeof(v) == "function" then
            v()
        end
    end

    table.clear(self._data)
end

Maid.Destroy = Maid.Cleanup

return Maid