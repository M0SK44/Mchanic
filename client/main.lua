ESX = exports["es_extended"]:getSharedObject()

-- Import config
local npcModel = Config.NPC.Model
local npcCoords = Config.NPC.Coords

local vehicleModel = Config.Vehicle.Model
local vehicleSpawnCoordsPrimary = Config.Vehicle.SpawnCoordsPrimary
local vehicleSpawnCoordsSecondary = Config.Vehicle.SpawnCoordsSecondary

local Locations = Config.Locations

local damagedVehicles = Config.DamagedVehicles
local clientNPCModels = Config.ClientNPCModels

local npcPed = nil
local working = false
local spawnedVehicle = nil
local markerActive = false
local isRepairing = false
local canRepair = false

local damagedVehicle = nil
local clientNPC = nil
local paymentReady = false
local paymentReceived = false

local clientBlip = nil -- blip variable

-- Variables para evitar repetir la misma misión
local lastLocationIndex = nil
local lastDamagedVehicleModel = nil
local lastClientNPCModel = nil

-- Create mechanic NPC
Citizen.CreateThread(function()
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do Citizen.Wait(100) end

    npcPed = CreatePed(4, npcModel, npcCoords.x, npcCoords.y, npcCoords.z - 1.0, npcCoords.w, false, true)
    SetEntityInvincible(npcPed, true)
    SetBlockingOfNonTemporaryEvents(npcPed, true)
    FreezeEntityPosition(npcPed, true)
    TaskStartScenarioInPlace(npcPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
end)

-- Interaction with NPC
Citizen.CreateThread(function()
    while true do
        local waitTime = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if npcPed then
            local dist = #(playerCoords - GetEntityCoords(npcPed))
            if dist < 5.0 then
                waitTime = 0
                Draw3DText(npcCoords.x, npcCoords.y, npcCoords.z + 1.2, "[E] Talk to the manager",
                    { r = 0, g = 255, b = 203, a = 255 })
                if IsControlJustPressed(0, 38) then
                    OpenWorkMenu()
                end
            end
        end

        Citizen.Wait(waitTime)
    end
end)

function OpenWorkMenu()
    local elements = {
        { label = "Start working", value = "start" },
        { label = "Stop working",  value = "stop" }
    }

    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'work_menu', {
        title = 'Mechanic Job',
        align = 'right',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'start' then
            if not working then
                if not IsSpawnPointClear(vehicleSpawnCoordsPrimary, 5.0) and not IsSpawnPointClear(vehicleSpawnCoordsSecondary, 5.0) then
                    ESX.ShowNotification("~r~No space available to spawn the vehicle.")
                    menu.close()
                    return
                end
                working = true
                SpawnWorkVehicle()
                ESX.ShowNotification("~g~You have started working.")
            else
                ESX.ShowNotification("~y~You are already working.")
            end
            menu.close()
        elseif data.current.value == 'stop' then
            if working then
                working = false
                DeleteWorkVehicle()
                ESX.ShowNotification("~r~You have stopped working.")
            else
                ESX.ShowNotification("~y~You are not working.")
            end
            menu.close()
        end
    end, function(data, menu)
        menu.close()
    end)
end

function IsSpawnPointClear(coords, radius)
    local vehicles = ESX.Game.GetVehiclesInArea(coords, radius)
    return (#vehicles == 0)
end

function SpawnWorkVehicle()
    RequestModel(vehicleModel)
    while not HasModelLoaded(vehicleModel) do Citizen.Wait(100) end

    local spawnCoords = nil
    if IsSpawnPointClear(vehicleSpawnCoordsPrimary, 5.0) then
        spawnCoords = vehicleSpawnCoordsPrimary
    elseif IsSpawnPointClear(vehicleSpawnCoordsSecondary, 5.0) then
        spawnCoords = vehicleSpawnCoordsSecondary
    else
        ESX.ShowNotification("~r~No space available for the vehicle.")
        working = false
        return
    end

    spawnedVehicle = CreateVehicle(vehicleModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetVehicleNumberPlateText(spawnedVehicle, "MECHANIC")
    SetVehicleHasBeenOwnedByPlayer(spawnedVehicle, true)
    SetVehicleEngineOn(spawnedVehicle, true, true, false)
    markerActive = true
end

function DeleteWorkVehicle()
    if spawnedVehicle and DoesEntityExist(spawnedVehicle) then
        DeleteVehicle(spawnedVehicle)
        spawnedVehicle = nil
    end
    markerActive = false
end

-- Show marker on vehicle
Citizen.CreateThread(function()
    while true do
        local waitTime = 1000
        if working and spawnedVehicle and DoesEntityExist(spawnedVehicle) and markerActive then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local vehCoords = GetEntityCoords(spawnedVehicle)
            if #(playerCoords - vehCoords) < 20.0 then
                waitTime = 0
                if GetVehiclePedIsIn(playerPed, false) ~= spawnedVehicle then
                    DrawMarker(36, vehCoords.x, vehCoords.y, vehCoords.z + 1.8, 0, 0, 0, 0, 0, 0, 1.2, 1.2, 1.0, 0, 255,
                        200, 100, false, false, 2, false)
                    Draw3DText(vehCoords.x, vehCoords.y, vehCoords.z + 1.3, "~b~Work vehicle",
                        { r = 0, g = 255, b = 255, a = 255 })
                else
                    markerActive = false
                    CreateRepairTask()
                end
            end
        end
        Citizen.Wait(waitTime)
    end
end)

function CreateRepairTask()
    local newLocationIndex
    local newVehicleModel
    local newClientNPCModel

    -- Evitar repetir la misma ubicación, vehículo y cliente consecutivamente
    repeat
        newLocationIndex = math.random(#Locations)
    until newLocationIndex ~= lastLocationIndex

    repeat
        newVehicleModel = damagedVehicles[math.random(#damagedVehicles)]
    until newVehicleModel ~= lastDamagedVehicleModel

    repeat
        newClientNPCModel = clientNPCModels[math.random(#clientNPCModels)]
    until newClientNPCModel ~= lastClientNPCModel

    local location = Locations[newLocationIndex]
    local repairLoc = location.repairLocation
    local clientLoc = location.clientCoords

    lastLocationIndex = newLocationIndex
    lastDamagedVehicleModel = newVehicleModel
    lastClientNPCModel = newClientNPCModel

    RequestModel(newVehicleModel)
    RequestModel(newClientNPCModel)
    while not HasModelLoaded(newVehicleModel) or not HasModelLoaded(newClientNPCModel) do
        Citizen.Wait(100)
    end

    damagedVehicle = CreateVehicle(newVehicleModel, repairLoc.x, repairLoc.y, repairLoc.z, repairLoc.w, true, false)
    SetVehicleEngineHealth(damagedVehicle, 200.0)
    SetVehicleDoorBroken(damagedVehicle, 0, true)

    clientNPC = CreatePed(4, newClientNPCModel, clientLoc.x, clientLoc.y, clientLoc.z - 1.0, clientLoc.w, false, true)
    SetEntityInvincible(clientNPC, true)
    SetBlockingOfNonTemporaryEvents(clientNPC, true)
    FreezeEntityPosition(clientNPC, true)
    TaskStartScenarioInPlace(clientNPC, "WORLD_HUMAN_STAND_MOBILE", 0, true) -- Animación de llamar por teléfono

    if clientBlip then
        RemoveBlip(clientBlip)
    end

    clientBlip = AddBlipForCoord(repairLoc.x, repairLoc.y, repairLoc.z)
    SetBlipSprite(clientBlip, 280)
    SetBlipColour(clientBlip, 3)
    SetBlipScale(clientBlip, 0.8)
    SetBlipAsShortRange(clientBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Repair Client")
    EndTextCommandSetBlipName(clientBlip)

    SetNewWaypoint(repairLoc.x, repairLoc.y)

    ESX.ShowNotification("~b~Go to the client's location.")
end

local CustomSettings = {
    settings = {
        handleEnd = true,               --Send a result message if true and callback when message closed or callback immediately without showing the message
        speed = 10,                     --pixels / second
        scoreWin = 500,                 --Score to win
        scoreLose = -150,               --Lose if this score is reached
        maxTime = 60000,                --sec
        maxMistake = 5,                 --How many missed keys can there be before losing
        speedIncrement = 1,             --How much should the speed increase when a key hit was successful
    },
    keys = { "a", "w", "d", "s", "g" }, --You can hash this out if you want to use default keys in the java side.
}

-- Repair and payment
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        if working and damagedVehicle and DoesEntityExist(damagedVehicle) and not isRepairing then
            local vehicleCoords = GetEntityCoords(damagedVehicle)
            local distance = #(playerCoords - vehicleCoords)

            if distance < 5.0 then
                sleep = 0
                if distance < 3.0 then
                    canRepair = true
                    Draw3DText(vehicleCoords.x, vehicleCoords.y, vehicleCoords.z + 1.2, "[E] Repair vehicle",
                        { r = 255, g = 200, b = 0, a = 255 })
                    if IsControlJustReleased(0, 38) and not isRepairing then
                        if Config.cd_keymaster == true then
                            TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
                            local example = exports['cd_keymaster']:StartKeyMaster(CustomSettings)
                            if example then
                                isRepairing = true
                                TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
                                ESX.ShowNotification("~b~Repairing vehicle...")
                                Citizen.Wait(5000)
                                ClearPedTasks(playerPed)
                                SetVehicleFixed(damagedVehicle)
                                SetVehicleDeformationFixed(damagedVehicle)
                                ESX.ShowNotification("~g~Vehicle repaired successfully, client is happy.")
                                paymentReady = true
                                -- Do not clear damagedVehicle here to allow deletion after payment
                            else
                                ESX.ShowNotification("~r~Intentalo de nuevo.")
                                ClearPedTasks(playerPed)
                            end
                        else
                            isRepairing = true
                            TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
                            ESX.ShowNotification("~b~Repairing vehicle...")
                            Citizen.Wait(10000)
                            ClearPedTasks(playerPed)
                            SetVehicleFixed(damagedVehicle)
                            SetVehicleDeformationFixed(damagedVehicle)
                            ESX.ShowNotification("~g~Vehicle repaired successfully, client is happy.")
                            paymentReady = true
                            -- Do not clear damagedVehicle here to allow deletion after payment
                        end
                    end
                end
            end
        end

        if paymentReady and clientNPC and DoesEntityExist(clientNPC) and not paymentReceived then
            local npcCoords = GetEntityCoords(clientNPC)
            local distance = #(playerCoords - npcCoords)

            if distance < 10.0 then
                sleep = 0
                local text = "Client - Approach to receive payment"
                if distance < 2.0 then
                    text = "[E] Receive payment"
                    if IsControlJustReleased(0, 38) then
                        paymentReceived = true
                        TriggerServerEvent('mecanico:darPago')

                        -- Clean up client, damaged vehicle and blip
                        if clientBlip then
                            RemoveBlip(clientBlip)
                            clientBlip = nil
                        end

                        if clientNPC and DoesEntityExist(clientNPC) then
                            DeleteEntity(clientNPC)
                            clientNPC = nil
                        end

                        if damagedVehicle and DoesEntityExist(damagedVehicle) then
                            SetEntityAsMissionEntity(damagedVehicle, true, true)
                            DeleteVehicle(damagedVehicle)
                            damagedVehicle = nil
                        end

                        -- Reset variables
                        isRepairing = false
                        paymentReady = false
                        paymentReceived = false
                        markerActive = true
                    end
                end

                Draw3DText(npcCoords.x, npcCoords.y, npcCoords.z + 1.2, text, { r = 255, g = 255, b = 0, a = 255 })
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- Draw 3D text
function Draw3DText(x, y, z, text, color)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoords()
    local dist = #(vector3(x, y, z) - camCoords)
    local scale = (1 / dist) * 2 * (1 / GetGameplayCamFov()) * 100

    if onScreen then
        SetTextScale(0.0 * scale, 0.5 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
    end
end

-- Mechanic job blip on map
Citizen.CreateThread(function()
    local blip = AddBlipForCoord(npcCoords.x, npcCoords.y, npcCoords.z)
    SetBlipSprite(blip, 402) -- mechanic workshop icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.9)
    SetBlipColour(blip, 5) -- teal
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Mechanic Job")
    EndTextCommandSetBlipName(blip)
end)
