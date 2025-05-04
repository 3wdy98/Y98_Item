local QBCore = exports['qb-core']:GetCoreObject()  -- إضافة هذا السطر لتحديد QBCore بشكل صحيح

RegisterCommand("itemadmin", function()
    lib.callback('admin:checkPermission', false, function(hasPerm)
        if not hasPerm then
            lib.notify({ title = "صلاحية مفقودة", description = "أنت لا تملك صلاحية استخدام هذا الأمر", type = "error" })
            return
        end

        -- فتح قائمة الأدمن عند التأكد من الصلاحية
        lib.registerContext({
            id = "admin:itemMenu",
            title = "قائمة الأدمن - الأيتيمات",
            options = {
                {
                    title = "إعطاء أيتيم",
                    icon = "fa-solid fa-box",
                    event = "admin:startItemGive"
                },
                {
                    title = "سجل الأيتيمات",
                    icon = "fa-solid fa-clipboard-list",
                    event = "admin:showItemLogs"
                }
            }
        })

        lib.showContext("admin:itemMenu")
    end)
end)

    
    RegisterNetEvent("admin:startItemGive", function()
        local input = lib.inputDialog("إعطاء أيتيم", {
            { type = "number", label = "ID اللاعب", required = true },
            { type = "number", label = "الكمية", required = true },
            { type = "input", label = "السبب", required = true }
        })
    
        if not input then return end
        local targetId, amount, reason = table.unpack(input)
    
        -- ننتظر لحظيًّا لتفادي مشاكل العرض
        Wait(200)
    
        local items = lib.callback.await("admin:getItemList", false)
        if not items or #items == 0 then
            lib.notify({ title = "خطأ", description = "لا توجد أيتيمات متاحة", type = "error" })
            return
        end
    
        -- بناء خيارات الأيتيمات مع البيانات المطلوبة
        local options = {}
        for _, item in pairs(items) do
            table.insert(options, {
                title = item.title,
                description = item.description,
                icon = item.icon,
                event = "admin:giveItemFinal",
                args = {
                    targetId = targetId,
                    itemName = item.args,
                    amount = amount,
                    reason = reason
                }
            })
        end
    
        -- تسجيل وفتح القائمة
        local menuId = "admin:itemSelectMenu_" .. math.random(11111, 99999)
        lib.registerContext({
            id = menuId,
            title = "اختر الأيتيم لإعطائه",
            search = true,
            options = options
        })
        lib.showContext(menuId)
    end)
    lib.callback.register("admin:getItemLogs", function()
        local result = exports.oxmysql:query('SELECT * FROM admin_item_logs ORDER BY timestamp DESC LIMIT 30', {})
        local logs = {}
    
        for _, log in ipairs(result) do
            table.insert(logs, {
                title = log.admin_name .. " 🎁 " .. log.item_name .. " x" .. log.amount,
                description = "📌 ID: " .. log.target_id .. " | 🕒 " .. os.date("%Y-%m-%d %H:%M", os.time(log.timestamp)),
                icon = "fa-solid fa-scroll"
            })
        end
    
        return logs
    end)
    
    RegisterNetEvent("admin:showItemLogs", function()
        local logs = lib.callback.await("admin:getItemLogs", false)
        if not logs or #logs == 0 then
            lib.notify({ title = "سجل الأيتيمات", description = "لا يوجد سجلات حالياً", type = "info" })
            return
        end
    
        lib.registerContext({
            id = "admin:itemLogsContext",
            title = "سجل الأيتيمات (آخر 30 عملية)",
            options = logs
        })
        lib.showContext("admin:itemLogsContext")
    end)
    
    RegisterNetEvent("admin:giveItemFinal", function(data)
        if not data or not data.targetId or not data.itemName then return end
        TriggerServerEvent("admin:giveItem", data.targetId, data.itemName, data.amount, data.reason)
    end)
    
    RegisterNetEvent("admin:showItemLogs", function()
        lib.notify({ title = "سجل الأيتيمات", description = "عرض السجل هنا" })
    end)
    
    -- استدعاء الأيتيمات من السيرفر
    lib.callback.register("admin:getItemList", function()
        local items = {}
        for name, item in pairs(QBCore.Shared.Items) do
            table.insert(items, {
                title = item.label,
                description = name,
                icon = item.image and Config.InventoryIconPath .. item.image or "nui://Y98_item/icon/default.png",
                event = "admin:selectItem",
                args = name
            })
        end
        return items
    end)
    
    lib.callback.register("admin:checkPermission", function(source)
        return QBCore.Functions.HasPermission(source, "admin") or QBCore.Functions.HasPermission(source, "god")
    end)
    