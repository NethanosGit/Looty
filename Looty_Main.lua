local _, addon = ...
local API = addon.API
local L = addon.L

API.GetCurrencyInfo(1)
local Round = API.Round
local AbbreviateNumbers = API.AbbreviateNumbers
local ipairs = ipairs
local LootSlot = LootSlot
local CloseLoot = CloseLoot
function GetPhysicalScreenSize()
	local width, height = GetScreenWidth(), GetScreenHeight()
	return width, height
end
local GetPhysicalScreenSize = GetPhysicalScreenSize
local InCombatLockdown = InCombatLockdown
local CreateFrame = CreateFrame
local IsModifiedClick = IsModifiedClick
local GetItemCount = GetItemCount
local GetCursorPosition = GetCursorPosition
function IsDressableItemByID(itemID)
	local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
	return itemType == "Armor" or itemType == "Weapon"
end
local IsDressableItemByID = IsDressableItemByID

-- User Settings
local SHOW_ITEM_COUNT = true
local USE_HOTKEY = true
local TAKE_ALL_KEY = "E"
local TAKE_ALL_MODIFIER_KEY = nil --"LALT"
local USE_MOG_MARKER = true
local AUTO_LOOT_ENABLE_TOOLTIP = true
------------------

local MainFrame = CreateFrame("Frame", nil, UIParent)
MainFrame:Hide()
MainFrame:SetAlpha(0)
MainFrame:SetFrameStrata("DIALOG")
MainFrame:SetToplevel(true)
MainFrame:SetClampedToScreen(true)

local P_Loot = {}
P_Loot.MainFrame = MainFrame
addon.P_Loot = P_Loot

local Defination = {
	SLOT_TYPE_CURRENCY = 3,
	SLOT_TYPE_MONEY = 10, --Game value is 2, but we sort it to top
	SLOT_TYPE_REP = 9, --Custom Value
	SLOT_TYPE_ITEM = 1,
	SLOT_TYPE_OVERFLOW = 128, --Display overflown currency

	QUEST_TYPE_NEW = 2,
	QUEST_TYPE_ONGOING = 1,
}
P_Loot.Defination = Defination

local Formatter = {}
P_Loot.Formatter = Formatter
do
	Formatter.tostring = tostring
	Formatter.strlen = string.len

	function Formatter:Init()
		local fontSize = PlumberDB and PlumberDB.LootUI_FontSize
		Formatter:CalculateDimensions(fontSize)

		if not self.DummyFontString then
			self.DummyFontString = MainFrame:CreateFontString(nil, "BACKGROUND", "LootyFont")
			self.DummyFontString:Hide()
			self.DummyFontString:SetPoint("TOP", UIParent, "BOTTOM", 0, -64)
		end
	end

	function Formatter:CalculateDimensions(fontSize)
		if not (fontSize and fontSize >= 10 and fontSize <= 16) then
			fontSize = nil
		end

		local baseFont = _G.GameFontNormal
		local fontFile, defaultFontSize = baseFont:GetFont()
		local normalizedFontSize

		if not fontSize then
			fontSize = defaultFontSize
		end

		local fontObject = LootyFont
		fontObject:SetFont(fontFile, Round(fontSize), "OUTLINE")
		fontObject:SetShadowOffset(0, 0)

		local locale = GetLocale()
		if locale == "zhCN" or locale == "zhTW" then
			normalizedFontSize = Round(0.8 * fontSize)
		else
			normalizedFontSize = fontSize
		end

		self.BASE_FONT_SIZE = fontSize --GameFontNormal
		self.ICON_SIZE = Round(32 / 12 * normalizedFontSize)
		self.TEXT_BUTTON_HEIGHT = Round(16 / 12 * normalizedFontSize)
		self.ICON_BUTTON_HEIGHT = self.ICON_SIZE
		self.ICON_TEXT_GAP = Round(self.ICON_SIZE / 4)
		self.DOT_SIZE = Round(1.5 * normalizedFontSize)
		self.COUNT_NAME_GAP = Round(0.5 * normalizedFontSize)
		self.NAME_WIDTH = Round(16 * fontSize)
		self.BUTTON_WIDTH = self.ICON_SIZE
			+ self.ICON_TEXT_GAP
			+ self.BASE_FONT_SIZE
			+ self.COUNT_NAME_GAP
			+ self.NAME_WIDTH
		self.BUTTON_SPACING = 12

		self.numberWidths = {}

		if MainFrame.Header then
			if fontSize < defaultFontSize then
				MainFrame.Header:SetFont(fontFile, fontSize, "")
			else
				MainFrame.Header:SetFont(fontFile, defaultFontSize, "")
			end
		end
	end

	function Formatter:GetNumberWidth(number)
		number = number or 0
		local digits = self.strlen(self.tostring(number))

		if not self.numberWidths[digits] then
			local text = "+"
			for i = 1, digits do
				text = text .. "8"
			end
			text = text .. " "
			self.DummyFontString:SetText(text)
			self.numberWidths[digits] = Round(self.DummyFontString:GetWidth())
		end

		return self.numberWidths[digits]
	end

	function Formatter:GetPixelPerfectScale()
		if not self.pixelPerfectScale then
			local SCREEN_WIDTH, SCREEN_HEIGHT = GetPhysicalScreenSize()
			self.pixelPerfectScale = 768 / SCREEN_HEIGHT
		end
		return self.pixelPerfectScale
	end

	function Formatter:PixelPerfectTextureSlice(object)
		object:SetScale(self:GetPixelPerfectScale())
	end

	function Formatter:PixelSizeForScale(pixelSize, objectScale)
		local scale0 = self:GetPixelPerfectScale()
		return pixelSize * scale0 / objectScale
	end
end

local IsMouseMotionFocus = function(object)
	return object:IsMouseOver()
end

local FocusSolver = CreateFrame("Frame")
do
	function FocusSolver:OnUpdate(elapsed)
		self.t = self.t + elapsed
		if self.t > 0.05 then
			self.t = nil
			self:SetScript("OnUpdate", nil)
			if self.object and IsMouseMotionFocus(self.object) then
				self.object:OnFocused()
			end
		end
	end

	function FocusSolver:SetFocus(itemFrame)
		self.object = itemFrame
		if itemFrame then
			if not self.t then
				self:SetScript("OnUpdate", self.OnUpdate)
			end
			self.t = 0
		else
			self:SetScript("OnUpdate", nil)
			self.t = nil
		end
	end

	function FocusSolver:IsLastFocus(itemFrame)
		return self.object and self.object == itemFrame
	end
end

local CreateItemFrame
local ItemFrameMixin = {}
do --UI ItemButton
	local ANIM_DURATION_BUTTON_HOVER = 0.25
	local ANIM_OFFSET_H_BUTTON_HOVER = 8
	local Esaing_OutQuart = addon.EasingFunctions.outQuart

	local function Anim_ShiftButtonCentent_OnUpdate(self, elapsed)
		self.t = self.t + elapsed
		if self.t < ANIM_DURATION_BUTTON_HOVER then
			self.offset = Esaing_OutQuart(self.t, 0, ANIM_OFFSET_H_BUTTON_HOVER, ANIM_DURATION_BUTTON_HOVER)
		else
			self.offset = ANIM_OFFSET_H_BUTTON_HOVER
			self:SetScript("OnUpdate", nil)
		end
		self.Reference:SetPoint("LEFT", self, "LEFT", self.offset, 0)
	end

	local function Anim_ResetButtonCentent_OnUpdate(self, elapsed)
		self.t = self.t + elapsed
		if self.t < ANIM_DURATION_BUTTON_HOVER then
			self.offset = Esaing_OutQuart(self.t, self.offset, 0, ANIM_DURATION_BUTTON_HOVER)
		else
			self.offset = 0
			self:SetScript("OnUpdate", nil)
			self.hovered = nil
			self.t = nil
		end
		self.Reference:SetPoint("LEFT", self, "LEFT", self.offset, 0)
	end

	local function Anim_ShiftAndFadeOutButton_OnUpdate(self, elapsed)
		self.t = self.t + elapsed
		if self.t > 0 then
			self.alpha = self.alpha - 5 * elapsed
			if self.alpha < 0 then
				self.alpha = 0
			end
			self:SetAlpha(self.alpha)

			self.offset = self.offset + 128 * elapsed
			if self.t < ANIM_DURATION_BUTTON_HOVER then
			else
				self:SetScript("OnUpdate", nil)
			end
			self.Reference:SetPoint("LEFT", self, "LEFT", self.offset, 0)
		end
	end

	function ItemFrameMixin:ShowHoverVisual()
		self.hovered = true
		self.t = 0
		self:SetScript("OnUpdate", Anim_ShiftButtonCentent_OnUpdate)
	end

	function ItemFrameMixin:PlaySlideOutAnimation(delay)
		if false and self.hovered then
			self:Hide()
		else
			self.hovered = true
			self.t = (delay and -delay) or 0
			self.alpha = self:GetAlpha()
			if not self.offset then
				self.offset = 0
			end
			self:SetScript("OnUpdate", Anim_ShiftAndFadeOutButton_OnUpdate)
		end
	end

	function ItemFrameMixin:ResetHoverVisual(instant)
		if self.hovered then
			self.t = 0
			if instant then
				self.hovered = nil
				self.offset = 0
				self.Reference:SetPoint("LEFT", self, "LEFT", 0, 0)
				self:SetScript("OnUpdate", nil)
			else
				if not self.offset then
					self.offset = 0
				end
				self:SetScript("OnUpdate", Anim_ResetButtonCentent_OnUpdate)
			end
		end
	end

	function ItemFrameMixin:SetIcon(texture, data)
		self.showIcon = texture ~= nil
		local f = self.IconFrame
		if texture then
			self.hasIcon = true
			local iconSize = Formatter.ICON_SIZE
			f.Icon:SetTexture(texture)
			f:SetSize(iconSize, iconSize)
			f:SetPoint("LEFT", self.Reference, "LEFT", 0, 0)
			f.Count:SetText(nil)
			f.IconOverlay:Hide()
			f.IconOverlay:SetSize(2 * iconSize, 2 * iconSize)
			self:SetButtonHeight(Formatter.ICON_BUTTON_HEIGHT)

			if data then
				if data.locked then
					f.Icon:SetVertexColor(0.9, 0, 0)
				else
					f.Icon:SetVertexColor(1, 1, 1)
				end
				if data.slotType == Defination.SLOT_TYPE_ITEM then
					if data.questType ~= 0 then
						if data.questType == Defination.QUEST_TYPE_NEW then
							f.IconOverlay:SetTexCoord(0.625, 0.75, 0, 0.125)
						elseif data.questType == Defination.QUEST_TYPE_ONGOING then
							f.IconOverlay:SetTexCoord(0.75, 0.875, 0, 0.125)
						end
						f.IconOverlay:Show()
						self:SetBorderColor(1, 195 / 255, 41 / 255)
					end

					if SHOW_ITEM_COUNT and data.id then
						local numOwned = GetItemCount(data.id)
						if numOwned > 0 then
							f.Count:SetText(numOwned)
						end
					end
				elseif data.slotType == Defination.SLOT_TYPE_CURRENCY then
					local overflow, numOwned = API.WillCurrencyRewardOverflow(data.id, data.quantity)

					if overflow then
						self:SetBorderColor(1, 0, 0)
						f.IconOverlay:SetTexCoord(0.875, 1, 0, 0.125)
						f.IconOverlay:Show()
					end

					if SHOW_ITEM_COUNT and numOwned > 9999 then
						f.Count:SetText(AbbreviateNumbers(numOwned))
					end
				end
			else
				f.Icon:SetVertexColor(1, 1, 1)
			end

			f:Show()
		else
			self.hasIcon = nil
			f:Hide()
			self:SetHeight(Formatter.TEXT_BUTTON_HEIGHT)
		end
	end

	function ItemFrameMixin:ShowGlow(state)
		if state then
			if not self.glowFX then
				-- TODO - set MainFrame.glowFXPool
				local f = MainFrame.glowFXPool:Acquire()
				f.glowFX = f
				f:ClearAllPoints()
				f:SetPoint("CENTER", self.IconFrame, "CENTER", 0, 0)
				f:SetParent(self.IconFrame)
				f:SetFrameSize(Formatter.ICON_SIZE, Formatter.ICON_SIZE)
				f.AnimGlow:Play()
				f:SetQualityColor(self.quality)
				f:Show()
			end
		else
			if self.glowFX then
				self.glowFX:Release()
				self.glowFX = nil
			end
		end
	end

	function ItemFrameMixin:SetButtonHeight(height)
		self:SetHeight(height)
		self.Reference:SetHeight(height)
	end

	function ItemFrameMixin:SetBorderColor(r, g, b)
		self.IconFrame.Border:SetVertexColor(r, g, b)
	end

	function ItemFrameMixin:SetNameByColor(name, color)
		color = color or API.GetItemQualityColor(1)
		local r, g, b = color
		self.Text:SetText(name)
		self.Text:SetTextColor(r, g, b)
		self:SetBorderColor(r, g, b)
	end
end
