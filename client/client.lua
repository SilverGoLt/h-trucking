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


--Check NPC Delivery
CreateThread(function()
    while true do
        local w = 500
        local pos = GetEntityCoords(PlayerPedId())
        local npc = vector3(Config.NPC.x , Config.NPC.y, Config.NPC.z)
        local dist = #(npc - pos)
        if dist < 2 and not haveDelivery then
            DrawText3D(npc, '~INPUT_PICKUP~ Get a delivery!')
            w = 10
        else
            w = 500
        end
        Wait(w)
    end
end)

--NPC Thread :)
Citizen.CreateThread(function() 
	RequestModel("s_m_y_dealer_01")
    while not HasModelLoaded("s_m_y_dealer_01") do
      Wait(10)
    end
    localNpc = CreatePed(26, "s_m_y_dealer_01",Config.NPC.x , Config.NPC.y,Config.NPC.z  - 1, Config.NPC.h, false, false)
    TaskStartScenarioInPlace(localNpc, "WORLD_HUMAN_DRUG_DEALER_HARD", 0, false)
    FreezeEntityPosition(localNpc, true)
    SetEntityInvincible(localNpc, true)
	GiveWeaponToPed(localNpc, 1834241177, 9999,  false, true);
    SetPedCanRagdollFromPlayerImpact(localNpc, false)
    SetPedCanRagdoll(localNpc, false)
    SetBlockingOfNonTemporaryEvents(localNpc, true)
end)

-- Check trailer to give delivery point
CreateThread(function()
    while true do
        if not hasTrailer then
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
        Wait(1000)
    end
end)

--Return vehicle thread
CreateThread(function()
    while true do
        local w = 500
        local pos = GetEntityCoords(PlayerPedId())
        local ret = vector3(Config.Return.x , Config.Return.y, Config.Return.z)
        local dist = #(ret - pos)
        if dist < 3 and haveVeh then
            DrawText3D(ret, '~INPUT_PICKUP~ Return truck!')
            w = 10
        else
            w = 500
        end
        Wait(w)
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

RegisterCommand('return_truck', function() returnTruck() end, false)
RegisterKeyMapping('return_truck', 'return truck', 'keyboard', 'e')

RegisterCommand('get_delivery', function() getDelivery() end, false)
RegisterKeyMapping('get_delivery', 'Receive a delivery', 'keyboard', 'e')

RegisterCommand('trucker_car', function() spawnTruck() end, false)
RegisterKeyMapping('trucker_car', 'Spawns Trucker vehicle', 'keyboard', 'e')


--Return truck
function returnTruck()
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(PlayerPedId())
    local ret = vector3(Config.Return.x , Config.Return.y, Config.Return.z)
    local dist = #(ret - pos)
    if dist < 3 and haveVeh then
        if IsPedInAnyVehicle(ped) then
            ESX.Game.DeleteVehicle(currentVeh)
            haveVeh = false
        end
    end
end

--Receive delivery
function getDelivery()
    local pos = GetEntityCoords(PlayerPedId())
    local npc = vector3(Config.NPC.x , Config.NPC.y, Config.NPC.z)
    local dist = #(npc - pos)
    if dist < 3 and not haveDelivery then
        haveDelivery = true
        ESX.ShowNotification('You have received the information for your delivery!', true, false)
        randPick()
        pickGps()
        getTrailer()
    end
end
--Spawn Truck
function spawnTruck()
    local pos = GetEntityCoords(PlayerPedId())
    local dist = #(veh - pos)
    if dist < 3 then
        if not haveVeh and haveDelivery then
            if ESX.Game.IsSpawnPointClear(vehspw, 5.0) then
                -- Not tested so not sure if it works :shrug:
                local r = math.random(1, #Config.Vehicles)
                local truck = Config.Vehicles[r]

                ESX.Game.SpawnVehicle(truck, vehspw, 300.0, function(vehicle)
                    currentVeh = vehicle
                end)
                ESX.ShowNotification('You have received your truck', true, false)
                haveVeh = true
            elseif not haveVeh then
                ESX.ShowNotification("There's a truck over there already!", true, false)
            end
        else
            ESX.ShowNotification("Currently you don't have a delivery :/", true, false)
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
    print('Executina')
    Wait(10)
    for k,v in pairs(Config.Delivery) do
        if k == currentID then
            pay = v.pay
            deliverPos = vector3(v.coords.x, v.coords.y, v.coords.z)
            print(deliverPos)
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

function returnBlip()
    local returnBlip
    returnBlip = AddBlipForCoord(Config.Return.x,Config.Return.y,Config.Return.z)
    SetBlipHighDetail(returnBlip, true)
    SetBlipSprite (returnBlip, 524)
    SetBlipDisplay(returnBlip, 4)
    SetBlipScale  (returnBlip, 0.6)
    SetBlipColour (returnBlip, 67)
    SetBlipAsShortRange(returnBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Truck Return')
    EndTextCommandSetBlipName(returnBlip)
end

function removeBlip()
    RemoveBlip(blip)
end
-- Trailer Spawn
function getTrailer()
    for k,v in pairs(Config.Pickup) do
        if k == currentID then
            if ESX.Game.IsSpawnPointClear(pickPos, 5.0) then
                ESX.Game.SpawnVehicle(v.trailer, pickPos, v.coords.h, function(vehicle)
                    trailer = vehicle
                    print(trailer)
                end)
            end
        end
    end
end
--Deliver trailer
function deliverTrailer()
    if hasTrailer and inZone and IsVehicleAttachedToTrailer(currentVeh) == 1 then
        local pos = GetEntityCoords(PlayerPedId())
        local dist = #(deliverPos - pos)
        if dist < 3 and inZone then
            ESX.Game.DeleteVehicle(trailer)
            ESX.ShowNotification("You have delivered the product and received $"..pay, true, false)
            TriggerServerEvent('trucker:getPay')
            removeBlip()
            delivered = false
            hasTrailer = false
            trailer = 0
            inZone = false
            currentID = 0
            pickPos = 0
            deliverPos = 0
            haveDelivery = false
        end
    else
        ESX.ShowNotification("I think you lost your trailer on the way?", true, false)
    end
end
function createMainBlip()
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

function npcBlip()
    local mainBlip
    mainBlip = AddBlipForCoord(Config.NPC.x,Config.NPC.y,Config.NPC.z)
    SetBlipHighDetail(mainBlip, true)
    SetBlipSprite (mainBlip, 133)
    SetBlipDisplay(mainBlip, 4)
    SetBlipScale  (mainBlip, 0.7)
    SetBlipColour (mainBlip, 26)
    SetBlipAsShortRange(mainBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Delivery HQ')
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
        createMainBlip()
        npcBlip()
        returnBlip()
    end
end)