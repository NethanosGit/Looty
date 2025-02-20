local VERSION_TEXT = "alpha"
local VERSION_DATE = 1739600000
local addonName, addon = ...

local L = {} --Locale
local API = {} --Custom APIs used by this addon
local DB

addon.L = L
addon.API = API
addon.VERSION_TEXT = VERSION_TEXT

local CallbackRegistry = {}
CallbackRegistry.events = {}
addon.CallbackRegistry = CallbackRegistry

local tinsert = table.insert
local type = type
local ipairs = ipairs

function CallbackRegistry:CallbackRegistry(event, func, owner)
	if not self.events[event] then
		self.events[event] = {}
	end

	local callbackType

	if type(func) == "string" then
		callbackType = 2
	else
		callbackType = 1
	end

	tinsert(self.events[event], { callbackType, func, owner })
end

function CallbackRegistry:Trigger(event, ...)
	if self.events[event] then
		for _, cb in ipairs(self.events[event]) do
			if cb[1] == 1 then
				if cb[3] then
					cb[2](cb[3], ...)
				else
					cb[2](...)
				end
			else
				cb[3][cb[2]](cb[3], ...)
			end
		end
	end
end

function CallbackRegistry:RegisterSettingCallback(dbKey, func, owner)
	self:Register("SettingChanged." .. dbKey, func, owner)
end

local function GetDBValue(dbKey)
	return DB[dbKey]
end
addon.GetDBValue = GetDBValue

local function SetDBValue(dbKey, value, userInput)
	DB[dbKey] = value
	addon.CallbackRegistry:Trigger("SettingChanged." .. dbKey, value, userInput)
end
addon.SetDBValue = SetDBValue

local function GetDBBool(dbKey)
	return DB[dbKey] == true
end
addon.GetDBBool = GetDBBool

local DefaultValues = {
	LootUI = false,
	LootUI_FontSize = 14,
	LootUI_FadeDelayPerItem = 0.25,
	LootUI_ItemsPerPage = 6,
	LootUI_BackgroundAlpha = 0.5,
	LootUI_ShowItemCount = false,
	LootUI_NewTransmogIcon = true,
	LootUI_ForceAutoLoot = true,
	LootUI_LootUnderMouse = false,
	LootUI_UseHotkey = true,
	LootUI_HotkeyName = "E",
	LootUI_ReplaceDefaultAlert = false,
	LootUI_UseStockUI = false,
}

local function LoadDatabase()
	PlumberDB = PlumberDB or {}
	PlumberStorage = PlumberStorage or {} --Save large data (Spell)

	DB = PlumberDB

	local alwaysEnableNew = DB.EnableNewByDefault or false
	local newDBKeys = {}

	for dbKey, value in pairs(DefaultValues) do
		if DB[dbKey] == nil then
			DB[dbKey] = value
			if alwaysEnableNew and type(value) == "boolean" then
				--Not all Booleans are the master switch of individual module
				--Send these new ones to ControlCenter
				--Test: /run PlumberDB = {EnableNewByDefault = true}
				newDBKeys[dbKey] = true
			end
		end
	end

	for dbKey, value in pairs(DB) do
		CallbackRegistry:Trigger("SettingChanged." .. dbKey, value)
	end

	if not DB.installTime or type(DB.installTime) ~= "number" then
		DB.installTime = VERSION_DATE
	end

	DefaultValues = nil

	CallbackRegistry:Trigger("NewDBKeysAdded", newDBKeys)
end

local EL = CreateFrame("Frame")
EL:RegisterEvent("ADDON_LOADED")

EL:SetScript("OnEvent", function(self, event, ...)
	local name = ...
	if name == addonName then
		self:UnregisterEvent(event)
		LoadDatabase()
	end
end)

do
	local tocVersion = select(4, GetBuildInfo())
	tocVersion = tonumber(tocVersion or 0)

	local function IsToCVersionEqualOrNewerThan(targetVersion)
		return tocVersion >= targetVersion
	end
	addon.IsToCVersionEqualOrNewerThan = IsToCVersionEqualOrNewerThan
end
