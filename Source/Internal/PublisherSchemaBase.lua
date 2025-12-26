-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local ReactivePublisherSchemaBase = LibTSMReactive:DefineInternalClassType("ReactivePublisherSchemaBase", nil, "ABSTRACT")
local Util = LibTSMReactive:Include("Reactive.Util")
local STEP = Util.PUBLISHER_STEP

---@alias PublisherMapFunc fun(value: any, arg: any): any
---@alias PublisherFlatMapFunc fun(value: any): ReactivePublisher



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
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param map PublisherMapFunc|string|number|table Either a map function, table key (string or number) to index, method call (in the form "MyMethod()"), or lookup table
---@param arg any An additional argument to pass to a map function
---@return T
function ReactivePublisherSchemaBase:Map(map, arg)
	---@cast self +ReactivePublisherSchemaBase
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
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param map PublisherMapFunc|string Either a map function or method call (in the form "MyMethod()") for non-nil values
---@param arg any An additinoal argument to pass to the map function or method
---@return T
function ReactivePublisherSchemaBase:MapNonNil(map, arg)
	---@cast self +ReactivePublisherSchemaBase
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
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to map to
---@return T
function ReactivePublisherSchemaBase:CoalesceNil(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_NIL_TO_VALUE, value)
end

---Invert published boolean values.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@return T
function ReactivePublisherSchemaBase:InvertBoolean()
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.INVERT_BOOLEAN)
end

---Map published values to a boolean based on whether or not it equals the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to compare with
---@return T
function ReactivePublisherSchemaBase:ToBooleanEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_EQUALS, value)
end

---Map published values to a boolean based on whether or not it equals the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to compare with
---@return T
function ReactivePublisherSchemaBase:ToBooleanNotEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_NOT_EQUALS, value)
end

---Map published values to a boolean based on whether or not it is greater than or equal to the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value string|number The value to compare with
---@return T
function ReactivePublisherSchemaBase:ToBooleanGreaterThanOrEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_GREATER_THAN_OR_EQUALS, value)
end

---Map published values to a boolean based on whether or not it is less than or equal to the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value string|number The value to compare with
---@return T
function ReactivePublisherSchemaBase:ToBooleanLessThanOrEquals(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_LESS_THAN_OR_EQUALS, value)
end

---Map published values as arguments to a format string.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param formatStr string The string to format with the published values
---@return T
function ReactivePublisherSchemaBase:ToStringFormat(formatStr)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_STRING_FORMAT, formatStr)
end

---Replaces published values with the specific value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value any The value to replace with
---@return T
function ReactivePublisherSchemaBase:ReplaceWith(value)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_TO_VALUE, value)
end

---Replaces published boolean values with the specified true / false values.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param trueValue any The value to replace with to if true
---@param falseValue any The value to replace with to if false
---@return T
function ReactivePublisherSchemaBase:ReplaceBooleanWith(trueValue, falseValue)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_BOOLEAN_WITH_VALUES, trueValue, falseValue)
end

---Ignores published values which equal the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value string|number|boolean|nil The value to compare against
---@param key? string|number The key to access for filtering
---@return T
function ReactivePublisherSchemaBase:IgnoreIfEquals(value, key)
	---@cast self +ReactivePublisherSchemaBase
	if key == nil then
		self:_AddStepHelper(STEP.IGNORE_IF_EQUALS, value)
	else
		self:_AddStepHelper(STEP.IGNORE_IF_KEY_EQUALS, key, value)
	end
	return self
end

---Ignores published values which don't equal the specified value.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param value string|number|boolean|nil The value to compare against
---@param key? string|number The key to access for filtering
---@return T
function ReactivePublisherSchemaBase:IgnoreIfNotEquals(value, key)
	---@cast self +ReactivePublisherSchemaBase
	if key == nil then
		self:_AddStepHelper(STEP.IGNORE_IF_NOT_EQUALS, value)
	else
		self:_AddStepHelper(STEP.IGNORE_IF_KEY_NOT_EQUALS, key, value)
	end
	return self
end

---Ignores published values if it's nil.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@return T
function ReactivePublisherSchemaBase:IgnoreNil()
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.IGNORE_IF_EQUALS, nil)
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
---@param arg any An additional argument to pass to the method
---@return T
function ReactivePublisherSchemaBase:CallMethod(obj, method, arg)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.CALL_METHOD, obj, method, arg)
end

---Calls a function with the published values.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param func fun(value: any, arg: any) The function to call with the published values
---@param arg any An additional argument to pass to the function
---@return T
function ReactivePublisherSchemaBase:CallFunction(func, arg)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.CALL_FUNCTION, func, arg)
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

---Maps published values to a new publisher which is owned by the current publisher.
---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param map table|PublisherFlatMapFunc A function which takes a published value and returns a new publisher or an object to call a method on which does the same
---@param methodOrArg? string|any The method name to call if an object is passed for `map` or an extra argument to pass to the function
---@param methodArg? string An extra argument to pass to the method (if applicable)
---@return T
function ReactivePublisherSchemaBase:FlatMap(map, methodOrArg, methodArg)
	---@cast self +ReactivePublisherSchemaBase
	local mapType = type(map)
	if mapType == "function" then
		assert(methodArg == nil)
		self:_AddStepHelper(STEP.FLAT_MAP_FUNCTION, map, methodOrArg)
	elseif mapType == "table" then
		assert(type(methodOrArg) == "string")
		self:_AddStepHelper(STEP.FLAT_MAP_METHOD, map, methodOrArg, methodArg)
	else
		error("Invalid map type: "..tostring(map), 2)
	end
	return self
end



-- ============================================================================
-- Protected/Private Class Methods
-- ============================================================================

---@generic T: ReactivePublisherSchemaBase
---@param self T
---@param func fun(...: any): any
---@param ... string
---@return T
---@private
function ReactivePublisherSchemaBase:_MapWithFunctionAndKeys(func, ...)
	---@cast self +ReactivePublisherSchemaBase
	return self:_AddStepHelper(STEP.MAP_WITH_FUNCTION_AND_KEYS, func, ...)
end

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
