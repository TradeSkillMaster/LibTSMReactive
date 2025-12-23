-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local Util = LibTSMReactive:InitInternal("Reactive.Util")
local EnumType = LibTSMReactive:From("LibTSMUtil"):Include("BaseType.EnumType")
Util.INITIAL_IGNORE_VALUE = newproxy(false)
local STEP = EnumType.New("PUBLISHER_STEP", {
	MAP_WITH_FUNCTION = EnumType.NewValue(),
	MAP_WITH_FUNCTION_AND_KEYS = EnumType.NewValue(),
	MAP_WITH_METHOD = EnumType.NewValue(),
	MAP_WITH_KEY = EnumType.NewValue(),
	MAP_WITH_KEY_COALESCED = EnumType.NewValue(),
	MAP_WITH_LOOKUP_TABLE = EnumType.NewValue(),
	MAP_WITH_STATE_EXPRESSION = EnumType.NewValue(),
	MAP_BOOLEAN_WITH_VALUES = EnumType.NewValue(),
	MAP_BOOLEAN_EQUALS = EnumType.NewValue(),
	MAP_BOOLEAN_NOT_EQUALS = EnumType.NewValue(),
	MAP_BOOLEAN_GREATER_THAN_OR_EQUALS = EnumType.NewValue(),
	MAP_BOOLEAN_LESS_THAN_OR_EQUALS = EnumType.NewValue(),
	MAP_STRING_FORMAT = EnumType.NewValue(),
	MAP_TO_VALUE = EnumType.NewValue(),
	MAP_NIL_TO_VALUE = EnumType.NewValue(),
	MAP_NON_NIL_WITH_FUNCTION = EnumType.NewValue(),
	MAP_NON_NIL_WITH_METHOD = EnumType.NewValue(),
	INVERT_BOOLEAN = EnumType.NewValue(),
	IGNORE_IF_KEY_EQUALS = EnumType.NewValue(),
	IGNORE_IF_KEY_NOT_EQUALS = EnumType.NewValue(),
	IGNORE_IF_EQUALS = EnumType.NewValue(),
	IGNORE_IF_NOT_EQUALS = EnumType.NewValue(),
	IGNORE_NIL = EnumType.NewValue(),
	IGNORE_DUPLICATES = EnumType.NewValue(),
	IGNORE_DUPLICATES_WITH_KEYS = EnumType.NewValue(),
	IGNORE_DUPLICATES_WITH_METHOD = EnumType.NewValue(),
	PRINT = EnumType.NewValue(),
	START_PROFILING = EnumType.NewValue(),
	SHARE = EnumType.NewValue(),
	END_SHARE = EnumType.NewValue(),
	CALL_METHOD = EnumType.NewValue(),
	CALL_FUNCTION = EnumType.NewValue(),
	ASSIGN_TO_TABLE_KEY = EnumType.NewValue(),
})
Util.PUBLISHER_STEP = STEP

---@class ReactiveSubject
---@field _AddPublisher fun(self: ReactiveSubject, publisher: ReactivePublisher)
---@field _RemovePublisher fun(self: ReactiveSubject, publisher: ReactivePublisher)
---@field _SetPublisherDisabled fun(self: ReactiveSubject, publisher: ReactivePublisher, disabled: boolean)
---@field _GetInitialValue fun(self: ReactiveSubject): any
---@field _RequiresOptimized fun(): boolean
