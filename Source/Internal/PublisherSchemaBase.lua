-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local ReactivePublisherSchemaBase = LibTSMReactive:DefineInternalClassType("ReactivePublisherSchemaBase", nil, "ABSTRACT")
local Util = LibTSMReactive:Include("Reactive.Util")
local STEP = Util.PUBLISHER_STEP

---@alias ReactivePublisherMapFunc fun(value: any, arg: any): any



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

---Map published values to another value.
---@param map ReactivePublisherMapFunc|string|number|table Either a map function, table key (string or number) to index, method call (in the form "MyMethod()"), or lookup table
---@param arg? any An additional argument to pass to a map function
---@return self
function ReactivePublisherSchemaBase:Map(map, arg)
	local mapType = type(map)
	if mapType == "function" then
		self:_AddStepHelper(STEP.MAP_WITH_FUNCTION, map, arg)
	elseif mapType == "string" and strsub(map, -2) == "()" then
		self:_AddStepHelper(STEP.MAP_WITH_METHOD, strsub(map, 1, -3), arg)
	elseif mapType == "string" or mapType == "number" then
		assert(arg == nil)
		self:_AddStepHelper(STEP.MAP_WITH_KEY, map)
	elseif mapType == "table" then
		assert(arg == nil)
		self:_AddStepHelper(STEP.MAP_WITH_LOOKUP_TABLE, map)
	else
		error("Invalid map type: "..tostring(map), 2)
	end
	return self
end

---Map non-nil publishes values to another value.
---@param map ReactivePublisherMapFunc|string Either a map function or method call (in the form "MyMethod()") for non-nil values
---@param arg? any An additinoal argument to pass to the map function or method
---@return self
function ReactivePublisherSchemaBase:MapNonNil(map, arg)
	local mapType = type(map)
	if mapType == "function" then
		self:_AddStepHelper(STEP.MAP_NON_NIL_WITH_FUNCTION, map, arg)
	elseif mapType == "string" and strsub(map, -2) == "()" then
		self:_AddStepHelper(STEP.MAP_NON_NIL_WITH_METHOD, strsub(map, 1, -3), arg)
	else
		error("Invalid map type: "..tostring(map), 2)
	end
	return self
end

---Coalesces nil published values to a specific value.
---@param value any The value to map to
---@return self
function ReactivePublisherSchemaBase:CoalesceNil(value)
	return self:_AddStepHelper(STEP.MAP_NIL_TO_VALUE, value)
end

---Invert published boolean values.
---@return self
function ReactivePublisherSchemaBase:InvertBoolean()
	return self:_AddStepHelper(STEP.INVERT_BOOLEAN)
end

---Map published values to a boolean based on whether or not it equals the specified value.
---@param value any The value to compare with
---@return self
function ReactivePublisherSchemaBase:ToBooleanEquals(value)
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_EQUALS, value)
end

---Map published values to a boolean based on whether or not it equals the specified value.
---@param value any The value to compare with
---@return self
function ReactivePublisherSchemaBase:ToBooleanNotEquals(value)
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_NOT_EQUALS, value)
end

---Map published values to a boolean based on whether or not it is greater than or equal to the specified value.
---@param value string|number The value to compare with
---@return self
function ReactivePublisherSchemaBase:ToBooleanGreaterThanOrEquals(value)
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_GREATER_THAN_OR_EQUALS, value)
end

---Map published values to a boolean based on whether or not it is less than or equal to the specified value.
---@param value string|number The value to compare with
---@return self
function ReactivePublisherSchemaBase:ToBooleanLessThanOrEquals(value)
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_LESS_THAN_OR_EQUALS, value)
end

---Map published values as arguments to a format string.
---@param formatStr string The string to format with the published values
---@return self
function ReactivePublisherSchemaBase:ToStringFormat(formatStr)
	return self:_AddStepHelper(STEP.MAP_STRING_FORMAT, formatStr)
end

---Replaces published values with the specific value.
---@param value any The value to replace with
---@return self
function ReactivePublisherSchemaBase:ReplaceWith(value)
	return self:_AddStepHelper(STEP.MAP_TO_VALUE, value)
end

---Replaces published boolean values with the specified true / false values.
---@param trueValue any The value to replace with to if true
---@param falseValue any The value to replace with to if false
---@return self
function ReactivePublisherSchemaBase:ReplaceBooleanWith(trueValue, falseValue)
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_WITH_VALUES, trueValue, falseValue)
end

---Ignores published values which equal the specified value.
---@param value string|number|boolean|nil The value to compare against
---@param key? string|number The key to access for filtering
---@return self
function ReactivePublisherSchemaBase:IgnoreIfEquals(value, key)
	if key == nil then
		self:_AddStepHelper(STEP.IGNORE_IF_EQUALS, value)
	else
		self:_AddStepHelper(STEP.IGNORE_IF_KEY_EQUALS, key, value)
	end
	return self
end

---Ignores published values which don't equal the specified value.
---@param value string|number|boolean|nil The value to compare against
---@param key? string|number The key to access for filtering
---@return self
function ReactivePublisherSchemaBase:IgnoreIfNotEquals(value, key)
	if key == nil then
		self:_AddStepHelper(STEP.IGNORE_IF_NOT_EQUALS, value)
	else
		self:_AddStepHelper(STEP.IGNORE_IF_KEY_NOT_EQUALS, key, value)
	end
	return self
end

---Ignores published values if it's nil.
---@return self
function ReactivePublisherSchemaBase:IgnoreNil()
	return self:_AddStepHelper(STEP.IGNORE_IF_EQUALS, nil)
end

---Ignores duplicate published values.
---@param hashFunc? string A method call (in the form "MyMethod()") to calculate the hash to check for equality
---@return self
function ReactivePublisherSchemaBase:IgnoreDuplicates(hashFunc)
	if type(hashFunc) == "string" and strsub(hashFunc, -2) == "()" then
		return self:_AddStepHelper(STEP.IGNORE_DUPLICATES_WITH_METHOD, strsub(hashFunc, 1, -3))
	else
		assert(hashFunc == nil)
		return self:_AddStepHelper(STEP.IGNORE_DUPLICATES)
	end
end

---Ignores duplicate published values by checking the specified keys.
---@param ... string Keys to compare to detect duplicate published values
---@return self
function ReactivePublisherSchemaBase:IgnoreDuplicatesWithKeys(...)
	return self:_AddStepHelper(STEP.IGNORE_DUPLICATES_WITH_KEYS, ...)
end

---Prints published values and passes them through for debugging purposes.
---@param tag? string An optional tag to add to the prints
---@return self
function ReactivePublisherSchemaBase:Print(tag)
	return self:_AddStepHelper(STEP.PRINT, tag)
end

---Calls a method with the published values.
---@param obj table The object to call the method on
---@param method string The name of the method to call with the published values
---@param arg? any An additional argument to pass to the method
---@return self
function ReactivePublisherSchemaBase:CallMethod(obj, method, arg)
	return self:_AddStepHelper(STEP.CALL_METHOD, obj, method, arg)
end

---Calls a function with the published values.
---@param func fun(value: any, arg: any) The function to call with the published values
---@param arg? any An additional argument to pass to the function
---@return self
function ReactivePublisherSchemaBase:CallFunction(func, arg)
	return self:_AddStepHelper(STEP.CALL_FUNCTION, func, arg)
end

---Assigns published values to the specified key in the table.
---@param tbl table The table to assign the published values into
---@param key string The key to assign the published values at
---@return self
function ReactivePublisherSchemaBase:AssignToTableKey(tbl, key)
	return self:_AddStepHelper(STEP.ASSIGN_TO_TABLE_KEY, tbl, key)
end

---Maps published values to a new publisher which is owned by the current publisher and call a method with values it publishes.
---@param map ReactivePublisherFlatMapFunc A function which takes a published value and returns a new publisher
---@param obj table The object to call the method on
---@param method string The name of the method to call with the published values
---@param arg? any An additional argument to pass to the method
---@return self
function ReactivePublisherSchemaBase:FlatMapCallMethod(map, obj, method, arg)
	return self:_AddStepHelper(STEP.FLAT_MAP_CALL_METHOD, map, obj, method, arg)
end

---Maps published values to a new publisher which is owned by the current publisher and call a function with values it publishes.
---@param map ReactivePublisherFlatMapFunc A function which takes a published value and returns a new publisher
---@param func fun(value: any) The function to call with the published values
---@param arg? any An additional argument to pass to the function
---@return self
function ReactivePublisherSchemaBase:FlatMapCallFunction(map, func, arg)
	return self:_AddStepHelper(STEP.FLAT_MAP_CALL_FUNCTION, map, func, arg)
end



-- ============================================================================
-- Protected/Private Class Methods
-- ============================================================================

---@param func fun(...: any): any
---@param ... string
---@return self
---@private
function ReactivePublisherSchemaBase:_MapWithFunctionAndKeys(func, ...)
	return self:_AddStepHelper(STEP.MAP_WITH_FUNCTION_AND_KEYS, func, ...)
end

---@return self
---@private
function ReactivePublisherSchemaBase:_MapWithStateExpression(expression)
	return self:_AddStepHelper(STEP.MAP_WITH_STATE_EXPRESSION, expression)
end

---@param stepType EnumValue
---@param ... any
---@return self
function ReactivePublisherSchemaBase.__abstract:_AddStepHelper(stepType, ...)
	return self
end
