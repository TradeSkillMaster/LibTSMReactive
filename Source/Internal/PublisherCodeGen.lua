-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local ReactivePublisherCodeGen = LibTSMReactive:DefineInternalClassType("ReactivePublisherCodeGen")
local CompiledPublisher = LibTSMReactive:Include("Reactive.CompiledPublisher")
local Util = LibTSMReactive:Include("Reactive.Util")
local EnumType = LibTSMReactive:From("LibTSMUtil"):Include("BaseType.EnumType")
local Table = LibTSMReactive:From("LibTSMUtil"):Include("Lua.Table")
local Vararg = LibTSMReactive:From("LibTSMUtil"):Include("Lua.Vararg")
local ObjectPool = LibTSMReactive:From("LibTSMUtil"):IncludeClassType("ObjectPool")
local StringBuilder = LibTSMReactive:From("LibTSMUtil"):IncludeClassType("StringBuilder")
local Hash = LibTSMReactive:From("LibTSMUtil"):Include("Util.Hash")
local private = {
	objectPool = ObjectPool.New("PUBLISHER_CODE_GEN", ReactivePublisherCodeGen, 1),
	argCommentTemp = {},
	codeTemp = {},
	codeIndentation = 0,
	cache = {}, ---@type table<number,CompiledPublisherObject>
	stringBuilder = nil,
	indentationCache = {},
}
local MAX_VARARG_ARGS = 20
local STEP = Util.PUBLISHER_STEP
local ARG_TYPE = EnumType.New("PUBLISHER_ARG_TYPE", {
	STRING = EnumType.NewValue(),
	STRING_OR_NUMBER = EnumType.NewValue(),
	TABLE = EnumType.NewValue(),
	FUNCTION = EnumType.NewValue(),
	ANY_LITERAL = EnumType.NewValue(),
	ANY = EnumType.NewValue(),
	OPTIONAL_ANY = EnumType.NewValue(),
	VARARG_STRING = EnumType.NewValue(),
	STATE_EXPRESSION = EnumType.NewValue(),
})
local SHARE_TYPE = EnumType.New("PUBLISHER_SHARE_TYPE", {
	START = EnumType.NewValue(),
	END = EnumType.NewValue(),
})
local UNOPTIMIZABLE_STEPS = {
	[STEP.MAP_WITH_FUNCTION] = true,
	[STEP.MAP_WITH_FUNCTION_AND_KEYS] = true,
	[STEP.MAP_WITH_METHOD] = true,
	[STEP.MAP_WITH_STATE_EXPRESSION] = true,
	[STEP.MAP_BOOLEAN_WITH_VALUES] = true,
	[STEP.MAP_BOOLEAN_EQUALS] = true,
	[STEP.MAP_BOOLEAN_NOT_EQUALS] = true,
	[STEP.MAP_BOOLEAN_GREATER_THAN_OR_EQUALS] = true,
	[STEP.MAP_BOOLEAN_LESS_THAN_OR_EQUALS] = true,
	[STEP.IGNORE_IF_EQUALS] = true,
	[STEP.IGNORE_IF_NOT_EQUALS] = true,
	[STEP.MAP_WITH_LOOKUP_TABLE] = true,
	[STEP.MAP_NON_NIL_WITH_FUNCTION] = true,
	[STEP.MAP_NON_NIL_WITH_METHOD] = true,
}
local OPTIMIZATION_IGNORED_STEPS = {
	[STEP.PRINT] = true,
	[STEP.INVERT_BOOLEAN] = true,
}
local ARG_TYPE_IS_LITERAL = {
	[ARG_TYPE.STRING] = true,
	[ARG_TYPE.STRING_OR_NUMBER] = true,
	[ARG_TYPE.TABLE] = false,
	[ARG_TYPE.FUNCTION] = false,
	[ARG_TYPE.ANY_LITERAL] = true,
	[ARG_TYPE.ANY] = false,
	[ARG_TYPE.OPTIONAL_ANY] = false,
	[ARG_TYPE.STATE_EXPRESSION] = true,
}
local ARG_TYPE_CHECK_FUNC = { ---@type table<EnumValue,fun(valueType: type):boolean>
	[ARG_TYPE.STRING] = function(valueType) return valueType == "string" end,
	[ARG_TYPE.STRING_OR_NUMBER] = function(valueType) return valueType == "string" or valueType == "number" end,
	[ARG_TYPE.TABLE] = function(valueType) return valueType == "table" end,
	[ARG_TYPE.FUNCTION] = function(valueType) return valueType == "function" end,
	[ARG_TYPE.ANY_LITERAL] = function(valueType) return valueType == "nil" or valueType == "string" or valueType == "number" or valueType == "boolean" end,
	[ARG_TYPE.ANY] = function(valueType) return true end,
	[ARG_TYPE.OPTIONAL_ANY] = function(valueType) return true end,
	[ARG_TYPE.STATE_EXPRESSION] = function(valueType) return valueType == "table" end,
}
local TERMINAL_STEPS = {
	[STEP.CALL_METHOD] = true,
	[STEP.CALL_FUNCTION] = true,
	[STEP.ASSIGN_TO_TABLE_KEY] = true,
	[STEP.FLAT_MAP] = true,
}

---@class PublisherStepInfo
---@field argTypes EnumValue[]
---@field codeTemplate string?
---@field numIgnoreContext number?
---@field numExtraContextArgs number?
---@field shareType userdata?
---@field hasCancellable boolean?
---@field isTerminal boolean
---@field ignoreOptimization boolean
---@field isUnoptimizable boolean



-- ============================================================================
-- Function Environment
-- ============================================================================

local FUNC_ENV = setmetatable({
	Dump = function(...)
		if not TSMDEV then
			return
		end
		TSMDEV.Dump(...)
	end,
	print = print,
	format = format,
	tostring = tostring,
	error = error,
	unpack = unpack,
	wipe = wipe,
	min = min,
	max = max,
	type = type,
}, {
	__index = function(_, key)
		error("Attempt to access global from compiled publisher: "..tostring(key), 2)
	end,
	__newindex = function(_, key)
		error("Attempt to set global from compiled publisher: "..tostring(key), 2)
	end,
	__metatable = false,
})



-- ============================================================================
-- Code Template Strings
-- ============================================================================

local CODE_TEMPLATE =
[=[local function Reset(context, initialIgnoreValue)
  for i = 1, %(numIgnoreVars)d do
    context[-i] = initialIgnoreValue
  end
  for i = 1, %(numCancellables)d do
    local cancellable = context["cancellable"..i]
    context["cancellable"..i] = nil
    if cancellable then
      cancellable:Cancel()
    end
  end
end
local function Main(data, context)
  %(mainCode)s
end
do
  return Reset, Main
end]=]

---@diagnostic disable: missing-fields
local STEP_INFO = {} ---@type table<EnumValue,PublisherStepInfo>
STEP_INFO[STEP.MAP_WITH_FUNCTION] = { argTypes = { ARG_TYPE.FUNCTION, ARG_TYPE.OPTIONAL_ANY } }
STEP_INFO[STEP.MAP_WITH_FUNCTION].codeTemplate = [=[data = context[%(contextArgIndex)d](data, context[%(contextArgIndex)d + 1])]=]
STEP_INFO[STEP.MAP_WITH_FUNCTION_AND_KEYS] = { argTypes = { ARG_TYPE.FUNCTION, ARG_TYPE.VARARG_STRING }, numExtraContextArgs = MAX_VARARG_ARGS }
STEP_INFO[STEP.MAP_WITH_FUNCTION_AND_KEYS].codeTemplate =
[=[do
  local keyOffset = %(contextArgIndex)d + 1
  local numArgs = context[keyOffset]
  local valueOffset = keyOffset + numArgs
  for i = 1, numArgs do
    context[valueOffset + i] = data[context[keyOffset + i]]
  end
  data = context[%(contextArgIndex)d](unpack(context, valueOffset + 1, valueOffset + numArgs))
end]=]
STEP_INFO[STEP.MAP_WITH_METHOD] = { argTypes = { ARG_TYPE.STRING, ARG_TYPE.OPTIONAL_ANY } }
STEP_INFO[STEP.MAP_WITH_METHOD].codeTemplate = [=[data = data[%(literal)s](data, context[%(contextArgIndex)d])]=]
STEP_INFO[STEP.MAP_WITH_KEY] = { argTypes = { ARG_TYPE.STRING_OR_NUMBER } }
STEP_INFO[STEP.MAP_WITH_KEY].codeTemplate = [=[data = data[%(literal)s]]=]
STEP_INFO[STEP.MAP_WITH_LOOKUP_TABLE] = { argTypes = { ARG_TYPE.TABLE } }
STEP_INFO[STEP.MAP_WITH_LOOKUP_TABLE].codeTemplate = [=[data = context[%(contextArgIndex)d][data]]=]
STEP_INFO[STEP.MAP_WITH_STATE_EXPRESSION] = { argTypes = { ARG_TYPE.STATE_EXPRESSION } }
STEP_INFO[STEP.MAP_WITH_STATE_EXPRESSION].codeTemplate =
[=[do
  %(literal)s
end]=]
STEP_INFO[STEP.MAP_BOOLEAN_WITH_VALUES] = { argTypes = { ARG_TYPE.ANY, ARG_TYPE.ANY } }
STEP_INFO[STEP.MAP_BOOLEAN_WITH_VALUES].codeTemplate =
[=[if data then
  data = context[%(contextArgIndex)d]
else
  data = context[%(contextArgIndex)d + 1]
end]=]
STEP_INFO[STEP.MAP_BOOLEAN_EQUALS] = { argTypes = { ARG_TYPE.ANY } }
STEP_INFO[STEP.MAP_BOOLEAN_EQUALS].codeTemplate = [=[data = data == context[%(contextArgIndex)d]]=]
STEP_INFO[STEP.MAP_BOOLEAN_NOT_EQUALS] = { argTypes = { ARG_TYPE.ANY } }
STEP_INFO[STEP.MAP_BOOLEAN_NOT_EQUALS].codeTemplate = [=[data = data ~= context[%(contextArgIndex)d]]=]
STEP_INFO[STEP.MAP_BOOLEAN_GREATER_THAN_OR_EQUALS] = { argTypes = { ARG_TYPE.STRING_OR_NUMBER } }
STEP_INFO[STEP.MAP_BOOLEAN_GREATER_THAN_OR_EQUALS].codeTemplate = [=[data = data >= %(literal)s]=]
STEP_INFO[STEP.MAP_BOOLEAN_LESS_THAN_OR_EQUALS] = { argTypes = { ARG_TYPE.STRING_OR_NUMBER } }
STEP_INFO[STEP.MAP_BOOLEAN_LESS_THAN_OR_EQUALS].codeTemplate = [=[data = data <= %(literal)s]=]
STEP_INFO[STEP.MAP_STRING_FORMAT] = { argTypes = { ARG_TYPE.STRING } }
STEP_INFO[STEP.MAP_STRING_FORMAT].codeTemplate = [=[data = format(%(literal)s, data)]=]
STEP_INFO[STEP.MAP_TO_VALUE] = { argTypes = { ARG_TYPE.ANY } }
STEP_INFO[STEP.MAP_TO_VALUE].codeTemplate = [=[data = context[%(contextArgIndex)d]]=]
STEP_INFO[STEP.MAP_NIL_TO_VALUE] = { argTypes = { ARG_TYPE.ANY } }
STEP_INFO[STEP.MAP_NIL_TO_VALUE].codeTemplate =
[=[if data == nil then
  data = context[%(contextArgIndex)d]
end]=]
STEP_INFO[STEP.MAP_NON_NIL_WITH_FUNCTION] = { argTypes = { ARG_TYPE.FUNCTION, ARG_TYPE.OPTIONAL_ANY } }
STEP_INFO[STEP.MAP_NON_NIL_WITH_FUNCTION].codeTemplate =
[=[if data ~= nil then
  data = context[%(contextArgIndex)d](data, context[%(contextArgIndex)d + 1])
end]=]
STEP_INFO[STEP.MAP_NON_NIL_WITH_METHOD] = { argTypes = { ARG_TYPE.STRING, ARG_TYPE.OPTIONAL_ANY } }
STEP_INFO[STEP.MAP_NON_NIL_WITH_METHOD].codeTemplate =
[=[if data ~= nil then
  local key = %(literal)s
  local func = data[key]
  if not func then
    error("Method ("..tostring(key)..") does not exist on object ("..tostring(data)..")")
  end
  data = func(data, context[%(contextArgIndex)d])
end]=]
STEP_INFO[STEP.INVERT_BOOLEAN] = { argTypes = {} }
STEP_INFO[STEP.INVERT_BOOLEAN].codeTemplate =
[=[if data ~= true and data ~= false then
  error("Invalid data type: "..tostring(data))
end
data = not data]=]
STEP_INFO[STEP.IGNORE_IF_KEY_EQUALS] = { argTypes = { ARG_TYPE.STRING_OR_NUMBER, ARG_TYPE.ANY_LITERAL } }
STEP_INFO[STEP.IGNORE_IF_KEY_EQUALS].codeTemplate =
[=[if data[%(literal)s] == %(literal2)s then
  break
end]=]
STEP_INFO[STEP.IGNORE_IF_KEY_NOT_EQUALS] = { argTypes = { ARG_TYPE.STRING_OR_NUMBER, ARG_TYPE.ANY_LITERAL } }
STEP_INFO[STEP.IGNORE_IF_KEY_NOT_EQUALS].codeTemplate =
[=[if data[%(literal)s] ~= %(literal2)s then
  break
end]=]
STEP_INFO[STEP.IGNORE_IF_EQUALS] = { argTypes = { ARG_TYPE.ANY_LITERAL } }
STEP_INFO[STEP.IGNORE_IF_EQUALS].codeTemplate =
[=[if data == %(literal)s then
  break
end]=]
STEP_INFO[STEP.IGNORE_IF_NOT_EQUALS] = { argTypes = { ARG_TYPE.ANY_LITERAL } }
STEP_INFO[STEP.IGNORE_IF_NOT_EQUALS].codeTemplate =
[=[if data ~= %(literal)s then
  break
end]=]
STEP_INFO[STEP.IGNORE_DUPLICATES] = { argTypes = {}, numIgnoreContext = 1 }
STEP_INFO[STEP.IGNORE_DUPLICATES].codeTemplate =
[=[if data == context[-%(ignoreIndex)d] then
  break
end
context[-%(ignoreIndex)d] = data]=]
STEP_INFO[STEP.IGNORE_DUPLICATES_WITH_KEYS] = { argTypes = { ARG_TYPE.VARARG_STRING }, numIgnoreContext = -1 }
STEP_INFO[STEP.IGNORE_DUPLICATES_WITH_KEYS].codeTemplate =
[=[do
  local isEqual = true
  for i = 1, context[%(contextArgIndex)d] do
    local key = context[%(contextArgIndex)d + i]
    local value = data[key]
    local ignoreIndex = -(%(ignoreIndex)d + i - 1)
    isEqual = isEqual and value == context[ignoreIndex]
    context[ignoreIndex] = value
  end
  if isEqual then
    break
  end
end]=]
STEP_INFO[STEP.SHARE] = { argTypes = {}, shareType = SHARE_TYPE.START }
STEP_INFO[STEP.END_SHARE] = { argTypes = {}, shareType = SHARE_TYPE.END }
STEP_INFO[STEP.PRINT] = { argTypes = { ARG_TYPE.OPTIONAL_ANY } }
STEP_INFO[STEP.PRINT].codeTemplate =
[=[do
  local contextStr = context[%(contextArgIndex)d]
  if contextStr then
    print("Published value ("..tostring(contextStr).."): "..tostring(data))
  else
    print("Published value: "..tostring(data))
  end
  if type(data) == "table" then
    Dump(data)
  end
end]=]
STEP_INFO[STEP.CALL_METHOD] = { argTypes = { ARG_TYPE.TABLE, ARG_TYPE.STRING, ARG_TYPE.OPTIONAL_ANY } }
STEP_INFO[STEP.CALL_METHOD].codeTemplate =
[=[do
  local obj = context[%(contextArgIndex)d]
  local methodName = %(literal)s
  local func = obj[methodName]
  if not func then
    error("Method ("..methodName..") does not exist on object ("..tostring(obj)..")")
  end
  func(obj, data, context[%(contextArgIndex)d + 1])
end]=]
STEP_INFO[STEP.CALL_FUNCTION] = { argTypes = { ARG_TYPE.FUNCTION, ARG_TYPE.OPTIONAL_ANY } }
STEP_INFO[STEP.CALL_FUNCTION].codeTemplate = [=[context[%(contextArgIndex)d](data, context[%(contextArgIndex)d + 1])]=]
STEP_INFO[STEP.ASSIGN_TO_TABLE_KEY] = { argTypes = { ARG_TYPE.TABLE, ARG_TYPE.STRING } }
STEP_INFO[STEP.ASSIGN_TO_TABLE_KEY].codeTemplate = [=[context[%(contextArgIndex)d][%(literal)s] = data]=]
STEP_INFO[STEP.FLAT_MAP] = { argTypes = { ARG_TYPE.FUNCTION }, hasCancellable = true }
STEP_INFO[STEP.FLAT_MAP].codeTemplate =
[=[do
  local publisher = context[%(contextArgIndex)d](data)
  local cancellable = context[%(cancellableKey)s]
  if cancellable then
    cancellable:Cancel()
  end
  context[%(cancellableKey)s] = publisher:Stored()
end]=]
do
	for stepType, info in pairs(STEP_INFO) do
		info.isTerminal = TERMINAL_STEPS[stepType] or false
		info.ignoreOptimization = OPTIMIZATION_IGNORED_STEPS[stepType] or info.isTerminal
		info.isUnoptimizable = UNOPTIMIZABLE_STEPS[stepType] or false
		for i, argType in ipairs(info.argTypes) do
			if argType == ARG_TYPE.VARARG_STRING or argType == ARG_TYPE.STATE_EXPRESSION then
				assert(i == #info.argTypes)
			end
		end
	end
end
---@diagnostic enable: missing-fields



-- ============================================================================
-- Static Class Functions
-- ============================================================================

---Gets a code gen object.
---@return ReactivePublisherCodeGen
function ReactivePublisherCodeGen.__static.Get()
	local obj = private.objectPool:Get()
	return obj
end



-- ============================================================================
-- Meta Class Methods
-- ============================================================================

function ReactivePublisherCodeGen.__private:__init()
	self._hash = nil
	self._steps = {} ---@type PublisherStepInfo[]
	self._args = {}
	self._comment = {}
	self._firstArgIndex = {}
	self._totalNumArgs = 0
	self._firstIgnoreVarIndex = {}
	self._totalNumIgnoreVars = 0
	self._literals = {}
	self._optimizeResult = nil
	self._optimizeKeys = {}
end

function ReactivePublisherCodeGen.__private:_Release()
	self._hash = nil
	wipe(self._steps)
	Table.WipeAndDeallocate(self._args)
	Table.WipeAndDeallocate(self._comment)
	wipe(self._firstArgIndex)
	self._totalNumArgs = 0
	wipe(self._firstIgnoreVarIndex)
	self._totalNumIgnoreVars = 0
	wipe(self._literals)
	self._optimizeResult = nil
	Table.WipeAndDeallocate(self._optimizeKeys)
	private.objectPool:Recycle(self)
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

---Adds a publisher step for code generation and returns whether or not it should be the last step.
---@param stepType EnumValue The publisher step type
---@param ... any The arguments
function ReactivePublisherCodeGen:AddStep(stepType, ...)
	assert(STEP:HasValue(stepType))
	local numArgs = select("#", ...)

	-- Add the step
	local info = STEP_INFO[stepType]
	assert(info)
	tinsert(self._steps, info)
	self._hash = Hash.Calculate(tostring(stepType), self._hash)
	local stepNum = #self._steps

	-- Handle share steps specially
	if info.shareType then
		if info.shareType == SHARE_TYPE.START then
			-- Can't have a start share step right after another share step
			assert(not self._steps[stepNum - 1].shareType)
		end
		if self._optimizeResult == nil then
			self._optimizeResult = false
			wipe(self._optimizeKeys)
		end
		self:_AddComment(stepType, "")
		return
	end

	-- Process the args
	local numVarargArgs = 0
	assert(#private.argCommentTemp == 0)
	for i, argType in ipairs(info.argTypes) do
		if argType == ARG_TYPE.VARARG_STRING then
			numVarargArgs = numArgs - i + 1
			assert(numVarargArgs > 0 and numVarargArgs <= MAX_VARARG_ARGS)
			self:_AddArg(numVarargArgs)
			for j = i, numArgs do
				local key = select(j, ...)
				self:_AddTypedArg(key, ARG_TYPE.STRING)
				if info.numIgnoreContext then
					self:_AddIgnoreVar()
				end
			end
		else
			local arg = select(i, ...)
			self:_AddTypedArg(arg, argType, i, numArgs)
		end
	end
	self:_AddComment(stepType, table.concat(private.argCommentTemp, ","))
	wipe(private.argCommentTemp)
	if info.numExtraContextArgs then
		assert(self._firstArgIndex[stepNum])
		self._totalNumArgs = self._totalNumArgs + info.numExtraContextArgs
	end
	if numVarargArgs > 0 then
		if info.numIgnoreContext == -1 then
			-- Add placeholder ignore vars so that the total number is always the same
			self._totalNumIgnoreVars = self._totalNumIgnoreVars + MAX_VARARG_ARGS - numVarargArgs
		else
			assert(not info.numIgnoreContext)
		end
		-- Add placeholder args for the unused vararg slots so that the total number of arguments is always the same
		self._totalNumArgs = self._totalNumArgs + MAX_VARARG_ARGS - numVarargArgs
	else
		assert(numArgs <= #info.argTypes)
		if info.numIgnoreContext then
			assert(info.numIgnoreContext >= 1)
			self._firstIgnoreVarIndex[stepNum] = self._totalNumIgnoreVars + 1
			self._totalNumIgnoreVars = self._totalNumIgnoreVars + info.numIgnoreContext
		end
	end

	-- Update the optimization info
	if self._optimizeResult == nil then
		if stepType == STEP.MAP_WITH_KEY or stepType == STEP.IGNORE_IF_KEY_EQUALS or stepType == STEP.IGNORE_IF_KEY_NOT_EQUALS then
			local arg1 = ...
			self._optimizeKeys[arg1] = true
		elseif stepType == STEP.IGNORE_DUPLICATES or stepType == STEP.MAP_TO_VALUE then
			self._optimizeResult = true
		elseif stepType == STEP.IGNORE_DUPLICATES_WITH_KEYS then
			for _, key in Vararg.Iterator(...) do
				self._optimizeKeys[key] = true
			end
			self._optimizeResult = true
		elseif info.isTerminal or info.ignoreOptimization then
			-- Ignore these steps for optimizations
		elseif info.isUnoptimizable then
			-- Not able to optimize
			self._optimizeResult = false
			wipe(self._optimizeKeys)
		else
			error("Invalid stepType: "..tostring(stepType))
		end
	end
end

---Commits the generated code to a compiled publisher object and release the code gen object.
---@return CompiledPublisherObject compiledObj
---@return boolean optimizeResult
function ReactivePublisherCodeGen:Commit(context, optimizeKeys)
	Table.CopyFrom(context, self._args)
	Table.CopyFrom(optimizeKeys, self._optimizeKeys)
	local optimizeResult = self._optimizeResult
	local hash = self._hash
	assert(hash)
	private.cache[hash] = private.cache[hash] or CompiledPublisher.Create(self:_CompileFunction())
	self:_Release()
	return private.cache[hash], optimizeResult
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

function ReactivePublisherCodeGen.__private:_AddComment(stepType, argsStr)
	local stepNum = #self._steps
	local stepName = strmatch(tostring(stepType), "^PUBLISHER_STEP%.(.+)$")
	stepName = gsub(stepName, "([^_]+)", private.UpperCamelCaseHelper)
	stepName = gsub(stepName, "_", "")
	self._comment[stepNum] = format("%s(%s)", stepName, argsStr)
end

function ReactivePublisherCodeGen.__private:_AddTypedArg(arg, argType, argNum, numArgs)
	local passedArgType = type(arg)
	assert(ARG_TYPE_CHECK_FUNC[argType](passedArgType))
	if argType == ARG_TYPE.STATE_EXPRESSION then
		local expression = arg --[[@as ReactiveStateExpression]]
		self:_AddLiteral(gsub(expression:GetCode(), "\n", "\n  "), true)
		tinsert(private.argCommentTemp, "[["..expression:GetOriginalExpression().."]]")
		return
	elseif passedArgType == "string" then
		tinsert(private.argCommentTemp, "\""..arg.."\"")
	elseif passedArgType == "number" or passedArgType == "boolean" then
		tinsert(private.argCommentTemp, tostring(arg))
	elseif argNum < numArgs and passedArgType == "nil" then
		tinsert(private.argCommentTemp, "nil")
	elseif argNum < numArgs or (argNum == numArgs and passedArgType ~= "nil") then
		tinsert(private.argCommentTemp, "<"..tostring(arg)..">")
	end
	if ARG_TYPE_IS_LITERAL[argType] and argNum then
		self:_AddLiteral(arg)
	else
		self:_AddArg(arg)
	end
end

function ReactivePublisherCodeGen.__private:_AddArg(arg)
	local stepNum = #self._steps
	local argIndex = self._totalNumArgs + 1
	self._totalNumArgs = argIndex
	self._args[argIndex] = arg
	self._firstArgIndex[stepNum] = self._firstArgIndex[stepNum] or argIndex
end

function ReactivePublisherCodeGen.__private:_AddIgnoreVar()
	local stepNum = #self._steps
	local argIndex = self._totalNumIgnoreVars + 1
	self._totalNumIgnoreVars = argIndex
	self._firstIgnoreVarIndex[stepNum] = self._firstIgnoreVarIndex[stepNum] or argIndex
end

function ReactivePublisherCodeGen.__private:_AddLiteral(value, raw)
	-- Add the literal to our hash
	self._hash = Hash.Calculate(value, self._hash)
	local valueType = type(value)
	if raw then
		assert(valueType == "string")
	elseif valueType == "string" then
		value = "\""..value.."\""
	else
		value = tostring(value)
	end
	local stepNum = #self._steps
	if self._literals[stepNum] then
		-- Store a 2nd literal at the negative index
		assert(not self._literals[-stepNum])
		self._literals[-stepNum] = value
	else
		self._literals[stepNum] = value
	end
end

function ReactivePublisherCodeGen.__private:_CompileFunction()
	assert(not next(private.codeTemp) and private.codeIndentation == 0)
	private.InsertBlockStartCode()
	local numSteps = #self._steps
	local shareDepth, numCancellables = 0, 0
	for stepNum, info in ipairs(self._steps) do
		private.InsertIndentedCode("-- "..self._comment[stepNum])
		local endSharedDataBlock = false
		if info.shareType == SHARE_TYPE.START then
			assert(not info.hasCancellable)
			private.InsertShareBlockStart()
			private.InsertSharedDataBlockStart()
			shareDepth = shareDepth + 1
		elseif info.shareType == SHARE_TYPE.END then
			assert(not info.hasCancellable)
			private.InsertBlockEndCode()
			shareDepth = shareDepth - 1
			assert(shareDepth ~= 0 or stepNum == numSteps)
			endSharedDataBlock = shareDepth > 0
		else
			assert(not info.shareType)
			if info.hasCancellable then
				numCancellables = numCancellables + 1
			end
			self:_CompileStep(stepNum, info.codeTemplate, info.hasCancellable and numCancellables or nil)
			endSharedDataBlock = info.isTerminal and shareDepth > 0
		end
		if endSharedDataBlock then
			-- End the current shared data block
			private.InsertIndentedCode("-- End shared data block")
			private.InsertBlockEndCode()
			assert(stepNum < numSteps)
			if self._steps[stepNum + 1].shareType ~= SHARE_TYPE.END then
				private.InsertSharedDataBlockStart()
			end
		end
	end
	assert(shareDepth == 0)
	private.InsertBlockEndCode()
	assert(private.codeIndentation == 0)
	local funcCode = private.stringBuilder
		:SetTemplate(CODE_TEMPLATE)
		:SetParam("numIgnoreVars", self._totalNumIgnoreVars)
		:SetParam("numCancellables", numCancellables)
		:SetParam("mainCode", table.concat(private.codeTemp, "\n  "))
		:Commit()
	wipe(private.codeTemp)

	local wrapperFunc = assert(loadstring(funcCode))
	setfenv(wrapperFunc, FUNC_ENV)
	return wrapperFunc()
end

function ReactivePublisherCodeGen.__private:_CompileStep(stepNum, codeTemplate, cancellableIndex)
	private.stringBuilder = private.stringBuilder or StringBuilder.Create()
	private.stringBuilder:SetTemplate(codeTemplate)
	local literal = self._literals[stepNum]
	if literal then
		private.stringBuilder:SetParam("literal", literal)
		assert(private.stringBuilder:GetParamCount("literal") == 1)
		local literal2 = self._literals[-stepNum]
		if literal2 then
			private.stringBuilder:SetParam("literal2", literal2)
			assert(private.stringBuilder:GetParamCount("literal2") == 1)
		else
			assert(private.stringBuilder:GetParamCount("literal2") == 0)
		end
	else
		assert(private.stringBuilder:GetParamCount("literal") == 0)
		assert(private.stringBuilder:GetParamCount("literal2") == 0)
	end
	local firstArgIndex = self._firstArgIndex[stepNum]
	if firstArgIndex then
		private.stringBuilder:SetParam("contextArgIndex", firstArgIndex)
		assert(private.stringBuilder:GetParamCount("contextArgIndex") > 0)
	else
		assert(private.stringBuilder:GetParamCount("contextArgIndex") == 0)
	end
	local firstIgnoreVarIndex = self._firstIgnoreVarIndex[stepNum]
	if firstIgnoreVarIndex then
		private.stringBuilder:SetParam("ignoreIndex", firstIgnoreVarIndex)
		assert(private.stringBuilder:GetParamCount("ignoreIndex") > 0)
	else
		assert(private.stringBuilder:GetParamCount("ignoreIndex") == 0)
	end
	if cancellableIndex then
		private.stringBuilder:SetParam("cancellableKey", "\"cancellable"..cancellableIndex.."\"")
		assert(private.stringBuilder:GetParamCount("cancellableKey") > 0)
	else
		assert(private.stringBuilder:GetParamCount("cancellableKey") == 0)
	end
	private.InsertIndentedCode(private.FixIndentation(private.stringBuilder:Commit(), private.codeIndentation + 1))
end



-- ============================================================================
-- Private Helper Functions
-- ============================================================================

function private.UpperCamelCaseHelper(part)
	return strsub(part, 1, 1)..strlower(strsub(part, 2))
end

function private.InsertBlockStartCode()
	private.InsertIndentedCode("repeat")
	private.codeIndentation = private.codeIndentation + 1
end

function private.InsertBlockEndCode()
	private.codeIndentation = private.codeIndentation - 1
	private.InsertIndentedCode("until true")
end

function private.InsertShareBlockStart()
	private.InsertBlockStartCode()
	-- Intentionally shadowing the outer `shareData` variable
	private.InsertIndentedCode("local shareData = data")
end

function private.InsertSharedDataBlockStart()
	private.InsertIndentedCode("-- New shared data block")
	private.InsertBlockStartCode()
	-- Intentionally shadowing the outer `data` variable
	private.InsertIndentedCode("local data = shareData")
end

function private.InsertIndentedCode(code)
	assert(private.codeIndentation >= 0)
	tinsert(private.codeTemp, private.GetIndentation(private.codeIndentation)..code)
end

function private.FixIndentation(code, indentationLevel)
	code = gsub(code, "\n", "\n"..private.GetIndentation(indentationLevel))
	return code
end

function private.GetIndentation(level)
	private.indentationCache[level] = private.indentationCache[level] or strrep("  ", level)
	return private.indentationCache[level]
end
