--[=[
    Module for dealing with and storing custom data in buffers.

    Written by Turing6.

    @class BufferUtils
]=]
const BufferUtils = {}

const CFrame = require("./CFrame")

const U8_MAX = (2 ^ 8) - 1
const U16_MAX = (2 ^ 16) - 1
const U32_MAX = (2 ^ 32) - 1
const I8_MAX = (2 ^ 7) - 1
const I16_MAX = (2 ^ 15) - 1
const I32_MAX = (2 ^ 31) - 1
const F32_MAX = (3.4 * (10 ^ 38))
const F64_MAX = (1.8 * (10 ^ 308))

const U8_MIN = 0
const U16_MIN = U8_MIN
const U32_MIN = U8_MIN
const I8_MIN = (-2 ^ 7)
const I16_MIN = (-2 ^ 15)
const I32_MIN = (-2 ^ 31)
const F32_MIN = -F32_MAX
const F64_MIN = -F64_MAX

const SIZE_8 = 1
const SIZE_16 = 2
const SIZE_32 = 4
const SIZE_64 = 8

const BIG = buffer.create(16000 * 1000)

type Deserialize<T> = (b: buffer, offset: number) -> (T, number)
type Serialize<T> = (b: buffer, offset: number, val: T) -> number

export type Schema = {SchemaType} | {{Key: string, Type: SchemaType}}

export type SchemaType<T = any> = {
    Serialize: Serialize<T>,
    Deserialize: Deserialize<T>
}

function checkType(val: any, t: string)
    if typeof(val) ~= t then
        error(`Invalid value for serialization! expected '{t}', got '{typeof(val)}'`, 3)
    end
end

function checkNumberBounds(val: number, min: number, max: number, t: string)
    if val < min then
        error(`Invalid number for {t} serialization! must be at least {min}, got {val}`)
    elseif val > max then
        error(`Invalid number for {t} serialization! must be at most {max}, got {val}`)
    end
end

function checkString(length: number, max: number, t: string)
    if length > max then
        error(`Invalid string for {t} serialization! must be at most {max} characters long, got {length}`, 2)
    end
end

BufferUtils.SchemaTypes = {
    Boolean = {
        Serialize = function(b: buffer, offset: number, val: boolean): number
            checkType(val, "boolean")
            buffer.writeu8(b, offset, if val then 1 else 0)
            return offset + SIZE_8
        end,
        Deserialize = function(b: buffer, offset: number): (boolean, number)
            return buffer.readu8(b, offset) == 1, offset + SIZE_8
        end
    },
    U8 = {
        Serialize = function(b: buffer, offset: number, val: number): number
            checkType(val, "number")
            checkNumberBounds(val, U8_MIN, U8_MAX, "U8")
            buffer.writeu8(b, offset, val)
            return offset + SIZE_8
        end,
        Deserialize = function(b: buffer, offset: number): (number, number)
            return buffer.readu8(b, offset), offset + SIZE_8
        end
    },
    I8 = {
        Serialize = function(b: buffer, offset: number, val: number): number
            checkType(val, "number")
            checkNumberBounds(val, I8_MIN, I8_MAX, "I8")
            buffer.writei8(b, offset, val)
            return offset + SIZE_8
        end,
        Deserialize = function(b: buffer, offset: number): (number, number)
            return buffer.readi8(b, offset), offset + SIZE_8
        end
    },
    U16 = {
        Serialize = function(b: buffer, offset: number, val: number): number
            checkType(val, "number")
            checkNumberBounds(val, U16_MIN, U16_MAX, "U16")
            buffer.writeu16(b, offset, val)
            return offset + SIZE_16
        end,
        Deserialize = function(b: buffer, offset: number): (number, number)
            return buffer.readu16(b, offset), offset + SIZE_16
        end
    },
    I16 = {
        Serialize = function(b: buffer, offset: number, val: number): number
            checkType(val, "number")
            checkNumberBounds(val, I16_MIN, I16_MAX, "I16")
            buffer.writei16(b, offset, val)
            return offset + SIZE_16
        end,
        Deserialize = function(b: buffer, offset: number): (number, number)
            return buffer.readi16(b, offset), offset + SIZE_16
        end
    },
    U32 = {
        Serialize = function(b: buffer, offset: number, val: number): number
            checkType(val, "number")
            checkNumberBounds(val, U32_MIN, U32_MAX, "U32")
            buffer.writeu32(b, offset, val)
            return offset + SIZE_32
        end,
        Deserialize = function(b: buffer, offset: number): (number, number)
            return buffer.readu32(b, offset), offset + SIZE_32
        end
    },
    I32 = {
        Serialize = function(b: buffer, offset: number, val: number): number
            checkType(val, "number")
            checkNumberBounds(val, I32_MIN, I32_MAX, "I32")
            buffer.writei32(b, offset, val)
            return offset + SIZE_32
        end,
        Deserialize = function(b: buffer, offset: number): (number, number)
            return buffer.readi32(b, offset), offset + SIZE_32
        end
    },
    F32 = {
        Serialize = function(b: buffer, offset: number, val: number): number
            checkType(val, "number")
            checkNumberBounds(val, F32_MIN, F32_MAX, "F32")
            buffer.writef32(b, offset, val)
            return offset + SIZE_32
        end,
        Deserialize = function(b: buffer, offset: number): (number, number)
            return buffer.readf32(b, offset), offset + SIZE_32
        end
    },
    F64 = {
        Serialize = function(b: buffer, offset: number, val: number): number
            checkType(val, "number")
            checkNumberBounds(val, F64_MIN, F64_MAX, "F64")
            buffer.writef64(b, offset, val)
            return offset + SIZE_64
        end,
        Deserialize = function(b: buffer, offset: number): (number, number)
            return buffer.readf64(b, offset), offset + SIZE_64
        end
    },
    String8 = {
        Serialize = function(b: buffer, offset: number, val: string): number
            checkType(val, "string")
            local length = string.len(val)
            checkString(length, U8_MAX, "String8")
            buffer.writeu8(b, offset, length)
            buffer.writestring(b, offset + SIZE_8, val)
            return offset + SIZE_8 + length
        end,
        Deserialize = function(b: buffer, offset: number): (string, number)
            local length = buffer.readu8(b, offset)
            return buffer.readstring(b, offset + SIZE_8, length), offset + SIZE_8 + length
        end
    },
    String16 = {
        Serialize = function(b: buffer, offset: number, val: string): number
            checkType(val, "string")
            local length = string.len(val)
            checkString(length, U16_MAX, "String16")
            buffer.writeu16(b, offset, length)
            buffer.writestring(b, offset + SIZE_16, val)
            return offset + SIZE_16 + length
        end,
        Deserialize = function(b: buffer, offset: number): (string, number)
            local length = buffer.readu16(b, offset)
            return buffer.readstring(b, offset + SIZE_16, length), offset + SIZE_16 + length
        end
    },
    String32 = {
        Serialize = function(b: buffer, offset: number, val: string): number
            checkType(val, "string")
            local length = string.len(val)
            checkString(length, U32_MAX, "String32")
            buffer.writeu32(b, offset, length)
            buffer.writestring(b, offset + SIZE_32, val)
            return offset + SIZE_32 + length
        end,
        Deserialize = function(b: buffer, offset: number): (string, number)
            local length = buffer.readu32(b, offset)
            return buffer.readstring(b, offset + SIZE_32, length), offset + SIZE_32 + length
        end
    },
    Buffer8 = {
        Serialize = function(b: buffer, offset: number, val: buffer): number
            checkType(val, "buffer")
            local length = buffer.len(val)
            checkString(length, U8_MAX, "Buffer8")
            buffer.writeu8(b, offset, length)
            buffer.copy(b, offset + SIZE_8, val, 0, length)
            return offset + SIZE_8 + length
        end,
        Deserialize = function(b: buffer, offset: number): (buffer, number)
            local length = buffer.readu8(b, offset)
            local val = buffer.create(length)
            buffer.copy(val, 0, b, offset + SIZE_8, length)
            return val, offset + SIZE_8 + length
        end
    },
    Buffer16 = {
        Serialize = function(b: buffer, offset: number, val: buffer): number
            checkType(val, "buffer")
            local length = buffer.len(val)
            checkString(length, U16_MAX, "Buffer16")
            buffer.writeu16(b, offset, length)
            buffer.copy(b, offset + SIZE_16, val, 0, length)
            return offset + SIZE_16 + length
        end,
        Deserialize = function(b: buffer, offset: number): (buffer, number)
            local length = buffer.readu16(b, offset)
            local val = buffer.create(length)
            buffer.copy(val, 0, b, offset + SIZE_16, length)
            return val, offset + SIZE_16 + length
        end
    },
    Buffer32 = {
        Serialize = function(b: buffer, offset: number, val: buffer): number
            checkType(val, "buffer")
            local length = buffer.len(val)
            checkString(length, U32_MAX, "Buffer32")
            buffer.writeu32(b, offset, length)
            buffer.copy(b, offset + SIZE_32, val, 0, length)
            return offset + SIZE_32 + length
        end,
        Deserialize = function(b: buffer, offset: number): (buffer, number)
            local length = buffer.readu32(b, offset)
            local val = buffer.create(length)
            buffer.copy(val, 0, b, offset + SIZE_32, length)
            return val, offset + SIZE_32 + length
        end
    },
    Vector2 = {
        Serialize = function(b: buffer, offset: number, val: vector): number
            if typeof(val) ~= "vector" then
                checkType(val, "Vector2")
            end
            buffer.writef32(b, offset, val.X)
            buffer.writef32(b, offset + SIZE_32, val.Y)
            return offset + SIZE_32 + SIZE_32
        end,
        Deserialize = function(b: buffer, offset: number): (vector, number)
            local x = buffer.readf32(b, offset)
            local y = buffer.readf32(b, offset + SIZE_32)
            return Vector2.new(x, y), offset + SIZE_32 + SIZE_32
        end
    },
    Vector3 = {
        Serialize = function(b: buffer, offset: number, val: vector): number
            if typeof(val) ~= "vector" then
                checkType(val, "Vector3")
            end
            buffer.writef32(b, offset, val.X)
            buffer.writef32(b, offset + SIZE_32, val.Y)
            buffer.writef32(b, offset + SIZE_32 + SIZE_32, val.Z)
            return offset + SIZE_32 + SIZE_32 + SIZE_32
        end,
        Deserialize = function(b: buffer, offset: number): (vector, number)
            local x = buffer.readf32(b, offset)
            local y = buffer.readf32(b, offset + SIZE_32)
            local z = buffer.readf32(b, offset + SIZE_32 + SIZE_32)
            return Vector3.new(x, y, z), offset + SIZE_32 + SIZE_32 + SIZE_32
        end
    },
    Udim = {
        Serialize = function(b: buffer, offset: number, val: UDim): number
            checkType(val, "UDim")
            buffer.writei32(b, offset, val.Offset)
            buffer.writef32(b, offset + SIZE_32, val.Scale)
            return offset + SIZE_32 + SIZE_32
        end,
        Deserialize = function(b: buffer, offset: number): (UDim, number)
            local o = buffer.readi32(b, offset)
            local scale = buffer.readf32(b, offset + SIZE_32)
            return UDim.new(scale, o), offset + SIZE_32 + SIZE_32
        end
    },
    Udim2 = {
        Serialize = function(b: buffer, offset: number, val: UDim2): number
            checkType(val, "UDim2")
            buffer.writei32(b, offset, val.X.Offset)
            buffer.writef32(b, offset + SIZE_32, val.X.Scale)
            buffer.writei32(b, offset + SIZE_32 + SIZE_32, val.Y.Offset)
            buffer.writef32(b, offset + SIZE_32 + SIZE_32 + SIZE_32, val.Y.Scale)
            return offset + SIZE_32 + SIZE_32 + SIZE_32 + SIZE_32
        end,
        Deserialize = function(b: buffer, offset: number): (UDim2, number)
            local xOffset = buffer.readi32(b, offset)
            local xScale = buffer.readf32(b, offset + SIZE_32)
            local yOffset = buffer.readi32(b, offset + SIZE_32 + SIZE_32)
            local yScale = buffer.readf32(b, offset + SIZE_32 + SIZE_32 + SIZE_32)
            return UDim2.new(xScale, xOffset, yScale, yOffset), offset + SIZE_32 + SIZE_32 + SIZE_32 + SIZE_32
        end
    },
    Color3 = {
        Serialize = function(buf: buffer, offset: number, val: vector): number
            if typeof(val) ~= "vector" then
                checkType(val, "Vector3")
            end
            buffer.writeu8(buf, offset, val.R * 255)
            buffer.writeu8(buf, offset + SIZE_8, val.G * 255)
            buffer.writeu8(buf, offset + SIZE_8 + SIZE_8, val.B * 255)
            return offset + SIZE_8 + SIZE_8 + SIZE_8
        end,
        Deserialize = function(buf: buffer, offset: number): (vector, number)
            local r = buffer.readu8(buf, offset)
            local g = buffer.readu8(buf, offset + SIZE_8)
            local b = buffer.readu8(buf, offset + SIZE_8 + SIZE_8)
            return Color3.fromRGB(r, g, b), offset + SIZE_8 + SIZE_8 + SIZE_8
        end
    },
    Cframe = {
        Serialize = function(b: buffer, offset: number, val: CFrame.CFrame): number
            if not CFrame.is(val) then
                error(`Invalid value for CFrame serialization! expected CFrame, got {typeof(val)}`)
            end
            local pos = val.Position
            local rot = val.Orientation
            offset = BufferUtils.SchemaTypes.Vector3.Serialize(b, offset, pos)
            offset = BufferUtils.SchemaTypes.Vector3.Serialize(b, offset, rot)
            return offset
        end,
        Deserialize = function(b: buffer, offset: number): (CFrame.CFrame, number)
            local pos: vector, rot: vector
            pos, offset = BufferUtils.SchemaTypes.Vector3.Deserialize(b, offset)
            rot, offset = BufferUtils.SchemaTypes.Vector3.Deserialize(b, offset)
            return CFrame.new(pos) * CFrame.fromOrientation(rot), offset
        end
    }
}

--[=[
    Creates and registers a new schema type that uses the given functions for serialization/deserialization.

    @function newSchemaType
    @param name string
    @param serializeFunc (b: buffer, offset: number, value: T) -> number
    @param deserializeFunc (b: buffer, offset: number) -> (T, number)
    @return SchemaType<T>
]=]
function BufferUtils.newSchemaType<T>(name: string, serializeFunc: Serialize<T>, deserializeFunc: Deserialize<T>): SchemaType<T>
    name = string.upper(string.sub(name, 1, 1))..string.lower(string.sub(name, 2))

    if BufferUtils.SchemaTypes[name] then
        error(`Schema type '{name}' already exists!`, 2)
    end

    local newType: SchemaType = {
        Serialize = serializeFunc,
        Deserialize = deserializeFunc
    }

    BufferUtils.SchemaTypes[name] = newType

    return newType
end

function findSchemaType(str: string): SchemaType?
    return BufferUtils.SchemaTypes[string.upper(string.sub(str, 1, 1))..string.lower(string.sub(str, 2))]
end

--[=[
    Creates a new schema where each type is the schema type of the given names in the order given.

    e.g.
    ```lua
        BufferUtils.schemaByNames("u8", "Boolean", "Vector3") -- returns {BufferUtils.SchemaTypes.U8, BufferUtils.SchemaTypes.Boolean, BufferUtils.SchemaTypes.Vector3}
    ```

    @function schemaByNames
    @param ... string -- Names of schema types
    @return Schema -- The created schema
]=]
function BufferUtils.schemaByNames(...: string): Schema
    local schema: Schema = {}
    local values = {...}

    for _,str in values do
        local schemaType: SchemaType? = findSchemaType(str)
        if schemaType then
            table.insert(schema, schemaType)
        else
            error(`Unable to find schema type '{str}'`, 2)
        end
    end

    return schema
end

function findNumberType(v: number): string
    local typeName = if string.find(tostring(v), ".") then "F32" else if v < 0 then "I8" else "U8"
    if v > U32_MAX then
        if v > F32_MAX then
            typeName = "F64"
        else
            typeName = "F32"
        end
    elseif v > I32_MAX then
        typeName = "U32"
    elseif v > U16_MAX then
        typeName = "I32"
    elseif v > I16_MAX then
        typeName = "U16"
    elseif v > U8_MAX then
        typeName = "I16"
    elseif v > I8_MAX then
        typeName = "U8"
    elseif v < 0 then
        if v < F32_MIN then
            typeName = "F64"
        elseif v < I32_MIN then
            typeName = "F32"
        elseif v < I16_MIN then
            typeName = "I32"
        elseif v < I8_MIN then
            typeName = "I16"
        else
            typeName = "I8"
        end
    end
    return typeName
end

function findStringType(v: string): string
    local typeName = "String8"
    local length = string.len(v)

    if length > U16_MAX then
        typeName = "String32"
    elseif length > U8_MAX then
        typeName = "String16"
    end

    return typeName
end

--[=[
    Attempts to create a new schema for the given list of values, errors if the list contains an unsupported type.

    `number` values are given the smallest possible type capable of holding that number
    e.g. `254` is assigned `U8`, `-5` is assigned `I8`, `65580` is assigned `I32`

    @function autoSchema
    @param t {any} -- List of values
    @return Schema -- The created schema
]=]
function BufferUtils.autoSchema(t: {any}): Schema
    local schema: Schema = {}
    
    for _,v: any in t do
        local typeName = typeof(v)
        if typeName == "table" and typeof(getmetatable(v)) == "table" and typeof(rawget(v, "__className")) == "string" then
            typeName = rawget(v, "__className")
        elseif typeName == "number" then
            typeName = findNumberType(v)
        elseif typeName == "string" then
            typeName = findStringType(v)
        elseif typeName == "vector" then
            typeName = if v.Z ~= 0 then "Vector3" else "Vector2"
        elseif typeName == "Vector3" then
            if v.X >= 0 and v.Y >= 0 and v.Z >= 0 and v.X <= 255 and v.Y <= 255 and v.Z <= 255 then
                typeName = "Color3"
            end
        end
        local schemaType: SchemaType? = findSchemaType(typeName)
        if schemaType then
            table.insert(schema, schemaType)
        else
            error(`Unable to find schema type '{typeName}'`, 2)
        end
    end

    return schema
end

function convertSchema(schema: Schema): {SchemaType}
    if not schema[1].Key then
        return schema
    else
        local s: Schema = {}

        for _,v in schema do
            table.insert(s, v.Type)
        end

        return s
    end
end

function serialize(schema: Schema, t: {any}, b: buffer): number
    if #schema ~= #t then error("value count mismatch! schema must have the same amount of values as t") end
    local offset = 0

    for i = 1, #schema do
        offset = schema[i].Serialize(b, offset, t[i])
    end

    return offset
end

--[=[
    Serializes a list of values into a buffer according to the given `schema`

    @function serialize
    @param schema: Schema -- Schema defining how list values should be serialized
    @param t {any} -- List of values
    @return buffer?, string? -- New buffer containing the serialized list data or nil if an error occured, Error message if applicable
]=]
function BufferUtils.serialize(schema: Schema, t: {any}): (buffer?, string?)
    local ogSchema: Schema = schema
    schema = convertSchema(schema)
    local success, offset = pcall(serialize, schema, t, BIG)

    if not success then
        if #schema ~= #t then
            return nil, offset
        end
        offset = 0

        for i = 1, #schema do
            local val = t[i]
            success, offset = pcall(schema[i].Serialize, BIG, offset, val)

            if not success then
                local name = i
                if ogSchema[i].Key then
                    name = ogSchema[i].Key
                end
                return nil, `Couldn't serialize value {name}! Message: {offset}`
            end
        end

        return nil, "Unknown error"
    end

    local b = buffer.create(offset)

    buffer.copy(b, 0, BIG, 0, offset)

    return b
end

function push(schema: Schema, t: {any}, b: buffer, offset: number): number
    if #schema ~= #t then
        error("value count mismatch! schema must have the same amount of values as t")
    end

    for i = 1, #schema do
        offset = schema[i].Serialize(b, offset, t[i])
    end

    return offset
end

--[=[
    Serializes a list of values according to the given `schema` and pushes into `buffer`, optionally at `offset`

    @function push
    @param schema Schema -- Schema defining how values should be serialized
    @param t {any} -- List of values
    @param b buffer -- Buffer to write to
    @param offset number? -- Optional offset into the buffer, defaults to `0`
    @return number?, string? -- The offset into `buffer` representing the end of the list data or nil if an error occured, Error message if applicable
]=]
function BufferUtils.push(schema: Schema, t: {any}, b: buffer, offset: number?): (number?, string?)
    offset = if offset then offset else 0
    local ogSchema: Schema = schema
    schema = convertSchema(schema)
    
    local originalOffset = offset

    local success = false
    success, offset = pcall(push, schema, t, b, offset)

    if not success then
        offset = originalOffset

        for i = 1, #schema do
            local val = t[i]
            success, offset = pcall(schema[i].Serialize, b, offset, val)
            
            if not success then
                local name = i
                if ogSchema[i].Key then
                    name = ogSchema[i].Key
                end
                return nil, `Couldn't serialize value {name}! Message: {offset}`
            end
        end

        return nil, "Unknown error"
    end

    return offset
end

function deserialize(schema: Schema, b: buffer, offset: number?): ({any}, number)
    offset = (if offset then offset else 0)

    local count = #schema
    local result = table.create(count)

    for i = 1, count do
        result[i], offset = schema[i].Deserialize(b, offset)
    end

    return result, offset
end

--[=[
    Deserializes a buffer into a table of values according to the given `schema`, starting at `offset`

    @function deserialize
    @param schema Schema -- Schema defining how values are serialized
    @param b buffer -- Buffer to read from
    @param offset number? -- Offset into the buffer to start reading from, defaults to `0`
    @return ({any} | {[string]: any})?, string? -- Table of deserialized values, Error message if applicable
]=]
function BufferUtils.deserialize(schema: Schema, b: buffer, offset: number?): (({any} | {[string]: any})?, string?)
    offset = if offset then offset else 0
    local ogSchema: Schema = schema
    schema = convertSchema(schema)
    local success, val = pcall(deserialize, schema, b, offset)

    if not success then
        for i = 1, #schema do
            success, offset = pcall(schema[i].Deserialize, b, offset)
            
            if not success then
                local name = i
                if ogSchema[i].Key then
                    name = ogSchema[i].Key
                end
                return nil, `Couldn't deserialize value {name}! Message: {offset}`
            end
        end

        return nil, "Unknown error"
    end

    if ogSchema[1].Key then
        local newVal: {[string]: any} = {}

        for i,v in ogSchema do
            newVal[v.Key] = val[i]
        end

        return newVal
    end

    return val
end

return BufferUtils