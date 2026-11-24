--[=[
    @class CFrame

    Represents a location in 3D space via both a position vector and a rotation matrix

    Written by Turing6. Some math by yeno.
]=]
const CFrame = {}

const Enum = require("./Enum")
const NetworkEventDefinition = require("./NetworkEventDefinition")

type CFrameInternal = {
    x: number,
    y: number,
    z: number,
    X: number,
    Y: number,
    Z: number,
    R00: number,
    R01: number,
    R02: number,
    R10: number,
    R11: number,
    R12: number,
    R20: number,
    R21: number,
    R22: number,
    r00: number,
    r01: number,
    r02: number,
    r10: number,
    r11: number,
    r12: number,
    r20: number,
    r21: number,
    r22: number,
    Position: vector,
    Orientation: vector,
    Rotation: vector,
    XVector: vector,
    YVector: vector,
    ZVector: vector,
    LookVector: vector,
    UpVector: vector,
    RightVector: vector,
    position: vector,
    orientation: vector,
    rotation: vector,
    xVector: vector,
    yVector: vector,
    zVector: vector,
    lookVector: vector,
    upVector: vector,
    rightVector: vector
} & NetworkEventDefinition.Networkable<CFrame, {string}>

export type CFrame = typeof(setmetatable({} :: CFrameInternal, {__index = CFrame, __sub = CFrame.__sub, __add = CFrame.__add, __mul = CFrame.__mul, __tostring = CFrame.__tostring}))

--[=[
    @interface RotationOrder
    @within CFrame
    @field YXZ string -- YXZ order
    @field YZX string -- YZX order
    @field ZYX string -- ZYX order
    @field ZXY string -- ZXY order
    @field XZY string -- XZY order
    @field XYZ string -- XYZ order

    Enum for available Euler angle component orientations
]=]
CFrame.RotationOrder = Enum.MakeEnum("RotationOrder", {"YXZ", "YZX", "ZYX", "ZXY", "XZY", "XYZ"} :: {
    YXZ: string,
    YZX: string,
    ZYX: string,
    ZXY: string,
    XZY: string,
    XYZ: string
})

export type RotationOrder = typeof(CFrame.RotationOrder)

const ArgumentsError = "CFrame.new called with incorrect number of arguments! Expected %d"

function NewCFrameTable(x: number, y: number, z: number, R00: number?, R01: number?, R02: number?, R10: number?, R11: number?, R12: number?, R20: number?, R21: number?, R22: number?)
    return {
        X = x,
        Y = y,
        Z = z,
        R00 = R00 or 1,
        R01 = R01 or 0,
        R02 = R02 or 0,
        R10 = R10 or 0,
        R11 = R11 or 1,
        R12 = R12 or 0,
        R20 = R20 or 0,
        R21 = R21 or 0,
        R22 = R22 or 1,
        __className = "CFrame"
    }
end

--[=[
    Returns true if the given value is a CFrame.

    @param value any -- Value to test
    @return boolean
]=]
function CFrame.is(value: any): boolean
    if typeof(value) == "table" and typeof(getmetatable(value)) == "table" and getmetatable(value) == CFrame then
        return true
    end
    return false
end

--[=[
    Creates a new CFrame

    @function new
    @param x (number | vector)? -- `x` component or vector containing `x`, `y`, and `z`, defaults to `(0, 0, 0)`
    @param y (number | vector)? -- `y` component or vector containing the X components of the rotation matrix e.g. (R00, R01, R02)
    @param z (number | vector)? -- `z` component or vector containing the Y components of the rotation matrix e.g. (R10, R11, R12)
    @param R00 (number | vector)? -- `R00` component or vector containing the Z components of the rotation matrix e.g. (R20, R21, R22), defaults to 1
    @param R01 number? -- `R01` component, defaults to 0
    @param R02 number? -- `R02` component, defaults to 0
    @param R10 number? -- `R10` component, defaults to 0
    @param R11 number? -- `R11` component, defaults to 1
    @param R12 number? -- `R12` component, defaults to 0
    @param R20 number? -- `R20` component, defaults to 0
    @param R21 number? -- `R21` component, defaults to 0
    @param R22 number? -- `R22` component, defaults to 1
    @return CFrame
]=]
function CFrame.new(x: number? | vector?, y: number? | vector?, z: number? | vector?, R00: number? | vector?, R01: number?, R02: number?, R10: number?, R11: number?, R12: number?, R20: number?, R21: number?, R22: number?): CFrame
    if not x then x = Vector3.new() end
    
    if type(y) == "vector" and type(z) == "vector" and type(R00) == "vector" then
        R20 = R00
        R10 = z
        R00 = y
    end
    if type(x) == "vector" then
        y = x.Y
        z = x.Z
        x = x.X
    elseif not z or not y then
        error(string.format(ArgumentsError, 3), 2)
    end

    if R00 and R10 and R20 then
        if type(R20) == "vector" then
            R21 = R20.Y
            R22 = R20.Z
            R20 = R20.X
        elseif not R22 or not R21 then
            error(string.format(ArgumentsError, 12), 2)
        end
        if type(R10) == "vector" then
            R11 = R10.Y
            R12 = R10.Z
            R10 = R10.X
        elseif not R12 or not R11 then
            error(string.format(ArgumentsError, 12), 2)
        end
        if type(R00) == "vector" then
            R01 = R00.Y
            R02 = R00.Z
            R00 = R00.X
        elseif not R02 or not R01 then
            error(string.format(ArgumentsError, 12), 2)
        end
    elseif R00 then
        error(string.format(ArgumentsError, 12), 2)
    end

    return setmetatable(NewCFrameTable(
        x,
        y,
        z,
        R00,
        R01,
        R02,
        R10,
        R11,
        R12,
        R20,
        R21,
        R22
    ), CFrame)
end

--[=[
    Returns a new CFrame equal to the inverse of the current CFrame

    @method Inverse
    @return CFrame
]=]
@native
function CFrame.Inverse(self: CFrame): CFrame
    local x = -(self.R00 * self.X + self.R10 * self.Y + self.R20 * self.Z)
    local y = -(self.R01 * self.X + self.R11 * self.Y + self.R21 * self.Z)
    local z = -(self.R02 * self.X + self.R12 * self.Y + self.R22 * self.Z)

    return CFrame.new(Vector3.new(x, y, z), self.XVector, self.YVector, self.ZVector)
end

--[=[
    Takes one or more CFrame values and returns them transformed from object to world space
    Eqivalent to `CFrame * cf`

    @method ToWorldSpace
    @param ...CFrame -- one or more CFrames in object (local) space
    @return ...CFrame
]=]
function CFrame.ToWorldSpace(self: CFrame, ...: CFrame): ...CFrame
    local cframes = {...}

    for i,v in ipairs(cframes) do
        cframes[i] = self * v
    end

    return unpack(cframes, 1, #cframes)
end

--[=[
    Takes one or more CFrame values and returns them transformed from world to object space
    Eqivalent to `CFrame:Inverse() * cf`

    @method ToObjectSpace
    @param ...CFrame -- one or more CFrames in world (global) space
    @return ...CFrame
]=]
function CFrame.ToObjectSpace(self: CFrame, ...: CFrame): ...CFrame
    local cframes = {...}

    for i,v in ipairs(cframes) do
        cframes[i] = self:Inverse() * v
    end

    return unpack(cframes, 1, #cframes)
end

--[=[
    Takes one or more vector values and returns them transformed from object to world space
    Eqivalent to `CFrame * v`

    @method PointToWorldSpace
    @param ...vector -- one or more vectors in object (local) space
    @return ...vector
]=]
function CFrame.PointToWorldSpace(self: CFrame, ...: vector): ...vector
    local vectors = {...}

    for i,v in ipairs(vectors) do
        vectors[i] = self * v
    end

    return unpack(vectors, 1, #vectors)
end

--[=[
    Takes one or more vector values and returns them transformed from world to object space
    Eqivalent to `CFrame:Inverse() * v`

    @method PointToObjectSpace
    @param ...vector -- one or more vectors in world (global) space
    @return ...vector
]=]
function CFrame.PointToObjectSpace(self: CFrame, ...: vector): ...vector
    local vectors = {...}

    for i,v in ipairs(vectors) do
        vectors[i] = self:Inverse() * v
    end

    return unpack(vectors, 1, #vectors)
end

--[=[
    Takes one or more vector values and returns them transformed from object to world space
    Equivalent to `(CFrame - CFrame.Position) * v`

    @method VectorToWorldSpace
    @param ...vector -- one or more direction vectors in object (local) space
    @return ...vector
]=]
function CFrame.VectorToWorldSpace(self: CFrame, ...: vector): ...vector
    local vectors = {...}

    for i,v in ipairs(vectors) do
        vectors[i] = (self - self.Position) * v
    end

    return unpack(vectors, 1, #vectors)
end

--[=[
    Takes one or more vector values and returns them transformed from world to object space
    Equivalent to `(CFrame:Inverse() - CFrame:Inverse().Position) * v`

    @method VectorToObjectSpace
    @param ...vector -- one or more direction vectors in world (global) space
    @return ...vector
]=]
function CFrame.VectorToObjectSpace(self: CFrame, ...: vector): ...vector
    local vectors = {...}

    for i,v in ipairs(vectors) do
        vectors[i] = (self:Inverse() - self:Inverse().Position) * v
    end

    return unpack(vectors, 1, #vectors)
end

--[=[
    Returns the values `x`, `y`, `z`, `R00`, `R01`, `R02`, `R10`, `R11`, `R12`, `R20`, `R21`, and `R22`, where `x` `y` `z` represent the position and `R00` - `R22` represent the 3x3 rotation matrix

    @method GetComponents
    @return number -- `x`
    @return number -- `y`
    @return number -- `z`
    @return number -- `R00`
    @return number -- `R01`
    @return number -- `R02`
    @return number -- `R10`
    @return number -- `R11`
    @return number -- `R12`
    @return number -- `R20`
    @return number -- `R21`
    @return number -- `R22`
]=]
function CFrame.GetComponents(self: CFrame): (number, number, number, number, number, number, number, number, number, number, number, number)
    return self.X, self.Y, self.Z, self.R00, self.R01, self.R02, self.R10, self.R11, self.R12, self.R20, self.R21, self.R22
end

const ATAN2_CACHE = {}
const ASIN_CACHE = {}

--[=[
    If true, math results for converting a CFrame to Euler angles will be cached to avoid repeating calculations.

    Enabling this option makes converting to Euler angles (which includes accessing `CFrame.Orientation`, `CFrame.Rotation` or `CFrame:ToInstance`) faster in cases where a similar calculation has been done before, 
    but can end up using a lot of memory if many unique CFrames are being worked on regularly.

    Defaults to false.

    @prop CACHE_ON boolean
    @within CFrame
]=]
CFrame.CACHE_ON = false

function CFrame._reportCacheSize()
    local as, at = 0, 0

    for _,v in ASIN_CACHE do
        as += 1
    end
    for _,v in ATAN2_CACHE do
        at += 1
    end

    print(`CFrame cache: \{ asin: {as}, atan2: {at} \}`)
end

function asin(x: number): number
    if x == 0 then
        return 0
    else
        if ASIN_CACHE[x] then return ASIN_CACHE[x] end
        local result = math.asin(x)
        if CFrame.CACHE_ON then ASIN_CACHE[x] = result end
        return result
    end
end

function atan2(x: number, y: number): number
    if x == 0 then
        return 0
    else
        local key = x + y
        if ATAN2_CACHE[key] then return ATAN2_CACHE[key] end
        local result = math.atan2(x, y)
        if CFrame.CACHE_ON then ATAN2_CACHE[key] = result end
        return result
    end
end

--[=[
    Returns a Euler angles representation of the rotation matrix of this CFrame using the `RotationOrder`

    @method ToEulerAngles
    @param order RotationOrder? -- order of components, defaults to YXZ
    @return number -- first component in degrees
    @return number -- second component in degrees
    @return number -- third component in degrees
]=]
@native
function CFrame.ToEulerAngles(self: CFrame, order: RotationOrder?): (number, number, number)
    order = if order then order else CFrame.RotationOrder.YXZ
    local x, y, z = 0, 0, 0

    if order == "YXZ" then
        y = atan2(self.R02, self.R22)
        x = asin(-self.R12)
        z = atan2(self.R10, self.R11)
    elseif order == "XYZ" then
        x = atan2(-self.R12, self.R22)
        y = asin(self.R02)
        z = atan2(-self.R02, self.R01)
    elseif order == "XZY" then
        x = atan2(self.R21, self.R11)
        z = asin(-self.R01)
        y = atan2(self.R02, self.R00)
    elseif order == "YZX" then
        y = atan2(-self.R20, self.R00)
        z = asin(self.R10)
        x = atan2(-self.R12, self.R11)
    elseif order == "ZYX" then
        z = atan2(self.R10, self.R00)
        y = asin(-self.R20)
        x = atan2(self.R21, self.R22)
    elseif order == "ZXY" then
        z = atan2(-self.R01, self.R11)
        x = asin(self.R21)
        y = atan2(-self.R20, self.R22)
    end

    return math.deg(x), math.deg(y), math.deg(z)
end

--[=[
    Returns `x`, `y`, and `z` components this CFrame's rotation matrix in XYZ Euler angles.
    Equivalent to `CFrame:ToEulerAngles(CFrame.RotationOrder.XYZ)`

    @method ToEulerAnglesXYZ
    @return number -- `x` component
    @return number -- `y` component
    @return number -- `z` component
]=]
function CFrame.ToEulerAnglesXYZ(self: CFrame): (number, number, number)
    return self:ToEulerAngles(CFrame.RotationOrder.XYZ)
end

--[=[
    Returns `x`, `y`, and `z` components this CFrame's rotation matrix in YXZ Euler angles.
    Equivalent to `CFrame:ToEulerAngles(CFrame.RotationOrder.YXZ)`

    @method ToEulerAnglesXYZ
    @return number -- `x` component
    @return number -- `y` component
    @return number -- `z` component
]=]
function CFrame.ToEulerAnglesYXZ(self: CFrame): (number, number, number)
    return self:ToEulerAngles(CFrame.RotationOrder.YXZ)
end

--[=[
    Returns the orientation of this CFrame in YXZ Euler angles.
    Equivalent to `CFrame:ToEulerAnglesYXZ()`, but returns a vector instead of components.
    
    @method ToOrientation
    @return vector
]=]
function CFrame.ToOrientation(self: CFrame): vector
    return Vector3.new(self:ToEulerAnglesYXZ())
end

--[=[
    Creates a new CFrame with a position of 0 and a rotation matrix matching that of the given Euler angles.

    @function fromEulerAngles
    @param x number -- first component in degrees
    @param y number -- second component in degrees
    @param z number -- third component in degrees
    @param order RotationOrder? -- X Y and Z order of components, defaults to YXZ
    @return CFrame
]=]
@native
function CFrame.fromEulerAngles(x: number, y: number, z: number, order: RotationOrder?): CFrame
    order = if order then order else CFrame.RotationOrder.YXZ
    local R00, R01, R02, R10, R11, R12, R20, R21, R22
    local sx, cx = math.sin(x), math.cos(x)
    local sy, cy = math.sin(y), math.cos(y)
    local sz, cz = math.sin(z), math.cos(z)

    if order == "XZY" then
        R00 = cz * cy
        R01 = -sz
        R02 = cz * sy
        R10 = (sx * sy) + (cx * cy * sz)
        R11 = cx * cz
        R12 = (cx * sz * sy) - (cy * sx)
        R20 = (cy * sx * sz) - (cx * sy)
        R21 = cz * sx
        R22 = (cx * cy) + (sx * sz * sy)
    elseif order == "XYZ" then
        R00 = cy * cz
        R01 = -(cy * sz)
        R02 = sy
        R10 = (cx * sz) + (cz * sx * sy)
        R11 = (cx * cz) - (sx * sy * sz)
        R12 = -(cy * sx)
        R20 = (sx * sz) - (cx * cz * sy)
        R21 = (cz * sx) + (cx * sy * sz)
        R22 = cx * cy
    elseif order == "YXZ" then
        R00 = (cy * cz) + (sy * sx * sz)
        R01 = (cz * sy * sx) - (cy * sz)
        R02 = cx * sy
        R10 = cx * sz
        R11 = cx * cz
        R12 = -sx
        R20 = (cy * sx * sz) - (cz * sy)
        R21 = (cy * cz * sx) + (sy * sz)
        R22 = cy * cx
    elseif order == "YZX" then
        R00 = cy * cz
        R01 = (sy * sx) - (cy * cx * sz)
        R02 = (cx * sy) + (cy * sz * sx)
        R10 = sz
        R11 = cz * cx
        R12 = -(cz * sx)
        R20 = -(cz * sy)
        R21 = (cy * sx) + (cx * sy * sz)
        R22 = (cy * cx) - (sy * sz * sx)
    elseif order == "ZYX" then
        R00 = cz * cy
        R01 = (cz * sy * sx) - (cx * sz)
        R02 = (sz * sx) + (cz * cx * sy)
        R10 = cy * sz
        R11 = (cz * cx) + (sz * sy * sx)
        R12 = (cx * sz * sy) - (cz * sx)
        R20 = -sz
        R21 = cy * sx
        R20 = cy * cx
    elseif order == "ZXY" then
        R00 = (cz * cy) - (sz * sx * sy)
        R01 = -(cx * sz)
        R02 = (cz * sy) + (cy * sz * sx)
        R10 = (cy * sz) + (cz * sx * sy)
        R11 = cz * cx
        R12 = (sz * sy) - (cz * cy * sx)
        R20 = -(cx * sy)
        R21 = sx
        R22 = cx * cy
    end

    return CFrame.new(0, 0, 0, R00, R01, R02, R10, R11, R12, R20, R21, R22)
end

--[=[
    Creates a new CFrame with a position of 0 and a rotation matrix matching the given YXZ Euler angles.
    Equivalent to `CFrame.fromEulerAngles(x, y, z, CFrame.RotationOrder.YXZ)`

    @function fromEulerAnglesYXZ
    @param x number -- first component in degrees
    @param y number -- second component in degrees
    @param z number -- third component in degrees
    @return CFrame
]=]
function CFrame.fromEulerAnglesYXZ(x: number, y: number, z: number): CFrame
    return CFrame.fromEulerAngles(x, y, z, CFrame.RotationOrder.YXZ)
end

--[=[
    Creates a new CFrame with a position of 0 and a rotation matrix matching the given XYZ Euler angles.
    Equivalent to `CFrame.fromEulerAngles(x, y, z, CFrame.RotationOrder.XYZ)`

    @function fromEulerAnglesXYZ
    @param x number -- first component in degrees
    @param y number -- second component in degrees
    @param z number -- third component in degrees
    @return CFrame
]=]
function CFrame.fromEulerAnglesXYZ(x: number, y: number, z: number): CFrame
    return CFrame.fromEulerAngles(x, y, z, CFrame.RotationOrder.XYZ)
end

--[=[
    Creates a new CFrame with a position of 0 and a rotation matrix matching the given YXZ Euler angles.
    Equivalent to `CFrame.fromEulerAnglesYXZ(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))`

    @function fromOrientation
    @param rotation vector -- Euler angles in YXZ order
    @return CFrame
]=]
function CFrame.fromOrientation(rotation: vector): CFrame
    return CFrame.fromEulerAnglesYXZ(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
end

CFrame.fromRotation = CFrame.fromOrientation
CFrame.Angles = CFrame.fromEulerAnglesXYZ
CFrame.angles = CFrame.Angles

--[=[
    Creates a new CFrame at the position vector and facing the target vector

    math by yeno

    @function lookAt
    @param position vector -- world space of the CFrame
    @param target vector -- target to look at
    @param up vector? -- unit vector specifying the upward direction, defaults to `(0, 1, 0)`
    @return CFrame
]=]
@native
function CFrame.lookAt(position: vector, target: vector, up: vector?): CFrame
    up = if up then up else Vector3.new(0, 1)

    local diffX, diffY, diffZ = position.X - target.X, position.Y - target.Y, position.Z - target.Z
    local f = math.sqrt(diffX * diffX + diffY * diffY + diffZ * diffZ)
    local vector = Vector3.new(diffX / f, diffY / f, diffZ / f)

    local correctedX, correctedY, correctedZ = (up.Y * vector.Z - up.Z * vector.Y), (up.Z * vector.X - up.X * vector.Z), (up.X * vector.Y - up.Y * vector.X)
    local f2 = math.sqrt(correctedX * correctedX + correctedY * correctedY + correctedZ * correctedZ)
    local correctedVector = Vector3.new(correctedX / f2, correctedY / f2, correctedZ / f2)

    return CFrame.new(position, 
        Vector3.new(correctedVector.X, (vector.Y * correctedVector.Z - vector.Z * correctedVector.Y), vector.X),
        Vector3.new(correctedVector.Y, (vector.Z * correctedVector.X - vector.X * correctedVector.Z), vector.Y),
        Vector3.new(correctedVector.Z, (vector.X * correctedVector.Y - vector.Y * correctedVector.X), vector.Z)
    )
end

--[=[
    Creates a new CFrame equal to the Position and Orientation of the given Instance.
    Equivalent to 
    ```lua
        CFrame.new(instance.Position) * CFrame.fromOrientation(instance.Orientation)
    ```

    @function fromInstance
    @param instance Instance
    @return CFrame
]=]
function CFrame.fromInstance(instance: Instance): CFrame
    return CFrame.new(instance.Position) * CFrame.fromOrientation(instance.Orientation)
end

--[=[
    Modifies the given Instance such that it's Position and Orientation are equal to this CFrame.
    Equivalent to 
    ```lua
        instance.Position = cf.Position
        instance.Orientation = cf.Orientation
    ```

    @method ToInstance
    @param instance Instance
]=]
function CFrame.ToInstance(self: CFrame, instance: Instance)
    instance.Position = self.Position
    instance.Orientation = self.Orientation
end

CFrame.NetworkDefinition = {game.EventTable.Buffer}

--[=[
    Serializes this CFrame into a buffer string that can be easily stored in a non-code format.

    @method Serialize
    @return string
]=]
function CFrame.Serialize(self: CFrame): buffer
    local b = buffer.create(48)
    buffer.writef32(b, 0, self.X)
    buffer.writef32(b, 4, self.Y)
    buffer.writef32(b, 8, self.Z)
    buffer.writef32(b, 12, self.R00)
    buffer.writef32(b, 16, self.R01)
    buffer.writef32(b, 20, self.R02)
    buffer.writef32(b, 24, self.R10)
    buffer.writef32(b, 28, self.R11)
    buffer.writef32(b, 32, self.R12)
    buffer.writef32(b, 36, self.R20)
    buffer.writef32(b, 40, self.R21)
    buffer.writef32(b, 44, self.R22)
    return b
end

--[=[
    Deserializes a buffer string back into a CFrame.

    @return CFrame
]=]
function CFrame.Deserialize(b: buffer): CFrame
    return CFrame.new(
        buffer.readf32(b, 0),
        buffer.readf32(b, 4),
        buffer.readf32(b, 8),
        buffer.readf32(b, 12),
        buffer.readf32(b, 16),
        buffer.readf32(b, 20),
        buffer.readf32(b, 24),
        buffer.readf32(b, 28),
        buffer.readf32(b, 32),
        buffer.readf32(b, 36),
        buffer.readf32(b, 40),
        buffer.readf32(b, 44)
    )
end

function CFrame.__tostring(self: CFrame): string
    return `\{ {self.X}, {self.Y}, {self.Z}, {self.R00}, {self.R01}, {self.R02}, {self.R10}, {self.R11}, {self.R12}, {self.R20}, {self.R21}, {self.R22} }`
end

function CFrame.__index(self: CFrame, i: string)
    i = string.upper(string.sub(i, 1, 1))..string.sub(i, 2)
    if rawget(CFrame, i) then
        return rawget(CFrame, i)
    end
    if rawget(self, i) then
        return rawget(self, i)
    end

    if i == "Position" then
        return Vector3.new(self.X, self.Y, self.Z)
    elseif i == "XVector" or i == "RightVector" then
        return Vector3.new(self.R00, self.R10, self.R20)
    elseif i == "YVector" or i == "UpVector" then
        return Vector3.new(self.R01, self.R11, self.R21)
    elseif i == "ZVector" then
        return Vector3.new(self.R02, self.R12, self.R22)
    elseif i == "LookVector" then
        return -self.ZVector
    elseif i == "Rotation" or i == "Orientation" then
        return CFrame.ToOrientation(self)
    end

    return nil
end

-- math by yeno
@native
function CFrame.__mul(self: CFrame, other: CFrame | vector): CFrame
    if typeof(other) == "vector" or typeof(other) == "Vector3" then
        return CFrame.PointToWorldSpace(self, other)
    elseif typeof(other) == "table" and getmetatable(other) == CFrame then
        return CFrame.new(self.R00 * other.X + self.R01 * other.Y + self.R02 * other.Z + self.X, self.R10 * other.X + self.R11 * other.Y + self.R12 * other.Z + self.Y, self.R20 * other.X + self.R21 * other.Y + self.R22 * other.Z + self.Z,
            self.R00 * other.R00 + self.R01 * other.R10 + self.R02 * other.R20, self.R00 * other.R01 + self.R01 * other.R11 + self.R02 * other.R21, self.R00 * other.R02 + self.R01 * other.R12 + self.R02 * other.R22,
            self.R10 * other.R00 + self.R11 * other.R10 + self.R12 * other.R20, self.R10 * other.R01 + self.R11 * other.R11 + self.R12 * other.R21, self.R10 * other.R02 + self.R11 * other.R12 + self.R12 * other.R22,
            self.R20 * other.R00 + self.R21 * other.R10 + self.R22 * other.R20, self.R20 * other.R01 + self.R21 * other.R11 + self.R22 * other.R21, self.R20 * other.R02 + self.R21 * other.R12 + self.R22 * other.R22
        )
    else
        error(`Attempt to perform arithmetic mul on CFrame and {typeof(other)}`, 2)
    end
end

function CFrame.__add(self: CFrame, other: vector): CFrame
    if typeof(other) == "vector" or typeof(other) == "Vector3" then
        local components = {CFrame.GetComponents(self)}
        components[1] += other.X
        components[2] += other.Y
        components[3] += other.Z
        return CFrame.new(unpack(components, 1, #components))
    else
        error(`Attempt to perform arithmetic add on CFrame and {typeof(other)}`, 2)
    end
end

function CFrame.__sub(self: CFrame, other: vector): CFrame
    if typeof(other) == "vector" or typeof(other) == "Vector3" then
        return self + (-other)
    else
        error(`Attempt to perform arithmetic sub on CFrame and {typeof(other)}`, 2)
    end
end

--[=[
    @prop Identity CFrame
    @within CFrame
    An identity CFrame with no translation or rotation
]=]
CFrame.Identity = CFrame.new()
CFrame.identity = CFrame.Identity

NetworkEventDefinition.registerType("CFrame", CFrame)

return CFrame