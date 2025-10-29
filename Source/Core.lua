-- ------------------------------------------------------------------------------ --
--                                 LibTSMReactive                                 --
--               https://github.com/TradeSkillMaster/LibTSMReactive               --
--         Licensed under the MIT license. See LICENSE.txt for more info.         --
-- ------------------------------------------------------------------------------ --

local ADDON_TABLE = select(2, ...)
ADDON_TABLE.LibTSMReactive = ADDON_TABLE.LibTSMCore.NewComponent("LibTSMReactive")
	:AddDependency("LibTSMUtil")
