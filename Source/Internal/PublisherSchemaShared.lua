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
	objectPool = ObjectPool.New("PUBLISHER_SCHEMA_SHARED", ReactivePublisherSchemaShared --[[@as Class]], 2),
}
local STEP = Util.PUBLISHER_STEP



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
	self._parentSchema = nil
	self._codeGen = nil
	self._numShares = 0
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

---Shares the result of the publisher at the current point in the chain.
---@return ReactivePublisherSchemaShared
function ReactivePublisherSchemaShared:NestedShare()
	self._numShares = self._numShares + 1
	return self:_AddStepHelper(STEP.SHARE)
end

---Ends the nested share.
---@return ReactivePublisherSchemaShared
function ReactivePublisherSchemaShared:EndNestedShare()
	assert(self._numShares > 0)
	self._numShares = self._numShares - 1
	return self:_AddStepHelper(STEP.END_SHARE)
end

---Ends the share.
---@return ReactivePublisher
function ReactivePublisherSchemaShared:EndShare()
	self:_AddStepHelper(STEP.END_SHARE)
	return self:_Commit()
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
	assert(self._numShares == 0)
	assert(self._codeGen)
	self._codeGen = nil
	local parentSchema = self._parentSchema
	assert(not parentSchema:IsShared())
	---@cast parentSchema ReactivePublisherSchema
	local publisher = parentSchema:_Commit() ---@diagnostic disable-line invisible
	self:_Release()
	return publisher
end
