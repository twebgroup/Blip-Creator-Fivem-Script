local Blips = {}
local BlipsToTerminate = {}

local ActiveBlip = 0
local Blip = {}
local BlipIDs = {}
local BlipCache = {}

if not DisplayStartJobTooltipInMapMenu then
    if not N_0xf1a6c18b35bcade6 then
        DisplayStartJobTooltipInMapMenu = function(...) return Citizen.InvokeNative(0xF1A6C18B35BCADE6, ...) end
    else
        DisplayStartJobTooltipInMapMenu = N_0xf1a6c18b35bcade6
    end
end

local IsEditorOpen = false
function OpenEditor(blip)
    UpdateBlipsList()
    ActiveBlip = blip

    Blip = {}

    if Blips[blip] then
        for k, v in next, Blips[blip] do
            Blip[k] = v
        end
    else
        Blip.sprite = GetBlipSprite(blip)
        Blip.color = GetBlipColour(blip)
        Blip.alpha = GetBlipAlpha(blip)
        Blip.name = GetCurrentBlipName(blip)
        Blip.scale = 0.70

        local coords = GetBlipCoords(blip)
        if coords and coords.x and coords.y and coords.z then
            Blip.pos = {x = coords.x, y = coords.y, z = coords.z}
        else
            local playerCoords = GetEntityCoords(PlayerPedId())
            Blip.pos = {x = playerCoords.x, y = playerCoords.y, z = playerCoords.z}
        end

        Blip.bHideLegend = false
        Blip.bAlwaysVisible = false
        Blip.bCheckmark = false
        Blip.bHeightIndicator = false
        Blip.bHeadingIndicator = false
        Blip.bShrink = false
        Blip.bOutline = false
        
        Blips[blip] = Blip
    end

    SendNuiMessage(json.encode({
        method = "name",
        data = Blip.name or ""
    }))

    SendNuiMessage(json.encode({
        method = "updateInputValue",
        data = {
            inputId = "inp_name",
            value = Blip.name or ""
        }
    }))

    if Blips[blip] and Blips[blip].id then
        SendNuiMessage(json.encode({
            method = "blipData",
            data = {
                id = Blips[blip].id,
                name = Blip.name,
                sprite = Blip.sprite,
                color = Blip.color,
                scale = Blip.scale,
                alpha = Blip.alpha,
                bCheckmark = Blip.bCheckmark,
                bHeightIndicator = Blip.bHeightIndicator,
                bHeadingIndicator = Blip.bHeadingIndicator,
                bShrink = Blip.bShrink,
                bOutline = Blip.bOutline
            }
        }))
    end

    for k, v in next, Blip do
        BlipCache[k] = v
    end

    local sentData = {}
    local function sendData(field, value)
        if value == nil then
            value = Blip[field]
        end
        SendNuiMessage(json.encode({
            method = field,
            data = value,
        }))
        sentData[field] = true
    end

    sendData("sprite")
    sendData("color")
    sendData("alpha")
    sendData("name")
    
    if Blip.scale then
        sendData("scale", math.floor(Blip.scale * 10))
    else
        sendData("scale", 7)
    end

    sendData("bCheckmark")
    sendData("bHeightIndicator")
    sendData("bHeadingIndicator")
    sendData("bShrink")
    sendData("bOutline")

    for field, value in next, Blip do
        if not sentData[field] then
            sendData(field, value)
        end
    end

    SetNuiFocus(true, true)
    IsEditorOpen = true
    SendNuiMessage(json.encode({
        method = "open",
    }))

    if GetCurrentFrontendMenuVersion() == -1 then
        ActivateFrontendMenu(-1171018317, false, 0)
    end
    
    if Blip.pos then
        SetPlayerBlipPositionThisFrame(Blip.pos.x, Blip.pos.y)
    end
end

function CloseEditor()
    SetNuiFocus(false, false)
    IsEditorOpen = false
    SendNuiMessage(json.encode({
        method = "close",
    }))

    SendNuiMessage(json.encode({
        method = "resetForm",
        data = {
            name = "",
            sprite = 1,
            color = 0,
            scale = 7,
            alpha = 255,
            bCheckmark = false,
            bHeightIndicator = false,
            bHeadingIndicator = false,
            bShrink = false,
            bOutline = false
        }
    }))

    Blip = {}
    BlipCache = {}
    ActiveBlip = 0
end

function SetBlipName(blip, name)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
end

function UpdateBlip(_blip, _blipdata)
    if _blip ~= 0 then
        SetBlipSprite(_blip, _blipdata.sprite)
        SetBlipColour(_blip, _blipdata.color)
        SetBlipAlpha(_blip, _blipdata.alpha)
        SetBlipScale(_blip, _blipdata.scale)
        SetBlipHiddenOnLegend(_blip, not not _blipdata.bHideLegend)
        SetBlipAsShortRange(_blip, not _blipdata.bAlwaysVisible)
        SetBlipChecked(_blip, not not _blipdata.bCheckmark)
        ShowHeightOnBlip(_blip, not not _blipdata.bHeightIndicator)
        SetBlipShowCone(_blip, not not _blipdata.bHeadingIndicator)
        SetBlipShrink(_blip, not not _blipdata.bShrink)
        ShowOutlineIndicatorOnBlip(_blip, not not _blipdata.bOutline)
        
        if _blipdata.name and _blipdata.name ~= "" then
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(_blipdata.name)
            EndTextCommandSetBlipName(_blip)
        end
    end
end

RegisterNetEvent("blip-editor:save")
AddEventHandler("blip-editor:save", function(newdata)
    local blipid = newdata.id
    if not BlipIDs[blipid] then
        local ok = false
        for blip, blipdata in next, Blips do
            if blipdata.id == nil then
                local pos1 = newdata.pos
                local pos2 = blipdata.pos
                if type(pos1) == "table" and type(pos2) == "table" then
                    local match = false
                    if pos1[1] and pos2[1] then
                        match = pos1[1] == pos2[1] and pos1[2] == pos2[2]
                    elseif pos1.x and pos2.x then
                        match = pos1.x == pos2.x and pos1.y == pos2.y
                    end
                    
                    if match then
                        BlipIDs[blipid] = blip
                        Blips[blip] = newdata
                        UpdateBlip(blip, Blips[blip])
                        ok = true
                        break
                    end
                end
            end
        end
        if not ok then
            local coords = newdata.pos
            local x, y, z = 0, 0, 0
            
            if type(coords) == "table" then
                if coords[1] then
                    x, y, z = coords[1], coords[2], coords[3]
                elseif coords.x then
                    x, y, z = coords.x, coords.y, coords.z
                end
            end
            
            local blip = AddBlipForCoord(x, y, z)
            SetBlipAsMissionCreatorBlip(blip, true)
            BlipIDs[blipid] = blip
            Blips[blip] = newdata
            UpdateBlip(blip, Blips[blip])
        end
    else
        local blip = BlipIDs[blipid]
        Blips[blip] = newdata
        UpdateBlip(blip, Blips[blip])
    end
end)

RegisterNetEvent("blip-editor:delete")
AddEventHandler("blip-editor:delete", function(blipid)
    if BlipIDs[blipid] then
        local blip = BlipIDs[blipid]
        RemoveBlip(blip)
        Blips[blip] = nil
        BlipIDs[blipid] = nil
    end
end)

function CheckAcePermission()
    if Config.ACE_PERMISSIONS then
        local hasPermission = exports['qb-core']:HasPermission('admin')
        if not hasPermission then
            TriggerEvent('QBCore:Notify', 'You do not have permission for this action!', 'error')
            return false
        end
    end
    return true
end

RegisterCommand("makeblip", function()
    if not CheckAcePermission() then return end
    local pos = GetEntityCoords(PlayerPedId())
    CreateNewBlip(pos.x, pos.y, pos.z)
end)

RegisterCommand("makeblipr", function()
    if not CheckAcePermission() then return end
    local pos = vector3(math.random(-4000, 4000) * 1.0, math.random(-1000, 8000) * 1.0, 0.0)
    CreateNewBlip(pos.x, pos.y, pos.z)
end)

RegisterCommand("blips", function()
    local c = 1
    for blip, bd in next, Blips do
        c = c + 1
    end
end)

RegisterCommand("bedit", function(_, args)
    local blip = tonumber(args[1])
    if Blips[blip] then
        OpenEditor(blip)
    end
end)

function CreateNewBlip(x, y, z)
    CreateThread(function()
        local _blip = AddBlipForCoord(x, y, z)
        SetBlipAsMissionCreatorBlip(_blip, true)
        OpenEditor(_blip)
        
        local pos = GetBlipCoords(_blip)
        if not pos then
            pos = vector3(x, y, z)
        end
        
        while IsEditorOpen do
            LockMinimapPosition(pos.x, pos.y)
            Wait(0)
        end
        UnlockMinimapPosition()
    end)
end

CreateThread(function()
    if Config.ALLOW_EDIT then AddTextEntry("IB_SRTMISS", "Edit Blip (Blip Creator)") end
    if Config.ALLOW_CREATING then AddTextEntry("IB_POI", "Create Blip (Blip Creator)") end
    Wait(750)
    CloseEditor()
    TriggerServerEvent("blip-editor:requestServerBlips")
    local current_blip = nil
    while true do
        if Config.ALLOW_CREATING then
            local blip = GetFirstBlipInfoId(162)
            while blip ~= 0 do
                local pos = GetBlipCoords(blip)
                if pos ~= vector3(0, 0, 0) then
                    if not BlipsToTerminate[blip] then
                        BlipsToTerminate[blip] = true
                        SetBlipCoords(blip, 0, 0, 0)
                        SetBlipAlpha(blip, 0)
                        local _blip = AddBlipForCoord(pos)
                        SetBlipAsMissionCreatorBlip(_blip, true)
                        OpenEditor(_blip)
                        local pos = GetBlipCoords(_blip)
                        while IsEditorOpen do
                            LockMinimapPosition(pos.x, pos.y)
                            Wait(0)
                        end
                        UnlockMinimapPosition()
                        BlipsToTerminate[blip] = false
                    end
                end
                blip = GetNextBlipInfoId(162)
            end
        end

        if Config.STANDALONE_MODE then
            if N_0x3bab9a4e4f2ff5c7() then
                local blip = DisableBlipNameForVar()
                if N_0x4167efe0527d706e() then
                    if DoesBlipExist(blip) then
                        if current_blip ~= blip then
                            current_blip = blip
                            TriggerEvent("onHoverBlipStart", current_blip)
                        end
                    end
                else
                    if current_blip then
                        TriggerEvent("onHoverBlipEnd", current_blip)
                        current_blip = nil
                    end
                end
            end
        end

        if Config.ALLOW_EDIT then
            if N_0x4167efe0527d706e() and ActiveBlip ~= 0 then
                if IsControlJustPressed(13, 203) then
                    local pos = GetBlipCoords(ActiveBlip)
                    OpenEditor(ActiveBlip)
                    while IsEditorOpen do
                        LockMinimapPosition(pos.x, pos.y)
                        Wait(0)
                    end
                    UnlockMinimapPosition()
                end
            end
        end
        Wait(0)
    end
end)

function UpdateBlipsList()
    local blipsList = {}
    for blipId, blipData in pairs(Blips) do
        table.insert(blipsList, {
            id = blipData.id,
            name = blipData.name,
            sprite = blipData.sprite
        })
    end
    SendNuiMessage(json.encode({
        method = "updateBlips",
        data = blipsList
    }))
end

function GetCurrentBlipName(blip)
    if Blips[blip] and Blips[blip].name then
        return Blips[blip].name
    end
    
    local defaultName = GetLabelText("BLIP_" .. GetBlipSprite(blip))
    if defaultName and defaultName ~= "NULL" then
        return defaultName
    end
    
    return "Blip " .. blip
end

RegisterNUICallback("return", function(data)
    local field = data.type
    local value = data.data
    
    if field == "deleteBlip" then
        if type(value) == "table" then
            local blipId = value.id
            for blip, blipData in pairs(Blips) do
                if blipData.id == blipId then
                    RemoveBlip(blip)
                    Blips[blip] = nil
                    BlipIDs[blipId] = nil
                    break
                end
            end
            TriggerServerEvent("blip-editor:delete", blipId)
        end
        return
    end
    
    if field == "finish" then
        if value == "delete" then
            if Blips[ActiveBlip] and Blips[ActiveBlip].id then
                TriggerServerEvent("blip-editor:delete", Blips[ActiveBlip].id)
                RemoveBlip(ActiveBlip)
                Blips[ActiveBlip] = nil
            elseif Blips[ActiveBlip] then
                RemoveBlip(ActiveBlip)
                Blips[ActiveBlip] = nil
            end
            ActiveBlip = 0
        elseif value == "discard" then
            for k, v in next, BlipCache do
                Blip[k] = v
            end
        elseif value == "save" or value == "update" then
            for k, v in next, Blip do
                if not Blips[ActiveBlip] then
                    Blips[ActiveBlip] = {}
                end
                Blips[ActiveBlip][k] = v
            end
            TriggerServerEvent("blip-editor:save", Blips[ActiveBlip])
        end
        CloseEditor()
    elseif field == "sprite" then
        Blip.sprite = value
        Blip.name = GetLabelText("BLIP_" .. Blip.sprite)
        SendNuiMessage(json.encode({
            method = "name",
            data = Blip.name,
        }))
    elseif field == "color" then
        Blip.color = value
    elseif field == "alpha" then
        Blip.alpha = math.floor(tonumber(value))
    elseif field == "scale" then
        Blip.scale = tonumber(value) / 10
    elseif field == "name" then
        Blip.name = value
    else
        Blip[field] = value
    end
    UpdateBlip(ActiveBlip, Blip)
end)

if Config.ALLOW_EDIT then
    local current_blip = nil
    AddEventHandler("onHoverBlipStart", function(blip)
        if DoesBlipExist(blip) then
            if current_blip ~= blip then
                current_blip = blip
                if Blips[blip] then
                    ActiveBlip = blip
                    DisplayStartJobTooltipInMapMenu(true)
                else
                    ActiveBlip = 0
                    DisplayStartJobTooltipInMapMenu(false)
                end
            end
        end
    end)
    AddEventHandler("onHoverBlipEnd", function(blip)
        if current_blip == blip then
            current_blip = nil
            ActiveBlip = 0
            DisplayStartJobTooltipInMapMenu(false)
        end
    end)
end
