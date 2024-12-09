local attachedVehicle = nil

RegisterCommand("towmenu", function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        local trailerFound, trailer = GetVehicleTrailerVehicle(vehicle)
        if trailerFound and Config.AllowedTrailers[GetEntityModel(trailer)] then
            TriggerEvent('qb-menu:client:openMenu', {
                {
                    header = "Tow Menu",
                    txt = "Attach or Detach a vehicle",
                    isMenuHeader = true
                },
                {
                    header = "Attach Vehicle",
                    txt = "Drive a vehicle onto the trailer",
                    params = {
                        event = "towmenu:attachVehicle",
                        args = {
                            trailer = trailer
                        }
                    }
                },
                {
                    header = "Detach Vehicle",
                    txt = "Remove the vehicle from the trailer",
                    params = {
                        event = "towmenu:detachVehicle",
                        args = {
                            trailer = trailer
                        }
                    }
                }
            })
        else
            QBCore.Functions.Notify("You are not near a valid trailer!", "error")
        end
    else
        QBCore.Functions.Notify("You need to be in a vehicle to use this command!", "error")
    end
end)

RegisterNetEvent('towmenu:attachVehicle', function(data)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if attachedVehicle == nil then
        attachedVehicle = vehicle
        AttachVehicleToTrailer(attachedVehicle, data.trailer, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        QBCore.Functions.Notify("Vehicle attached to the trailer!", "success")
    else
        QBCore.Functions.Notify("A vehicle is already attached!", "error")
    end
end)

RegisterNetEvent('towmenu:detachVehicle', function(data)
    if attachedVehicle ~= nil then
        DetachVehicleFromTrailer(attachedVehicle)
        QBCore.Functions.Notify("Vehicle detached from the trailer!", "success")
        attachedVehicle = nil
    else
        QBCore.Functions.Notify("No vehicle is attached!", "error")
    end
end)
