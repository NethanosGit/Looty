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

CreateIconFrame()
