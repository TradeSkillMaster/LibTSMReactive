-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local Reactive = LibTSMReactive:Init("Reactive")
local ReactiveOneShot = LibTSMReactive:IncludeClassType("ReactiveOneShot")
local ReactiveStateSchema = LibTSMReactive:IncludeClassType("ReactiveStateSchema")
local ReactiveStream = LibTSMReactive:IncludeClassType("ReactiveStream")



-- ============================================================================
-- Module Functions
-- ============================================================================

---Creates a new state schema object.
---@param name string The name for debugging purposes
---@return ReactiveStateSchema
function Reactive.CreateStateSchema(name)
	return ReactiveStateSchema.Create(name)
end

---Gets a stream object.
---@param initialValueFunc fun(): any A function to get the initial value to send to new publishers
---@return ReactiveStream
function Reactive.GetStream(initialValueFunc)
	return ReactiveStream.Get(initialValueFunc)
end

---Gets a publisher which publishes a single initial value and never again.
---@param value any The value to publish
---@param autoDisable? boolean Whether or not to automatically disable the publisher
---@param autoStore? table The table to store the publisher in automatically
---@return ReactivePublisherSchema
function Reactive.GetOneShotPublisher(value, autoDisable, autoStore)
	return ReactiveOneShot.GetPublisher(value, autoDisable, autoStore)
end
