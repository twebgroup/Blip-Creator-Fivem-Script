RegisterServerEvent("blip-editor:save")
AddEventHandler("blip-editor:save", function(blip)
    if (not Config.ALLOW_CREATING) and (not Config.ALLOW_EDIT) then return end
    if Config.ACE_PERMISSIONS then if not IsPlayerAceAllowed(source, "blipeditor.save") then return end end
    if not blip.created then blip.created = os.time() end
    blip.last_edited = os.time()
    
    -- Yeni blip mi yoksa güncelleme mi kontrol et
    if not blip.id then
        TriggerClientEvent('QBCore:Notify', source, 'Yeni blip başarıyla oluşturuldu!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', source, 'Blip başarıyla güncellendi!', 'success')
    end
    
    saveBlip(blip)
end)

RegisterServerEvent("blip-editor:delete")
AddEventHandler("blip-editor:delete", function(blipid)
    if not Config.ALLOW_DELETE then return end
    if Config.ACE_PERMISSIONS then if not IsPlayerAceAllowed(source, "blipeditor.delete") then return end end
    
    if removeExistingBlip(blipid) then
        TriggerClientEvent('QBCore:Notify', source, 'Blip başarıyla silindi!', 'success')
    end
end)

function removeExistingBlip(blipid)
    if Blips[blipid] then
        TriggerClientEvent("blip-editor:delete", -1, blipid)
        Blips[blipid] = nil
        updateJson()
        return true
    end
    return false
end 