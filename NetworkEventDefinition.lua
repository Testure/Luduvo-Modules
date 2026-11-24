--[=[
    Class that defines the types for a network event, with seemless serialization/deserialization of types not supported by default.

    Written by Turing6.

    @class NetworkEventDefinition
]=]
const NetworkEventDefinition = {}
NetworkEventDefinition.__index = NetworkEventDefinition

export type NetworkEventDefinition<T...> = typeof(setmetatable({}, NetworkEventDefinition))

type NetworkDefinition = {EventFieldType}

export type Networkable<T = Networkable, A = {any}> = {
    NetworkDefinition: NetworkDefinition,
    Serialize: (self: Networkable) -> A,
    Deserialize: (A) -> T
}

export type TableTypeDefinition = {
    MaxSize: number,
    Type: EventFieldType
}

NetworkEventDefinition._savedDefs = {} :: {[string]: Networkable}

NetworkEventDefinition.Types = {}

--[=[
    Registers a new serializable type to a name so that it may be passed into network events seemlessly.

    see CFrame for an example implementation of a networkable type.

    @param name string
    @param class Networkable
]=]
function NetworkEventDefinition.registerType(name: string, class: Networkable)
    NetworkEventDefinition._savedDefs[name] = class
    NetworkEventDefinition.Types[name] = name
end

function NetworkEventDefinition.new<T...>(...: string | EventFieldType | TableTypeDefinition): NetworkEventDefinition<T...>
    local self: NetworkEventDefinition<T...> = setmetatable({}, NetworkEventDefinition)
    local luduvoDef = {}
    local classMap = {}
    local classMap2 = {}
    local args = {...}
    local valueCount = 0
    local count = 0

    for i = 1, #args do
        if typeof(args[i]) == "userdata" then
            count += 1
            valueCount += 1
            table.insert(luduvoDef, {`Arg{count}`, args[i]})
        elseif typeof(args[i]) == "string" then
            if NetworkEventDefinition.Types[args[i]] == args[i] and NetworkEventDefinition._savedDefs[args[i]] then
                local def = NetworkEventDefinition._savedDefs[args[i]].NetworkDefinition
                count +=1
                local mapping = {start = count, ending = count, class = args[i]}
                valueCount += 1

                for _,v in def do
                    table.insert(luduvoDef, {`Arg{count}`, v})
                    count += 1
                end

                mapping.ending = count
                classMap[tostring(valueCount)] = mapping
                classMap2[tostring(mapping.start)] = mapping
            end
        elseif typeof(args[i]) == "table" and typeof(args[i].MaxSize) == "number" and typeof(args[i].Type) == "userdata" then
            local tableDef = args[i]
            count += 1
            table.insert(luduvoDef, {`Arg{count}`, game.EventTable.U8})
            local mapping = {start = count, ending = count, class = "table", size = tableDef.MaxSize}
            valueCount += 1

            for a = 1, tableDef.MaxSize do
                count += 1
                table.insert(luduvoDef, {`Arg{count}`, tableDef.Type})
            end

            mapping.ending = count
            classMap[tostring(valueCount)] = mapping
            classMap2[tostring(mapping.start)] = mapping
        end
    end

    self.luduvoDef = luduvoDef
    self.classMap = classMap
    self.values = valueCount
    self.classMap2 = classMap2
    
    return self
end

function NetworkEventDefinition.SerializeValues(self, ...): (...any)
    local args = {...}
    if #args ~= self.values then error("Arg count does not match number of values!", 2) end

    local serialized = {}
    local i = 1

    while i <= #args do
        if self.classMap[tostring(i)] then
            local mapping = self.classMap[tostring(i)]

            if mapping.class == "table" then
                table.insert(serialized, #args[i])
                local added = 0
                local f = nil

                for _,v in ipairs(args[i]) do
                    added += 1
                    if not f then f = v end
                    table.insert(serialized, v)
                end

                for a = added + 1, mapping.size do
                    table.insert(serialized, f)
                end
            elseif NetworkEventDefinition._savedDefs[mapping.class] then
                local class = NetworkEventDefinition._savedDefs[mapping.class]
                local vals = {class.Serialize(args[i])}

                for _,v in ipairs(vals) do
                    table.insert(serialized, v)
                end
            end
        else
            table.insert(serialized, args[i])
        end
        i += 1
    end

    return unpack(serialized, 1, #serialized)
end

function NetworkEventDefinition:DeserializeValues(...): (...any)
    local args = {...}

    local deserialzed = {}
    local i = 1

    while i <= #args do
        if self.classMap2[tostring(i)] then
            local mapping = self.classMap2[tostring(i)]
            
            if mapping.class == "table" then
                local count = args[i]
                local tbl = {}

                for a = 1, count do
                    i += 1
                    tbl[a] = args[i]
                end

                table.insert(deserialzed, tbl)
                i = mapping.ending
            elseif NetworkEventDefinition._savedDefs[mapping.class] then
                local class = NetworkEventDefinition._savedDefs[mapping.class]
                local tbl = {}

                for a = 1, #class.NetworkDefinition do
                    if a > 1 then i += 1 end
                    tbl[a] = args[i]
                end

                table.insert(deserialzed, class.Deserialize(unpack(tbl, 1, #tbl)))
            end
        else
            table.insert(deserialzed, args[i])
        end
        i += 1
    end

    return unpack(deserialzed, 1, #deserialzed)
end

return NetworkEventDefinition