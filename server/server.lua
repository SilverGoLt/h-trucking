local delivery
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
RegisterCommand('pos', function(source)
    local pos = GetEntityCoords(GetPlayerPed(source))
    print('x = '..pos.x..',y = '..pos.y..',z = '..pos.z)
end, false)

RegisterCommand('getpos', function(source)
    local pos = GetEntityCoords(GetPlayerPed(source))
    local h = GetEntityHeading(GetPlayerPed(source))
    print(pos.x..', '..pos.y..', '..pos.z..', '..h)
end, false)

RegisterCommand('getPay', function(source)
    TriggerEvent('trucker:getPay')
end, false)

RegisterNetEvent('trucker:setDelivery')
AddEventHandler('trucker:setDelivery', function(num)
    delivery = num
end)

--Receive payment for this bitch :)
RegisterNetEvent('trucker:getPay')
AddEventHandler('trucker:getPay', function()
    local pos = GetEntityCoords(GetPlayerPed(source))
    local xPlayer = ESX.GetPlayerFromId(source)
    for k,v in pairs(Config.Delivery) do
        if k == delivery then
            local delivpos = vector3(v.coords.x,v.coords.y,v.coords.z)
            local dist = #(delivpos - pos)
            if dist < 3 then
                local pay = v.pay
                xPlayer.addMoney(pay)
            end
        end
    end
end)