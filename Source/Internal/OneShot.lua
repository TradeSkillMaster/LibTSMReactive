-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local ReactiveOneShot = LibTSMReactive:DefineInternalClassType("ReactiveOneShot")
local ReactivePublisherSchema = LibTSMReactive:IncludeClassType("ReactivePublisherSchema")
local private = {
	cache = {},
}

---@class ReactiveOneShot: ReactiveSubject



-- ============================================================================
-- Static Class Functions
-- ============================================================================

---Gets a one-shot publisher.
---@param value any The value to publish
---@param autoDisable? boolean Whether or not to automatically disable the publisher
---@param autoStore? table The table to store the publisher in automatically
---@return ReactivePublisherSchema
function ReactiveOneShot.__static.GetPublisher(value, autoDisable, autoStore)
	assert(value ~= nil)
	local oneShot = private.cache[value] or ReactiveOneShot(value)
	return oneShot:Publisher(autoDisable, autoStore)
end



-- ============================================================================
-- Meta Class Methods
-- ============================================================================

function ReactiveOneShot.__private:__init(value)
	self._value = value
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

---Creates a new publisher for the one-shot.
---@param autoDisable? boolean Automatically disable the publisher
---@param autoStore? table The table to store new publishers in
---@return ReactivePublisherSchema
function ReactiveOneShot:Publisher(autoDisable, autoStore)
	local schema = ReactivePublisherSchema.Get(self)
	if autoDisable then
		schema:_AutoDisable() ---@diagnostic disable-line invisible
	end
	if autoStore then
		schema:_AutoStore(autoStore) ---@diagnostic disable-line invisible
	end
	return schema
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

---@private
---@param publisher ReactivePublisher
function ReactiveOneShot:_AddPublisher(publisher)
	-- Do nothing
end

---@private
---@param publisher ReactivePublisher
function ReactiveOneShot:_RemovePublisher(publisher)
	-- Do nothing
end

---@private
---@param publisher ReactivePublisher
---@param disabled boolean
function ReactiveOneShot:_SetPublisherDisabled(publisher, disabled)
	-- Do nothing
end

---@private
---@return any
function ReactiveOneShot:_GetInitialValue()
	return self._value
end

---@private
---@return boolean
function ReactiveOneShot:_RequiresOptimized()
	return false
end
