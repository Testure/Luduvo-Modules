--!strict
--[=[
    A class representing a linear stream of elements of a single type.

    Written by Turing6.

    @class Stream
]=]
const Stream = {}
Stream.__index = Stream
Stream.__mode = "v"

const Optional = require("./Optional")

type StreamInternal<T = any> = {
    _elements: {T}
}

export type Stream<T = any> = typeof(setmetatable({}, Stream))

type Self<T = any> = Stream<T> & StreamInternal<T>

type Predicate<T> = (value: T) -> boolean
type Comparator<T> = (a: T, b: T) -> number
type Consumer<T> = (value: T) -> ()
type Function<T, R> = (T) -> R

--[=[
    Creates a new `Stream` containing the elements of the given table.

    @function new
    @param elements {T}
    @return Stream<T>
]=]
function Stream.new<T>(elements: {T}): Stream<T>
    return setmetatable({_elements = elements}, Stream)
end

--[=[
    Creates a new `Stream` containing the given values.

    @function of
    @param ... ...T -- Values 
    @return Stream<T>
]=]
function Stream.of<T>(...: T): Stream<T>
    return Stream.new({...})
end

--[=[
    Returns a new empty `Stream`

    @function empty
    @return Stream
]=]
function Stream.empty<T>(): Stream<T>
    return Stream.new({})
end

--[=[
    Collects the elements of this stream into a table, optionally using a `collector` function.
    
    @method Collect
    @param collector (({T}) -> R)?
    @return R -- Table of elements
]=]
function Stream.Collect<T, R>(self: Self<T>, collector: Function<{T}, R>?): R
    if collector then
        return collector(self._elements)
    else
        return table.clone(self._elements)
    end
end

--[=[
    Returns the number of elements in this `Stream`

    @method Count
    @return number
]=]
function Stream.Count<T>(self: Self<T>): number
    return #self._elements
end

--[=[
    Returns an `Optional` describing the first value in this `Stream`

    @method FindFirst
    @return Optional<T>
]=]
function Stream.FindFirst<T>(self: Self<T>): Optional.Optional<T>
    if self:Count() > 0 then
        return Optional.of(self._elements[1])
    else
        return Optional.empty()
    end
end

--[=[
    Returns `true` if any of the elements in this `Stream` pass the `predicate` test.

    @method AnyMatch
    @param predicate (T) -> boolean
    @return boolean
]=]
function Stream.AnyMatch<T>(self: Self<T>, predicate: Predicate<T>): boolean
    for _,v: T in self._elements do
        if predicate(v) then
            return true
        end
    end
    return false
end

--[=[
    Returns `true` if no elements in this `Stream` pass the `predicate` test.

    @method NoneMatch
    @param predicate (T) -> boolean
    @return boolean
]=]
function Stream.NoneMatch<T>(self: Self<T>, predicate: Predicate<T>): boolean
    for _,v: T in self._elements do
        if predicate(v) then
            return false
        end
    end
    return true
end

--[=[
    Returns `true` if all elements in this `Stream` pass the `predicate` test.

    @method AllMatch
    @param predicate (T) -> boolean
    @return boolean
]=]
function Stream.AllMatch<T>(self: Self<T>, predicate: Predicate<T>): boolean
    for _,v: T in self._elements do
        if not predicate(v) then
            return false
        end
    end
    return true
end

--[=[
    Returns an `Optional` defining the minimum element in this stream as determined by `comparator`

    @method Min
    @param comparator (a: T, b: T) -> number
    @return Optional<T>
]=]
function Stream.Min<T>(self: Self<T>, comparator: Comparator<T>): Optional.Optional<T>
    local min = nil
    for _,v: T in self._elements do
        if not min or comparator(min, v) < 0 then
            min = v
        end
    end
    return Optional.of(min)
end

--[=[
    Returns an `Optional` defining the maximum element in this stream as determined by `comparator`

    @method Max
    @param comparator (a: T, b: T) -> number
    @return Optional<T>
]=]
function Stream.Max<T>(self: Self<T>, comparator: Comparator<T>): Optional.Optional<T>
    local max = nil
    for _,v: T in self._elements do
        if not max or comparator(max, v) > 0 then
            max = v
        end
    end
    return Optional.of(max)
end

--[=[
    Returns a copy of this `Stream` limited to `limit` entries.

    @method Limit
    @param limit number -- Maximum number of elements
    @return Stream<T>
]=]
function Stream.Limit<T>(self: Self<T>, limit: number): Stream<T>
    limit = math.max(limit, 0)
    if limit == 0 then
        return Stream.empty()
    else
        local copy = table.create(limit)

        for i = 1, limit do
            table.insert(copy, self._elements[i])
        end

        return Stream.new(copy)
    end
end

--[=[
    Returns a new `Stream` who's contents are the contents of this `Stream` starting at index `n`

    @method Skip
    @param n number -- Number of elements to skip
    @return Stream<T>
]=]
function Stream.Skip<T>(self: Self<T>, n: number): Stream<T>
    n = math.min(math.max(n, 0), self:Count())
    if n == 0 then return self end
    local copy: {T} = table.create(self:Count() - n)
    
    for i = n, self:Count() do
        table.insert(copy, self._elements[i])
    end

    return Stream.new(copy)
end

--[=[
    Runs the given `consumer` on each element in this `Stream`, then returns this `Stream`

    @method ForEach
    @param consumer (T) -> ()
    @return Stream
]=]
function Stream.ForEach<T>(self: Self<T>, consumer: Consumer<T>): Stream<T>
    for _,v: T in self._elements do
        consumer(v)
    end
    return self
end

local function basicComparator(a: any, b: any): number
    return if a < b then -1 else if a > b then 1 else 0
end

--[=[
    Sorts the elements of this `Stream` according to the given `comparator`, then returns this `Stream`

    A comparator should conform to the standard of returning -1 if a < b, 1 if a > b or 0 if a == b

    A basic comparator implementation is as follows:
    ```lua
        function(a, b)
            if a < b then
                return -1
            elseif a > b then
                return 1
            else
                return 0
            end
        end
    ```

    If no comparator is provided the one described above will be used.

    If this `Stream` contains a type that does not support comparison operators, a custom comparator must be provided.

    @method Sort
    @param comparator ((a: T, b: T) -> number)?
    @return Stream<T>
]=]
function Stream.Sort<T>(self: Self<T>, comparator: Comparator<T>?): Stream<T>
    comparator = (if comparator then comparator else basicComparator)

    table.sort(self._elements, function(a0: T, a1: T): boolean
        return (comparator :: Comparator<T>)(a0, a1) < 0 
    end)

    return self
end

--[=[
    Returns a new `Stream` that contains only the elements of this `Stream` which are distinct (that is they do not equal any other element in this `Stream`).

    @method Distinct
    @return Stream<T>
]=]
function Stream.Distinct<T>(self: Self<T>): Stream<T>
    if self:Count() == 0 then
        return Stream.empty() 
    end
    local copy = {}

    for _,v: T in self._elements do
        local distinct = true
        for _,a: T in copy do
            if a == v then
                distinct = false
                break
            end
        end
        if distinct then
            table.insert(copy, v)
        end
    end

    return Stream.new(copy)
end

--[=[
    Returns a new `Stream` that contains only the elements of this `Stream` that pass the `predicate` test.

    @method Filter
    @param predicate (T) -> boolean
    @return Stream<T>
]=]
function Stream.Filter<T>(self: Self<T>, predicate: Predicate<T>): Stream<T>
    local copy = {}

    for _,v: T in self._elements do
        if predicate(v) then
            table.insert(copy, v)
        end
    end

    return Stream.new(copy)
end

--[=[
    Returns a new `Stream` containing the mapped values of this `Stream` as according to the given `mapper`

    @method Map
    @param mapper (T) -> R
    @return Stream<R>
]=]
function Stream.Map<T, R>(self: Self<T>, mapper: Function<T, R>): Stream<R>
    local copy: {R} = table.create(self:Count())

    for _,v: T in self._elements do
        table.insert(copy, mapper(v))
    end

    return Stream.new(copy)
end

--[=[
    Closes this `Stream`, clearing it's elements and rendering it unusable.

    @method Close
]=]
function Stream.Close<T>(self: Stream<T>)
    self._elements = nil
end

return Stream