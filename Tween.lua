--[=[
    Module for tweening (interpolating) values.
    
    Written by Turing6. BIG thanks to [easings.net](https://easings.net)

    @class Tween
]=]
const Tween = {}

const Enum = require("./Enum")
const Promise = require("./Promise")
const CFrame = require("./CFrame")

type function valueofkey(value, key)
    local t = value:readproperty(key)

    return t
end

--[=[
    @interface EasingDirection
    @field In string -- Easing applied forwards
    @field Out string -- Easing applied in reverse
    @field InOut string -- Easing applied forwards for first half and in reverse for the second half

    Enum for easing direction.
]=]
Tween.EasingDirection = Enum.MakeEnum("EasingDirection", {"In", "Out", "InOut"} :: {In: string, Out: string, InOut: string})

--[=[
    Interval in seconds at which every tween updates.

    Lower numbers are more accurate with more tween steps but use more CPU, higher numbers use less CPU but are less accurate with less tween steps.

    Defaults to `0.001`

    @within Tween
    @prop INTERVAL number
]=]
Tween.INTERVAL = 0.001

export type EasingDirection = typeof(Tween.EasingDirection)

--[=[
    @interface EasingStyle
    @field Linear string -- Easing at a constant speed
    @field Sine string -- Uses a sine wave for easing speed
    @field Quad string -- Similar to `Sine` but with a slightly sharper curve based on quadratic interpolation
    @field Cubic string -- Similar to `Quad` but with a slightly sharper curve based on cubic interpolation
    @field Quart string -- Similar to `Cubic` but with an even sharper curve based on quartic interpolation
    @field Quint string -- Similar to `Quart` but with an even sharper curve based on quintic interpolation
    @field Expo string -- Easing at an exponential rate
    @field Circ string -- Easing follows a circular arc
    @field Back string -- Slightly overshoots target, then backs into place
    @field Elastic string -- Moves as if attached to a rubber band
    @field Bounce string -- Bounces backwards multiple times after reaching the target

    Enum for easing style.
]=]
Tween.EasingStyle = Enum.MakeEnum("EasingStyle", {
    "Linear",
    "Sine",
    "Quad",
    "Cubic",
    "Quart",
    "Quint",
    "Expo",
    "Circ",
    "Back",
    "Elastic",
    "Bounce"
} :: {
    Linear: string,
    Sine: string,
    Quad: string,
    Cubic: string,
    Quart: string,
    Quint: string,
    Expo: string,
    Circ: string,
    Back: string,
    Elastic: string,
    Bounce: string
})

export type EasingStyle = typeof(Tween.EasingStyle)

type EasingFunction = (v0: number, v1: number, t: number) -> number

const EASING_FUNCTIONS: {[string]: EasingFunction} = {}

function lerp(v0: number, v1: number, t: number): number
    return (1 - t) * v0 + t * v1
end

EASING_FUNCTIONS.LinearInOut = lerp
EASING_FUNCTIONS.LinearIn = lerp
EASING_FUNCTIONS.LinearOut = lerp

function EASING_FUNCTIONS.SineIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, 1 - math.cos((t * math.pi) * 0.5))
end

function EASING_FUNCTIONS.SineOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, math.sin((t * math.pi) * 0.5))
end

function EASING_FUNCTIONS.SineInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, -(math.cos(math.pi * t) - 1) * 0.5)
end

function EASING_FUNCTIONS.QuadIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, t * t)
end

function EASING_FUNCTIONS.QuadOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, 1 - (1 - t) * (1 - t))
end

function EASING_FUNCTIONS.QuadInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t < 0.5 then 2 * t * t else 1 - math.pow(-2 * t + 2, 2) * 0.5)
end

function EASING_FUNCTIONS.CubicIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, t * t * t)
end

function EASING_FUNCTIONS.CubicOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, 1 - math.pow(1 - t, 3))
end

function EASING_FUNCTIONS.CubicInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t < 0.5 then 4 * t * t * t else 1 - math.pow(-2 * t + 2, 3) * 0.5)
end

function EASING_FUNCTIONS.QuartIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, t * t * t * t)
end

function EASING_FUNCTIONS.QuartOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, 1 - math.pow(1 - t, 4))
end

function EASING_FUNCTIONS.QuartInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t < 0.5 then 8 * t * t * t * t else 1 - math.pow(-2 * t + 2, 4) * 0.5)
end

function EASING_FUNCTIONS.QuintIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, t * t * t * t * t)
end

function EASING_FUNCTIONS.QuintOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, 1 - math.pow(1 - t, 5))
end

function EASING_FUNCTIONS.QuintInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t < 0.5 then 16 * t * t * t * t * t else 1 - math.pow(-2 * t + 2, 5) * 0.5)
end

function EASING_FUNCTIONS.ExpoIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t == 0 then 0 else math.pow(2, 10 * t - 10))
end

function EASING_FUNCTIONS.ExpoOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t == 1 then 1 else 1 - math.pow(2, -10 * t))
end

function EASING_FUNCTIONS.ExpoInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t == 0 then 0 else if t == 1 then 1 else if t < 0.5 then math.pow(2, 20 * t - 10) * 0.5 else (2 - math.pow(2, -20 * t + 10)) * 0.5)
end

function EASING_FUNCTIONS.CircIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, 1 - math.sqrt(1 - math.pow(t, 2)))
end

function EASING_FUNCTIONS.CircOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, math.sqrt(1 - math.pow(t - 1, 2)))
end

function EASING_FUNCTIONS.CircInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t < 0.5 then (1 - math.sqrt(1 - math.pow(2 * t, 2))) * 0.5 else (math.sqrt(1 - math.pow(-2 * t + 2, 2)) + 1) * 0.5)
end

const C1 = 1.70158
const C2 = C1 * 1.525
const C3 = C1 + 1
const C4 = (2 * math.pi) / 3
const C5 = (2 * math.pi) / 4.5
const N1 = 7.5625
const D1 = 2.75

function EASING_FUNCTIONS.BackIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, C3 * t * t * t - C1 * t * t)
end

function EASING_FUNCTIONS.BackOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, 1 + C3 * math.pow(t - 1, 3) + C1 * math.pow(t - 1, 2))
end

function EASING_FUNCTIONS.BackInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t < 0.5 then (math.pow(2 * t, 2) * ((C2 + 1) * 2 * t - C2)) * 0.5 else (math.pow(2 * t - 2, 2) * ((C2 + 1) * (t * 2 - 2) + C2) + 2) * 0.5)
end

function EASING_FUNCTIONS.ElasticIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t == 0 then 0 else if t == 1 then 1 else -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * C4))
end

function EASING_FUNCTIONS.ElasticOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t == 0 then 0 else if t == 1 then 1 else math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * C4) + 1)
end

function EASING_FUNCTIONS.ElasticInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t == 0 then 0 else if t == 1 then 1 else if t < 0.5 then -(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * C5)) * 0.5 else (math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * C5)) / 2 + 1)
end

function bounceOutVal(t: number): number
    if t < 1 / D1 then
        return N1 * t * t
    elseif t < 2 / D1 then
        t -= 1.5 / D1
        return N1 * t * t + 0.75
    elseif t < 2.5 / D1 then
        t -= 2.25 / D1
        return N1 * t * t + 0.9375
    else
        t -= 2.625 / D1
        return N1 * t * t + 0.984375
    end
end

function EASING_FUNCTIONS.BounceIn(v0: number, v1: number, t: number): number
    return lerp(v0, v1, 1 - bounceOutVal(1 - t))
end

function EASING_FUNCTIONS.BounceOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, bounceOutVal(t))
end

function EASING_FUNCTIONS.BounceInOut(v0: number, v1: number, t: number): number
    return lerp(v0, v1, if t < 0.5 then (1 - bounceOutVal(1 - 2 * t)) * 0.5 else (1 + bounceOutVal(2 * t - 1)) * 0.5)
end

type Tweenable = number | vector | CFrame.CFrame | UDim | UDim2

function tweenValue(value: Tweenable, goal: Tweenable, t: number, method: EasingFunction): Tweenable
    if typeof(value) == "number" then
        return method(value, goal, t)
    elseif typeof(value) == "vector" then
        return vector.create(method(value.X, goal.X, t), method(value.Y, goal.Y, t), method(value.Z, goal.Z, t))
    elseif typeof(value) == "Vector2" then
        return Vector2.new(method(value.X, goal.X, t), method(value.Y, goal.Y, t))
    elseif typeof(value) == "Vector3" then
        return Vector3.new(method(value.X, goal.X, t), method(value.Y, goal.Y, t), method(value.Z, goal.Z, t))
    elseif typeof(value) == "Color3" then
        return Color3.new(method(value.R, goal.R, t), method(value.G, goal.G, t), method(value.B, goal.B, t))
    elseif typeof(value) == "UDim" then
        return UDim.new(method(value.Scale, goal.Scale, t), method(value.Offset, goal.Offset, t))
    elseif typeof(value) == "UDim2" then
        return UDim2.new(method(value.X.Scale, goal.X.Scale, t), method(value.X.Offset, goal.X.Offset, t), method(value.Y.Scale, goal.Y.Scale, t), method(value.Y.Offset, goal.Y.Offset, t))
    elseif CFrame.is(value) then
        local components = {value:GetComponents()}
        local goals = {goal:GetComponents()}
        
        for i = 1, #components do
            components[i] = method(components[i], goals[i], t)
        end

        return CFrame.new(unpack(components, 1, #components))
    end
    error(`Attempt to tween untweenable value '{typeof(value)}'`, 2)
end

--[=[
    Tweens (interpolates) a property of the given object between it's current value and a goal value over time.

    @function tween
    @param object Instance | {[string]: any} -- The object containing the property to tween
    @param property string -- The name of the property to tween
    @param goal: typeof<object.property> -- The value the the property will be at the end of the tween. Supported types are: `number`, `vector`, `UDim`, `UDim2`, and `CFrame`
    @param time: number? -- Length of the tween in seconds. Defaults to `1`
    @param style EasingStyle -- Easing method to use for the tween. Defaults to `Linear`
    @param direction EasingDirection -- Direction of the easing. Defaults to `InOut`
    @return Promise -- A Promise that resolves when the tween finishes and cancels the tween when cancelled.
]=]
function Tween.tween<T, K>(object: Instance | T, property: K, goal: valueofkey<T, K>, t: number?, style: EasingStyle?, direction: EasingDirection?): Promise.Promise<()>
    t = if t then t else 1
    direction = if direction then direction else Tween.EasingDirection.InOut
    style = if style then style else Tween.EasingStyle.Linear

    if typeof(object) ~= "Instance" and typeof(object) ~= "table" then
        error(`Attempt to tween property of invalid object! expected 'table' or 'Instance', got '{typeof(object)}'`, 2)
    end
    if typeof(property) ~= "string" then
        error(`Invalid property argument! expected 'string' got '{typeof(property)}'`, 2)
    end
    if not object[property] then
        error(`Attempt to tween invalid property '{property}'! property does not exist!`, 2)
    end
    if typeof(goal) ~= typeof(object[property]) then
        error(`Property type mismatch! property is '{typeof(object[property])}' while tween goal is '{typeof(goal)}'`, 2)
    end
    
    return Promise.new(function(resolve: () -> (), reject: () -> (), onCancel: (cancelHandler: () -> ()) -> ())
        local canceled = false
        local start = object[property]
        local s = 0
        local method = EASING_FUNCTIONS[style .. direction]

        onCancel(function()
            canceled = true
        end)

        while not canceled and s < t do
            object[property] = tweenValue(start, goal, s / t, method)
            s += Tween.INTERVAL
            task.wait(Tween.INTERVAL)
        end

        resolve()
    end)
end

return Tween