-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local ReactivePublisherSchemaBase = LibTSMReactive:DefineInternalClassType("ReactivePublisherSchemaBase", nil, "ABSTRACT")
local Util = LibTSMReactive:Include("Reactive.Util")
local STEP = Util.PUBLISHER_STEP



-- ============================================================================
-- Meta Class Methods
-- ============================================================================

function ReactivePublisherSchemaBase.__protected:__init(isShared)
	self._isShared = isShared
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

---Returns whether or not this is a shared publisher.
---@return boolean
function ReactivePublisherSchemaBase:IsShared()
	return self._isShared
end

---Map published values to another value using a function.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param func fun(value: any, arg: any): any The mapping function which takes the published values and returns the results
---@param arg any An additional argument to pass to the function
---@return T
function ReactivePublisherSchemaBase:MapWithFunction(func, arg)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_WITH_FUNCTION, func, arg)
end

---Map published values to another value using a function and passing in the specified keys of the value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param func fun(...: any): any The mapping function which takes the specified keys of the published values and returns the results
---@return T
function ReactivePublisherSchemaBase:MapWithFunctionAndKeys(func, ...)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_WITH_FUNCTION_AND_KEYS, func, ...)
end

---Maps published values by calling a method on it.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param method string The name of the method to call on the published values
---@param arg any An additional argument to pass to the method
---@return T
function ReactivePublisherSchemaBase:MapWithMethod(method, arg)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_WITH_METHOD, method, arg)
end

---Maps published values by indexing it with the specified key.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param key string|number The key to index the published values with
---@return T
function ReactivePublisherSchemaBase:MapWithKey(key)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_WITH_KEY, key)
end

---Map published values by indexing it with two keys, keeping the first value one which is non-nil.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param key1 string The first key to index the published values with
---@param key2 string The second key to index the published values with
---@return T
function ReactivePublisherSchemaBase:MapWithKeyCoalesced(key1, key2)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_WITH_KEY_COALESCED, key1, key2)
end

---Maps published values by using them as a key to a lookup table.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param tbl table The lookup table
---@return T
function ReactivePublisherSchemaBase:MapWithLookupTable(tbl)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_WITH_LOOKUP_TABLE, tbl)
end

---Map published boolean values to the specified true / false values.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param trueValue any The value to map to if true
---@param falseValue any The value to map to if false
---@return T
function ReactivePublisherSchemaBase:MapBooleanWithValues(trueValue, falseValue)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_WITH_VALUES, trueValue, falseValue)
end

---Map published values to a boolean based on whether or not it equals the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to compare with
---@return T
function ReactivePublisherSchemaBase:MapBooleanEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_EQUALS, value)
end

---Map published values to a boolean based on whether or not it equals the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to compare with
---@return T
function ReactivePublisherSchemaBase:MapBooleanNotEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_NOT_EQUALS, value)
end

---Map published values to a boolean based on whether or not it is greater than or equal to the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to compare with
---@return T
function ReactivePublisherSchemaBase:MapBooleanGreaterThanOrEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_GREATER_THAN_OR_EQUALS, value)
end

---Map published values to a boolean based on whether or not it is less than to the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to compare with
---@return T
function ReactivePublisherSchemaBase:MapBooleanLessThan(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_LESS_THAN, value)
end

---Map published values as arguments to a format string.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param formatStr string The string to format with the published values
---@return T
function ReactivePublisherSchemaBase:MapToStringFormat(formatStr)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_STRING_FORMAT, formatStr)
end

---Map published values to a string with the specified suffix appended.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param suffix string The string to append to the published values
---@return T
function ReactivePublisherSchemaBase:MapToStringAddSuffix(suffix)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_STRING_ADD_SUFFIX, suffix)
end

---Map published values to a string with the specified prefix prepended.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param prefix string The string to prepend to the published values
---@return T
function ReactivePublisherSchemaBase:MapToStringAddPrefix(prefix)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_STRING_ADD_PREFIX, prefix)
end

---Map published values to a specific value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to map to
---@return T
function ReactivePublisherSchemaBase:MapToValue(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_TO_VALUE, value)
end

---Map nil published values to a specific value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to map to
---@return T
function ReactivePublisherSchemaBase:MapNilToValue(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_NIL_TO_VALUE, value)
end

---Map non-nil published values to another value using a function and passes nil values straight through.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param func fun(value: any): any The mapping function which takes the published values and returns the results
---@param arg any An additional argument to pass to the method
---@return T
function ReactivePublisherSchemaBase:MapNonNilWithFunction(func, arg)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_NON_NIL_WITH_FUNCTION, func, arg)
end

---Map non-nil published values to another value by calling a method on them and passes nil values straight through.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param method string The name of the method to call on the published values
---@param arg any An additional argument to pass to the method
---@return T
function ReactivePublisherSchemaBase:MapNonNilWithMethod(method, arg)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_NON_NIL_WITH_METHOD, method, arg)
end

---Invert published boolean values.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@return T
function ReactivePublisherSchemaBase:InvertBoolean()
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.INVERT_BOOLEAN)
end

---Ignores published values where a specified key equals the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param key string|number The key to compare at
---@param value any The value to compare with
---@return T
function ReactivePublisherSchemaBase:IgnoreIfKeyEquals(key, value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_IF_KEY_EQUALS, key, value)
end

---Ignores published values where a specified key does not equal the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param key string|number The key to compare at
---@param value any The value to compare with
---@return T
function ReactivePublisherSchemaBase:IgnoreIfKeyNotEquals(key, value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_IF_KEY_NOT_EQUALS, key, value)
end

---Ignores published values which equal the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to compare against
---@return T
function ReactivePublisherSchemaBase:IgnoreIfEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_IF_EQUALS, value)
end

---Ignores published values which don't equal the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to compare against
---@return T
function ReactivePublisherSchemaBase:IgnoreIfNotEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_IF_NOT_EQUALS, value)
end

---Ignores published values if it's nil.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@return T
function ReactivePublisherSchemaBase:IgnoreNil()
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_NIL)
end

---Ignores duplicate published values.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@return T
function ReactivePublisherSchemaBase:IgnoreDuplicates()
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_DUPLICATES)
end

---Ignores duplicate published values by checking the specified keys.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param ... string Keys to compare to detect duplicate published values
---@return T
function ReactivePublisherSchemaBase:IgnoreDuplicatesWithKeys(...)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_DUPLICATES_WITH_KEYS, ...)
end

---Ignores duplicate published values by calling the specified method.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param method string The method to call on the published values
---@return T
function ReactivePublisherSchemaBase:IgnoreDuplicatesWithMethod(method)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_DUPLICATES_WITH_METHOD, method)
end

---Prints published values and passes them through for debugging purposes.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param tag? string An optional tag to add to the prints
---@return T
function ReactivePublisherSchemaBase:Print(tag)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.PRINT, tag)
end

---Calls a method with the published values.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param obj table The object to call the method on
---@param method string The name of the method to call with the published values
---@return T
function ReactivePublisherSchemaBase:CallMethod(obj, method)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.CALL_METHOD, obj, method)
end

---Calls a function with the published values.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param func fun(value: any) The function to call with the published values
---@return T
function ReactivePublisherSchemaBase:CallFunction(func)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.CALL_FUNCTION, func)
end

---Assigns published values to the specified key in the table.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param tbl table The table to assign the published values into
---@param key string The key to assign the published values at
---@return T
function ReactivePublisherSchemaBase:AssignToTableKey(tbl, key)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.ASSIGN_TO_TABLE_KEY, tbl, key)
end



-- ============================================================================
-- Protected/Private Class Methods
-- ============================================================================

---@generic T: ReactivePublisherSchemaBase
---@param self T
---@return T
---@private
function ReactivePublisherSchemaBase:_MapWithStateExpression(expression)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_WITH_STATE_EXPRESSION, expression)
end

---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param stepType EnumValue
---@param ... any
---@return T
function ReactivePublisherSchemaBase.__abstract:_AddStepHelper(stepType, ...)
	return self
end
