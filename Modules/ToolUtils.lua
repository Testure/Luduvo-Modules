--[=[
    Module that provides functions for handling tools.

    Written by Turing6.

    @class ToolUtils
]=]
const ToolUtils = {}

const Promise = require("./Promise")

const TOOL_TAG = game.World.Pair("Tag", "Tool")
const CHARACTER_PARTS = {
    "Right Arm",
    "Left Arm",
    "Head",
    "Torso",
    "Right Leg",
    "Left Leg"
}

--[=[
    Equips the given tool.

    @function equipTool
    @param character Instance
    @param tool Instance | string -- Either the tool instance to equip or the name of the tool to equip
    @return boolean -- If the tool was successfully equipped
]=]
function ToolUtils.equipTool(character: Instance, tool: Instance | string): boolean
    if not character or not character:HasComponent("Character") then error(`Invalid argument #1 to ToolUtils.equipTool! expected Character Instance got '{typeof(character)}'`, 2) end
    if not tool or (typeof(tool) ~= "string" and typeof(tool) ~= "Instance") then error(`Invalid argument #2 to ToolUtils.equipTool! expected Instance or string got '{typeof(tool)}'`, 2) end

    local toolInstance: Instance = nil

    if typeof(tool) == "Instance" then
        toolInstance = tool
    else
        toolInstance = character:FindFirstChild(tool)
        if not toolInstance then return false end
    end
    
    local grip = toolInstance.attr.ToolGripHand
    if not grip then
        grip = 0
    end

    local part = character:FindFirstChild(CHARACTER_PARTS[grip + 1])
    if part then
        toolInstance.Parent = part
        return true
    end
    return false
end

--[=[
    Unequips the given tool, putting it back in the players backpack.

    @function unequipTool
    @param character Instance
    @param tool Instance | string -- Either the tool instance to unequip or the name of the tool to unequip
    @return boolean -- If the tool was successfully unequipped
]=]
function ToolUtils.unequipTool(character: Instance, tool: Instance | string): boolean
    if not character or not character:HasComponent("Character") then error(`Invalid argument #1 to ToolUtils.unequipTool! expected Character Instance got '{typeof(character)}'`, 2) end
    if not tool or (typeof(tool) ~= "string" and typeof(tool) ~= "Instance") then error(`Invalid argument #2 to ToolUtils.unequipTool! expected Instance or string to '{typeof(tool)}'`, 2) end

    local toolInstance = nil
    
    if typeof(tool) == "Instance" then
        toolInstance = tool
    else
        toolInstance = character:FindFirstChild(tool, true)
    end

    if toolInstance then
        toolInstance.Parent = character
        return true
    end
    return false
end

--[=[
    Removes the given tool from the character, removing it from their backpack entirely.

    @function removeTool
    @param character Instance
    @param tool Instance | string -- Either the tool instance to remove or the name of the tool to remove
    @return boolean -- If the tool was successfully removed
]=]
function ToolUtils.removeTool(character: Instance, tool: Instance | string): boolean
    if not character or not character:HasComponent("Character") then error(`Invalid argument #1 to ToolUtils.removeTool! expected Character Instance got '{typeof(character)}'`, 2) end
    if not tool or (typeof(tool) ~= "string" and typeof(tool) ~= "Instance") then error(`Invalid argument #2 to ToolUtils.removeTool! expected Instance or string to '{typeof(tool)}'`, 2) end

    local toolInstance = nil
    
    if typeof(tool) == "Instance" then
        toolInstance = tool
    else
        toolInstance = character:FindFirstChild(tool, true)
    end

    if toolInstance then
        toolInstance:Destroy()
        return true
    end
    return false
end

--[=[
    Unequips all tools the player has equipped.

    @function unequipTools
    @param character Instance
]=]
function ToolUtils.unequipTools(character: Instance)
    if not character or not character:HasComponent("Character") then error(`Invalid argument #1 to ToolUtils.unequipTools! expected Character Instance got '{typeof(character)}'`, 2) end

    for _,part in CHARACTER_PARTS do
        local p = character:FindFirstChild(part)
        if p then
            for _,v in p:GetChildren() do
                v.Parent = character
            end
        end
    end
end

--[=[
    Connects a signal to the given character that causes them to have both equip and unequip animations for holding tools in both the left and right arms.

    The signal may be disconnected manually, but is automatically disconnected when the character dies.

    @function handleCharacterHoldAnimation
    @param character Instance
    @return SignalConnection
]=]
function ToolUtils.handleCharacterHoldAnimations(character: Instance): SignalConnection
    local rightArm = character:WaitForChild("Right Arm")
    local leftArm = character:WaitForChild("Left Arm")

    local connection: SignalConnection = {_events = {}, Connected = true, Disconnect = function(self: SignalConnection)
        self.Connected = false
        character.AnimLayers[7] = nil
        character.AnimLayers[8] = nil
        for _,v in self._events do
            v:Disconnect()
        end
        if rightArm:HasComponent("LimbPose") then
            rightArm.LimbPose.Rotation = Vector3.zero
        end
        if leftArm:HasComponent("LimbPose") then
            leftArm.LimbPose.Rotation = Vector3.zero
        end
    end}

    table.insert(connection._events, character:GetPropertyChangedSignal("State"):Connect(function()
        if character.HumanoidState.State == "Dead" then
            connection:Disconnect()
        end
    end))

    table.insert(connection._events, rightArm.ChildAdded:Connect(function(child: Instance)
        if child:HasComponent(TOOL_TAG) then
            if character.AnimLayers[7] == nil then
                character.AnimLayers[7] = {
                    clip = "idle",
                    loop = true,
                    speed = 0,
                    weight = 1,
                    mask = game.Animation.Part.RightArm
                }
            end
            if not rightArm:HasComponent("LimbPose") then
                rightArm:AddComponent("LimbPose")
            end

            while rightArm.LimbPose.Rotation.X < 90 do
                if rightArm.LimbPose.Rotation.X >= 75 then
                    rightArm.LimbPose.Rotation = Vector3.new(90)
                    break
                end
                task.wait(0.01)
                rightArm.LimbPose.Rotation += Vector3.new(15)
            end
        end
    end))
    table.insert(connection._events, leftArm.ChildAdded:Connect(function(child: Instance)
        if child:HasComponent(TOOL_TAG) then
            if character.AnimLayers[8] == nil then
                character.AnimLayers[8] = {
                    clip = "idle",
                    loop = true,
                    speed = 0,
                    weight = 1,
                    mask = game.Animation.Part.LeftArm
                }
            end
            if not leftArm:HasComponent("LimbPose") then
                leftArm:AddComponent("LimbPose")
            end

            while leftArm.LimbPose.Rotation.X < 90 do
                if leftArm.LimbPose.Rotation.X >= 75 then
                    leftArm.LimbPose.Rotation = Vector3.new(90)
                    break
                end
                task.wait(0.01)
                leftArm.LimbPose.Rotation += Vector3.new(15)
            end
        end
    end))

    table.insert(connection._events, rightArm.ChildRemoved:Connect(function(child: Instance)
        local success = pcall(function()
            local _ = child.Name
        end)
        if not success or child:HasComponent(TOOL_TAG) then
            character.AnimLayers[7] = nil
            if rightArm:HasComponent("LimbPose") then
                rightArm.LimbPose.Rotation = Vector3.zero
            end
        end
    end))
    table.insert(connection._events, leftArm.ChildRemoved:Connect(function(child: Instance)
        local success = pcall(function()
            local _ = child.Name
        end)
        if not success or child:HasComponent(TOOL_TAG) then
            character.AnimLayers[8] = nil
            if leftArm:HasComponent("LimbPose") then
                leftArm.LimbPose.Rotation = Vector3.zero
            end
        end
    end))

    return connection
end

--[=[
    Performs a classic style swingging animation on the characters arm.

    This function assumes the character is already doing a hold animation.

    @function doSwingAnimation
    @param character Instance
    @param leftArm (boolean | Instance)? -- If true the left arm will be used instead of the right arm. If the tool instance is given, the proper arm will be used based on the tool's attributes
    @return Promise
]=]
function ToolUtils.doSwingAnimation(character: Instance, leftArm: (boolean | Instance)?): Promise.Promise<()>
    if not character or not character:HasComponent("Character") then error(`Invalid argument #1 to ToolUtils.doSwingAnimation! expected Character Instance got '{typeof(character)}'`, 2) end
    if typeof(leftArm) == "Instance" then
        if leftArm.attr.ToolGripHand then
            leftArm = leftArm.attr.ToolGripHand == 1
        else
            leftArm = false
        end
    end
    return Promise.new(function(resolve: () -> (), reject: () -> (), onCancel: (cancelHandler: () -> ()) -> ())
        if character.AnimLayers[if leftArm then 8 else 7] == nil then
            warn("Swing animation attempted on character who lacks the proper AnimLayer! this is a mistake.")
            reject()
            return
        end

        local canceled = false
        local part = if leftArm then character:FindFirstChild("Left Arm") else character:FindFirstChild("Right Arm")

        if not part then
            warn("Could not find body part for swing animation!")
            reject()
            return
        end

        onCancel(function()
            canceled = true
        end)

        while not canceled and part.LimbPose.Rotation.X > 0 do
            if part.LimbPose.Rotation.X <= 15 then
                part.LimbPose.Rotation = Vector3.zero
                break
            end
            task.wait(0.025)
            part.LimbPose.Rotation -= Vector3.new(15)
        end

        if not canceled then
            task.wait(0.01)
        end

        while part.LimbPose.Rotation.X < 90 do
            if part.LimbPose.Rotation.X >= 75 then
                part.LimbPose.Rotation = Vector3.new(90)
                break
            end
            task.wait(0.01)
            part.LimbPose.Rotation += Vector3.new(15)
        end

        resolve()
    end)
end

export type ToolStats = {
    ToolGripHand: number,
    ToolGripOffset: vector,
    ToolGripRotation: vector,
    ToolNoDrop: boolean
}

const DEFAULT_TOOL_STATS: ToolStats = {
    ToolGripHand = 0,
    ToolNoDrop = false,
    ToolGripRotation = Vector3.zero,
    ToolGripOffset = Vector3.zero
}

--[=[
    Returns the given part after adding the necessary tag and attributes to make it a valid tool.
    
    The optional `stats` parameter determines the tool's starting attributes.

    @function makeToolFrom
    @type ToolStats
    @param part Instance
    @param stats ToolStats?
    @return Instance
]=]
function ToolUtils.makeToolFrom(part: Instance, stats: ToolStats?): Instance
    stats = if stats then stats else DEFAULT_TOOL_STATS

    part.attr.ToolEquipped = false
    part.attr.ToolGripHand = stats.ToolGripHand
    part.attr.ToolNoDrop = stats.ToolNoDrop
    part.attr.ToolGripRotation = stats.ToolGripRotation
    part.attr.ToolGripOffset = stats.ToolGripOffset
    part:AddComponent(TOOL_TAG)

    return part
end

return ToolUtils