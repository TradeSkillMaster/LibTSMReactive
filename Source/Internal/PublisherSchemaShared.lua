-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local LibTSMReactive = select(2, ...).LibTSMReactive
local ReactivePublisherSchemaBase = LibTSMReactive:IncludeClassType("ReactivePublisherSchemaBase")
local ReactivePublisherSchemaShared = LibTSMReactive:DefineInternalClassType("ReactivePublisherSchemaShared", ReactivePublisherSchemaBase)
local Util = LibTSMReactive:Include("Reactive.Util")
local ObjectPool = LibTSMReactive:From("LibTSMUtil"):IncludeClassType("ObjectPool")
local private = {
	objectPool = ObjectPool.New("PUBLISHER_SCHEMA_SHARED", ReactivePublisherSchemaShared, 2),
}
local STEP = Util.PUBLISHER_STEP

---@class ReactivePublisherSchemaShared<TCur,TShared> : ReactivePublisherSchemaBase<TCur>



-- ============================================================================
-- Static Class Functions
-- ============================================================================

---Gets a shared publisher schema object.
---@param parentSchema ReactivePublisherSchemaBase The parent schema which is being shared
---@param codeGen ReactivePublisherCodeGen The code gen object to add steps to
---@return ReactivePublisherSchemaShared
function ReactivePublisherSchemaShared.__static.Get(parentSchema, codeGen)
	local publisher = private.objectPool:Get()
	publisher:_Acquire(parentSchema, codeGen)
	return publisher
end



-- ============================================================================
-- Meta Class Methods
-- ============================================================================

function ReactivePublisherSchemaShared.__protected:__init()
	self.__super:__init(true)
	self._parentSchema = nil ---@type ReactivePublisherSchemaBase!
	self._codeGen = nil
end

---@param parentSchema ReactivePublisherSchemaBase
---@param codeGen ReactivePublisherCodeGen
function ReactivePublisherSchemaShared.__protected:_Acquire(parentSchema, codeGen)
	self._parentSchema = parentSchema
	self._codeGen = codeGen
end

function ReactivePublisherSchemaShared.__protected:_Release()
	assert(not self._codeGen)
	self._parentSchema = nil
	private.objectPool:Recycle(self)
end



-- ============================================================================
-- Public Class Methods
-- ============================================================================

---Ends the share.
---@return ReactivePublisher
function ReactivePublisherSchemaShared:EndShare()
	self:_AddStepHelper(STEP.END_SHARE)
	return self:_Commit()
end

---Calls a method with the published values.
---@generic Obj, K: keyof Obj
---@param obj Obj The object to call the method on
---@param method K The name of the method to call with the published values
---@param arg? any An additional argument to pass to the method
---@return self<TShared,TShared>
function ReactivePublisherSchemaShared:CallMethod(obj, method, arg)
	return self.__super:CallMethod(obj, method, arg)
end

---Calls a function with the published values.
---@generic A
---@param func fun(value: TCur, arg: A) The function to call with the published values
---@param arg? A An additional argument to pass to the function
---@return self<TShared,TShared>
function ReactivePublisherSchemaShared:CallFunction(func, arg)
	return self.__super:CallFunction(func, arg)
end

---Assigns published values to the specified key in the table.
---@param tbl table The table to assign the published values into
---@param key string The key to assign the published values at
---@return self<TShared,TShared>
function ReactivePublisherSchemaShared:AssignToTableKey(tbl, key)
	return self.__super:AssignToTableKey(tbl, key)
end

---Maps published values to a new publisher which is owned by the current publisher and call a method with values it publishes.
---@generic Obj, K: keyof Obj
---@param map ReactivePublisherFlatMapFunc<TCur> A function which takes a published value and returns a new publisher
---@param obj Obj The object to call the method on
---@param method K The name of the method to call with the published values
---@param arg? any An additional argument to pass to the method
---@return self<TShared,TShared>
function ReactivePublisherSchemaShared:FlatMapCallMethod(map, obj, method, arg)
	return self.__super:FlatMapCallMethod(map, obj, method, arg)
end

---Maps published values to a new publisher which is owned by the current publisher and call a function with values it publishes.
---@generic A
---@param map ReactivePublisherFlatMapFunc<TCur> A function which takes a published value and returns a new publisher
---@param func fun(value: TCur, arg: A) The function to call with the published values
---@param arg? A An additional argument to pass to the function
---@return self<TShared,TShared>
function ReactivePublisherSchemaShared:FlatMapCallFunction(map, func, arg)
	return self.__super:FlatMapCallFunction(map, func, arg)
end



-- ============================================================================
-- Private Class Methods
-- ============================================================================

function ReactivePublisherSchemaShared.__protected:_AddStepHelper(stepType, ...)
	assert(self._codeGen)
	self._codeGen:AddStep(stepType, ...)
	return self
end

---@protected
function ReactivePublisherSchemaShared:_Commit()
	assert(self._codeGen)
	self._codeGen = nil
	local parentSchema = self._parentSchema
	assert(not parentSchema:IsShared())
	---@cast parentSchema ReactivePublisherSchema
	local publisher = parentSchema:_Commit() ---@diagnostic disable-line: invisible
	self:_Release()
	return publisher
end
