--- @class PlayerRoundState
--- Represents a player's state during a round
local PlayerRoundState = {}
PlayerRoundState.__index = PlayerRoundState

--- @param player Player
--- @return PlayerRoundState
function PlayerRoundState.new(player)
	return setmetatable({
		Player = player,
		UserId = player.UserId,
		Connected = true,
		Ready = false,
		Metrics = {},
		_destroyed = false,
	}, PlayerRoundState)
end

--- @param newPlayer Player
--- @return ()
--- Rebinds the player round state to a new player instance
function PlayerRoundState:Rebind(newPlayer)
	self.Player = newPlayer
	self.Connected = true
end

--- @param key string
--- @return string | number
--- Returns the value of a metric for this player
function PlayerRoundState:GetMetric(key)
	return self.Metrics[key] or nil
end

--- @param key string
--- @param value string | number
--- @return ()
--- Sets the value of a metric for this player
function PlayerRoundState:SetMetric(key, value)
	self.Metrics[key] = value
end

--- @param connected boolean
--- @return ()
--- Sets the connection status of the player
function PlayerRoundState:SetConnected(connected)
	self.Connected = connected

	if not connected then
		self.Ready = false
		self.DisconnectedTime = os.clock()
	end
end

--- @param ready boolean
--- @return ()
--- Sets the ready status of the player
function PlayerRoundState:SetReady(ready)
	self.Ready = ready
end

--- @return ()
--- Destroys the player round state instance
function PlayerRoundState:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
end

return PlayerRoundState
