Config = {}
Config.cd_keymaster = true -- You have the minigame? https://github.com/dsheedes/cd_keymaster

Config.NPC = {
    Model = "s_m_m_autoshop_02",
    Coords = vector4(-229.7433, -1377.4200, 31.2582, 205.7170)
}

Config.Vehicle = {
    Model = "burrito3",
    SpawnCoordsPrimary = vector4(-236.3650, -1386.9093, 31.2584, 185.2234),
    SpawnCoordsSecondary = vector4(-235.4887, -1395.8510, 31.2900, 185.8437)
}

Config.Payment = {
    RandomAmount = true,    -- true para pago aleatorio, false para monto fijo
    FixedAmount = 200,       -- pago fijo cuando RandomAmount = false
    MinAmount = 150,         -- min pay
    MaxAmount = 300          -- max pay
}

Config.Locations = {
    {
        repairLocation = vector4(183.1635, -1727.7916, 29.2918, 213.2998),
        clientCoords = vector4(185.1631, -1726.4210, 29.2918, 168.3328),
    },
    {
        repairLocation = vector4(-294.3072, -1570.9436, 24.1214, 147.5445),
        clientCoords = vector4(-292.3060, -1572.9460, 24.3616, 49.4856),
    },
    {
        repairLocation = vector4(-155.9888, -847.0161, 30.2067, 336.8875),
        clientCoords = vector4(-151.6257, -848.4910, 30.3574, 69.9045),
    },
    {
        repairLocation = vector4(238.4710, -1626.1915, 29.2875, 78.7346),
        clientCoords = vector4(232.0779, -1624.7970, 29.2873, 257.6352),
    },
    {
        repairLocation = vector4(508.6329, -1131.4977, 29.3301, 0.2134),
        clientCoords = vector4(508.0005, -1123.1389, 29.3063, 190.8219),
    }
    -- You can add more here...
}

Config.DamagedVehicles = {
    "blista", "bison", "burrito3", "adder", "faggio",
    "sultan", "sultanrs", "dilettante", "rocoto", "panto",
    "voodoo2", "baller", "zion", "massacro", "zion2",
    "fusilade", "coquette", "elegy", "f620", "felon" --You can add more here...
}

Config.ClientNPCModels = {
    "a_m_m_business_01", "s_m_m_autoshop_02", "a_f_m_skidrow_01", "a_m_o_tramp_01",
    "a_f_y_business_02", "a_m_y_hipster_01", "a_m_y_vinewood_01", "a_f_m_bevhills_01",
    "a_m_m_farmer_01", "a_f_m_tourist_01", "a_m_y_soucent_01", "a_f_y_runner_01",
    "a_m_y_motox_01", "s_m_m_ammucity_01", "s_f_y_shop_high", "a_m_y_genstreet_01",
    "a_f_y_business_01", "a_m_m_skater_01", "a_f_m_beach_01", "a_m_m_socenlat_01" --You can add more here...
}
