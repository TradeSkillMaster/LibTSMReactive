-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local UIBindings = LibTSMReactive:DefineClassType("UIBindings")
local NamedTupleList = LibTSMReactive:From("LibTSMUtil"):IncludeClassType("NamedTupleList")



-- ============================================================================
-- Static Class Functions
-- ============================================================================

---Creates a new UI bindings object.
---@return UIBindings
function UIBindings.__static.Create()
	return UIBindings()
end



-- ============================================================================
-- Meta Class Methods
-- ============================================================================

function UIBindings.__private:__init()
	self._binds = NamedTupleList.New("bindKey", "state", "stateKey")
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

---Adds a binding.
---@param bindKey string The binding key
---@param state ReactiveState The state to store the value in
---@param stateKey string The state key to store the value at
function UIBindings:Add(bindKey, state, stateKey)
	self._binds:InsertRow(bindKey, state, stateKey)
end

---Clears all registered bindings.
function UIBindings:Clear()
	self._binds:Wipe()
end

---Processes the binds for an action and updates the bound state keys.
---@param bindKey string The binding key to update
---@param value any The value to set
function UIBindings:Process(bindKey, value)
	for _, entryBindKey, state, stateKey in self._binds:Iterator() do
		if entryBindKey == bindKey then
			state[stateKey] = value
		end
	end
end
