local QBCore = exports['qb-core']:GetCoreObject()

local function sendDiscordLog(itemName, playerName, amount, reason)
    local embed = {{
        ["color"] = 16711680,
        ["title"] = "تم إعطاء أيتيم",
        ["description"] = string.format("اللاعب **%s** قام بإعطاء الأيتيم **%s** بكمية **%d** بسبب: **%s**", playerName, itemName, amount, reason),
        ["footer"] = { ["text"] = os.date("%Y-%m-%d %H:%M:%S") }
    }}

    PerformHttpRequest(Config.ItemLogWebhook, function() end, 'POST', json.encode({
        username = "Admin Log",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent("admin:giveItem", function(targetId, itemName, count, reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)  -- الحصول على اللاعب بشكل صحيح
    if not Player then return end

    -- التحقق من صلاحيات اللاعب
    if not QBCore.Functions.HasPermission(src, "admin") and not QBCore.Functions.HasPermission(src, "god") then
        TriggerClientEvent("QBCore:Notify", src, "ليس لديك صلاحية", "error")
        return
    end
    

    local target = QBCore.Functions.GetPlayer(tonumber(targetId))
    if not target then
        TriggerClientEvent("QBCore:Notify", src, "اللاعب غير موجود", "error")
        return
    end

    -- التحقق من الأيتيم
    if not QBCore.Shared.Items[itemName] then
        TriggerClientEvent("QBCore:Notify", src, "الأيتيم غير صالح", "error")
        return
    end

    -- إعطاء الأيتيم
    target.Functions.AddItem(itemName, count)
    TriggerClientEvent("QBCore:Notify", src, "تم إعطاء الأيتيم بنجاح", "success")

    -- حفظ السجل في MySQL
    exports.oxmysql:insert('INSERT INTO admin_item_logs (admin_name, target_id, item_name, amount, reason) VALUES (?, ?, ?, ?, ?)', {
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        targetId,
        itemName,
        count,
        reason
    })
end)



lib.callback.register("admin:getItemList", function()
    local items = {}
    for name, item in pairs(QBCore.Shared.Items) do
        -- إضافة الآيتمات إلى القائمة مع الأيقونة (إن كانت موجودة)
        table.insert(items, {
            title = item.label,  -- اسم الآيتم
            description = name,  -- اسم الآيتم الفعلي
            icon = item.image and Config.InventoryIconPath .. item.image or "nui://qb-inventory/html/images/default.png",  -- إذا كان هناك صورة للأيقونة
            event = "admin:selectItem",  -- الحدث عند اختيار الآيتم
            args = name  -- اسم الآيتم لاستخدامه في إرسال البيانات
        })
    end
    return items
end)

lib.callback.register("admin:checkPermission", function(source)
    -- استخدام QBCore للتحقق من صلاحيات اللاعب
    if not QBCore.Functions.HasPermission(source, "admin") and not QBCore.Functions.HasPermission(source, "god") then
        return false
    end
    return true
end)
