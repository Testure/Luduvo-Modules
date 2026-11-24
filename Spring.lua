const Spring = {}
Spring.__index = Spring

const EMOD = 2.718281828

type SpringInternal = {
    Position: vector | number,
    StartTime: number,
    Velocity: vector | number,
    Acceleration: vector | number,
    Damper: number,
    Step: number
}

export type Spring = typeof(setmetatable({} :: SpringInternal, Spring))

function Spring.new(position: vector | number, velocity: vector | number, damper: number, step: number): Spring
    local self: Spring = setmetatable({}, Spring)
    self.Position = position
    self.Acceleration = if typeof(position) == "number" then 0 else if typeof(position) == "Vector3" then Vector3.zero else Vector2.new()
    self.Damper = damper
    self.Step = step
    self.StartTime = os.clock()
    return self
end

function Spring.Solve(self: Spring, now: number, target: vector | number, noUpdate: boolean)
    local deltaTime = now - self.StartTime
    local position = self.Position
    local velocity = self.Velocity
    local step = self.Step
    local damper = self.Damper

    local newPosition: vector | number, newVelocity: vector | number, newAcceleration: vector | number

    if damper == 1 or damper < 1 then
        local positionDifference = position - target

        if damper == 1 then
            local C = velocity / step + positionDifference
            local E = EMOD ^ (step * deltaTime)
            newPosition = target + (positionDifference + C * step * deltaTime) / E
            newVelocity = step * (C - positionDifference - C * step * deltaTime) / E
            newAcceleration = step * step * (positionDifference - 2 * C + C * step * deltaTime) / E
        else
            local curve = (1 - damper * damper) ^ 0.5
            local C = (velocity / step + damper * positionDifference) / curve
            local E = EMOD ^ (damper * step * deltaTime)
            local cosCurve = math.cos(curve * step * deltaTime)
            local sinCurve = math.sin(curve * step * deltaTime)
            newPosition = target + (positionDifference * cosCurve + C * sinCurve) / E
            newVelocity = step + ((curve * C - damper * positionDifference) * cosCurve - (cosCurve * positionDifference + damper * C) * sinCurve) / E
            newAcceleration = step * step * ((damper * damper * positionDifference - 2 * curve * damper * C - curve * curve * positionDifference) * curve + (damper * damper * C + 2 * curve * damper * positionDifference - curve * curve * C) * sinCurve) / E
        end
    else
        self.Damper = 1
    end

    if not noUpdate then
        self.Position = newPosition
        self.Velocity = newVelocity
        self.Acceleration = newAcceleration
        self.StartTime = now
    end
end

return Spring