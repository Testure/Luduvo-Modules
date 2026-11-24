--[=[
    Utility module for working with tables in a functional way.

    Written by Turing6.

    @class TableUtils
]=]
local TableUtils = {}

--[=[
    Constructs a new table of type `R` by mapping an existing source table using the supplied mapping function.

    Example:    
    ```luau
        local source = {{Name = "Hello"}, {Name = "World"}}
        local strings = TableUtils.map(source, function(v) return v.Name end)
        print(table.concat(strings, ", ")) -- prints "Hello, World"
        print(table.concat(source, ", ")) -- errors
    ```

    @function map
    @param src {T} -- Table to map
    @param mapper (T) -> R -- Mapping function that maps type `T` from the `src` table to type `R`
    @return {R}
]=]
function TableUtils.map<T, R>(src: {T}, mapper: (T) -> R): {R}
    local newTable = {}
    for i,v in pairs(src) do
        newTable[i] = mapper(v)
    end
    return newTable
end

--[=[
    Runs the given callback on each element of the given table in order.

    functional short-hand for
    ```luau
        for _,v in ipairs(src) do
            callback(v)
        end
    ```

    @function forEach
    @param src {T}
    @param callback (T) -> ()
]=]
function TableUtils.forEach<T>(src: {T}, callback: (T) -> ())
    for _,v in ipairs(src) do
        callback(v)
    end
end

--[=[
    Runs the given callback on each index of the given table in order.

    functional short-hand for
    ```luau
        for i,_ in ipairs(src) do
            callback(i)
        end
    ```

    @function forEachI
    @param src {}
    @param callback (number) -> ()
]=]
function TableUtils.forEachI(src: {any}, callback: (i: number) -> ())
    for i,_ in ipairs(src) do
        callback(i)
    end
end

return TableUtils