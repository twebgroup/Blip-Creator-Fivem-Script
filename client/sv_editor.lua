local Blips = {}

local LoadedBlips = LoadResourceFile(GetCurrentResourceName(), "blips.json")
if LoadedBlips and LoadedBlips ~= "" then
    local success, result = pcall(json.decode, LoadedBlips)
    if success and result then
        for id, blipData in pairs(result) do
            if blipData.pos then
                if type(blipData.pos) == "table" and blipData.pos.x and blipData.pos.y and blipData.pos.z then
                    blipData.pos = {blipData.pos.x, blipData.pos.y, blipData.pos.z}
                end
            end
        end
        Blips = result
    else
        print("^1[ERROR] Failed to decode blips.json^7")
        Blips = {}
    end
else
    Blips = {}
end

CreateThread(function()
    Wait(1000)
    if next(Blips) then
        for blipid, blipdata in next, Blips do
            TriggerClientEvent("blip-editor:save", -1, blipdata)
            Wait(0)
        end
    end
end)

RegisterServerEvent("blip-editor:save")
AddEventHandler("blip-editor:save", function(blip)
    if not blip then return end
    
    if (not Config.ALLOW_CREATING) and (not Config.ALLOW_EDIT) then return end
    if Config.ACE_PERMISSIONS then 
        if not IsPlayerAceAllowed(source, "blipeditor.save") then return end 
    end
    
    if not blip.created then blip.created = os.time() end
    blip.last_edited = os.time()
    saveBlip(blip)
end)

RegisterServerEvent("blip-editor:delete")
AddEventHandler("blip-editor:delete", function(blipid)
    if not blipid then return end
    
    if not Config.ALLOW_DELETE then return end
    if Config.ACE_PERMISSIONS then 
        if not IsPlayerAceAllowed(source, "blipeditor.delete") then 
            print("^1[ERROR] Player does not have delete permission: ^7" .. GetPlayerName(source))
            return 
        end 
    end
    
    removeExistingBlip(blipid)
end)

function saveBlip(blip)
    if not blip then return end
    
    if not blip.id then
        blip.id = GenerateBlipHash(blip.pos[1], blip.pos[2], os.time())
    end
    
    if blip.pos then
        if type(blip.pos) == "table" and #blip.pos >= 3 then
            blip.pos = {
                x = blip.pos[1],
                y = blip.pos[2], 
                z = blip.pos[3]
            }
        end
    end
    
    Blips[blip.id] = blip
    TriggerClientEvent("blip-editor:save", -1, blip)
    updateJson()
end

function removeExistingBlip(blipid)
    if not blipid then return end
    
    if Blips[blipid] then
        TriggerClientEvent("blip-editor:delete", -1, blipid)
        Blips[blipid] = nil
        updateJson()
        print("^2[INFO] Blip deleted: ^7" .. blipid)
        return true
    else
        print("^1[ERROR] Could not find blip to delete: ^7" .. blipid)
        return false
    end
end

function updateJson()
    SaveResourceFile(GetCurrentResourceName(), "blips.json", json.encode(Blips), -1)
end

RegisterServerEvent("blip-editor:requestServerBlips")
AddEventHandler("blip-editor:requestServerBlips", function()
    local source = source
    if next(Blips) then
        for blipid, blipdata in next, Blips do
            TriggerClientEvent("blip-editor:save", source, blipdata)
        end
    end
end)
