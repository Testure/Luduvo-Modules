--[=[
    Class that represents an asynchronous two-way communication from the client to the server.

    Written by Turing6.

    @class BindableFunction
]=]
const BindableFunction = {}
BindableFunction.__index = BindableFunction

const Promise = require("./Promise")
const NetworkEventDefinition = require("./NetworkEventDefinition")

const IsClient = pcall(function()
    local _ = game.Input.PointerRay
end)

type BindableFunctionInternal = {
    Name: string
}

export type BindableFunction<T..., R...> = typeof(setmetatable({} :: BindableFunctionInternal, BindableFunction))

--[=[
    Creates a new BindableFunction.

    @param name string -- The name of this function
    @param sendDefinition NetworkEventDefinition<T...> -- Type definitions for the arguments to send out
    @param returnDefinition NetworkEventDefinition<R...> -- Type definitions for the arguments to be returned back
    @param timeoutLimit number? -- Maximum time in seconds to wait before considering the function call failed
    @return BindableFunction<T..., R...>
]=]
function BindableFunction.new<T..., R...>(name: string, sendDefinition: NetworkEventDefinition.NetworkEventDefinition<T...>, returnDefinition: NetworkEventDefinition.NetworkEventDefinition<R...>, timeoutLimit: number?): BindableFunction<T..., R...>
    local sendParamDefinition = sendDefinition.luduvoDef
    local returnParamDefinition = returnDefinition.luduvoDef
    table.insert(sendParamDefinition, 1, {"callid", game.EventTable.I32})
    table.insert(returnParamDefinition, 1, {"callid", game.EventTable.I32})
    return setmetatable({
        Name = name,
        _timeout = if timeoutLimit then timeoutLimit else 5,
        _send = game.EventTable(`{name}-Send`, game.EventTable.ToServer, sendParamDefinition),
        _return = game.EventTable(`{name}-Return`, game.EventTable.ToClients, returnParamDefinition),
        _sendDef = sendDefinition,
        _returnDef = returnDefinition
    }, BindableFunction)
end

--[=[
    Binds the given callback to this function, it will be called with arguments sent from the client and it's return values will be sent back to the client.

    Each BindableFunction can only have one callback bound, binding a new callback will replace the old one and print a warning to the console.

    @method Bind
    @param callback (T...) -> R... -- Callback to bind
]=]
function BindableFunction.Bind<T..., R...>(self: BindableFunction<T..., R...>, callback: (T...) -> (R...))
    if IsClient then error("Attempt to call BindableFunction:Bind on the client! Method is server only!", 2) end
    if self._connection then
        self._connection:Disconnect()
        warn(`BindableFunction "{self.Name}" was already bound to a function! previously bound function will no longer be invoked.`)
    end
    self._connection = self._send.OnServerEvent:Connect(function(...)
        local pack = {...}

        local vals = {pcall(function()
            return callback(pack[1], self._sendDef:DeserializeValues(unpack(pack, 3, #pack)))
        end)}

        if not vals[1] then
            warn(`Error in BindableFunction callback: {vals[2]}`)
            return
        end

        local results = {self._returnDef:SerializeValues(unpack(vals, 2, #vals))}

        self._return:FireClient(pack[1], pack[2], unpack(results, 1, #results))
    end)
end

--[=[
    Invokes the callback on the server and returns a Promise that resolves with the values the callback returns or rejects with an error string.

    @method Invoke
    @param ... T... -- Arguments to send
    @return Promise<R..., string>
]=]
function BindableFunction.Invoke<T..., R...>(self: BindableFunction<T..., R...>, ...: T...): Promise.Promise<R..., (string)>
    if not IsClient then error("Attempt to call BindableFunction:Invoke on the server! Method is client only!", 2) end
    local args = {self._sendDef:SerializeValues(...)}
    return Promise.new(function(resolve, reject, onCancel)
        local thread, connection
        local resolved = false
        local sentTick = math.ceil(os.clock())
        connection = self._return.OnClientEvent:Connect(function(...)
            local pack = {self._returnDef:DeserializeValues(...)}
            
            if pack[1] == sentTick then
                connection:Disconnect()
                resolved = true
                resolve(unpack(pack, 2, #pack))
            else
                print(pack[1], sentTick)
            end
        end)

        onCancel(function()
            if not resolved then
                connection:Disconnect()
                coroutine.close(thread)
            end
        end)

        self._send:FireServer(sentTick, unpack(args, 1, #args))

        thread = task.delay(self._timeout, function()
            if not resolved then
                connection:Disconnect()
                reject(`BindableFunction "{self.Name}" timed out waiting for response!`)
            end
        end)
    end)
end

return BindableFunction