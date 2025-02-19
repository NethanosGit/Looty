function CreateIconFrame()
	local iconFrame = CreateFrame("Frame","LootyIcon",UIParent,"LootyIconTemplate");
	iconFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0); -- Position in the center
	iconFrame:Show();
	iconFrame.Icon:SetTexture("Interface/Icons/Inv_ingot_titansteel_red");
	iconFrame.Icon:SetTexCoord(0.0625,0.9375,0.0625,0.9375);
	iconFrame.Count:SetText(5);
	iconFrame.IconOverlay:SetTexture("Interface\\Addons\\Looty\\Art\\IconOverlay.tga");
	iconFrame.IconOverlay:SetTexCoord(0.625, 0.75, 0, 0.125);
	iconFrame.IconOverlay:SetSize(64,64)
	iconFrame.IconOverlay:Show();
	iconFrame.Border:SetVertexColor(1, 195/255, 41/255)
end

function CreateGenericButton()
	local button = CreateFrame("Button", "LootyTestButton", UIParent, "LootyGenericButtonTemplate")
	button:SetPoint("CENTER", UIParent, "CENTER", 100, 0);

	-- alpha needs to be setup from lua as there isn't an alpha argument on Texture
	button:SetAlpha(1)

	button.HotkeyFrame.HotkeyBackdrop:SetTexture("Interface\\Addons\\Looty\\Art\\LootUI.tga");
	button.HotkeyFrame.HotkeyBackdrop:SetTexCoord(17.5/1024, 30.5/1024, 41.5/512, 54.5/512);
	button.HotkeyFrame.Hotkey:SetText("E");
	button.Text:SetText("Take All");
	button.Background:SetTexture("Interface\\Addons\\Looty\\Art\\LootUI.tga")
	button.Background:SetTexCoord(0, 128/1024, 72/512, 104/512);

	button.Highlight:SetTexture("Interface\\Addons\\Looty\\Art\\LootUI.tga")
	button.Highlight:SetTexCoord(338/1024, 458/1024, 72/512, 104/512);
	button:Show()
	
end

CreateIconFrame()
CreateGenericButton()
