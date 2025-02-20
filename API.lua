local _, addon = ...
local API = addon.API
local L = addon.L

local match = string.match
local tremove = table.remove
local tinsert = table.insert
local unpack = unpack

---@diagnostic disable-next-line: undefined-global
local GetCurrencyListSize = GetCurrencyListSize
---@diagnostic disable-next-line: undefined-global
local GetCurrencyListInfo = GetCurrencyListInfo
local function Round(n)
	return floor(n + 0.5)
end
API.Round = Round

do
	local EasingFunctions = {}
	addon.EasingFunctions = EasingFunctions

	local sin = math.sin
	local cos = math.cos
	local pow = math.pow
	local pi = math.pi
	function EasingFunctions.linear(t, b, e, d)
		return (e - b) * t / d + b
	end

	function EasingFunctions.outSine(t, b, e, d)
		return (e - b) * sin(t / d * (pi / 2)) + b
	end

	function EasingFunctions.inOutSine(t, b, e, d)
		return -(e - b) / 2 * (cos(pi * t / d) - 1) + b
	end

	function EasingFunctions.outQuart(t, b, e, d)
		t = t / d - 1
		return (b - e) * (pow(t, 4) - 1) + b
	end

	function EasingFunctions.outQuint(t, b, e, d)
		t = t / d
		return (b - e) * (pow(1 - t, 5) - 1) + b
	end

	function EasingFunctions.inQuad(t, b, e, d)
		t = t / d
		return (e - b) * pow(t, 2) + b
	end
end

do -- AbbreviateNumbers
	local FIRST_NUMBER_CAP_NO_SPACE = "K"
	local SECOND_NUMBER_CAP_NO_SPACE = "M"
	local THIRD_NUMBER_CAP_NO_SPACE = "B"
	local FOURTH_NUMBER_CAP_NO_SPACE = "T"

	NUMBER_ABBREVIATION_DATA = {
		{
			breakpoint = 10000000000000,
			abbreviation = FOURTH_NUMBER_CAP_NO_SPACE,
			significandDivisor = 1000000000000,
			fractionDivisor = 1,
		},
		{
			breakpoint = 1000000000000,
			abbreviation = FOURTH_NUMBER_CAP_NO_SPACE,
			significandDivisor = 100000000000,
			fractionDivisor = 10,
		},
		{
			breakpoint = 10000000000,
			abbreviation = THIRD_NUMBER_CAP_NO_SPACE,
			significandDivisor = 1000000000,
			fractionDivisor = 1,
		},
		{
			breakpoint = 1000000000,
			abbreviation = THIRD_NUMBER_CAP_NO_SPACE,
			significandDivisor = 100000000,
			fractionDivisor = 10,
		},
		{
			breakpoint = 10000000,
			abbreviation = SECOND_NUMBER_CAP_NO_SPACE,
			significandDivisor = 1000000,
			fractionDivisor = 1,
		},
		{
			breakpoint = 1000000,
			abbreviation = SECOND_NUMBER_CAP_NO_SPACE,
			significandDivisor = 100000,
			fractionDivisor = 10,
		},
		{
			breakpoint = 10000,
			abbreviation = FIRST_NUMBER_CAP_NO_SPACE,
			significandDivisor = 1000,
			fractionDivisor = 1,
		},
		{
			breakpoint = 1000,
			abbreviation = FIRST_NUMBER_CAP_NO_SPACE,
			significandDivisor = 100,
			fractionDivisor = 10,
		},
	}

	API.AbbreviateNumbers = function(value)
		for i, data in ipairs(NUMBER_ABBREVIATION_DATA) do
			if value >= data.breakpoint then
				local finalValue = math.floor(value / data.significandDivisor) / data.fractionDivisor
				return finalValue .. data.abbreviation
			end
		end
		return tostring(value)
	end
end

do -- Currency
	local currenciesMaxQty = {
		[43308] = 75000,
		[43307] = 5000,
	}
	local GetCurrencyInfo = function(currencyID)
		local currencyListSize = GetCurrencyListSize()
		for i = 1, currencyListSize do
			local name, isHeader, isExpanded, isUnused, isWatched, count, _, icon, itemID = GetCurrencyListInfo(i)
			if itemID == currencyID then
				local currencyInfo = {
					name = name,
					description = "",
					isHeader = isHeader,
					IsHeaderExpanded = isExpanded,
					isTypeUnused = isUnused,
					isShownInBackpack = isWatched,
					quantity = count,
					trackedQuantity = count,
					iconFileID = icon,
					maxQuantity = currenciesMaxQty[itemID] and currenciesMaxQty[itemID] or 1000000,
				}
				return currencyInfo
			end
		end
	end
	API.GetCurrencyInfo = GetCurrencyInfo

	local CurrencyDataProvider = CreateFrame("Frame")
	CurrencyDataProvider.cache = {}
	CurrencyDataProvider.icons = {}

	CurrencyDataProvider:SetScript("OnEvent", function(self, event, currencyID, quantity, quantityChange)
		if currencyID and self.cache[currencyID] then
			self.cache[currencyID] = nil
		end
	end)

	function CurrencyDataProvider:CacheAndGetCurrencyInfo(currencyID)
		if not self.cache[currencyID] then
			local info = GetCurrencyInfo(currencyID)
			if not info then
				return
			end
			local vital = {}
		end

		if not self.registered then
			self.registered = true
			self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
		end

		return self.cache[currencyID]
	end

	local function WillCurrencyRewardOverflow(currencyID, rewardQuantity)
		local currencyInfo = GetCurrencyInfo(currencyID)
		local quantity = currencyInfo and currencyInfo.quantity
		return quantity and currencyInfo.maxQuantity > 0 and rewardQuantity + quantity > currencyInfo.maxQuantity,
			quantity
	end
	API.WillCurrencyRewardOverflow = WillCurrencyRewardOverflow

	local CoinUtil = {}
	addon.CoinUtil = CoinUtil
	CoinUtil.patternGold = L["Match Pattern Gold"]
	CoinUtil.patternSilver = L["Match Pattern Silver"]
	CoinUtil.patternCopper = L["Match Pattern Copper"]
	function CoinUtil:GetCopperFromCoinText(coinText)
		local rawCopper = 0
		local gold = match(coinText, self.patternGold)
		local silver = match(coinText, self.patternSilver)
		local copper = match(coinText, self.patternCopper)

		if gold then
			rawCopper = rawCopper + 10000 * (tonumber(gold) or 0)
		end

		if silver then
			rawCopper = rawCopper + 100 * (tonumber(silver) or 0)
		end

		if copper then
			rawCopper = rawCopper + (tonumber(copper) or 0)
		end

		return rawCopper
	end
end

do -- ObjectPool
	local ObjectPoolMixin = {}

	function ObjectPoolMixin:RemoveObject(obj)
		obj:Hide()
		obj:ClearAllPoints()

		if obj.OnRemoved then
			obj:OnRemoved()
		end
	end

	function ObjectPoolMixin:RecycleObject(obj)
		local isActive

		for i, activeObject in ipairs(self.activeObjects) do
			if activeObject == obj then
				tremove(self.activeObjects, i)
				isActive = true
				break
			end
		end

		if isActive then
			self:RemoveObject(obj)
			self.numUnused = self.numUnused + 1
			self.unusedObjects[self.numUnused] = obj
		end
	end

	function ObjectPoolMixin:CreateObject()
		local obj = self.createObjectFunc()
		tinsert(self.objects, obj)
		obj.Release = self.Object_Release
		return obj
	end

	function ObjectPoolMixin:Acquire()
		local obj

		if self.numUnused > 0 then
			obj = tremove(self.unusedObjects, self.numUnused)
			self.numUnused = self.numUnused - 1
		end

		if not obj then
			obj = self:CreateObject()
		end

		tinsert(self.activeObjects, obj)
		obj:Show()

		return obj
	end

	function ObjectPoolMixin:ReleaseAll()
		if #self.activeObjects == 0 then
			return
		end

		for _, obj in ipairs(self.activeObjects) do
			self:RemoveObject(obj)
		end

		self.activeObjects = {}
		self.unusedObjects = {}

		for index, obj in ipairs(self.objects) do
			self.unusedObjects[index] = obj
		end

		self.numUnused = #self.objects
	end

	function ObjectPoolMixin:GetTotalObjects()
		return #self.objects
	end

	function ObjectPoolMixin:CallAllObjects(method, ...)
		for i, obj in ipairs(self.objects) do
			obj[method](obj, ...)
		end
	end

	function ObjectPoolMixin:Object_Release()
		--Override
	end

	local function CreateObjectPool(createObjectFunc)
		local pool = {}
		API.Mixin(pool, ObjectPoolMixin)

		local function Object_Release(f)
			pool:RecycleObject(f)
		end
		pool.Object_Release = Object_Release

		pool.objects = {}
		pool.activeObjects = {}
		pool.unusedObjects = {}
		pool.numUnused = 0
		pool.createObjectFunc = createObjectFunc

		return pool
	end
	API.CreateObjectPool = CreateObjectPool
end

do -- Color
	local ColorSwatches = {
		SelectionBlue = { 12, 105, 216 },
		SmoothGreen = { 124, 197, 118 },
		WarningRed = { 212, 100, 28 }, --228, 13, 14  248, 81, 73
	}

	for _, swatch in pairs(ColorSwatches) do
		swatch[1] = swatch[1] / 255
		swatch[2] = swatch[2] / 255
		swatch[3] = swatch[3] / 255
	end

	local function GetColorByName(colorName)
		if ColorSwatches[colorName] then
			return unpack(ColorSwatches[colorName])
		else
			return 1, 1, 1
		end
	end
	API.GetColorByName = GetColorByName

	API.GetItemQualityColor = GetItemQualityColor
end
