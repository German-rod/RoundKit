local PlayerRoundState = require(script.Parent.Parent.Classes.PlayerRoundState)

--- @class PlayerStateRegistry
--- Used to store player states for the round
local PlayerStateRegistry = {}
PlayerStateRegistry.__index = PlayerStateRegistry

--- @return PlayerStateRegistry
--- Constructor method for a new player state registry
function PlayerStateRegistry.new()
	return setmetatable({
		_states = {},
	}, PlayerStateRegistry)
end

--- @param player Player
--- @return PlayerRoundState
--- Adds a new player state to the registry
function PlayerStateRegistry:AddPlayerState(player)
	local state = PlayerRoundState.new(player)
	self._states[player.UserId] = state
	return state
end

--- @param userId number
--- @return ()
--- Removes a player state from the registry
function PlayerStateRegistry:RemovePlayerState(userId)
	local state = self._states[userId]
	if state then
		state:Destroy()
		self._states[userId] = nil
	end
end

--- @param userId number
--- @return PlayerRoundState?
--- Gets a player state from the registry
function PlayerStateRegistry:GetPlayerState(userId)
	return self._states[userId] or nil
end

--- @return table - A table containing all player round state instances
--- Gets all player states from the registry
function PlayerStateRegistry:GetAllPlayerStates()
	return self._states
end

--- @return ()
--- Clears all player states from the registry
function PlayerStateRegistry:Clear()
	for userId in pairs(self._states) do
		self:RemovePlayerState(userId)
	end
end

--- @return ()
--- Destroys the player state registry
function PlayerStateRegistry:Destroy()
	self:Clear()
	self._states = nil
	setmetatable(self, nil)
end

return PlayerStateRegistry
