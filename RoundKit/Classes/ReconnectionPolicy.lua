--- @class ReconnectionPolicy
--- Used to handle player reconnections
local ReconnectionPolicy = {}
ReconnectionPolicy.__index = ReconnectionPolicy

local registry = {}

--- @param name string
--- @param handler (context: Context, player: Player, previousState: PlayerState) -> ()
--- @return ReconnectionPolicy
--- Constructor method for a new reconnection policy
function ReconnectionPolicy.new(name, handler)
	assert(not registry[name], "RoundKit: a ReconnectionPolicy named '" .. name .. "' is already registered")
	local self = setmetatable({ Name = name, _handler = handler }, ReconnectionPolicy)
	registry[name] = self
	return self
end

--- @param ctx Context
--- @param player Player
--- @param previousState PlayerState
--- @return ()
--- Handles the reconnection policy for a player
function ReconnectionPolicy:Handle(ctx, player, previousState)
	self._handler(ctx, player, previousState)
end

--- @param nameOrInstance string | ReconnectionPolicy
--- @return ReconnectionPolicy
--- Resolves a reconnection policy instance from its name
function ReconnectionPolicy.Resolve(nameOrInstance)
	if type(nameOrInstance) == "string" then
		local found = registry[nameOrInstance]
		assert(found, "RoundKit: no ReconnectionPolicy registered under name '" .. nameOrInstance .. "'")
		return found
	end
	return nameOrInstance
end

return ReconnectionPolicy
