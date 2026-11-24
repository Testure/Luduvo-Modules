--[=[
    @class Enum

    Small module to allow the creation of custom enums.

    Written by Turing6.
]=]
local Enum = {}

export type function Enum(value)
    if not value:is("table") then
        error("Cannot make enum of non-table")
    end

    local t = types.newtable()

    for property in pairs(value:properties()) do
        t:setreadproperty(property, property)
    end

    return t
end

--[=[
    Converts a table of strings into an Enum; meaning it's members are pre-determined and cannot be modified.

    @function MakeEnum
    @param name string
    @param members {string}
    @return {string}
]=]
function Enum.MakeEnum<T>(name: string, members: T): Enum<T>
    local enum = {}

    for _, memberName in ipairs(members) do
        enum[memberName] = memberName
    end

    return setmetatable(enum, {
        __index = function(_, k)
            error(`{k} is not in {name}!`, 2)
        end,
        __newindex = function()
            error(`Creating new members in {name} is not allowed!`, 2)
        end
    })
end

return Enum