local ped
local ShowRange = 50.0 -- adjust if needed

-- Update ped every 5 seconds
Citizen.CreateThread(function()
    while true do
        ped = PlayerPedId()
        Wait(5000)
    end
end)

-- Spawn / Despawn vehicles based on distance
Citizen.CreateThread(function()
    while true do
        local pCoords = GetEntityCoords(PlayerPedId())
        for i = 1, #Cars do
            if #(pCoords - Cars[i].pos) < ShowRange then
                if not Cars[i].spawned then
                    SpawnLocalCar(i)
                end
            else
                if Cars[i].spawned then
                    if DoesEntityExist(Cars[i].spawned) then
                        DeleteEntity(Cars[i].spawned)
                    end
                    Cars[i].spawned = nil
                    Cars[i].isSpawning = false
                end
            end
            Wait(300)
        end
    end
end)

-- Draw floating text above cars
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local pl = GetEntityCoords(PlayerPedId())
        for k, v in pairs(Cars) do
            if #(pl - vector3(v.pos.x, v.pos.y, v.pos.z)) < ShowRange then
                Draw3DText(v.pos.x, v.pos.y, v.pos.z - 0.5, v.text, 0, 0.1, 0.1)
            end
        end
    end
end)

-- Optional spinning cars
Citizen.CreateThread(function()
    while true do
        for i=1, #Cars do
            if Cars[i].spawned and Cars[i].spin then
                SetEntityHeading(Cars[i].spawned, GetEntityHeading(Cars[i].spawned) - 0.3)
            end
        end
        Wait(5)
    end
end)

-- Spawn cars with random neon + headlights + color
function SpawnLocalCar(i)
    if Cars[i].isSpawning then return end
    Cars[i].isSpawning = true

    Citizen.CreateThread(function()

        local hash = GetHashKey(Cars[i].model)
        RequestModel(hash)

        local attempts = 0
        while not HasModelLoaded(hash) do
            attempts = attempts + 1
            if attempts > 2000 then
                Cars[i].isSpawning = false
                return
            end
            Wait(0)
        end

        local veh = CreateVehicle(hash, Cars[i].pos.x, Cars[i].pos.y, Cars[i].pos.z - 1, Cars[i].heading, false, false)
        Cars[i].spawned = veh
        Cars[i].isSpawning = false
        SetModelAsNoLongerNeeded(hash)

        -- Engine + position
        SetVehicleEngineOn(veh, true, true, false)
        SetVehicleUndriveable(veh, false)
        FreezeEntityPosition(veh, true)
        SetVehicleOnGroundProperly(veh)

        -- Clean vehicle
        SetVehicleDirtLevel(veh, 0.0)
        SetVehicleDamage(veh, 0, 0, 0)

        -- Random primary + secondary color
        local p = math.random(0, 159)
        local s = math.random(0, 159)
        SetVehicleColours(veh, p, s)

        -- RANDOM NEON COLOR
        local neonR = math.random(0,255)
        local neonG = math.random(0,255)
        local neonB = math.random(0,255)

        for neonID = 0, 3 do
            SetVehicleNeonLightEnabled(veh, neonID, true)
        end
        SetVehicleNeonLightsColour(veh, neonR, neonG, neonB)

        -- RANDOM XENON COLOR + Forced ON
        local xenonColor = math.random(0,12)

        ToggleVehicleMod(veh, 22, true) -- enable xenons
        SetVehicleHeadlightsColour(veh, xenonColor)

        -- Force headlights ON
        SetVehicleLights(veh, 2)
        SetVehicleFullbeam(veh, true)
        Citizen.Wait(50)
        SetVehicleLights(veh, 2)

        -- Invincible option
        if carInvincible then
            SetEntityInvincible(veh, true)
        end

        -- Lock doors
        if DoorLock then
            SetVehicleDoorsLocked(veh, 2)
        end

        -- Plate
        SetVehicleNumberPlateText(veh, Cars[i].plate)
    end)
end

-- Clean up on resource stop
AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then
        for i=1, #Cars do
            if Cars[i].spawned then
                DeleteEntity(Cars[i].spawned)
            end
        end
    end
end)

-- Draw 3D text
function Draw3DText(x, y, z, text, fontId, scaleX, scaleY)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = #(vector3(px,py,pz) - vector3(x,y,z))
    local scale = (1 / dist) * 20 * ((1 / GetGameplayCamFov()) * 100)

    SetTextScale(scaleX * scale, scaleY * scale)
    SetTextFont(fontId)
    SetTextProportional(1)
    SetTextColour(250, 250, 250, 255)
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextOutline()
    SetTextCentre(1)

    SetTextEntry("STRING")
    AddTextComponentString(text)

    SetDrawOrigin(x, y, z + 2, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
