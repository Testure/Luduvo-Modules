--[=[
    Class representing an asynchronous one-way network communication.

    Written by Turing6.

    @class BindableEvent
]=]
const BindableEvent = {}
BindableEvent.__index = BindableEvent

const Promise = require("./Promise")
const NetworkEventDefinition = require("./NetworkEventDefinition")

const IsClient = pcall(function()
    local _ = game.Input.PointerRay
end)

type Internal = {
    Name: string
}

export type BindableEvent<T...> = typeof(setmetatable({} :: Internal, BindableEvent))

function GetProperSignal(event: BindableEvent<>): Signal
    return if IsClient then event._event.OnClientEvent else event._event.OnServerEvent
end

--[=[
    Creates a new BindableEvent. A BindableEvent with this name must be created on both the server and client.

    2nd and 3rd arguments are optional on the client.

    @function new
    @param name string -- The name of this event
    @param direction EventDirection? -- Network direction of this event
    @param parameterDefinition NetworkEventDefinition<T...>? -- Type definitions for this event's arguments.
    @return BindableEvent<T...>
]=]
function BindableEvent.new<T...>(name: string, direction: EventDirection?, parameterDefinition: NetworkEventDefinition.NetworkEventDefinition<T...>?): BindableEvent<T...>
    return setmetatable({Name = name, _event = game.EventTable(name, direction, if parameterDefinition then parameterDefinition.luduvoDef else nil), _connections = {}, _def = parameterDefinition}, BindableEvent)
end

--[=[
    Fires this event from the client to the server.

    @method FireServer
    @param ... T... -- Arguments to pass to the server
]=]
function BindableEvent.FireServer<T...>(self: BindableEvent<T...>, ...: T...)
    if not IsClient then error("Attempt to call BindableEvent:FireServer on the server! method is client only!", 2) end
    if self._def then
        self._event:FireServer(self._def:SerializeValues(...))
    else
        self._event:FireServer(...)
    end
end

--[=[
    Fires this event from the server to all clients.

    @method FireAllClients
    @param ... T... -- Arguments to pass to the client
]=]
function BindableEvent.FireAllClients<T...>(self: BindableEvent<T...>, ...: T...)
    if IsClient then error("Attempt to call BindableEvent:FireAllClients on the client! method is server only!", 2) end
    self._event:FireAllClients(self._def:SerializeValues(...))
end

--[=[
    Fires this event from the server to a specific client.

    @method FireClient
    @param player Instance -- Player instance of the client to communicate with
    @param ... T... -- Arguments to pass to the client
]=]
function BindableEvent.FireClient<T...>(self: BindableEvent<T...>, player: Instance, ...: T...)
    if IsClient then error("Attempt to call BindableEvent:FireClient on the client! method is server only!", 2) end
    if typeof(player) ~= "Instance" or not player:HasComponent("Player") then error(`Argument #1 to BindableEvent:FireClient expected a player! got {if typeof(player) == "Instance" then "non-player Instance" else '"'..typeof(player)..'"'}`, 2) end
    self._event:FireClient(player, self._def:SerializeValues(...))
end

--[=[
    Connects the given callback to this event.

    @method Connect
    @param callback (T...) -> () -- Callback to connect
    @return SignalConnection
]=]
function BindableEvent.Connect<T...>(self: BindableEvent<T...>, callback: (T...) -> ()): SignalConnection
    local signal = GetProperSignal(self)
    local connection = signal:Connect(function(...)
        local pack = {...}
        local success, error = pcall(function()
            callback(pack[1], self._def:DeserializeValues(unpack(pack, if IsClient then 1 else 2, #pack)))
        end)
        if not success then
            warn(`Error in BindableEvent callback: {error}`)
        end
    end)
    table.insert(self._connections, connection)
    return connection
end

--[=[
    Connects the given callback to this event only once, disconnecting it the first time it is called.

    @method Once
    @param callback (T...) -> () -- Callback to connect
]=]
function BindableEvent.Once<T...>(self: BindableEvent<T...>, callback: (T...) -> ())
    local signal = GetProperSignal(self)
    signal:Once(function(...)
        local pack = {...}
        local success, error = pcall(function()
            callback(pack[1], self._def:DeserializeValues(unpack(pack, if IsClient then 1 else 2, #pack)))
        end)
        if not success then
            warn(`Error in BindableEvent callback: {error}`)
        end
    end)
end

--[=[
    Yields the current thread until the next time this event is fired, and returns the arguments it was fired with.

    @method Wait
    @return T...
]=]
function BindableEvent.Wait<T...>(self: BindableEvent<T...>): T...
    local signal = GetProperSignal(self)
    if IsClient then
        return self._def:DeserializeValues(signal:Wait())
    else
        local pack = {signal:Wait()}
        return pack[1], self._def:DeserializeValues(unpack(pack, 2, #pack))
    end
end

--[=[
    Returns a Promise that resolves the next time this event is fired.

    @method WaitAsync
    @return Promise<T...>
]=]
function BindableEvent.WaitAsync<T...>(self: BindableEvent<T...>): Promise.Promise<T..., ()>
    return Promise.new(function(resolve, reject, onCancel)
        local thread = task.defer(function()
            resolve(self:Wait())
        end)

        onCancel(function()
            coroutine.close(thread)
        end)
    end)
end

return BindableEvent