--[=[
    Container class that represents a value that may or may not exist.

    @class Optional
]=]
const Optional = {}
Optional.__index = Optional
Optional.__mode = "v"

export type Optional<T = any> = typeof(setmetatable({}, Optional))

type Predicate<T> = (value: T) -> boolean

--[=[
    Returns a new `Optional` of the given value.

    @function of
    @param value T?
    @return Optional<T>
]=]
function Optional.of<T>(value: T?): Optional<T>
    return setmetatable({_value = value}, Optional)
end

const EMPTY: Optional<nil> = Optional.of(nil)

--[=[
    Returns an `Optional` of no value.

    @function empty
    @return Optional<nil>
]=]
function Optional.empty(): Optional<nil>
    return EMPTY
end

--[=[
    Returns `true` if the value is not empty.

    @method IsPresent
    @return boolean
]=]
function Optional.IsPresent<T>(self: Optional<T>): boolean
    return self._value ~= nil
end

--[=[
    Returns `true` if the value is empty.

    @method IsEmpty
    @return boolean
]=]
function Optional.IsEmpty<T>(self: Optional<T>): boolean
    return self._value == nil
end

--[=[
    Runs the given action on the value only if it is present.

    @method IfPresent
    @param action (T) -> ()
]=]
function Optional.IfPresent<T>(self: Optional<T>, action: (value: T) -> ())
    if self:IsPresent() then
        action(self._value)
    end
end

--[=[
    Runs the given action only if the value is empty.

    @method IfEmpty
    @param action () -> ()
]=]
function Optional.IfEmpty<T>(self: Optional<T>, action: () -> ())
    if self:IsEmpty() then
        action()
    end
end

--[=[
    If the value is present, runs `action`

    If the value is empty, runs `emptyAction`

    @method IfPresentOrElse
    @param action (T) -> ()
    @param emptyAction () -> ()
]=]
function Optional.IfPresentOrElse<T>(self: Optional<T>, action: (value: T) -> (), emptyAction: () -> ())
    if self:IsPresent() then
        action(self._value)
    else
        emptyAction()
    end
end

--[=[
    Returns the value if it is present, errors otherwise.

    @method Get
    @return T
]=]
function Optional.Get<T>(self: Optional<T>): T
    return self:OrElseError("No value present")
end

--[=[
    Returns the value if it is present, returns `default` otherwise.

    @method OrElse
    @param default T
    @return T
]=]
function Optional.OrElse<T>(self: Optional<T>, default: T): T
    return if self:IsPresent() then self._value else default
end

--[=[
    Returns the value if present, errors with the given message otherwise.

    @method OrElseError
    @param err string
    @return T
]=]
function Optional.OrElseError<T>(self: Optional<T>, err: string): T
    if self:IsPresent() then
        return self._value
    else
        error(if err then err else "No value present", 2)
    end
end

--[=[
    Returns the value if it is present, returns the result of `getter` otherwise.

    @method OrElseGet
    @param getter () -> T
    @return T
]=]
function Optional.OrElseGet<T>(self: Optional<T>, getter: () -> T): T
    return if self:IsPresent() then self._value else getter()
end

--[=[
    If the value is present and passes the `predicate` test, returns an `Optional` describing the value, otherwise returns an empty `Optional`

    @method Filter
    @param predicate (T) -> boolean
    @return Optional<T>
]=]
function Optional.Filter<T>(self: Optional<T>, predicate: Predicate<T>): Optional<T>
    if self:IsPresent() then
        return if predicate(self._value) then self else EMPTY
    else
        return self
    end
end

--[=[
    If the value is present, returns an `Optional` describing the value as mapped by `mapper`, otherwise returns an empty `Optional`

    @method Map
    @param mapper (T) -> V?
    @return Optional<V>
]=]
function Optional.Map<T, V>(self: Optional<T>, mapper: (value: T) -> V?): Optional<V>
    if self:IsPresent() then
        return Optional.of(mapper(self._value))
    else
        return EMPTY
    end
end

--[=[
    If the value is present, returns a mapped `Optional` provided by `mapper`, otherwise returns an empty `Optional`

    @method FlatMap
    @param mapper (T) -> Optional<V>
    @return Optional<V>
]=]
function Optional.FlatMap<T, V>(self: Optional<T>, mapper: (value: T) -> Optional<V>): Optional<V>
    if self:IsPresent() then
        return mapper(self._value)
    else
        return EMPTY
    end
end

--[=[
    If the value is present, returns this `Optional`, otherwise returns the `Optional` provided by `supplier`

    @method Or
    @param supplier () -> Optional<T>
    @return Optional<T>
]=]
function Optional.Or<T>(self: Optional<T>, supplier: () -> Optional<T>): Optional<T>
    return if self:IsPresent() then self else supplier()
end

function Optional.__tostring(self: Optional): string
    return `Optional[{self._value}]`
end

return Optional