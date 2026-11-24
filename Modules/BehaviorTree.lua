--[=[
    Module for creating basic behavior trees.

    A behavior tree is a tree of any type of 'node'.
    
    when the user manually 'ticks' the top node, all child nodes in the tree are ticked with each node type having different behavior.
    Custom logic is applied through providing custom callbacks to `Condition` and `Action` nodes, other node types control execution flow of their child nodes.


    Written by Turing6.

    @class BehaviorTree
]=]
const BehaviorTree = {}

const Enum = require("./Enum")

BehaviorTree.Status = Enum.MakeEnum("Status", {Success = "Success", Failure = "Failure", Running = "Running"} :: {Success: "Success", Failure: "Failure", Running: "Running"})

export type Status = typeof(BehaviorTree.Status)

export type Node<T = any> = {
    tick: (self: Node, actor: T, blackboard: {}?) -> Status
}

export type Condition<T = any> = Node<T> & {
    new: <T>(callback: (actor: T, blackboard: {}?) -> boolean, blackboard: {}?) -> Condition<T>
}

export type Action<T = any> = Node<T> & {
    new: <T>(callback: (actor: T, blackboard: {}?) -> Status, blackboard: {}?) -> Action<T>
}

export type Composite<T = any> = Node<T> & {
    new: <T>(children: {Node<T>}, blackboard: {}?) -> Composite<T>
}

export type Decorator<T = any> = Node<T> & {
    new: <T>(child: Node<T>, blackboard: {}?) -> Decorator<T>
}

--[=[
    The Condition node succeeds if it's callback returns true and fails otherwise.
]=]
BehaviorTree.Condition = {
    new = function<T>(callback: (actor: T, blackboard: {}?) -> boolean, blackboard: {}?): Condition<T>
        return setmetatable({_callback = callback, _blackboard = blackboard}, BehaviorTree.Condition)
    end,
    tick = function<T>(self: Condition<T>, actor: T, blackboard: {}?): Status
        blackboard = if blackboard then blackboard else self._blackboard
        return if self._callback(actor, blackboard) then BehaviorTree.Status.Success else BehaviorTree.Status.Failure
    end
}

--[=[
    The Action node simply runs it's callback and returns the status returned by the callback.
]=]
BehaviorTree.Action = {
    new = function<T>(callback: (actor: T, blackboard: {}?) -> Status, blackboard: {}?): Action<T>
        return setmetatable({_callback = callback, _blackboard = blackboard}, BehaviorTree.Action)
    end,
    tick = function<T>(self: Action<T>, actor: T, blackboard: {}?): Status
        blackboard = if blackboard then blackboard else self._blackboard
        return self._callback(actor, blackboard)
    end
}

--[=[
    The Sequence node attempts to run all of it's child nodes in order, but stops when a node doesn't succeed.
]=]
BehaviorTree.Sequence = {
    new = function<T>(children: {Node<T>}, blackboard: {}?): Composite<T>
        return setmetatable({_children = children, _blackboard = blackboard}, BehaviorTree.Sequence)
    end,
    tick = function<T>(self: Composite<T>, actor: T, blackboard: {}?): Status
        blackboard = if blackboard then blackboard else self._blackboard
        for _,v: Node<T> in self._children do
            local s = v:tick(actor, blackboard)
            if s ~= BehaviorTree.Status.Success then
                return s
            end
        end
        return BehaviorTree.Status.Success
    end
}

--[=[
    The Selector node attempts to select the first successful node, running all child nodes in order and stopping at the first success.
]=]
BehaviorTree.Selector = {
    new = function<T>(children: {Node<T>}, blackboard: {}?): Composite<T>
        return setmetatable({_children = children, _blackboard = blackboard}, BehaviorTree.Selector)
    end,
    tick = function<T>(self: Composite<T>, actor: T, blackboard: {}?): Status
        blackboard = if blackboard then blackboard else self._blackboard
        for _,v: Node<T> in self._children do
            local s = v:tick(actor, blackboard)
            if s ~= BehaviorTree.Status.Failure then
                return s
            end
        end
        return BehaviorTree.Status.Failure
    end
}

--[=[
    The Inverter node simply runs it's child node and returns the opposite result.
]=]
BehaviorTree.Inverter = {
    new = function<T>(child: Node<T>, blackboard: {}?): Decorator<T>
        return setmetatable({_child = child, _blackboard = blackboard}, BehaviorTree.Inverter)
    end,
    tick = function<T>(self: Decorator<T>, actor: T, blackboard: {}?): Status
        blackboard = if blackboard then blackboard else self._blackboard
        local s = self._child:tick(actor, blackboard)
        if s == BehaviorTree.Status.Failure then
            return BehaviorTree.Status.Success
        end
        if s == BehaviorTree.Status.Success then
            return BehaviorTree.Status.Failure
        end
        return BehaviorTree.Status.Running
    end
}

--[=[
    The MemorySequence node is the same as the Sequence node, but it remembers where it left off.
]=]
BehaviorTree.MemorySequence = {
    new = function<T>(children: {Node<T>}, blackboard: {}?): Composite<T>
        return setmetatable({_children = children, _current = 1, _blackboard = blackboard}, BehaviorTree.MemorySequence)
    end,
    tick = function<T>(self: Composite<T>, actor: T, blackboard: {}?): Status
        blackboard = if blackboard then blackboard else self._blackboard
        while self._current <= #self._children do
            local s = self._children[self._current]:tick(actor, blackboard)
            if s == BehaviorTree.Status.Running then
                return s
            end
            if s == BehaviorTree.Status.Failure then
                self._current = 1
                return s
            end
            self._current += 1
        end
        self._current = 1
        return BehaviorTree.Status.Success
    end
}

function searchNodeInstance(node: Instance, blackboards: {[string]: {}}, callbackGatherer: (string) -> () -> ()): Node
    local nodeType = node.attr.NodeType
    if nodeType and BehaviorTree[nodeType] then
        local blackboard = nil
        if node.attr.Blackboard then
            blackboard = blackboards[node.attr.Blackboard]
            if not blackboard then
                blackboard = {}
                blackboards[node.attr.Blackboard] = blackboard
            end
        end
        local children = node:GetChildren()
        if #children > 1 then
            local nodes = {}
            for i = 1, #children do
                nodes[i] = searchNodeInstance(children[i], blackboards, callbackGatherer)
            end
            return BehaviorTree[nodeType].new(nodes, blackboard)
        elseif #children == 1 then
            return BehaviorTree[nodeType].new(searchNodeInstance(children[1], blackboards, callbackGatherer), blackboard)
        else
            return BehaviorTree[nodeType].new(callbackGatherer(node.attr.CallbackName), blackboard)
        end
    end
    return nil
end

--[=[
    Attempts to construct a behavior tree out of one that has been serialized as a Instance tree.

    @param root Instance
    @param callbackSources {{[string]: any}} -- A table of sources for which named callbacks can be obtained from
    @return Node
]=]
function BehaviorTree.fromInstance<T>(root: Instance, callbackSources: {{[string]: any}}): {Node<T>}
    local blackboards = {}
    local nodes = {}
    local function callbackGatherer(name: string): (() -> ())?
        for _,v in callbackSources do
            if typeof(v[name]) == "function" then
                return v[name]
            end
        end
        return nil
    end
    local blackboardsInstance = root:FindFirstChild("Blackboards")
    local nodesInstance = root:FindFirstChild("Nodes")

    if blackboardsInstance then
        for _,v in blackboardsInstance:GetChildren() do
            local blackboard = {}

            for i,v: any in v.attr do
                blackboard[i] = v
            end

            blackboards[v.Name] = blackboard
        end
    end
    if nodesInstance then
        for _,v in nodesInstance:GetChildren() do
            table.insert(nodes, searchNodeInstance(v, blackboards, callbackGatherer))
        end
    end

    return nodes
end

return BehaviorTree