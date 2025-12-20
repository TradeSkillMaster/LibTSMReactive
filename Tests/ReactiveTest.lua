local TSM, Locals = ... ---@type TSM, table<string,table<string,any>>
local LibTSMReactive = TSM.LibTSMReactive
local Reactive = LibTSMReactive:Include("Reactive")
local EnumType = LibTSMReactive:From("LibTSMUtil"):Include("BaseType.EnumType")
local private = {
	cancellables = {},
}



-- ============================================================================
-- Tests
-- ============================================================================

TestState = {}

function TestState:setUp()
end

function TestState:tearDown()
	for _, cancellable in ipairs(private.cancellables) do
		cancellable:Cancel()
	end
	wipe(private.cancellables)
	local objectPool = Locals["LibTSMReactive.Internal.PublisherSchema"].private.objectPool
	assertEquals(objectPool._state, {})
	local objectPoolShared = Locals["LibTSMReactive.Internal.PublisherSchemaShared"].private.objectPool
	assertEquals(objectPoolShared._state, {})
end

function TestState:TestSetGetValues()
	local state = Reactive.CreateStateSchema("TEST_SET_GET")
		:AddNumberField("num1", 0)
		:AddStringField("str1", "")
		:Commit()
		:CreateState()

	assertEquals(state.num1, 0)
	assertEquals(state.str1, "")

	state.num1 = 1
	assertEquals(state.num1, 1)
	assertEquals(state.str1, "")

	state:ResetToDefault()
	assertEquals(state.num1, 0)
	assertEquals(state.str1, "")

	assertError(function() return state.str2 end)
	assertError(function() state.str2 = "" end)
	assertError(function() state.str1 = 0 end)
end

function TestState:TestPublisher()
	local state = Reactive.CreateStateSchema("TEST_PUBLISHER")
		:AddNumberField("num1", 0)
		:AddStringField("str1", "")
		:Commit()
		:CreateState()
		:SetAutoStore(private.cancellables)

	local publishedValues1 = {}
	state:Publisher("num1")
		:CallFunction(function(value) tinsert(publishedValues1, value) end)

	local publishedValues2, publishedValues3 = {}, {}
	state:Publisher("str1")
		:IgnoreIfEquals("ignore1")
		:IgnoreIfEquals("ignore2")
		:CallFunction(function(value) tinsert(publishedValues2, value) end)
	state:Publisher("str1")
		:IgnoreIfEquals("ignore1")
		:IgnoreIfEquals("ignore3")
		:CallFunction(function(value) tinsert(publishedValues3, value) end)

	assertEquals(publishedValues1, {0})
	assertEquals(publishedValues2, {""})
	assertEquals(publishedValues3, {""})

	state.num1 = 1
	assertEquals(publishedValues1, {0, 1})
	assertEquals(publishedValues2, {""})
	assertEquals(publishedValues3, {""})

	state.str1 = "a"
	assertEquals(publishedValues1, {0, 1})
	assertEquals(publishedValues2, {"", "a"})
	assertEquals(publishedValues3, {"", "a"})

	state.str1 = "ignore1"
	assertEquals(publishedValues1, {0, 1})
	assertEquals(publishedValues2, {"", "a"})
	assertEquals(publishedValues3, {"", "a"})

	state.str1 = "ignore2"
	assertEquals(publishedValues1, {0, 1})
	assertEquals(publishedValues2, {"", "a"})
	assertEquals(publishedValues3, {"", "a", "ignore2"})

	state.str1 = "ignore3"
	assertEquals(publishedValues1, {0, 1})
	assertEquals(publishedValues2, {"", "a", "ignore3"})
	assertEquals(publishedValues3, {"", "a", "ignore2"})

	local publishedValues4 = {}
	state:Publisher("num1")
		:MapToValue({val = 2, GetValue = function(self, extra) return self.val + extra end})
		:MapWithMethod("GetValue", 1)
		:CallFunction(function(value) tinsert(publishedValues4, value) end)
	assertEquals(publishedValues4, {3})
end

function TestState:TestNilDuplicates()
	local state = Reactive.CreateStateSchema("TEST_PUBLISHER")
		:AddOptionalNumberField("num")
		:Commit()
		:CreateState()
		:SetAutoStore(private.cancellables)

	local publishedValues = {}
	state:Publisher("num")
		:MapNilToValue(-1)
		:CallFunction(function(value) tinsert(publishedValues, value) end)

	assertEquals(publishedValues, {-1})

	state.num = 1
	assertEquals(publishedValues, {-1, 1})

	state.num = -1
	assertEquals(publishedValues, {-1, 1, -1})

	state.num = nil
	assertEquals(publishedValues, {-1, 1, -1, -1})

	state.num = -1
	assertEquals(publishedValues, {-1, 1, -1, -1, -1})
end

function TestState:TestFunctionWithKeys()
	local state = Reactive.CreateStateSchema("TEST_FUNCTION_WITH_KEYS")
		:AddNumberField("num", 0)
		:AddOptionalStringField("str")
		:Commit()
		:CreateState()
		:SetAutoStore(private.cancellables)

	local function MapFunc(num, str)
		return num == 0 and "" or str or "nil"
	end
	local function MapFunc2(num)
		return num % 2 == 0 and "EVEN" or "ODD"
	end
	local publishedValues1 = {}
	local publishedValues2 = {}
	state:PublisherForFunctionWithKeys(MapFunc, "num", "str")
		:CallFunction(function(value) tinsert(publishedValues1, value) end)
	state:PublisherForFunctionWithKeys(MapFunc2, "num")
		:CallFunction(function(value) tinsert(publishedValues2, value) end)

	assertEquals(publishedValues1, {""})
	assertEquals(publishedValues2, {"EVEN"})

	state.num = 1
	assertEquals(publishedValues1, {"", "nil"})
	assertEquals(publishedValues2, {"EVEN", "ODD"})

	state.num = 2
	assertEquals(publishedValues1, {"", "nil"})
	assertEquals(publishedValues2, {"EVEN", "ODD", "EVEN"})

	state.num = 0
	assertEquals(publishedValues1, {"", "nil", ""})
	assertEquals(publishedValues2, {"EVEN", "ODD", "EVEN"})

	state.str = "a"
	assertEquals(publishedValues1, {"", "nil", ""})
	assertEquals(publishedValues2, {"EVEN", "ODD", "EVEN"})

	state.num = 1
	assertEquals(publishedValues1, {"", "nil", "", "a"})
	assertEquals(publishedValues2, {"EVEN", "ODD", "EVEN", "ODD"})

	state.str = "b"
	assertEquals(publishedValues1, {"", "nil", "", "a", "b"})
	assertEquals(publishedValues2, {"EVEN", "ODD", "EVEN", "ODD"})

	state.num = 3
	assertEquals(publishedValues1, {"", "nil", "", "a", "b"})
	assertEquals(publishedValues2, {"EVEN", "ODD", "EVEN", "ODD"})

	state.num = 0
	assertEquals(publishedValues1, {"", "nil", "", "a", "b", ""})
	assertEquals(publishedValues2, {"EVEN", "ODD", "EVEN", "ODD", "EVEN"})
end

function TestState:TestShare()
	local state = Reactive.CreateStateSchema("TEST_SHARE")
		:AddNumberField("num", 0)
		:Commit()
		:CreateState()
		:SetAutoStore(private.cancellables)

	local publishedValues1 = {}
	local publishedValues2 = {}
	state:Publisher("num")
		:IgnoreIfEquals(0)
		:Share()
		:MapWithFunction(function(value) return floor(value / 2) end)
		:IgnoreDuplicates()
		:CallFunction(function(value) tinsert(publishedValues1, value) end)
		:CallFunction(function(value) tinsert(publishedValues2, value) end)
		:EndShare()

	state.num = 1
	assertEquals(publishedValues1, {0})
	assertEquals(publishedValues2, {1})

	state.num = 2
	assertEquals(publishedValues1, {0, 1})
	assertEquals(publishedValues2, {1, 2})

	state.num = 3
	assertEquals(publishedValues1, {0, 1})
	assertEquals(publishedValues2, {1, 2, 3})

	state.num = 0
	assertEquals(publishedValues1, {0, 1})
	assertEquals(publishedValues2, {1, 2, 3})
end

function TestState:TestNestedShare()
	local state = Reactive.CreateStateSchema("TEST_NESTED_SHARE")
		:AddStringField("str", "INITIAL")
		:Commit()
		:CreateState()
		:SetAutoStore(private.cancellables)

	local function GetInsertValueFunc(tbl)
		return function(value) tinsert(tbl, value) end
	end

	local publishedValues = {{}, {}, {}, {}, {}, {}}
	state:Publisher("str")
		:IgnoreIfEquals("")
		:Share()
		:MapToStringAddSuffix("_1")
		:CallFunction(GetInsertValueFunc(publishedValues[1]))
		:IgnoreIfEquals("B")
		:MapToStringAddSuffix("_2")
		:NestedShare()
			:MapToStringAddSuffix("_3")
			:NestedShare()
				:CallFunction(GetInsertValueFunc(publishedValues[2]))
				:MapToStringAddSuffix("_4")
				:CallFunction(GetInsertValueFunc(publishedValues[3]))
			:EndNestedShare()
			:CallFunction(GetInsertValueFunc(publishedValues[4]))
		:EndNestedShare()
		:MapToStringAddSuffix("_5")
		:CallFunction(GetInsertValueFunc(publishedValues[5]))
		:CallFunction(GetInsertValueFunc(publishedValues[6]))
		:EndShare()

	assertEquals(publishedValues, {{"INITIAL_1"}, {"INITIAL_2_3"}, {"INITIAL_2_3_4"}, {"INITIAL_2"}, {"INITIAL_5"}, {"INITIAL"}})
	for _, tbl in ipairs(publishedValues) do wipe(tbl) end

	state.str = "A"
	assertEquals(publishedValues, {{"A_1"}, {"A_2_3"}, {"A_2_3_4"}, {"A_2"}, {"A_5"}, {"A"}})
	for _, tbl in ipairs(publishedValues) do wipe(tbl) end

	state.str = "B"
	assertEquals(publishedValues, {{"B_1"}, {}, {}, {}, {"B_5"}, {"B"}})
	for _, tbl in ipairs(publishedValues) do wipe(tbl) end

	state.str = "C"
	assertEquals(publishedValues, {{"C_1"}, {"C_2_3"}, {"C_2_3_4"}, {"C_2"}, {"C_5"}, {"C"}})
	for _, tbl in ipairs(publishedValues) do wipe(tbl) end

	state.str = ""
	assertEquals(publishedValues, {{}, {}, {}, {}, {}, {}})
	for _, tbl in ipairs(publishedValues) do wipe(tbl) end
end

function TestState:TestStateExpression()
	local COLOR = EnumType.New("COLOR", {
		RED = EnumType.NewValue(),
		BLUE = EnumType.NewValue(),
	})
	local state = Reactive.CreateStateSchema("TEST_STATE_EXPRESSION")
		:AddEnumField("color", COLOR, COLOR.RED)
		:AddNumberField("num1", 10)
		:AddNumberField("num2", 20)
		:AddStringField("str", "1+2")
		:Commit()
		:CreateState()
		:SetAutoStore(private.cancellables)

	local publishedValues1 = {}
	local publishedValues2 = {}
	local publishedValues3 = {}
	local publishedValues4 = {}
	state:Publisher([[num1 + num2]])
		:CallFunction(function(value) tinsert(publishedValues1, value) end)
	state:Publisher([[-1 * (EnumEquals(color, RED) and -num1 or -num2)]])
		:CallFunction(function(value) tinsert(publishedValues2, value) end)
	state:Publisher([[EnumEquals(color, RED) and "String 1" or "String 2"]])
		:CallFunction(function(value) tinsert(publishedValues3, value) end)
	state:Publisher([[num1 == 10 and Ignore() or num1]])
		:CallFunction(function(value) tinsert(publishedValues4, value) end)

	assertEquals(publishedValues1, {30})
	assertEquals(publishedValues2, {10})
	assertEquals(publishedValues3, {"String 1"})
	assertEquals(publishedValues4, {})

	state.color = COLOR.BLUE
	assertEquals(publishedValues1, {30})
	assertEquals(publishedValues2, {10, 20})
	assertEquals(publishedValues3, {"String 1", "String 2"})
	assertEquals(publishedValues4, {})

	state.num1 = 11
	assertEquals(publishedValues1, {30, 31})
	assertEquals(publishedValues2, {10, 20})
	assertEquals(publishedValues3, {"String 1", "String 2"})
	assertEquals(publishedValues4, {11})

	state.num2 = 21
	assertEquals(publishedValues1, {30, 31, 32})
	assertEquals(publishedValues2, {10, 20, 21})
	assertEquals(publishedValues3, {"String 1", "String 2"})
	assertEquals(publishedValues4, {11})

	local publishedValues5 = {}
	state:Publisher([[str == "1+2" and "orig" or "changed"]])
		:CallFunction(function(value) tinsert(publishedValues5, value) end)
	assertEquals(publishedValues5, {"orig"})
	state.str = "2+3"
	assertEquals(publishedValues5, {"orig", "changed"})
end

function TestState:TestDeferred()
	local state = Reactive.CreateStateSchema("TEST_DEFER")
		:AddStringField("str", "A")
		:Commit()
		:CreateState()
		:SetAutoStore(private.cancellables)

	local publishedValues = {}
	state:SetAutoDeferred(true)
	state:Publisher("str")
		:CallFunction(function(value) tinsert(publishedValues, "1_"..value) end)
	state:SetAutoDeferred(false)
	state:Publisher("str")
		:CallFunction(function(value) tinsert(publishedValues, "2_"..value) end)
	assertEquals(publishedValues, {"1_A", "2_A"})

	state.str = "B"
	assertEquals(publishedValues, {"1_A", "2_A", "2_B", "1_B"})
end

function TestState:TestDisable()
	local state = Reactive.CreateStateSchema("TEST_DIABLE")
		:AddStringField("str", "A")
		:Commit()
		:CreateState()
		:SetAutoStore(private.cancellables)
		:SetAutoDisable(true)

	local publishedValues = {}
	local publisher = state:Publisher("str")
		:CallFunction(function(value) tinsert(publishedValues, value) end)
	assertEquals(publishedValues, {})

	state.str = "B"
	assertEquals(publishedValues, {})

	publisher:EnableAndReset()
	assertEquals(publishedValues, {"B"})

	publisher:Disable()
	publisher:EnableAndReset()
	assertEquals(publishedValues, {"B", "B"})

	state.str = "C"
	assertEquals(publishedValues, {"B", "B", "C"})

	publisher:Disable()
	state.str = "D"
	assertEquals(publishedValues, {"B", "B", "C"})
end
