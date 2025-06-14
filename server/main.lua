ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('mecanico:darPago')
AddEventHandler('mecanico:darPago', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if xPlayer then
        local amount = 0
        if Config.Payment.RandomAmount then
            amount = math.random(Config.Payment.MinAmount, Config.Payment.MaxAmount)
        else
            amount = Config.Payment.FixedAmount
        end
        xPlayer.addMoney(amount)
        TriggerClientEvent('esx:showNotification', _source, ("~g~You have received $%s for your work."):format(amount))
    end
end)
