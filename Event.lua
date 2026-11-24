--[=[
    An entirely code based implementation of `Signal`.

    Written by Turing6.

    @class Event
]=]
local Event = {}
Event.__index = Event

export type Event<T...> = typeof(setmetatable({}, Event))

--[=[
    a callback connection to an Event.

    @class Connection
]=]
local Connection = {}
local ConnectionPrototype = {}
Connection.__index = ConnectionPrototype

export type EventConnection = typeof(setmetatable({}, Connection))

function Connection.new<T...>(event: Event<T...>, callback: (T...) -> ()): EventConnection
    return setmetatable({_event = event, _callback = callback}, Connection)
end

--[=[
    Disconnects this callback, causing it to no longer get called when the Event is fired.

    @method Disconnect
]=]
function ConnectionPrototype.Disconnect(self: EventConnection)
    self._callback = nil
    local i = table.find(self._event._connections, self)
    if i then
        table.remove(self._event._connections, i)
    end
end

--[=[
    Creates a new Event instance with no connected callbacks.

    @return Event
]=]
function Event.new<T...>(): Event<T...>
    return setmetatable({_connections = {}}, Event)
end

--[=[
    Connects the given callback to this Event and returns the Connection.

    @method Connect
    @param callback (T...) -> () -- The callback to connect
    @return Connection
]=]
function Event.Connect<T...>(self: Event<T...>, callback: (T...) -> ()): EventConnection
    local connection = Connection.new(self, callback)
    table.insert(self._connections, connection)
    return connection
end

--[=[
    Calls all connected callbacks with the given arguments.

    @method Fire
    @param ... T... -- Arguments to pass to connected callbacks
]=]
function Event.Fire<T...>(self: Event<T...>, ...: T...)
    for v: EventConnection in self._connections do
        if v._callback then
            local success, error = pcall(v._callback, ...)
            if not success then
                warn(`Error in event callback: {error}`)
            end
        end
    end
end

--[=[
    Disconnects all callbacks connected to this Event and renders the Event unusable.

    @method Destroy
]=]
function Event.Destroy<T...>(self: Event<T...>)
    local connections = table.clone(self._connections)
    for v: EventConnection in connections do
        v:Disconnect()
    end
    self._connections = {}
    connections = nil
end

return Event