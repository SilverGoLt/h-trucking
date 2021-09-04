ESX = nil
Citizen.CreateThread(function()
    if ESX == nil then
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

-- Variables
local haveVeh = false
local haveDelivery = false
local veh = vector3(Config.Cords['veh'].x,Config.Cords['veh'].y,Config.Cords['veh'].z)
local vehspw = vector3(Config.Cords['vehspw'].x,Config.Cords['vehspw'].y,Config.Cords['vehspw'].z)
local currentVeh
local currentID
local trailer
local pickPos
local deliverPos
local hasTrailer = false
local delivered = false
local inZone = false
local pay = 0
--Variable End

--Thread
CreateThread(function()
    while true do
        local w = 500
        local pos = GetEntityCoords(PlayerPedId())
        local dist = #(veh - pos)
        if dist < 3 and not haveVeh then
            DrawText3D(veh, '~INPUT_PICKUP~ Take out your truck!')
            w = 10
        else
            w = 500
        end
        Wait(w)
    end
end)

-- Check trailer to give delivery point
CreateThread(function()
    while not hasTrailer do
        Wait(300)
        if trailer == trailer then
            if IsVehicleAttachedToTrailer(currentVeh) == 1 then
                deliverGps()
                hasTrailer = true
                TriggerServerEvent('trucker:setDelivery', currentID)
                ESX.ShowNotification('You have taken the trailer, deliver it safely!', true, false)
                Wait(100)
                checkDelivery()
            end
        end
    end
end)
-- Check if player is at delivery point with trailer!
function checkDelivery()
    Citizen.CreateThread(function()
    while not delivered do
        Wait(500)
        local pos = GetEntityCoords(PlayerPedId())
        local dist = #(deliverPos - pos)
        if dist < 3 then
            if not inZone then
                ESX.ShowNotification('Press E to deliver the product', true, false)
                inZone = true
            end
        end
        end
    end)
end

--Thread End
RegisterCommand('deliver_trailer', function() deliverTrailer() end, false)
RegisterKeyMapping('deliver_trailer', 'Deliver Trailer', 'keyboard', 'e')

RegisterCommand('trucker_car', function() spawnTruck() end, false)
RegisterKeyMapping('trucker_car', 'Spawns Trucker vehicle', 'keyboard', 'e')

--Spawn Truck
function spawnTruck()
    local pos = GetEntityCoords(PlayerPedId())
    local dist = #(veh - pos)
    if dist < 3 then
        if not haveVeh and not haveDelivery then
            if ESX.Game.IsSpawnPointClear(vehspw, 5.0) then
                ESX.Game.SpawnVehicle('phantom3', vehspw, 300.0, function(vehicle)
                    currentVeh = vehicle
                end)
                ESX.ShowNotification('You have received your car and coordinates', true, false)
                haveVeh = true
                randPick()
                Wait(100)
                pickGps()
                trailer()
            elseif not haveVeh then
                ESX.ShowNotification("There's a truck over there already!", true, false)
            end
        end    
    end
end

local blip
-- Random Pickup location
function randPick()
	local rand = math.random(1, #Config.Pickup)
	for k,v in pairs(Config.Pickup) do
		if k == rand then
			currentID = rand
            pickPos = vector3(v.coords.x,v.coords.y,v.coords.z)
		end
	end
end

-- Create blip and set gps to pickup
function pickGps()
    for k,v in pairs(Config.Pickup) do
        if k == currentID then
            blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipHighDetail(blip, true)
            SetBlipSprite (blip, 8)
            SetBlipDisplay(blip, 4)
            SetBlipScale  (blip, 0.7)
            SetBlipColour (blip, 5)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName('Pickup')
            EndTextCommandSetBlipName(blip)
            SetBlipRoute(blip, true)
        end
    end
end
-- Delivery GPS
function deliverGps()
    RemoveBlip(blip)
    Wait(10)
    for k,v in pairs(Config.Delivery) do
        if k == currentID then
            pay = v.pay
            deliverPos = vector3(v.coords.x, v.coords.y, v.coords.z)
            blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipHighDetail(blip, true)
            SetBlipSprite (blip, 8)
            SetBlipDisplay(blip, 4)
            SetBlipScale  (blip, 0.7)
            SetBlipColour (blip, 5)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName('Delivery Point')
            EndTextCommandSetBlipName(blip)
            SetBlipRoute(blip, true)
        end
    end
end

function removeBlip()
    RemoveBlip(blip)
end
-- Trailer Spawn
function trailer()
    for k,v in pairs(Config.Pickup) do
        if k == currentID then
            if ESX.Game.IsSpawnPointClear(pickPos, 5.0) then
                ESX.Game.SpawnVehicle(v.trailer, pickPos, v.coords.h, function(vehicle)
                trailer = vehicle
                end)
            end
        end
    end
end
--Deliver trailer
function deliverTrailer()
    if hasTrailer and inZone then
        local pos = GetEntityCoords(PlayerPedId())
        local dist = #(deliverPos - pos)
        if dist < 3 and inZone then
            ESX.Game.DeleteVehicle(trailer)
            ESX.ShowNotification("You have delivered the product and received $"..pay, true, false)
            TriggerServerEvent('trucker:getPay')
            removeBlip()
            delivered = true
        end
    end
end
function createBlip()
    local mainBlip
    mainBlip = AddBlipForCoord(Config.Cords['veh'].x,Config.Cords['veh'].y,Config.Cords['veh'].z)
    SetBlipHighDetail(mainBlip, true)
    SetBlipSprite (mainBlip, 67)
    SetBlipDisplay(mainBlip, 4)
    SetBlipScale  (mainBlip, 0.7)
    SetBlipColour (mainBlip, 5)
    SetBlipAsShortRange(mainBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Trucker Garage')
    EndTextCommandSetBlipName(mainBlip)
end
-- Text
function DrawText3D(coords, text, customEntry)
    local str = text

    local start, stop = string.find(text, "~([^~]+)~")
    if start then
        start = start - 2
        stop = stop + 2
        str = ""
        str = str .. string.sub(text, 0, start)
    end

    if customEntry ~= nil then
        AddTextEntry(customEntry, str)
        BeginTextCommandDisplayHelp(customEntry)
    else
        AddTextEntry(GetCurrentResourceName(), str)
        BeginTextCommandDisplayHelp(GetCurrentResourceName())
    end
    EndTextCommandDisplayHelp(2, false, false, -1)

    SetFloatingHelpTextWorldPosition(1, coords)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
end


AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    else
        createBlip()
    end
end)