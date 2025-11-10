-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local Debug = LibTSMReactive:Init("Debug")
local State = LibTSMReactive:Include("Reactive.State")



-- ============================================================================
-- Module Functions
-- ============================================================================

---Gets the current properties for all state objects for debug purposes.
---@return table<string,table>
function Debug.GetAllStateData()
	return State.GetDebugData()
end

---Gets a debug representation of a specific state object.
---@param state ReactiveState
---@return string?
function Debug.GetStateInfo(state)
	return State.GetDebugInfo(state)
end
