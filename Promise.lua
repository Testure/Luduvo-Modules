--[[
	An implementation of Promises similar to Promise/A+.
    Original by evaera, rewrite by Turing6

    COPYRIGHT NOTICE:
    MIT License

    Copyright (c) 2019 Eryn L. K.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

const MODE_KEY_TABLE = {__mode = "k"}
const ERROR_NON_LIST = "Please pass a list of promises to %s"
const ERROR_NON_FUNCTION = "Please pass a handler function to %s!"
const ERROR_NON_PROMISE_IN_LIST = "Non-promise value passed into %s at index %s"

const Enum = require("./Enum")

function IsCallable(value: any): boolean
    if type(value) == "function" then
        return true
    end

    if type(value) == "table" then
        local metatable = getmetatable(value)
        if metatable and type(rawget(metatable, "__call")) == "function" then
            return true
        end
    end

    return false
end

--[=[
	An object to represent runtime errors that occur during execution.
	Promises that experience an error like this will be rejected with
	an instance of this object.

	@class Error
]=]
local Error

    Error = {
        Kind = Enum.MakeEnum("Promise.Error.Kind", {
            "ExecutionError",
            "AlreadyCancelled",
            "NotResolvedInTime",
            "TimedOut"
        } :: {
            ExecutionError: string,
            AlreadyCancelled: string,
            NotResolvedInTime: string,
            TimedOut: string
        })
    }
    Error.__index = Error

    type Kind = keyof<typeof(Error.Kind)>

    type ErrorInternal = {
        kind: Kind?,
        parent: Error?,
        createdTick: number,
        createdTrace: string,
        trace: string?,
        context: string?,
        error: string
    }

    type ErrorOptions = {
        kind: Kind?,
        trace: string?,
        context: string?
    }

    export type Error = typeof(setmetatable({} :: ErrorInternal, Error))

    function Error.new(options: ErrorOptions?, parent: Error?): Error
        options = options or {}
        return setmetatable({
            error = tostring(options.error) or "[This error has no error text.]",
            trace = options.trace,
            context = options.context,
            parent = parent,
            kind = options.kind,
            createdTick = os.clock(),
            createdTrace = debug.traceback()
        }, Error)
    end

    function Error.is(any: any): boolean
        if type(any) == "table" then
            local metatable = getmetatable(any)

            if type(metatable) == "table" then
                return rawget(any, "error") ~= nil and type(rawget(any, "extend")) == "function"
            end
        end

        return false
    end

    function Error.isKind(any, kind: Kind): boolean
        assert(kind ~= nil, "Argument #2 to Promise.Error.isKind must not be nil")

        return Error.is(any) and any.kind == kind
    end

    function Error.extend(self: Error, options): Error
        options = options or {}

        options.kind = options.kind or self.kind

        return Error.new(options, self)
    end

    function Error.getErrorChain(self: Error): {Error}
        local runtimeErrors = {self}

        while runtimeErrors[#runtimeErrors].parent do
            table.insert(runtimeErrors, runtimeErrors[#runtimeErrors].parent)
        end

        return runtimeErrors
    end

    function Error.__tostring(self: Error)
        local errorStrings = {
            `-- Promise.Error({self.kind or "?"}) --`
        }

        for _, runtimeError in ipairs(self:getErrorChain()) do
            table.insert(errorStrings, table.concat({runtimeError.trace or runtimeError.error, runtimeError.context}, "\n"))
        end

        return table.concat(errorStrings, "\n")
    end


function pack<T...>(...: T...)
    return select("#", ...), {...}
end

function packResult<T...>(success: boolean, ...: T...)
    return success, pack(...)
end

function makeErrorHandler(traceback: string): ((err: Error | string) -> Error)
    assert(traceback ~= nil, "traceback is nil")

    return function(err: Error | string)
        if type(err) == "table" then
            return err
        end

        return Error.new({
            error = err,
            kind = Error.Kind.ExecutionError,
            trace = debug.traceback(tostring(err), 2),
            context = `Promise created at:\n\n{traceback}`
        })
    end
end

function runExecuter<T..., R...>(traceback: string, callback: (T...) -> R..., ...: T...)
    return packResult(xpcall(callback, makeErrorHandler(traceback), ...))
end

function isEmpty(t: {any}): boolean
    return next(t) == nil
end

function createAdvancer<T..., R...>(traceback: string, callback: (T...) -> R..., resolve: (R...) -> (), reject: (R...) -> ()): (T...) -> ()
    return function(...: T...)
        local ok, length, results = runExecuter(traceback, callback, ...)

        if ok then
            resolve(unpack(results, 1, length))
        else
            reject(unpack(results, 1, length))
        end
    end
end

--[=[
	A Promise is an object that represents a value that will exist in the future, but doesn't right now.
	Promises allow you to then attach callbacks that can run once the value becomes available (known as *resolving*),
	or if an error has occurred (known as *rejecting*).

	@class Promise
	@__index prototype
]=]
local Promise = {
    Error = Error,
    Status = Enum.MakeEnum("Promise.Status", {"Started", "Resolved", "Rejected", "Cancelled"} :: {
        Started: string,
        Resolved: string,
        Rejected: string,
        Cancelled: string
    }),
    _getTime = os.clock,
    _unhandledRejectionCallbacks = {}
}
Promise.prototype = {}
Promise.__index = Promise.prototype

export type Status = keyof<typeof(Promise.Status)>

type PromiseCallback<T..., R...> = (resolve: (T...) -> (), reject: (R...) -> (), onCancel: (cancelHandler: () -> ()) -> ()) -> ()

export type Promise<T..., R...> = {
    read Error: Error,
    --[=[
        An enum value used to represent the Promise's status.
        @interface Status
        @tag enum
        @within Promise
        @field Started "Started" -- The Promise is executing, and not settled yet.
        @field Resolved "Resolved" -- The Promise finished successfully.
        @field Rejected "Rejected" -- The Promise was rejected.
        @field Cancelled "Cancelled" -- The Promise was cancelled before it finished.
    ]=]
    --[=[
        @prop Status Status
        @within Promise
        @readonly
        @tag enums
        A table containing all members of the `Status` enum, e.g., `Promise.Status.Resolved`.
    ]=]
    read Status: typeof(Promise.Status),
    --[=[
        Construct a new Promise that will be resolved or rejected with the given callbacks.

        If you `resolve` with a Promise, it will be chained onto.

        You can safely yield within the executor function and it will not block the creating thread.

        ```lua
        local MyFunction()
            return Promise.new(function(resolve, reject, onCancel)
                task.wait(1)
                resolve("Hello world!")
            end)
        end

        MyFunction():AndThen(print)
        ```

        You do not need to use `pcall` within a Promise. Errors that occur during execution will be caught and turned into a rejection automatically. If `error()` is called with a table, that table will be the rejection value. Otherwise, string errors will be converted into `Promise.Error(Promise.Error.Kind.ExecutionError)` objects for tracking debug information.

        You may register an optional cancellation hook by using the `onCancel` argument:

        * This should be used to abort any ongoing operations leading up to the promise being settled.
        * Call the `onCancel` function with a function callback as its only argument to set a hook which will in turn be called when/if the promise is cancelled.
        * `onCancel` returns `true` if the Promise was already cancelled when you called `onCancel`.
        * Calling `onCancel` with no argument will not override a previously set cancellation hook, but it will still return `true` if the Promise is currently cancelled.
        * You can set the cancellation hook at any time before resolving.
        * When a promise is cancelled, calls to `resolve` or `reject` will be ignored, regardless of if you set a cancellation hook or not.

        :::caution
        If the Promise is cancelled, the `executor` thread is closed with `coroutine.close` after the cancellation hook is called.

        You must perform any cleanup code in the cancellation hook: any time your executor yields, it **may never resume**.
        :::

        @param executor (resolve: (...: any) -> (), reject: (...: any) -> (), onCancel: (abortHandler?: () -> ()) -> boolean) -> ()
        @return Promise
        ]=]
    new: <TYPE..., REJECT...>(callback: PromiseCallback<TYPE..., REJECT...>) -> Promise<TYPE..., REJECT...>,
    --[=[
        Creates an immediately resolved Promise with the given value.

        ```lua
        -- Example using Promise.resolve to deliver cached values:
        function GetSomething(name)
            if cache[name] then
                return Promise.resolve(cache[name])
            else
                return Promise.new(function(resolve, reject)
                    local thing = GetTheThing()
                    cache[name] = thing

                    resolve(thing)
                end)
            end
        end
        ```

        @param ... any
        @return Promise<...any>
    ]=]
    resolve: <TYPE...>(TYPE...) -> Promise<TYPE...>,
    --[=[
        Creates an immediately rejected Promise with the given value.

        ::: caution
        Something needs to consume this rejection (i.e. `:Catch()` it), otherwise it will emit an unhandled Promise rejection warning on the next frame. Thus, you should not create and store rejected Promises for later use. Only create them on-demand as needed.
        :::

        @param ... any
        @return Promise<...any>
    ]=]
    reject: <REJECT...>(REJECT...) -> Promise<(), REJECT...>,
    --[=[
        Begins a Promise chain, calling a function and returning a Promise resolving with its return value. If the function errors, the returned Promise will be rejected with the error. You can safely yield within the Promise.try callback.

        :::info
        `Promise.try` is similar to [Promise.promisify](#promisify), except the callback is invoked immediately instead of returning a new function.
        :::

        ```lua
        Promise.try(function()
            return math.random(1, 2) == 1 and "ok" or error("Oh an error!")
        end)
            :AndThen(function(text)
                print(text)
            end)
            :Catch(function(err)
                warn("Something went wrong")
            end)
        ```

        @param callback (...: T...) -> ...any
        @param ... T... -- Additional arguments passed to `callback`
        @return Promise
    ]=]
    try: <ARGS..., RETURN...>(callback: (ARGS...) -> RETURN..., ARGS...) -> Promise<RETURN...>,
    --[=[
        The same as [Promise.new](/api/Promise#new), except execution begins after the next tick.

        This is a spiritual replacement for `spawn`, but it does not suffer from the same issues as `spawn`.

        @param executor (resolve: (...: any) -> (), reject: (...: any) -> (), onCancel: (abortHandler?: () -> ()) -> boolean) -> ()
        @return Promise
    ]=]
    defer: <TYPE..., REJECT...>(callback: PromiseCallback<TYPE..., REJECT...>) -> Promise<TYPE..., REJECT...>,
    --[=[
        Accepts an array of Promises and returns a new promise that:
        * is resolved after all input promises resolve.
        * is rejected if *any* input promises reject.

        Only the first return value from each promise will be present in the resulting array.

        After any input Promise rejects, all other input Promises that are still pending will be cancelled if they have no other consumers.

        ```lua
        local promises = {
            ReturnsAPromise("example 1"),
            ReturnsAPromise("example 2"),
            ReturnsAPromise("example 3"),
        }

        return Promise.all(promises)
        ```

        @param promises {Promise<T>}
        @return Promise<{T}>
    ]=]
    all: <TYPE..., REJECT...>(promises: {Promise<TYPE..., REJECT...>}) -> Promise<TYPE..., REJECT...>,
    --[=[
        Accepts an array of Promises and returns a Promise that is resolved as soon as `count` Promises are resolved from the input array. The resolved array values are in the order that the Promises resolved in. When this Promise resolves, all other pending Promises are cancelled if they have no other consumers.

        `count` 0 results in an empty array. The resultant array will never have more than `count` elements.

        ```lua
        local promises = {
            ReturnsAPromise("example 1"),
            ReturnsAPromise("example 2"),
            ReturnsAPromise("example 3"),
        }

        return Promise.some(promises, 2) -- Only resolves with first 2 promises to resolve
        ```

        @param promises {Promise<T>}
        @param count number
        @return Promise<{T}>
    ]=]
    some: <TYPE..., REJECT...>(promises: {Promise<TYPE..., REJECT...>}, count: number) -> Promise<TYPE..., REJECT...>,
    --[=[
        Accepts an array of Promises and returns a Promise that is resolved as soon as *any* of the input Promises resolves. It will reject only if *all* input Promises reject. As soon as one Promises resolves, all other pending Promises are cancelled if they have no other consumers.

        Resolves directly with the value of the first resolved Promise. This is essentially [[Promise.some]] with `1` count, except the Promise resolves with the value directly instead of an array with one element.

        ```lua
        local promises = {
            ReturnsAPromise("example 1"),
            ReturnsAPromise("example 2"),
            ReturnsAPromise("example 3"),
        }

        return Promise.any(promises) -- Resolves with first value to resolve (only rejects if all 3 rejected)
        ```

        @param promises {Promise<T>}
        @return Promise<T>
    ]=]
    any: <TYPE..., REJECT...>(promises: {Promise<TYPE..., REJECT...>}) -> Promise<TYPE..., REJECT...>,
    --[=[
        Wraps a function that yields into one that returns a Promise.

        Any errors that occur while executing the function will be turned into rejections.

        :::info
        `Promise.promisify` is similar to [Promise.try](#try), except the callback is returned as a callable function instead of being invoked immediately.
        :::

        ```lua
        local sleep = Promise.promisify(task.wait)

        sleep(1):AndThen(print)
        ```

        @param callback (...: any) -> ...any
        @return (...: any) -> Promise
    ]=]
    promisify: <T..., R...>(callback: (T...) -> R...) -> ((T...) -> Promise<(R...)>),
    --[=[
        Yields the current thread until the given Promise completes. Returns true if the Promise resolved, followed by the values that the promise resolved or rejected with.

        ::: caution
        If the Promise gets cancelled, this function will return `false`, which is indistinguishable from a rejection. If you need to differentiate, you should use [[Promise:AwaitStatus]] instead.
        :::

        ```lua
            local worked, value = GetTheValue():Await()

            if worked then
                print("got", value)
            else
                warn("it failed")
            end
        ```

        @yields
        @return boolean -- `true` if the Promise successfully resolved
        @return ...any -- The values the Promise resolved or rejected with.
    ]=]
    Await: (self: Promise<T..., R...>) -> (boolean, T...),
    --[=[
        Yields the current thread until the given Promise completes. Returns the Promise's status, followed by the values that the promise resolved or rejected with.

        @yields
        @return Status -- The Status representing the fate of the Promise
        @return ...any -- The values the Promise resolved or rejected with.
    ]=]
    AwaitStatus: (self: Promise<T..., R...>) -> (Status, T...),
    --[=[
        Yields the current thread until the given Promise completes. Returns the values that the promise resolved with.

        ```lua
        local worked = pcall(function()
            print("got", GetTheValue():Expect())
        end)

        if not worked then
            warn("it failed")
        end
        ```

        This is essentially sugar for:

        ```lua
        select(2, assert(promise:Await()))
        ```

        **Errors** if the Promise rejects or gets cancelled.

        @error any -- Errors with the rejection value if this Promise rejects or gets cancelled.
        @yields
        @return ...any -- The values the Promise resolved with.
    ]=]
    Expect: (self: Promise<T..., R...>) -> (T...),
    --[=[
        Cancels this promise, preventing the promise from resolving or rejecting. Does not do anything if the promise is already settled.

        Cancellations will propagate upwards and downwards through chained promises.

        Promises will only be cancelled if all of their consumers are also cancelled. This is to say that if you call `AndThen` twice on the same promise, and you cancel only one of the child promises, it will not cancel the parent promise until the other child promise is also cancelled.

        ```lua
            promise:Cancel()
        ```
    ]=]
    Cancel: (self: Promise<T..., R...>) -> (),
    --[=[
        Set a handler that will be called regardless of the promise's fate. The handler is called when the promise is
        resolved, rejected, *or* cancelled.

        Returns a new Promise that:
        - resolves with the same values that this Promise resolves with.
        - rejects with the same values that this Promise rejects with.
        - is cancelled if this Promise is cancelled.

        If the value you return from the handler is a Promise:
        - We wait for the Promise to resolve, but we ultimately discard the resolved value.
        - If the returned Promise rejects, the Promise returned from `finally` will reject with the rejected value from the
        *returned* promise.
        - If the `Finally` Promise is cancelled, and you returned a Promise from the handler, we cancel that Promise too.

        Otherwise, the return value from the `Finally` handler is entirely discarded.

        ::: note Cancellation
        As of Promise v4, `Promise:Finally` does not count as a consumer of the parent Promise for cancellation purposes.
        This means that if all of a Promise's consumers are cancelled and the only remaining callbacks are finally handlers,
        the Promise is cancelled and the finally callbacks run then and there.

        Cancellation still propagates through the `Finally` Promise though: if you cancel the `Finally` Promise, it can cancel
        its parent Promise if it had no other consumers. Likewise, if the parent Promise is cancelled, the `Finally` Promise
        will also be cancelled.
        :::

        ```lua
        local thing = CreateSomething()

        DoSomethingWith(thing)
            :AndThen(function()
                print("It worked!")
                -- do something..
            end)
            :Catch(function()
                warn("Oh no it failed!")
            end)
            :Finally(function()
                -- either way, destroy thing

                thing:Destroy()
            end)

        ```

        @param finallyHandler (status: Status) -> ...any
        @return Promise<...any>
    ]=]
    Finally: (self: Promise<T..., R...>, callback: (T...) -> ()) -> Promise<T..., R...>,
    --[=[
        Chains onto an existing Promise and returns a new Promise.

        ::: warning
        Within the failure handler, you should never assume that the rejection value is a string. Some rejections within the Promise library are represented by [[Error]] objects. If you want to treat it as a string for debugging, you should call `tostring` on it first.
        :::

        You can return a Promise from the success or failure handler and it will be chained onto.

        Calling `AndThen` on a cancelled Promise returns a cancelled Promise.

        :::tip
        If the Promise returned by `AndThen` is cancelled, `successHandler` and `failureHandler` will not run.

        To run code no matter what, use [Promise:Finally](#Finally).
        :::

        @param successHandler (...: any) -> ...any
        @param failureHandler? (...: any) -> ...any
        @return Promise<...any>
    ]=]
    AndThen: (self: Promise<T..., R...>, callback: (T...) -> (), catch: ((R...) -> ())?) -> Promise<T..., R...>,
    --[=[
        Shorthand for `Promise:AndThen(nil, failureHandler)`.

        Returns a Promise that resolves if the `failureHandler` worked without encountering an additional error.

        ::: warning
        Within the failure handler, you should never assume that the rejection value is a string. Some rejections within the Promise library are represented by [[Error]] objects. If you want to treat it as a string for debugging, you should call `tostring` on it first.
        :::

        Calling `Catch` on a cancelled Promise returns a cancelled Promise.

        :::tip
        If the Promise returned by `Catch` is cancelled,  `failureHandler` will not run.

        To run code no matter what, use [Promise:Finally](#Finally).
        :::

        @param failureHandler (...: any) -> ...any
        @return Promise<...any>
    ]=]
    Catch: (self: Promise<T..., R...>, callback: (R...) -> ()) -> Promise<T..., R...>,
    --[=[
        Returns the current Promise status.

        @return Status
    ]=]
    GetStatus: (self: Promise<T..., R...>) -> Status,
    --[=[
        Similar to [Promise:AndThen](#AndThen), except the return value is the same as the value passed to the handler. In other words, you can insert a `:Tap` into a Promise chain without affecting the value that downstream Promises receive.

        ```lua
            GetTheValue()
            :Tap(print)
            :AndThen(function(theValue)
                print("Got", theValue, "even though print returns nil!")
            end)
        ```

        If you return a Promise from the tap handler callback, its value will be discarded but `Tap` will still wait until it resolves before passing the original value through.

        @param tapHandler (...: any) -> ...any
        @return Promise<...any>
    ]=]
    Tap: (self: Promise<T..., R...>, callback: (T...) -> ()) -> Promise<T..., R...>
}

function Promise._new<T..., R...>(traceback: string, callback: (resolve: (T...) -> (), reject: (R...) -> (), onCancel: (cancelHandler: () -> ()) -> ()) -> (), parent: Promise<()>?): Promise<T..., R...>
    if parent ~= nil and not Promise.is(parent) then
        error("Argument #2 to Promise.new must be a promise or nil", 2)
    end

    local self = {
        _thread = nil,
        _source = traceback,
        _status = Promise.Status.Started,
        _values = nil,
        _valuesLength = -1,
        _unhandledRejection = true,
        _queuedResolve = {},
        _queuedReject = {},
        _queuedFinally = {},
        _canncellationHook = nil,
        _parent = parent,
        _consumers = setmetatable({}, MODE_KEY_TABLE)
    }

    if parent and parent._status == Promise.Status.Started then
        parent._consumers[self] = true
    end

    setmetatable(self, Promise)

    local function resolve(...)
        self:_resolve(...)
    end

    local function reject(...)
        self:_reject(...)
    end

    local function onCancel(canncellationHook: () -> ())
        if canncellationHook then
            if self._status == Promise.Status.Cancelled then
                canncellationHook()
            else
                self._canncellationHook = canncellationHook
            end
        end

        return self._status == Promise.Status.Cancelled
    end

    self._thread = coroutine.create(function()
        local ok, length, results = runExecuter(self._source, callback, resolve, reject, onCancel)

        if not ok then
            reject(unpack(results, 1, length))
        end
    end)

    task.spawn(self._thread)

    return self
end

function Promise.new<T..., R...>(executor: (resolve: (T...) -> (), reject: (R...) -> (), onCancel: (cancelHandler: () -> ()) -> ()) -> ()): Promise<T..., R...>
    return Promise._new(debug.traceback(nil, 2), executor)
end

function Promise.__tostring(self: Promise<()>)
    return `Promise({self._status})`
end

function Promise.defer<T..., R...>(executor: (resolve: (T...) -> (), reject: (R...) -> (), onCancel: (cancelHandler: () -> ()) -> ()) -> ()): Promise<T..., R...>
    local traceback = debug.traceback(nil, 2)
    local promise = Promise._new(traceback, function(resolve: (T...) -> (), reject: (R...) -> (), onCancel: (() -> ()) -> ())
        task.defer(function()
            local ok, length, results = runExecuter(traceback, executor, resolve, reject, onCancel)

            if not ok then
                reject(unpack(results, 1, length))
            end
        end)
    end)
    return promise
end

Promise.async = Promise.defer

function Promise.resolve<R...>(...: R...): Promise<R...>
    local length, values = pack(...)
    return Promise._new(debug.traceback(nil, 2), function(resolve: (R...) -> ())
        resolve(unpack(values, 1, length))
    end)
end

function Promise.reject<R...>(...: R...): Promise<R...>
    local length, values = pack(...)
    return Promise._new(debug.traceback(nil, 2), function(_, reject: (R...) -> ())
        reject(unpack(values, 1, length))
    end)
end

function Promise._try<T..., R...>(traceback: string, callback: (T...) -> R..., ...: T...): Promise<R...>
    local length, values = pack(...)
    return Promise._new(traceback, function(resolve: (R...) -> ())
        resolve(callback(unpack(values, 1, length)))
    end)
end

function Promise.try<T..., R...>(callback: (T...) -> R..., ...: T...): Promise<R...>
    return Promise._try(debug.traceback(nil, 2), callback, ...)
end

function Promise.promisify<T..., R...>(callback: (T...) -> R...): (T...) -> Promise<R...>
	return function(...)
		return Promise._try(debug.traceback(nil, 2), callback, ...)
	end
end

function Promise._all<R...>(traceback: string, promises: {Promise<R...>}, amount: number): Promise<R...>
    if type(promises) ~= "table" then
        error(string.format(ERROR_NON_LIST, "Promise.all"), 3)
    end

    for i, promise in pairs(promises) do
        if not Promise.is(promise) then
            error(string.format(ERROR_NON_PROMISE_IN_LIST, "Promise.all", tostring(i)), 3)
        end
    end

    if #promises == 0 or amount == 0 then
        return Promise.resolve({})
    end

    return Promise._new(traceback, function(resolve: (...any) -> (), reject: (...any) -> (), onCancel: (cancelHandler: () -> ()) -> ())
        local resolvedValues = {}
        local newPromises = {}

        local resolvedCount = 0
        local rejectedCount = 0
        local done = false

        local function cancel()
            for _, promise in pairs(newPromises) do
                promise:cancel()
            end
        end

        local function resolveOne(i, ...)
            if done then
                return
            end

            resolvedCount += 1

            if amount == nil then
                resolvedValues[i] = ...
            else
                resolvedValues[resolvedCount] = ...
            end

            if resolvedCount >= (amount or #promises) then
                done = true
                resolve(resolvedValues)
                cancel()
            end
        end

        onCancel(cancel)

        for i, promise in ipairs(promises) do
            newPromises[i] = promise:andThen(function(...)
                resolveOne(i, ...)
            end, function(...)
                rejectedCount += 1

                if amount == nil or #promises - rejectedCount < amount then
                    cancel()
                    done = true
                    reject(...)
                end
            end)
        end

        if done then
            cancel()
        end
    end)
end

function Promise.all<R...>(promises: {Promise<R...>}): Promise<R...>
    return Promise._all(debug.traceback(nil, 2), promises)
end

function Promise.fold(list, reducer, initVal)
    assert(type(list) == "table", "Bad argument #1 to Promise.fold: must be a table")
	assert(IsCallable(reducer), "Bad argument #2 to Promise.fold: must be a function")
    
    local accumulator = Promise.resolve(initVal)
    return Promise.each(list, function(resolvedElement, i)
        accumulator = accumulator:andThen(function(previousValueResolved)
            return reducer(previousValueResolved, resolvedElement, i)
        end)
    end):andThen(function()
        return accumulator
    end)
end

function Promise.each(list, predicate)
	assert(type(list) == "table", string.format(ERROR_NON_LIST, "Promise.each"))
	assert(IsCallable(predicate), string.format(ERROR_NON_FUNCTION, "Promise.each"))

	return Promise._new(debug.traceback(nil, 2), function(resolve, reject, onCancel)
		local results = {}
		local promisesToCancel = {}

		local cancelled = false

		local function cancel()
			for _, promiseToCancel in ipairs(promisesToCancel) do
				promiseToCancel:cancel()
			end
		end

		onCancel(function()
			cancelled = true

			cancel()
		end)

		local preprocessedList = {}

		for index, value in ipairs(list) do
			if Promise.is(value) then
				if value:getStatus() == Promise.Status.Cancelled then
					cancel()
					return reject(Error.new({
						error = "Promise is cancelled",
						kind = Error.Kind.AlreadyCancelled,
						context = string.format(
							"The Promise that was part of the array at index %d passed into Promise.each was already cancelled when Promise.each began.\n\nThat Promise was created at:\n\n%s",
							index,
							value._source
						),
					}))
				elseif value:getStatus() == Promise.Status.Rejected then
					cancel()
					return reject(select(2, value:await()))
				end

				local ourPromise = value:andThen(function(...)
					return ...
				end)

				table.insert(promisesToCancel, ourPromise)
				preprocessedList[index] = ourPromise
			else
				preprocessedList[index] = value
			end
		end

		for index, value in ipairs(preprocessedList) do
			if Promise.is(value) then
				local success
				success, value = value:await()

				if not success then
					cancel()
					return reject(value)
				end
			end

			if cancelled then
				return
			end

			local predicatePromise = Promise.resolve(predicate(value, index))

			table.insert(promisesToCancel, predicatePromise)

			local success, result = predicatePromise:await()

			if not success then
				cancel()
				return reject(result)
			end

			results[index] = result
		end

		resolve(results)
        return
	end)
end

function Promise.some(promises, count)
    assert(type(count) == "number", "Bad argument #2 to Promise.some: must be a number")

    return Promise._all(debug.traceback(nil, 2), promises, count)
end

function Promise.any<R...>(promises: {Promise<R...>}): Promise<R...>
    return Promise._all(debug.traceback(nil, 2), promises, 1):andThen(function(values)
        return values[1]
    end)
end

function Promise.is(val: any): boolean
    if type(val) ~= "table" then
        return false
    end

    local metatable = getmetatable(val)

    if metatable == Promise then
        return true
    elseif metatable == nil then
        return IsCallable(val)
    elseif type(metatable) == "table" and type(rawget(metatable, "__index")) == "table" and IsCallable(rawget(rawget(metatable, "__index"), "andThen")) then
        return true
    end

    return false
end

function Promise.delay(seconds: number): Promise<(number)>
    assert(type(seconds) == "number", "Bad argument #1 to Promise.delay, must be a number.")
    local startTime = Promise._getTime()
    return Promise._new(debug.traceback(nil, 2), function(resolve: (number) -> ())
        task.delay(seconds, function()
            resolve(Promise._getTime() - startTime)
        end)
    end)
end

function Promise.prototype:getStatus()
    return self._status
end

Promise.prototype.GetStatus = Promise.prototype.getStatus

function Promise.prototype._andThen<R...>(self: Promise<R...>, traceback: string, successHandler: (R...) -> (), failureHandler: (R...) -> ()): Promise<R...>
    self._unhandledRejection = false

    if self._status == Promise.Status.Cancelled then
        local promise = Promise.new(function() end)
        promise:cancel()
        return promise
    end

    return Promise._new(traceback, function(resolve: (R...) -> (), reject: (R...) -> (), onCancel: (cancelHandler: () -> ()) -> ())
        local successCallback = resolve
        if successHandler then
            successCallback = createAdvancer(traceback, successHandler, resolve, reject)
        end

        local failureCallback = reject
        if failureHandler then
            failureCallback = createAdvancer(traceback, failureHandler, resolve, reject)
        end

        if self._status == Promise.Status.Started then
            table.insert(self._queuedResolve, successCallback)
            table.insert(self._queuedReject, failureCallback)

            onCancel(function()
                if self._status == Promise.Status.Started then
                    table.remove(self._queuedResolve, table.find(self._queuedResolve, successCallback))
                    table.remove(self._queuedReject, table.find(self._queuedReject, failureCallback))
                end
            end)
        elseif self._status == Promise.Status.Resolved then
            successCallback(unpack(self._values, 1, self._valuesLength))
        elseif self._status == Promise.Status.Rejected then
            failureCallback(unpack(self._values, 1, self._valuesLength))
        end
    end, self)
end

function Promise.prototype.andThen<R...>(self: Promise<R...>, successHandler: (R...) -> (), failureHandler: (R...) -> ()): Promise<R...>
    assert(successHandler == nil or IsCallable(successHandler), string.format(ERROR_NON_FUNCTION, "Promise:andThen"))
	assert(failureHandler == nil or IsCallable(failureHandler), string.format(ERROR_NON_FUNCTION, "Promise:andThen"))

    return self:_andThen(debug.traceback(nil, 2), successHandler, failureHandler)
end

Promise.prototype.AndThen = Promise.prototype.andThen

function Promise.prototype.catch<R...>(self: Promise<R...>, failureHandler: (R...) -> ()): Promise<R...>
    assert(failureHandler == nil or IsCallable(failureHandler), string.format(ERROR_NON_FUNCTION, "Promise:catch"))
    return self:_andThen(debug.traceback(nil, 2), nil, failureHandler)
end

Promise.prototype.Catch = Promise.prototype.catch

function Promise.prototype.tap<R...>(self: Promise<R...>, tapHandler: (R...) -> ()): Promise<R...>
    assert(IsCallable(tapHandler), string.format(ERROR_NON_FUNCTION, "Promise:tap"))
    return self:_andThen(debug.traceback(nil, 2), function(...)
        local callbackReturn = tapHandler(...)

        if Promise.is(callbackReturn) then
            local length, values = pack(...)
            return callbackReturn:andThen(function()
                return unpack(values, 1, length)
            end)
        end

        return ...
    end)
end

Promise.prototype.Tap = Promise.prototype.tap

function Promise.prototype.andThenCall<R..., T...>(self: Promise<R...>, callback: (T...) -> (), ...: T...): Promise<R...>
    local length, values = pack(...)
    return self:_andThen(debug.traceback(nil, 2), function()
        return callback(unpack(values, 1, length))
    end)
end

Promise.prototype.AndThenCall = Promise.prototype.andThenCall

function Promise.prototype.cancel<R...>(self: Promise<R...>)
    if self._status ~= Promise.Status.Started then
        return
    end

    self._status = Promise.Status.Cancelled

    if self._cancellationHook then
        self._cancellationHook()
    end

    coroutine.close(self._thread)

    if self._parent then
        self._parent:_consumerCancelled(self)
    end

    for child in pairs(self._consumers) do
        child:cancel()
    end

    self:_finalize()
end

Promise.prototype.Cancel = Promise.prototype.cancel

function Promise.prototype._consumerCancelled<R...>(self: Promise<R...>, consumer)
    if self._status ~= Promise.Status.Started then
        return
    end

    self._consumers[consumer] = nil

    if next(self._consumers) == nil then
        self:cancel()
    end
end

function Promise.prototype._finally<R...>(self: Promise<R...>, traceback: string, finallyHandler: (status: Status) -> ()): Promise<(Status)>
    self._unhandledRejection = false
    
    local promise = Promise._new(traceback, function(resolve: (R...) -> (), reject: (R...) -> (), onCancel: (cancelHandler: () -> ()) -> ())
        local handlerPromise

        onCancel(function()
            self:_consumerCancelled(self)
            if handlerPromise then
                handlerPromise:cancel()
            end
        end)

        local finallyCallback = resolve
        if finallyHandler then
            finallyCallback = function(...)
                local ok, length, results = runExecuter(traceback, finallyHandler, ...)
                local result = results[1]
                
                if not ok then
                    return reject(unpack(results, 1, length))
                end

                if Promise.is(result) then
                    handlerPromise = result :: Promise<(any)>

                    result:finally(function(status)
                        if status ~= Promise.Status.Rejected then
                            resolve(self)
                        end
                    end):catch(function(...)
                        reject(...)
                    end)
                else
                    resolve(self)
                end

                return
            end
        end

        if self._status == Promise.Status.Started then
            table.insert(self._queuedFinally, finallyCallback)
        else
            finallyCallback(self._status)
        end
    end)

    return promise
end

function Promise.prototype.finally<R...>(self: Promise<R...>, finallyHandler: (status: Status) -> ()): Promise<(Status)>
    assert(finallyHandler == nil or IsCallable(finallyHandler), string.format(ERROR_NON_FUNCTION, "Promise:finally"))
    return self:_finally(debug.traceback(nil, 2), finallyHandler)
end

function Promise.prototype.finallyCall<R..., T...>(self: Promise<R...>, callback: (T...) -> (), ...: T...): Promise<(Status)>
    assert(IsCallable(callback), string.format(ERROR_NON_FUNCTION, "Promise:finallyCall"))
    local length, values = pack(...)
    return self:_finally(debug.traceback(nil, 2), function()
        return callback(unpack(values, 1, length))
    end)
end

Promise.prototype.Finally = Promise.prototype.finally
Promise.prototype.FinallyCall = Promise.prototype.finallyCall

function Promise.prototype.awaitStatus<R...>(self: Promise<R...>): (Status, R...)
    self._unhandledRejection = false

    if self._status == Promise.Status.Started then
        local thread = coroutine.running()

        self:finally(function()
            task.spawn(thread)
        end):catch(function() end)

        coroutine.yield()
    end

    if self._status == Promise.Status.Resolved then
        return self._status, unpack(self._values, 1, self._valuesLength)
    elseif self._status == Promise.Status.Rejected then
        return self._status, unpack(self._values, 1, self._valuesLength)
    end

    return self._status
end

Promise.prototype.AwaitStatus = Promise.prototype.awaitStatus

function awaitHelper<T...>(status: Status, ...: T...): (boolean, T...)
    return status == Promise.Status.Resolved, ...
end

function Promise.prototype.await<R...>(self: Promise<R...>): (boolean, R...)
    return awaitHelper(self:awaitStatus())
end

Promise.prototype.Await = Promise.prototype.await

function expectHelper<T...>(status: Status, ...: T...): T...
    if status ~= Promise.Status.Resolved then
        error((...) == nil and "Expected Promise rejected with no value." or (...), 3)
    end

    return ...
end

function Promise.prototype.expect<R...>(self: Promise<R...>): R...
    return expectHelper(self:awaitStatus())
end

Promise.prototype.awaitValue = Promise.prototype.expect
Promise.prototype.AwaitValue = Promise.prototype.expect
Promise.prototype.Expect = Promise.prototype.expect

function Promise.prototype._resolve<R...>(self: Promise<R...>, ...: R...)
    if self._status ~= Promise.Status.Started then
        if Promise.is((...)) then
            (...):_consumerCancelled(self)
        end
        return
    end

    if Promise.is((...)) then
        if select("#", ...) > 1 then
            local message = string.format("When returning a Promise from andThen, extra arguments are discarded! See:\n\n%s", self._source)
            warn(message)
        end

        local chainedPromise = ...

        local promise = chainedPromise:andThen(function(...)
            self:_resolve(...)
        end, function(...)
            local maybeRuntimeError = chainedPromise._values[1]

            if Error.isKind(maybeRuntimeError, Error.Kind.ExecutionError) then
                return self:_reject(maybeRuntimeError:extend({
                    error = "This promise was chained to a Promise that errored.",
                    trace = "",
                    context = string.format("The Promise at:\n\n%s\n...Rejected because it was chained to the following Promise, which encountered an error:\n", self._source)
                }))
            end

            self:_reject(...)
            return
        end)

        if promise._status == Promise.Status.Cancelled then
            self:cancel()
        elseif promise._status == Promise.Status.Started then
            self._parent = promise
            promise._consumers[self] = true
        end

        return
    end

    self._status = Promise.Status.Resolved
    self._valuesLength, self._values = pack(...)

    for _, callback in ipairs(self._queuedResolve) do
        coroutine.wrap(callback)(...)
    end

    self:_finalize()
end

function Promise.prototype._reject<R...>(self: Promise<R...>, ...: R...)
    if self._status ~= Promise.Status.Started then
        return
    end

    self._status = Promise.Status.Rejected
    self._valuesLength, self._values = pack(...)

    if not isEmpty(self._queuedReject) then
        for _, callback in ipairs(self._queuedReject) do
            coroutine.wrap(callback)(...)
        end
    else
        local err = tostring((...))

        coroutine.wrap(function()
            task.wait()

            if not self._unhandledRejection then
                return
            end

            local message = string.format("Unhandled Promise rejection:\n\n%s\n\n%s", err, self._source)

            for _, callback in ipairs(Promise._unhandledRejectionCallbacks) do
                task.spawn(callback, self, unpack(self._values, 1, self._valuesLength))
            end

            warn(message)
        end)()
    end

    self:_finalize()
end

function Promise.prototype._finalize<R...>(self: Promise<R...>)
    for _, callback in ipairs(self._queuedFinally) do
        coroutine.wrap(callback)(self._status)
    end

    self._queuedFinally = nil
    self._queuedResolve = nil
    self._queuedReject = nil

    self._parent = nil
    self._consumers = nil

    task.defer(coroutine.close, self._thread)
end

function Promise.prototype.now<r, R...>(self: Promise<R...>, rejectionValue: r?): Promise<R...> | Promise<(r?)>
    local traceback = debug.traceback(nil, 2)
    if self._status == Promise.Status.Resolved then
        return self:_andThen(traceback, function(...)
            return ...
        end)
    else
        return Promise.reject(rejectionValue == nil and Error.new({
            kind = Error.Kind.NotResolvedInTime,
            error = "This Promise was not resolved in time for :now()",
            context = ":now() was called at:\n\n" .. traceback
        }) or rejectionValue)
    end
end

Promise.prototype.Now = Promise.prototype.now

function Promise.onUnhandledPromiseRejection(callback: <R...>(promise: Promise<R...>, R...) -> ())
    table.insert(Promise._unhandledRejectionCallbacks, callback)

    return function()
        local index = table.find(Promise._unhandledRejectionCallbacks, callback)

        if index then
            table.remove(Promise._unhandledRejectionCallbacks, index)
        end
    end
end

return Promise