-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local ReactiveStateExpression = LibTSMReactive:DefineInternalClassType("ReactiveStateExpression")
local EnumType = LibTSMReactive:From("LibTSMUtil"):Include("BaseType.EnumType")
local String = LibTSMReactive:From("LibTSMUtil"):Include("Lua.String")
local Table = LibTSMReactive:From("LibTSMUtil"):Include("Lua.Table")
local private = {
	cache = {}, ---@type table<ReactiveStateSchema,table<string,ReactiveStateExpression>>
	linesTemp = {},
	enumTemp = {},
}
local VALID_OPERATORS = {
	["or"] = true,
	["and"] = true,
	["not"] = true,
	["false"] = true,
	["true"] = true,
	["nil"] = true,
	["#"] = true,
	[".."] = true,
}
local VALID_FUNCTIONS = {
	min = true,
	max = true,
}



-- ============================================================================
-- Module Functions
-- ============================================================================

---Gets an expression object.
---@param expressionStr string A valid lua expression which can only access fields of the state (as globals)
---@return ReactiveStateExpression
function ReactiveStateExpression.__static.Get(expressionStr)
	local obj = private.cache[expressionStr]
	if not obj then
		obj = ReactiveStateExpression(expressionStr)
		private.cache[expressionStr] = obj
	end
	return obj
end



-- ============================================================================
-- Meta Class Methods
-- ============================================================================

function ReactiveStateExpression.__private:__init(expressionStr)
	self._keys = {}
	self._enumInfo = {}
	self._origExpression = expressionStr
	self:_Compile(expressionStr)
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

---Validates the expression against the specified schema and returns the error string.
---@param schema ReactiveStateSchema The state schema
---@return string?
function ReactiveStateExpression:Validate(schema)
	for key in pairs(self._keys) do
		if not schema:_HasKey(key) then ---@diagnostic disable-line: invisible
			return "Unknown state key: "..tostring(key)
		end
	end
	for _, stateKey, valueKey in Table.StrideIterator(self._enumInfo, 2) do
		local enumType = schema:_GetEnumFieldType(stateKey) ---@diagnostic disable-line: invisible
		assert(enumType and EnumType.IsType(enumType))
		if strmatch(valueKey, "%.") then
			local enumValue = enumType
			for valueKeyPart in gmatch(valueKey, "[^%.]+") do
				enumValue = enumValue[valueKeyPart]
			end
			assert(enumValue)
		else
			assert(enumType[valueKey])
		end
	end
	return nil
end

---Gets the original expression.
---@return table
function ReactiveStateExpression:GetOriginalExpression()
	return self._origExpression
end

---Returns the single key or nil if there are multiple keys.
---@return string|nil
function ReactiveStateExpression:GetSingleKey()
	local key = next(self._keys)
	assert(key ~= nil)
	return next(self._keys, key) == nil and key or nil
end

---Iterates over the keys.
---@return fun(): string @Iterator with fields: `key`
---@return table
function ReactiveStateExpression:KeyIterator()
	return Table.KeyIterator(self._keys)
end

---Gets the code.
---@return string
function ReactiveStateExpression:GetCode()
	return self._code
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

function ReactiveStateExpression.__private:_Compile(expression)
	assert(not strmatch(expression, "__enum_"))
	assert(not strmatch(expression, "__string_"))
	assert(#private.linesTemp == 0)

	-- Replace EnumEquals() function calls and string literals
	expression = gsub(expression, "EnumEquals%((.-),(.-)%)", self:__closure("_EnumEqualsSub"))
	expression = gsub(expression, "(\"(.-)\")", self:__closure("_StringLiteralSub"))

	-- Process all the tokens
	expression = gsub(expression, "\"?[a-zA-Z0-9_%.#`]+\"?", self:__closure("_HandleToken"))

	assert(next(self._keys) ~= nil)
	local singleKey = self:GetSingleKey()
	if singleKey then
		expression = gsub(expression, "data%."..String.Escape(singleKey), "data")
	end

	-- Handle enums
	assert(#private.enumTemp == 0)
	for id, stateKey, valueKey in Table.StrideIterator(self._enumInfo, 2) do
		local dataAccess = singleKey and "data" or "data."..stateKey
		local typeName = "__enum_type_"..stateKey
		-- Use -1 as a placeholder if the field is nil since that'll result in the comparison with an optional enum field being false
		if not private.enumTemp[stateKey] then
			private.enumTemp[stateKey] = true
			tinsert(private.linesTemp, "local "..typeName.." = "..dataAccess.." ~= nil and "..dataAccess..":GetType() or -1")
		end
		tinsert(private.linesTemp, "local __enum_value_"..id.." = "..typeName.." ~= -1 and "..typeName.."."..valueKey.." or -1")
	end
	wipe(private.enumTemp)

	tinsert(private.linesTemp, "data = "..expression)
	self._code = table.concat(private.linesTemp, "\n")
	print(self._code)
	wipe(private.linesTemp)
end

function ReactiveStateExpression.__private:_HandleToken(token)
	if (strsub(token, 1, 1) == "\"" and strsub(token, -1) == "\"") or tonumber(token) then
		-- String or number literal
		return token
	elseif VALID_OPERATORS[token] or VALID_FUNCTIONS[token] then
		-- Valid operator or function
		return token
	elseif strmatch(token, "^__string_") or strmatch(token, "^__enum_") then
		-- Placeholder - pass
		return token
	else
		-- State key
		assert(token ~= "data", "Illegal key: "..tostring(token))
		self._keys[token] = true
		return "data."..token
	end
end

function ReactiveStateExpression.__private:_EnumEqualsSub(stateKey, valueKey)
	stateKey = strtrim(stateKey)
	valueKey = strtrim(valueKey)
	local id = #self._enumInfo + 1
	Table.InsertMultiple(self._enumInfo, stateKey, valueKey)
	return format("(%s == __enum_value_%d)", stateKey, id)
end

function ReactiveStateExpression.__private:_StringLiteralSub(origToken, str)
	if strmatch(str, "^[A-Za-z_0-9]*$") then
		-- Don't need to replace this
		return origToken
	end
	local id = #private.linesTemp + 1
	tinsert(private.linesTemp, "local __string_"..id.." = \""..str.."\"")
	return "__string_"..id
end
