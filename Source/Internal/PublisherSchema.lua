-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local ReactivePublisherSchemaBase = LibTSMReactive:IncludeClassType("ReactivePublisherSchemaBase")
local ReactivePublisherSchema = LibTSMReactive:DefineInternalClassType("ReactivePublisherSchema", ReactivePublisherSchemaBase)
local ReactivePublisher = LibTSMReactive:IncludeClassType("ReactivePublisher")
local ReactivePublisherCodeGen = LibTSMReactive:IncludeClassType("ReactivePublisherCodeGen")
local ReactivePublisherSchemaShared = LibTSMReactive:IncludeClassType("ReactivePublisherSchemaShared")
local Util = LibTSMReactive:Include("Reactive.Util")
local ObjectPool = LibTSMReactive:From("LibTSMUtil"):IncludeClassType("ObjectPool")
local private = {
	objectPool = ObjectPool.New("PUBLISHER_SCHEMA", ReactivePublisherSchema --[[@as Class]], 2),
}
local STEP = Util.PUBLISHER_STEP



-- ============================================================================
-- Static Class Functions
-- ============================================================================

---Gets a publisher schema object.
---@param subject ReactiveSubject The subject which is publishing values
---@return ReactivePublisherSchema
function ReactivePublisherSchema.__static.Get(subject)
	local publisher = private.objectPool:Get()
	publisher:_Acquire(subject)
	return publisher
end



-- ============================================================================
-- Meta Class Methods
-- ============================================================================

function ReactivePublisherSchema.__protected:__init()
	self.__super:__init(false)
	self._subject = nil
	self._codeGen = nil
	self._autoStore = nil
	self._autoDisable = false
	self._hasShare = false
end

---@param subject ReactiveSubject
function ReactivePublisherSchema.__protected:_Acquire(subject)
	self._subject = subject
end

function ReactivePublisherSchema.__protected:_Release()
	assert(not self._codeGen)
	self._subject = nil
	self._autoStore = nil
	self._autoDisable = false
	self._hasShare = false
	private.objectPool:Recycle(self)
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

---Shares the result of the publisher at the current point in the chain.
---@return ReactivePublisherSchemaShared
---@nodiscard
function ReactivePublisherSchema:Share()
	assert(not self._hasShare)
	self._hasShare = true
	self:_AddStepHelper(STEP.SHARE)
	assert(self._codeGen)
	return ReactivePublisherSchemaShared.Get(self, self._codeGen)
end

---Calls a method with the published values.
---@param obj table The object to call the method on
---@param method string The name of the method to call with the published values
---@param arg any An additional argument to pass to the method
---@return ReactivePublisher
function ReactivePublisherSchema:CallMethod(obj, method, arg)
	assert(not self._hasShare)
	local _ = self.__super:CallMethod(obj, method, arg)
	return self:_Commit()
end

---Calls a function with the published values.
---@param func fun(value: any) The function to call with the published values
---@param arg any An additional argument to pass to the function
---@return ReactivePublisher
function ReactivePublisherSchema:CallFunction(func, arg)
	assert(not self._hasShare)
	local _ = self.__super:CallFunction(func, arg)
	return self:_Commit()
end

---Assigns published values to the specified key in the table.
---@param tbl table The table to assign the published values into
---@param key string The key to assign the published values at
---@return ReactivePublisher
function ReactivePublisherSchema:AssignToTableKey(tbl, key)
	assert(not self._hasShare)
	local _ = self.__super:AssignToTableKey(tbl, key)
	return self:_Commit()
end

---Maps published values to a new publisher which is owned by the current publisher.
---@param map fun(value: any): ReactivePublisher A function which takes a published value and returns a new publisher
---@return ReactivePublisher
function ReactivePublisherSchema:FlatMap(map)
	assert(not self._hasShare)
	local _ = self.__super:FlatMap(map)
	return self:_Commit()
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

---@private
function ReactivePublisherSchema:_AutoStore(tbl)
	assert(type(tbl) == "table" and not self._autoStore)
	assert(self._subject and not self._codeGen)
	self._autoStore = tbl
	return self
end

---@private
function ReactivePublisherSchema:_AutoDisable()
	self._autoDisable = true
	return self
end

function ReactivePublisherSchema.__protected:_AddStepHelper(stepType, ...)
	assert(self._subject)
	self._codeGen = self._codeGen or ReactivePublisherCodeGen.Get()
	self._codeGen:AddStep(stepType, ...)
	return self
end

---@protected
function ReactivePublisherSchema:_AddStepFromSharedSchema(stepType, ...)
	self:_AddStepHelper(stepType)
	return self
end

---@protected
function ReactivePublisherSchema:_Commit()
	-- Commit the generated code to a publisher
	local publisher = ReactivePublisher.Get(self._codeGen, self._subject)
	self._codeGen = nil

	-- Disable the publisher if applicable
	if self._autoDisable then
		publisher:Disable()
	end

	-- Store the publisher if applicable
	if self._autoStore then
		publisher:StoreIn(self._autoStore)
	end

	-- Release this schema object
	self:_Release()

	return publisher
end
