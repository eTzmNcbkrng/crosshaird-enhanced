local alpha = 0.5
local Speed = 10 -- Higher number moves crosshair faster

local _, addon = ...

local f = CreateFrame('frame', nil, WorldFrame)
--LibStub('LibNameplateRegistry-1.0'):Embed(f)
f:Hide()
f:SetFrameLevel(0)
f:SetFrameStrata('BACKGROUND')
f:SetPoint('CENTER')
f:SetSize(64, 64)
--f:SetAlpha(0.5)

local circle = f:CreateTexture(nil, 'BACKGROUND')
circle:SetTexture([[interface/addons/crosshairs/circle]])
circle:SetAllPoints()
circle:SetAlpha(alpha)
--circle:SetPoint('CENTER')
--circle:SetSize(86, 86)

local left = f:CreateTexture(nil, 'BACKGROUND')
left:SetColorTexture(1, 1, 1, alpha)
left:SetPoint('RIGHT', f, 'LEFT', 8, 0)
left:SetSize(2000, 1)

local right = f:CreateTexture(nil, 'BACKGROUND')
right:SetColorTexture(1, 1, 1, alpha)
right:SetPoint('LEFT', f, 'RIGHT', -8, 0)
right:SetSize(2000, 1)

local top = f:CreateTexture(nil, 'BACKGROUND')
top:SetColorTexture(1, 1, 1, alpha)
top:SetPoint('BOTTOM', f, 'TOP', 0, -8)
top:SetSize(1, 2000)

local bottom = f:CreateTexture(nil, 'BACKGROUND')
bottom:SetColorTexture(1, 1, 1, alpha)
bottom:SetPoint('TOP', f, 'BOTTOM', 0, 8)
bottom:SetSize(1, 2000)

---[[
circle:SetBlendMode('ADD')
left:SetBlendMode('ADD')
right:SetBlendMode('ADD')
top:SetBlendMode('ADD')
bottom:SetBlendMode('ADD')
--]]

local tx = f:CreateTexture(nil, 'BACKGROUND')
tx:SetTexture([[interface/addons/crosshairs/arrows]])
tx:SetAllPoints()
--tx:SetPoint('CENTER')
--tx:SetSize(86, 86)
--tx:SetAlpha(0.5)

local ag = tx:CreateAnimationGroup()
local rotation = ag:CreateAnimation('Rotation')
rotation:SetDegrees(-360)
rotation:SetDuration(5)
ag:SetLooping('REPEAT')
ag:Play()

local group = tx:CreateAnimationGroup()
group:SetToFinalAlpha(true)
local alpha = group:CreateAnimation('Alpha')
alpha:SetFromAlpha(0)
alpha:SetToAlpha(1)
--alpha:SetChange(-1)
--alpha:SetOrder(1)
alpha:SetDuration(0.5)

--local alpha2 = group:CreateAnimation('Alpha')
--alpha2:SetChange(1)
--alpha2:SetDuration(0.5)
--alpha2:SetOrder(2)
--alpha2:SetSmoothing('OUT')

local scale1 = group:CreateAnimation('Scale')
--scale1:SetOrder(2)
scale1:SetScale(2, 2)
scale1:SetDuration(0)

local scale = group:CreateAnimation('Scale')
--scale:SetOrder(2)
scale:SetScale(0.5, 0.5)
scale:SetDuration(0.5)
--scale:SetSmoothing('IN')

local fadeOut = f:CreateAnimationGroup()
fadeOut:SetToFinalAlpha(true)
local alpha = fadeOut:CreateAnimation('Alpha')
--alpha:SetChange(-1)
alpha:SetFromAlpha(1)
alpha:SetToAlpha(0)
alpha:SetDuration(0.2)
fadeOut:SetScript('OnFinished', function(self) f:Hide() end)


local fadeIn = f:CreateAnimationGroup()
fadeIn:SetToFinalAlpha(true)
local alpha1 = fadeIn:CreateAnimation('Alpha')
alpha1:SetOrder(1)
--alpha1:SetChange(-1)
alpha1:SetFromAlpha(0)
alpha1:SetToAlpha(1)
alpha1:SetDuration(0.2)

--local alpha = fadeIn:CreateAnimation('Alpha')
--alpha:SetChange(1)
--alpha:SetOrder(2)
--alpha:SetDuration(0.2)
fadeOut:SetScript('OnFinished', function(self) f:Hide() end)

local targetPlate

local function SetColor(r, g, b)
	circle:SetVertexColor(r, g, b)
	left:SetVertexColor(r, g, b)
	right:SetVertexColor(r, g, b)
	top:SetVertexColor(r, g, b)
	bottom:SetVertexColor(r, g, b)
	tx:SetVertexColor(r, g, b)
end

-- fade in if our crosshairs weren't visible

local Moving = false
local function FocusPlate(plate)
	--f:SetPoint('CENTER', plate)
	fadeOut:Stop()
	if not f:IsShown() then
		local x, y = plate:GetCenter()
		if x and y then
			local scale = plate:GetEffectiveScale()
			x, y = x * scale, y * scale
			local fScale = f:GetScale()
			x, y = x / fScale, y / fScale
			f:SetPoint('CENTER', WorldFrame, 'BOTTOMLEFT', ScaleCoords(x, y))
		end
		fadeIn:Play()
	end
	
	f:Show()
	group:Play()
	targetPlate = plate
	
	local r, g, b = 1, 1, 1
	--if UnitIsTapped('target') and not UnitIsTappedByPlayer('target') and not UnitIsTappedByAllThreatList('target') then
	if UnitIsTapDenied('target') then
		--SetColor(0.5, 0.5, 0.5)
		r, g, b = 0.5, 0.5, 0.5
	elseif UnitIsPlayer('target') then
		local _, class = UnitClass('target')
		if class and RAID_CLASS_COLORS[class] then
			local colors = RAID_CLASS_COLORS[class]
			r, g, b = colors.r, colors.g, colors.b
		else
			r, g, b = 0.274, 0.705, 0.392 --70/255,  180/255, 100/255
		end
	elseif UnitIsOtherPlayersPet('target') then
		r, g, b = 0.6, 0.6, 0.6
	else
		r, g, b = UnitSelectionColor('target')
	end
	SetColor(r, g, b)
	
	
	Moving = GetTime()
end

function f:PLAYER_TARGET_CHANGED()
	local nameplate = C_NamePlate.GetNamePlateForUnit('target') --f:GetPlateByGUID(targetGUID)
	if nameplate then
		targetPlate = nameplate
		FocusPlate(nameplate)
		--TargetLock:Show()
	else
		fadeOut:Play()
		targetPlate = nil
	end
end
f:RegisterEvent('PLAYER_TARGET_CHANGED')

function f:PLAYER_ENTERING_WORLD()
	-- PLAYER_TARGET_CHANGED doesn't fire when you lose your target from zoning
	self:PLAYER_TARGET_CHANGED()
end
f:RegisterEvent('PLAYER_ENTERING_WORLD')

local xFactor, yFactor = 1, 1 -- pixel perfect stuff, just try and prevent it from screwing up our lines
function ScaleCoords(xPixel, yPixel, trueScale)
	local x, y  = xPixel / xFactor, yPixel / yFactor
	x, y = x - x % 1, y - y % 1 -- floor
	return trueScale and (xPixel * xFactor) or (x * xFactor), trueScale and (xPixel * xFactor) or (y * yFactor)
end

f:SetScript('OnUpdate', function(self, elapsed)
	--if Moving and GetTime() - Moving > 0.75 then Moving = false end -- snap to the target if it's been moving for a while
	
	local plate = targetPlate
	if plate then
		if Moving then
			local frame1, frame2 = f, targetPlate
			local x1, y1 = frame1:GetCenter()
			x1, y1 = x1 * frame1:GetEffectiveScale(), y1 * frame1:GetEffectiveScale()
			local x2, y2 = frame2:GetCenter()
			x2, y2 = x2 * frame2:GetEffectiveScale(), y2 * frame2:GetEffectiveScale()
			local delta1, delta2 = y2 - y1, x2 - x1
			local distance = ( delta2 ^ 2 + delta1 ^ 2 ) ^ 0.5
			--local vector = sqrt( delta2 ^ 2 + delta1 ^ 2 ) -- length
			--local nx, ny = delta2 / vector, delta1 / vector
			
			local timeLeft = Moving + 1 - GetTime()
			
			if timeLeft > 0 and distance > 3 then
				-- Move distance / timeLeft toward frame2
				-- elapsed / timeLeft
				local amountToMove = distance / timeLeft / 10
				local ratio = amountToMove / distance
				-- Move a point along a line in a given direction
				local x = x1 + ratio * delta2
				local y = y1 + ratio * delta1
				frame1:ClearAllPoints()
				frame1:SetPoint('CENTER', nil, 'BOTTOMLEFT', ScaleCoords(x, y))
			else
				frame1:ClearAllPoints()
				frame1:SetPoint('CENTER', nil, 'BOTTOMLEFT', ScaleCoords(x2, y2))
				Moving = false
			end
		else
			--f:SetPoint('CENTER', plate)

			local x, y = plate:GetCenter()
			local scale = plate:GetEffectiveScale()
			x, y = x * scale, y * scale --(y - plate:GetHeight()/2) * scale
			local fScale = f:GetScale()
			x, y = x / fScale, y / fScale
			f:SetPoint('CENTER', WorldFrame, 'BOTTOMLEFT', ScaleCoords(x, y))
		end
	end
end)

function f:DISPLAY_SIZE_CHANGED()
	local xRes, yRes = strmatch(({GetScreenResolutions()})[GetCurrentResolution()], '(%d+)x(%d+)')
	xFactor, yFactor = 768 / xRes * GetMonitorAspectRatio(), 768 / yRes
end
function f:PLAYER_LOGIN() f:DISPLAY_SIZE_CHANGED() end

f:RegisterEvent('DISPLAY_SIZE_CHANGED')
f:RegisterEvent('PLAYER_LOGIN')

function f:NAME_PLATE_UNIT_ADDED(unit)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if nameplate and UnitIsUnit('target', unit) then
		targetPlate = nameplate
		FocusPlate(nameplate)
		--TargetLock:Show()
	end
end
f:RegisterEvent('NAME_PLATE_UNIT_ADDED')

function f:NAME_PLATE_UNIT_REMOVED(unit)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if UnitIsUnit('target', unit) then
		targetPlate = nil
		fadeOut:Play()
	end
end
f:RegisterEvent('NAME_PLATE_UNIT_REMOVED')

f:SetScript('OnEvent', function(self, event, ...) return self[event] and self[event](self, ...) end)