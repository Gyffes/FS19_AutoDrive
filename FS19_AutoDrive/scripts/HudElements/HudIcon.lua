ADHudIcon = ADInheritsFrom(ADGenericHudElement)

function ADHudIcon:new(posX, posY, width, height, image, layer, name)
    local o = ADHudIcon:create()
    o:init(posX, posY, width, height)
    o.layer = layer
    o.name = name
    o.image = image
    o.isVisible = true

    o.ov = Overlay:new(o.image, o.position.x, o.position.y, o.size.width, o.size.height)

    return o
end

function ADHudIcon:onDraw(vehicle, uiScale)
    self:updateVisibility(vehicle)

    self:updateIcon(vehicle)

    if self.name == "header" then
        self:onDrawHeader(vehicle, uiScale)
    end

    if self.isVisible then
        self.ov:render()
    end
end

function ADHudIcon:onDrawHeader(vehicle, uiScale)
    local adFontSize = 0.009 * uiScale
    local textHeight = getTextHeight(adFontSize, "text")
    local adPosX = self.position.x + AutoDrive.Hud.gapWidth
    local adPosY = self.position.y + (self.size.height - textHeight) / 2

    setTextBold(false)
    setTextColor(1, 1, 1, 1)
    setTextAlignment(RenderText.ALIGN_LEFT)
    local firstLineText = ""
    local secondLineText = ""

    local textToShow = "AutoDrive"
    textToShow = textToShow .. " - " .. AutoDrive.version
    textToShow = textToShow .. " - " .. AutoDriveHud:getModeName(vehicle)

    local x, y, z = getWorldTranslation(vehicle.components[1].node)
    if vehicle.ad.stateModule:isActive() and vehicle.ad.isPaused == false and vehicle.spec_motorized ~= nil and not AutoDrive.checkIsOnField(x, y, z) and vehicle.ad.stateModule:getMode() ~= AutoDrive.MODE_BGA then
        local wp, currentWayPoint = vehicle.ad.drivePathModule:getWayPoints()
        local remainingTime = ADGraphManager:getDriveTimeForWaypoints(wp, currentWayPoint, math.min((vehicle.spec_motorized.motor.maxForwardSpeed * 3.6), vehicle.ad.stateModule:getSpeedLimit()))
        local remainingMinutes = math.floor(remainingTime / 60)
        local remainingSeconds = remainingTime % 60
        if remainingTime ~= 0 then
            if remainingMinutes > 0 then
                textToShow = textToShow .. " - " .. string.format("%.0f", remainingMinutes) .. ":" .. string.format("%02d", math.floor(remainingSeconds))
            elseif remainingSeconds ~= 0 then
                textToShow = textToShow .. " - " .. string.format("%2.0f", remainingSeconds) .. "s"
            end
        end
    end

    if vehicle.ad.sToolTip ~= "" and AutoDrive.getSetting("showTooltips") then
        textToShow = textToShow .. " - " .. string.sub(g_i18n:getText(vehicle.ad.sToolTip), 5, string.len(g_i18n:getText(vehicle.ad.sToolTip)))
        if vehicle.ad.sToolTipInfo ~= nil then
            textToShow = textToShow .. " - " .. vehicle.ad.sToolTipInfo
        end
    end

    local activeTask = vehicle.ad.taskModule:getActiveTask()
    if activeTask ~= nil and activeTask:getInfoText() ~= nil then
        textToShow = textToShow .. " - " .. activeTask:getInfoText()
    end

    if vehicle.ad.stateModule:isInExtendedEditorMode() then
        textToShow = textToShow .. " - " .. g_i18n:getText("AD_lctrl_for_creation")
        textToShow = textToShow .. " / " .. g_i18n:getText("AD_lalt_for_deletion")
    end

    local textWidth = getTextWidth(adFontSize, textToShow)
    if textWidth > self.size.width - 4 * AutoDrive.Hud.gapWidth then
        --expand header bar and split text
        if self.isExpanded == nil or self.isExpanded == false then
            self.ov:setDimension(nil, self.size.height + textHeight + AutoDrive.Hud.gapHeight)
            self.isExpanded = true
        end

        local textParts = textToShow:split("-")

        local width = 0
        local textIndex = 1
        while (width < self.size.width - 2 * AutoDrive.Hud.gapWidth) and textParts[textIndex] ~= nil do
            local textToAdd = ""
            if textIndex > 1 then
                textToAdd = textToAdd .. "-"
            end
            textToAdd = textToAdd .. textParts[textIndex]
            width = getTextWidth(adFontSize, firstLineText .. textToAdd)

            if (width < self.size.width - 2 * AutoDrive.Hud.gapWidth) then
                firstLineText = firstLineText .. textToAdd
                textIndex = textIndex + 1
            end
        end

        local secondLineIndex = 1
        while textParts[textIndex] ~= nil do
            if secondLineIndex > 1 then
                secondLineText = secondLineText .. "-"
            end
            secondLineText = secondLineText .. textParts[textIndex]
            if secondLineIndex == 1 then
                secondLineText = textParts[textIndex]:sub(2)
            end
            secondLineIndex = secondLineIndex + 1
            textIndex = textIndex + 1
        end

        if AutoDrive.pullDownListExpanded == 0 then
            renderText(adPosX, adPosY, adFontSize, firstLineText)
            adPosY = adPosY + textHeight + AutoDrive.Hud.gapHeight
            renderText(adPosX, adPosY, adFontSize, secondLineText)
        end
    else
        if self.isExpanded ~= nil and self.isExpanded == true then
            self.isExpanded = false
            self.ov:resetDimensions()
        end

        if AutoDrive.pullDownListExpanded == 0 then
            renderText(adPosX, adPosY, adFontSize, textToShow)
        end
    end
end

function ADHudIcon:updateVisibility(vehicle)
    local newVisibility = self.isVisible
    if self.name == "unloadOverlay" then
        if (vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER or vehicle.ad.stateModule:getMode() == AutoDrive.MODE_UNLOAD or vehicle.ad.stateModule:getMode() == AutoDrive.MODE_LOAD) then
            newVisibility = true
        else
            newVisibility = false
        end
    end

    self.isVisible = newVisibility
end

function ADHudIcon:act(vehicle, posX, posY, isDown, isUp, button)
    if self.name == "header" then
        if button == 1 and isDown and AutoDrive.pullDownListExpanded == 0 then
            AutoDrive.Hud:startMovingHud(posX, posY)
            return true
        end
    end
    return false
end

function ADHudIcon:updateIcon(vehicle)
    local newIcon = self.image
    if self.name == "unloadOverlay" then
        if vehicle.ad.stateModule:getMode() == AutoDrive.MODE_LOAD then
            newIcon = AutoDrive.directory .. "textures/tipper_load.dds"
        elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER then
            newIcon = AutoDrive.directory .. "textures/tipper_overlay.dds"
        elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_UNLOAD then
            newIcon = AutoDrive.directory .. "textures/tipper_overlay.dds"
        end
    elseif self.name == "destinationOverlay" then
        if vehicle.ad.stateModule:getMode() == AutoDrive.MODE_PICKUPANDDELIVER then
            newIcon = AutoDrive.directory .. "textures/tipper_load.dds"
        elseif vehicle.ad.stateModule:getMode() == AutoDrive.MODE_DELIVERTO then
            newIcon = AutoDrive.directory .. "textures/tipper_overlay.dds"
        elseif vehicle.ad.stateModule:getMode() ~= AutoDrive.MODE_BGA then
            newIcon = AutoDrive.directory .. "textures/destination.dds"
        end
    end

    self.image = newIcon
    self.ov:setImage(self.image)
end
