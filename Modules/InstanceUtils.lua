--[=[
    Module for cleaner handling of instances

    @class InstanceUtils
]=]
const InstanceUtils = {}

const CFrame = require("./CFrame")

--[=[
    Ensures that the given instance has the given component, adding it only if absent, then returns the instance.

    @function addComponent
    @param part Instance -- The instance to modify
    @param component string | Pair -- The component to add
    @return Instance -- `part`
]=]
function InstanceUtils.addComponent(part: Instance, component: string | Pair): Instance
    local success, msg = pcall(function()
        if not part:HasComponent(component) then
            part:AddComponent(component)
        end
    end)

    if not success then
        error(msg, 2)
    end

    return part
end

--[=[
    Ensures that the given instance does not have the given component, removing it only if present, then returns the instance.

    @function addComponent
    @param part Instance -- The instance to modify
    @param component string -- The component to remove
    @return Instance -- `part`
]=]
function InstanceUtils.removeComponent(part: Instance, component: string | Pair): Instance
    local success, msg = pcall(function()
        if part:HasComponent(component) then
            part:RemoveComponent(component)
        end
    end)

    if not success then
        error(msg, 2)
    end

    return part
end

--[=[
    Sets the transparency of the given instance, adding a transparency component if it doesn't have one already, then returns the instance.

    @function setTransparency
    @param part Instance -- The instance to modify
    @param transparency number
    @return Instance -- `part`
]=]
function InstanceUtils.setTransparency(part: Instance, transparency: number): Instance
    InstanceUtils.addComponent(part, "Transparency").Transparency = math.clamp(transparency, 0, 1)

    return part
end

--[=[
    Sets the anchored property of the given instance, adding or removing the `Anchored` component accordingly, then returns the instance.

    @function setAnchored
    @param part Instance -- the instance to modify
    @param anchored boolean
    @return Instance -- `part`
]=]
function InstanceUtils.setAnchored(part: Instance, anchored: boolean): Instance
    if anchored then
        InstanceUtils.addComponent(part, "Anchored").Anchored = true
        return part
    else
        return InstanceUtils.removeComponent(part, "Anchored")
    end
end

--[=[
    Creates a new part instance parented to `game.World` with a set of the components required for a basic part.

    The new part will have:
    - Transform component
    - Shape component
    - Color component
    - Material component

    @function newPart
    @param name string -- Part name
    @param position (vector | CFrame)? -- Optional part position
    @param color vector? -- Optional part color
    @param material string? -- Optional part material
    @param shape EnumShapeType? -- Optional part shape
    @return Instance -- The created part
]=]
function InstanceUtils.newPart(name: string, position: (vector | CFrame.CFrame)?, color: vector?, material: string?, shape: EnumShapeType?): Instance
    local part = Instance.new()
    part.Name = name

    part:AddComponent("Shape")
    part:AddComponent("Position")
    part:AddComponent("Color")
    part:AddComponent("Material")

    if position then
        if CFrame.is(position) then
            position:ToInstance(part)
        else
            part.Position = position
        end
    end

    if color then
        part.Color = color
    end

    if material then
        part.Material = material
    end

    if shape then
        part.Shape.Type = shape
    end

    part.Parent = game.World

    return part
end

--[=[
    Adds a `Weld` component to `a` and welds it to `b`, then returns `a`.

    If `forceLimit` or `torqueLimit` are supplied, a `WeldBreak` component will be added.

    @function weld
    @param a Instance
    @param b Instance
    @param forceLimit number? -- amount of force required to break the weld, defaults to `0` (will never break from force)
    @param torqueLimit number? -- amount of torque required to break the weld, defaults to `0` (will never break from torque)
    @return Instance `a`
]=]
function InstanceUtils.weld(a: Instance, b: Instance, forceLimit: number?, torqueLimit: number?): Instance
    InstanceUtils.addComponent(a, "Weld").Other = b
    if forceLimit or torqueLimit then
        InstanceUtils.addComponent(a, "WeldBreak")
        a.WeldBreak.BreakForce = if forceLimit then forceLimit else 0
        a.WeldBreak.BreakTorque = if torqueLimit then torqueLimit else 0
    end
    return a
end

--[=[
    Creates a new part who's position, rotation, and size visually represent a raycast of the given parameters.

    @function partFromRay
    @param pos vector -- Ray position
    @param dir vector -- Ray direction
    @param distance number -- Ray length
    @param name string -- Part name
    @param transparency number? -- Part transparency, defaults to `0.5`
    @param color vector? -- Part color
    @param material string? -- Part material
    @return Instance -- The created part
]=]
function InstanceUtils.partFromRay(pos: vector, dir: vector, distance: number, name: string, transparency: number?, color: vector?, material: string?): Instance
    transparency = if transparency then transparency else 0.5
    dir *= distance

    local part = InstanceUtils.setTransparency(InstanceUtils.newPart(name, CFrame.lookAt(pos + dir/2, pos + dir), color, material, game.Enum.ShapeType.Box), transparency)

    part.Size = Vector3.new(0.1, 0.1, dir.Magnitude)

    return part
end

--[=[
    Performs a shapecast with the same position, rotation, size, and shape as the given part.

    @function shapecast
    @param part Instance -- Part who's bounds will be used for the shapecast
    @param params QueryParams? -- Query parameters for the shapecast
    @param out {ShapecastHit}? -- Existing table to output results to, a new table will be allocated if absent
    @return number, {ShapecastHit} -- Number of hits found, Table of hits
]=]
function InstanceUtils.shapecast(part: Instance, params: QueryParams?, out: {ShapecastHit}?): (number, {ShapecastHit})
    local success, hit, instances = pcall(game.Physics.Shapecast, part.Shape.Type, part.Size, part.Position - (part.Size * 0.5), part.Position + (part.Size * 0.5), part.Orientation, out, params)
    
    if not success then
        error(hit, 2)
    else
        return hit, instances
    end
end

--[=[
    Performs a raycast from the given position towards the given instance's location.

    @function raycastTo
    @param part Instance -- Instance to raycast towards
    @param position vector -- Position to raycast from
    @param distance number -- Length of the ray
    @param params QueryParams? -- Parameters for the raycast
    @return RaycastResult?
]=]
function InstanceUtils.raycastTo(part: Instance, position: vector, distance: number, params: QueryParams?): RaycastResult?
    return game.Physics.Raycast(position, (part.Position - position).Unit, distance, params)
end

return InstanceUtils