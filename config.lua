Config = {}

Config.Target = true    
Config.PositionMenu = 'top-right'
Config.usecommand = false
Config.UITheme = 'bw'  


Config.SpawnKey = false 


Config.SpawnRadius = 100
Config.FallbackSpawnDistance = 10 -- If no road is nearby, spawn the wagon this many metres from the player
Config.usecommand = false
Config.MoneyType = {
    money = "cash",
}

Config.maxWagonsPerPlayer = 5
Config.Sell = 0.1 

Config.Keys = {
    OpenWagonStash = "INPUT_JUMP",                   -- Spacebar
    OpenStore      = "INPUT_SPRINT",                 -- Left Shift
    FleeWagon      = "INPUT_FRONTEND_CANCEL",        -- Escape
    CarcassMenu    = "INPUT_DOCUMENT_PAGE_PREV",     -- Q
    SeeCarcass     = "INPUT_DOCUMENT_PAGE_NEXT",     -- E (next page)
}

Config.Blip = {
    showBlip = true,           
    blipModel = "caravan",     
    blipName = "Wagon Shop", 
}

Config.Stores = {
    Valentine = {
        coords = vector3(-355.11, 775.18, 116.22),           -- Coordinates of the location where the menu will be opened
        npcmodel = `s_m_m_cghworker_01`,                      -- Model of the NPC that will open the menu
        npccoords = vector4(-355.11, 775.18, 116.22, 321.41), -- Coordinates of the NPC that will open the menu
        previewWagon = vec4(-353.43, 788.54, 116.15, 274.7), -- Location to preview the wagon
        cameraPreviewWagon = vec4(-353.43 + 8, 788.54, 116.15 + 2,274.7),
    },
    SaintDenis = {
        coords = vector3(2506.02, -1459.52, 46.37),           -- Coordinates of the location where the menu will be opened
        npcmodel = `s_m_m_cghworker_01`,                       -- Model of the NPC that will open the menu
        npccoords = vector4(2506.02, -1459.52, 46.37, 66.78),   -- Coordinates of the NPC that will open the menu
        previewWagon = vec4(2502.689, -1441.257, 45.313, 177.895), -- Location to preview the wagon
        cameraPreviewWagon = vec4(2502.689, -1441.257 - 8, 45.313 + 3, 177.895),
    },
    Strawberry = {
        coords = vector3(-1811.18, -555.63, 155.98),           -- Coordinates of the location where the menu will be opened
        npcmodel = `s_m_m_cghworker_01`,                        -- Model of the NPC that will open the menu
        npccoords = vec4(-1811.18, -555.63, 155.98, 265.87),    -- Coordinates of the NPC that will open the menu
        previewWagon = vec4(-1821.550, -561.547, 155.060, 253.239), -- Location to preview the wagon
        cameraPreviewWagon = vec4(-1821.550 + 6, -561.547, 155.060 + 2, 253.239),
    },
    BlackWater = {
        coords = vector3(-870.62, -1370.70, 43.62),          -- Coordinates of the location where the menu will be opened
        npcmodel = `s_m_m_cghworker_01`,                       -- Model of the NPC that will open the menu
        npccoords = vector4(-870.62, -1370.70, 43.62, 40.36), -- Coordinates of the NPC that will open the menu
        previewWagon = vec4(-865.77, -1366.23, 43.49, 88.50),   -- Location to preview the wagon
        cameraPreviewWagon = vec4(-865.77 - 8, -1366.23, 43.49 + 2, 88.50),
    },
    Tumbleweed = {
        coords = vector3(-5515.295, -3039.497, -2.388),         -- Coordinates of the location where the menu will be opened
        npcmodel = `s_m_m_cghworker_01`,                         -- Model of the NPC that will open the menu
        npccoords = vector4(-5515.295, -3039.497, -2.388, 182.161), -- Coordinates of the NPC that will open the menu
        previewWagon = vec4(-5522.063, -3044.438, -3.388, 265.561), -- Location to preview the wagon
        cameraPreviewWagon = vec4(-5522.063 + 8, -3044.438, -3.388 + 2, 265.561),
    },
	caliga = {
        coords = vector3(1894.08, -1320.43, 42.66),         -- Coordinates of the location where the menu will be opened
        npcmodel = `s_m_m_cghworker_01`,                         -- Model of the NPC that will open the menu
        npccoords = vector4(1894.08, -1320.43, 42.66, 329.71), -- Coordinates of the NPC that will open the menu
        previewWagon = vec4(1902.91,  -1319.31, 42.57, 246.61), -- Location to preview the wagon
        cameraPreviewWagon = vec4(1902.91 +8 ,-1319.31, 42.57 +2 , 246.61),
    },

}

Config.Wagons = {
    work = {
        wagon02x = {
            name = "Standard Camping Wagon", -- Previous: Camp Wagon 02
            maxWeight = 560,                       -- Maximum weight (ex: ~1250 lbs / 560 kg)
            slots = 50,                            -- Number of available slots
            price = 40,                            -- Price in dollars of the era
            maxAnimals = 5,                        -- Small animals/pelts
        },
        wagon03x = {
            name = "Reinforced Camping Wagon", -- Previous: Camp Wagon 03
            maxWeight = 600,                           -- (ex: ~1500 lbs / 680 kg)
            slots = 60,
            price = 50,
            maxAnimals = 6, -- Small animals/pelts
        },
        wagon04x = {
            name = "Light Farm Wagon", -- Previous: Camp Wagon 04
            maxWeight = 500,                  -- (ex: ~1100 lbs / 500 kg)
            slots = 45,
            price = 35,
            maxAnimals = 4, -- Small animals/pelts
        },
        wagon05x = {
            name = "Open Utility Wagon", -- Previous: Camp Wagon 05
            maxWeight = 635,                   -- (ex: ~1400 lbs / 635 kg)
            slots = 55,
            price = 45,
            maxAnimals = 5, -- Small animals/pelts
        },
        wagon06x = {
            name = "Covered Supply Wagon", -- Previous: Camp Wagon 06
            maxWeight = 725,                         -- (ex: ~1600 lbs / 725 kg)
            slots = 65,
            price = 55,
            maxAnimals = 2, -- Birds in cages or small items
        },
        cart01 = {
            name = "Light Peasant Cart", -- Previous: Peasant Cart 01
            maxWeight = 400,                   -- (ex: ~900 lbs / 400 kg)
            slots = 35,
            price = 25,
            maxAnimals = false,
        },
        cart02 = {
            name = "Peasant Cart with Sides", -- Previous: Peasant Cart 02
            maxWeight = 450,                           -- (ex: ~1000 lbs / 450 kg)
            slots = 40,
            price = 30,
            maxAnimals = false,
        },
        cart03 = {
            name = "Small Market Cart", -- Previous: Peasant Cart 03
            maxWeight = 360,                     -- (ex: ~800 lbs / 360 kg)
            slots = 30,
            price = 22,
            maxAnimals = false,
        },
        cart04 = {
            name = "Compact Farm Cart", -- Previous: Peasant Cart 04
            maxWeight = 430,                     -- (ex: ~950 lbs / 430 kg)
            slots = 38,
            price = 28,
            maxAnimals = false,
        },
        cart05 = {
            name = "Water/Liquid Tank Wagon", -- Previous: Liquid Transport
            maxWeight = 900,                         -- (ex: ~2000 lbs / 900 kg - liquids are heavy)
            slots = 10,                              -- Represents large containers/tank
            price = 70,                              -- Specialized
            maxAnimals = false,
        },
        cart06 = {
            name = "General Cargo Cart", -- Previous: Cargo Cart 01
            maxWeight = 790,                 -- (ex: ~1750 lbs / 790 kg)
            slots = 70,
            price = 60,
            maxAnimals = false,
        },
        cart07 = {
            name = "Farmer's Cart", -- Previous: Peasant Cart 05
            maxWeight = 475,                -- (ex: ~1050 lbs / 475 kg)
            slots = 42,
            price = 32,
            maxAnimals = false,
        },
        cart08 = {
            name = "Rural Utility Cart", -- Previous: Peasant Cart 06
            maxWeight = 520,                   -- (ex: ~1150 lbs / 520 kg)
            slots = 46,
            price = 38,
            priceGold = 2, -- Adjusted from 18
            maxAnimals = false,
        },
        chuckwagon000x = {
            name = "Kitchen Wagon (Chuckwagon)", -- Previous: Camp Wagon 01
            maxWeight = 860,                          -- (ex: ~1900 lbs / 860 kg) Chuckwagons carried a lot
            slots = 75,                               -- For food, utensils, etc.
            price = 80,                               -- Chuckwagons were substantial
            maxAnimals = false,                       -- Primarily for supplies
        },
        chuckwagon002x = {
            name = "Tool Cargo Wagon", -- Previous: Cargo Cart 02
            maxWeight = 815,                          -- (ex: ~1800 lbs / 815 kg)
            slots = 70,
            price = 65,
            maxAnimals = false,
        },
        coal_wagon = {
            name = "Coal/Ore Wagon", -- Previous: Coal Transport
            maxWeight = 1360,                -- (ex: ~3000 lbs / 1360 kg) For heavy and bulk cargo
            slots = 30,                      -- Fewer slots, for bulk items
            price = 100,
            maxAnimals = false,
        },
        gatchuck = {                             -- Hash may suggest something military (Gatling) or just heavy cargo
            name = "Articulated Heavy Cargo Wagon", -- Previous: Cargo Cart 03
            maxWeight = 1580,                        -- (ex: ~3500 lbs / 1580 kg) A large freight wagon
            slots = 80,
            price = 120,
            maxAnimals = false,
        },
        huntercart01 = {
            name = "Hunter's Cart",
            maxWeight = 250, -- For carcasses and pelts
            slots = 50,      -- Space for pelts and various game
            price = 75,      -- Specialized equipment
            maxAnimals = 20, -- Units of medium game (deer) or many small ones
        },
        oilwagon01x = {
            name = "Small Oil Tanker Wagon", -- Previous: Oil Transport 01
            maxWeight = 860,                        -- (ex: ~1900 lbs / 860 kg)
            slots = 8,                              -- Fewer slots for barrels/tank
            price = 85,
            maxAnimals = false,
        },
        oilwagon02x = {
            name = "Large Oil Tanker Wagon", -- Previous: Oil Transport 02
            maxWeight = 1250,                       -- (ex: ~2750 lbs / 1250 kg)
            slots = 12,                             -- More barrels/larger tank
            price = 110,
            maxAnimals = false,
        },
        supplywagon = {
            name = "Large Supply Wagon", -- Previous: Large Cargo Wagon
            maxWeight = 1700,                     -- (ex: ~3750 lbs / 1700 kg) A true freight wagon
            slots = 100,
            price = 130,
            maxAnimals = false, -- For general goods
        },
        utilliwag = {
            name = "Low Utility Wagon (Buckboard)", -- Previous: Low Cargo Wagon
            maxWeight = 450,                              -- (ex: ~1000 lbs / 450 kg) Buckboards were lighter
            slots = 40,
            price = 30,
            maxAnimals = 2, -- Could carry hunting dogs or some small game
        },
    },

    special = {
        gatchuck_2 = {       -- Wagon model hash
            name = "Combat Wagon with Machine Gun",
            maxWeight = 450, -- Payload capacity in KG (ammo, water, crew supplies)
            slots = 10,      -- Spaces for ammo, essential supplies
            price = 350,     -- A specialized military vehicle would be expensive
            maxAnimals = false,
        },
        policewagon01x = {   -- Wagon model hash
            name = "Police Patrol Wagon",
            maxWeight = 700, -- Capacity in KG (for 8-10 people + police equipment)
            slots = 15,      -- Seats and space for equipment
            price = 180,     -- Reinforced and special-purpose wagon
            maxAnimals = false,
        },
        policewagongatling01x = { -- Wagon model hash
            name = "Armed Police Wagon",
            maxWeight = 550,       -- Payload capacity in KG (extra ammo, tactical gear)
            slots = 12,            -- Spaces for ammo and tactical gear
            price = 400,           -- More expensive due to heavy armament
            maxAnimals = false,
        },
        stagecoach004_2x = { -- Wagon model hash
            name = "Heavy Armored Stagecoach",
            maxWeight = 800, -- Capacity in KG (passengers, luggage, valuables; already considering armor weight)
            slots = 25,      -- Internal seats, luggage rack, safe
            price = 600,     -- Stagecoaches were expensive, armored ones even more so
            maxAnimals = false,
        },
        stagecoach004x = {   -- Wagon model hash
            name = "Reinforced Stagecoach",
            maxWeight = 900, -- Capacity in KG (passengers and cargo; less armor can mean higher payload)
            slots = 22,      -- Seats and cargo space
            price = 500,     -- Still very expensive
            maxAnimals = false,
        },
        wagonarmoured01x = { -- Wagon model hash
            name = "Armored Valuables Wagon",
            maxWeight = 500, -- Cargo capacity in KG for valuables (e.g., gold, documents); the structure is already very heavy due to the armor.
            slots = 10,      -- Secure and limited internal space
            price = 700,     -- Extremely expensive due to armor and security
            maxAnimals = false,
        },
        wagoncircus01x = {   -- Wagon model hash
            name = "Circus Wagon - Floats",
            maxWeight = 800, -- Capacity in KG for circus equipment, bulky props
            slots = 40,      -- Space for items of various shapes
            price = 120,     -- Large and decorated wagons
            maxAnimals = false,
        },
        wagoncircus02x = {   -- Wagon model hash
            name = "Circus Wagon - Performers",
            maxWeight = 600, -- Capacity in KG for circus personnel and their belongings/costumes
            slots = 30,      -- Space for people and their items
            price = 100,

            maxAnimals = false,
        },
        wagondairy01x = {    -- Wagon model hash
            name = "Milkman's Wagon",
            maxWeight = 400, -- Capacity in KG (e.g., 400 liters of milk in cans, approx. 400kg + can weight)
            slots = 50,      -- Space for many small containers
            price = 70,      -- Cost of a specialized delivery wagon
            maxAnimals = false,
        },
        wagondoc01x = {      -- Wagon model hash
            name = "Traveling Apothecary's Wagon",
            maxWeight = 300, -- Capacity in KG (medicines, elixirs, demonstration equipment)
            slots = 45,      -- Many small bottles and boxes
            price = 90,      -- Specialized wagon
            maxAnimals = false,
        },
        wagonprison01x = {   -- Wagon model hash
            name = "Prisoner Transport Wagon",
            maxWeight = 750, -- Capacity in KG (for 8-10 prisoners + guards)
            slots = 10,      -- Focus on security, cells, not miscellaneous cargo
            price = 200,     -- Reinforced wagon with cells
            maxAnimals = false,
        },
        wagontraveller01x = { -- Wagon model hash
            name = "Traveler's/Merchant's Wagon",
            maxWeight = 500,  -- Capacity in KG (personal luggage, goods for itinerant trade)
            slots = 60,       -- Good internal and possibly external space
            price = 110,
            maxAnimals = false,
        },
        wagonwork01x = {     -- Wagon model hash
            name = "Miscellaneous Delivery Wagon (Ex: Baker)",
            maxWeight = 450, -- Capacity in KG (bread, flour sacks, other delivery goods)
            slots = 55,      -- Adaptable for different types of goods
            price = 75,
            maxAnimals = false,
        },
        warwagon2 = {        -- Wagon model hash
            name = "Armored War Wagon with Turret",
            maxWeight = 600, -- Payload capacity in KG (heavy ammo, supplies for prolonged operation)
            slots = 8,       -- Very limited internal space due to armor and mechanisms
            price = 1000,    -- One of the most expensive vehicles
            priceGold = 40,  -- 1000 / 25 = 40
            maxAnimals = false,
        },
    },
    coach = {
        coach2 = {
            name = "Light Closed Carriage (Brougham)", -- Ex: for 2-4 distinguished passengers
            maxWeight = 350,                            -- Capacity in KG (2-3 passengers + light luggage ~75kg/person + 50-125kg luggage)
            slots = 8,                                  -- Seats and small space for luggage (ex: 2-3 people + luggage)
            price = 250,                                -- Price of an elegant private carriage, but not the most opulent
            maxAnimals = false,
        },
        coach3 = {
            name = "Undertakers wagon", -- For urban use, passenger transport
            maxWeight = 400,                        -- Capacity in KG (typically 4 passengers + light luggage)
            slots = 10,                             -- Seats for 4 and space for hand luggage
            price = 220,                            -- Cost for a robust service vehicle
            maxAnimals = false,
        },
        coach4 = {
            name = "Landau for a Ride", -- Luxury convertible carriage
            maxWeight = 450,            -- Capacity in KG (4 passengers comfortably + day luggage)
            slots = 12,                 -- Spacious seats and area for picnic baskets, etc.
            price = 350,                -- Prestige vehicle
            maxAnimals = false,
        },
        coach5 = {
            name = "Elegant Victoria", -- Open carriage for 2 passengers, elevated driver, for outings
            maxWeight = 300,           -- Capacity in KG (2 passengers + driver + small personal luggage)
            slots = 6,                 -- Seats for 2 + space for the driver and minimal items
            price = 300,               -- Status carriage, focused on elegance
            maxAnimals = false,
        },
        stagecoach001x = {
            name = "Common Stagecoach (Concord)", -- Standard stagecoach for intercity routes
            maxWeight = 700,                     -- Capacity in KG (6-9 passengers + considerable luggage/mail)
            slots = 20,                          -- Internal, external roof seats, rear and front luggage rack
            price = 450,                         -- Cost of a robust and functional line stagecoach
            maxAnimals = false,
        },
        stagecoach002x = {
            name = "Light Rural Stagecoach", -- Smaller, for secondary routes or fewer passengers
            maxWeight = 500,                -- Capacity in KG (4-6 passengers + luggage/mail)
            slots = 15,                     -- Similar configuration to the larger one, but on a smaller scale
            price = 380,                    -- Cheaper, but still an essential service vehicle
            maxAnimals = false,
        },
        stagecoach005x = {
            name = "Long-Distance Stagecoach (Overland)", -- For extensive routes, requiring greater capacity and robustness
            maxWeight = 750,                                -- Capacity in KG (more passengers, cargo, and supplies for the journey)
            slots = 22,                                     -- Optimized to maximize transport over long distances
            price = 500,                                    -- A considerable investment for line operators
            maxAnimals = false,
        },
        stagecoach006x = {
            name = "Urban Omnibus Stagecoach", -- For mass transit within cities and surroundings
            maxWeight = 1000,                   -- Capacity in KG (designed for many passengers, little individual luggage)
            slots = 25,                         -- Focus on number of seats, like a "trolley on wheels"
            price = 400,                        -- Public transport vehicle, functional construction
            maxAnimals = false,
        },
        stagecoach003x = {
            name = "Simple Passenger Carriage (Town Coach)", -- Basic closed model for urban use or short trips
            maxWeight = 400,                                        -- Capacity in KG (4 passengers + light luggage)
            slots = 10,                                             -- Similar to the Fiacre, perhaps less ornate
            price = 200,                                            -- An entry-level model for closed carriages
            maxAnimals = false,
        },
        coach6 = {
            name = "Open Excursion Carriage (Light Charabanc)", -- For tourist trips or group transport
            maxWeight = 600,                                       -- Capacity in KG (several passengers seated in rows)
            slots = 18,                                            -- Multiple seats, usually open
            price = 320,                                           -- For group transport for leisure or events
            maxAnimals = false,
        },
        buggy01 = {
            name = "Luxury Buggy (Leather Top)", -- Elegant buggy for personal use
            maxWeight = 250,                          -- Capacity in KG (2 passengers + small hand luggage or shopping)
            slots = 5,                                -- Seats for 2 and minimal space for belongings
            price = 150,                              -- High-quality buggy, with superior finishes
            maxAnimals = false,
        },
        buggy02 = {
            name = "Standard Buggy (Runabout)", -- Common buggy, light and agile for 2 people
            maxWeight = 200,                  -- Capacity in KG (2 passengers, not much luggage)
            slots = 4,                        -- Essentially the seats
            price = 80,                       -- One of the most accessible and popular animal-drawn vehicles
            maxAnimals = false,
        },
        buggy03 = {
            name = "Family Buggy (Light Surrey)", -- Buggy for 4 people, often with a light top
            maxWeight = 350,                       -- Capacity in KG (4 passengers, little luggage)
            slots = 8,                             -- Seats for four, usually 2 benches
            price = 120,                           -- Popular option for families or small groups
            maxAnimals = false,
        },
    }
}

Config.CustomPrice = {
    livery = 15,  -- Price of the liveries
    extra = 25,   -- Price of the extra
    tint = 38,    -- Price of the paint
    props = 15,   -- Price of the props
    lantern = 15, -- Price of the lantern props
}


Config.AnimalsStorage = {
    [`a_c_alligator_01`] = { label = "Alligator" },
    [`a_c_alligator_02`] = { label = "Alligator" },
    [`a_c_alligator_03`] = { label = "Alligator" },
    [`a_c_armadillo_01`] = { label = "Armadillo" },
    [`a_c_badger_01`] = { label = "Badger" },
    [`a_c_bat_01`] = { label = "Bat" },
    [`a_c_bearblack_01`] = { label = "Black Bear" },
    [`a_c_bear_01`] = { label = "Bear" },
    [`a_c_beaver_01`] = { label = "Beaver" },
    [`a_c_bighornram_01`] = { label = "Ram" },
    [`a_c_bluejay_01`] = { label = "Blue Jay" },
    [`a_c_boarlegendary_01`] = { label = "Legendary Boar" },
    [`a_c_boar_01`] = { label = "Boar" },
    [`a_c_buck_01`] = { label = "Buck" },
    [`a_c_buffalo_01`] = { label = "Buffalo" },
    [`a_c_buffalo_tatanka_01`] = { label = "Tatanka Buffalo" },
    [`a_c_bull_01`] = { label = "Bull" },
    [`a_c_californiacondor_01`] = { label = "Condor" },
    [`a_c_cardinal_01`] = { label = "Cardinal" },
    [`a_c_carolinaparakeet_01`] = { label = "Parakeet" },
    [`a_c_cedarwaxwing_01`] = { label = "Cedar Waxwing" },
    [`a_c_chicken_01`] = { label = "Chicken" },
    [`mp_a_c_chicken_01`] = { label = "Chicken" },
    [`a_c_chipmunk_01`] = { label = "Chipmunk" },
    [`a_c_cormorant_01`] = { label = "Cormorant" },
    [`a_c_cougar_01`] = { label = "Cougar" },
    [`a_c_cow`] = { label = "Cow" },
    [`a_c_coyote_01`] = { label = "Coyote" },
    [`a_c_crab_01`] = { label = "Crab" },
    [`a_c_cranewhooping_01`] = { label = "Crane" },
    [`a_c_crawfish_01`] = { label = "Crawfish" },
    [`a_c_crow_01`] = { label = "Crow" },
    [`a_c_deer_01`] = { label = "Deer" },
    [`a_c_donkey_01`] = { label = "Donkey" },
    [`a_c_duck_01`] = { label = "Duck" },
    [`a_c_eagle_01`] = { label = "Eagle" },
    [`a_c_egret_01`] = { label = "Egret" },
    [`a_c_elk_01`] = { label = "Elk" },
    [`a_c_fishbluegil_01_ms`] = { label = "Bluegill" },
    [`a_c_fishbluegil_01_sm`] = { label = "Bluegill" },
    [`a_c_fishbullheadcat_01_ms`] = { label = "Bullhead Catfish" },
    [`a_c_fishbullheadcat_01_sm`] = { label = "Bullhead Catfish" },
    [`a_c_fishchainpickerel_01_ms`] = { label = "Chain Pickerel" },
    [`a_c_fishchainpickerel_01_sm`] = { label = "Chain Pickerel" },
    [`a_c_fishchannelcatfish_01_lg`] = { label = "Channel Catfish" },
    [`a_c_fishchannelcatfish_01_xl`] = { label = "Giant Channel Catfish" },
    [`a_c_fishlakesturgeon_01_lg`] = { label = "Lake Sturgeon" },
    [`a_c_fishlargemouthbass_01_lg`] = { label = "Largemouth Bass" },
    [`a_c_fishlargemouthbass_01_ms`] = { label = "Largemouth Bass" },
    [`a_c_fishlongnosegar_01_lg`] = { label = "Longnose Gar" },
    [`a_c_fishmuskie_01_lg`] = { label = "Muskie" },
    [`a_c_fishnorthernpike_01_lg`] = { label = "Northern Pike" },
    [`a_c_fishperch_01_ms`] = { label = "Perch" },
    [`a_c_fishperch_01_sm`] = { label = "Perch" },
    [`a_c_fishrainbowtrout_01_lg`] = { label = "Rainbow Trout" },
    [`a_c_fishrainbowtrout_01_ms`] = { label = "Rainbow Trout" },
    [`a_c_fishredfinpickerel_01_ms`] = { label = "Redfin Pickerel" },
    [`a_c_fishredfinpickerel_01_sm`] = { label = "Redfin Pickerel" },
    [`a_c_fishrockbass_01_ms`] = { label = "Rock Bass" },
    [`a_c_fishrockbass_01_sm`] = { label = "Rock Bass" },
    [`a_c_fishsalmonsockeye_01_lg`] = { label = "Sockeye Salmon" },
    [`a_c_fishsalmonsockeye_01_ml`] = { label = "Sockeye Salmon" },
    [`a_c_fishsalmonsockeye_01_ms`] = { label = "Sockeye Salmon" },
    [`a_c_fishsmallmouthbass_01_lg`] = { label = "Smallmouth Bass" },
    [`a_c_fishsmallmouthbass_01_ms`] = { label = "Smallmouth Bass" },
    [`a_c_fox_01`] = { label = "Fox" },
    [`a_c_frogbull_01`] = { label = "Bullfrog" },
    [`a_c_gilamonster_01`] = { label = "Gila Monster" },
    [`a_c_goat_01`] = { label = "Goat" },
    [`a_c_goosecanada_01`] = { label = "Goose" },
    [`a_c_hawk_01`] = { label = "Hawk" },
    [`a_c_heron_01`] = { label = "Heron" },
    [`a_c_iguanadesert_01`] = { label = "Desert Iguana" },
    [`a_c_iguana_01`] = { label = "Iguana" },
    [`a_c_javelina_01`] = { label = "Javelina" },
    [`a_c_lionmangy_01`] = { label = "Mangy Lion" },
    [`a_c_loon_01`] = { label = "Loon" },
    [`a_c_moose_01`] = { label = "Moose" },
    [`a_c_muskrat_01`] = { label = "Muskrat" },
    [`a_c_oriole_01`] = { label = "Oriole" },
    [`a_c_owl_01`] = { label = "Owl" },
    [`a_c_ox_01`] = { label = "Ox" },
    [`a_c_panther_01`] = { label = "Panther" },
    [`a_c_parrot_01`] = { label = "Parrot" },
    [`a_c_pelican_01`] = { label = "Pelican" },
    [`a_c_pheasant_01`] = { label = "Pheasant" },
    [`a_c_pigeon`] = { label = "Pigeon" },
    [`a_c_pig_01`] = { label = "Pig" },
    [`a_c_possum_01`] = { label = "Opossum" },
    [`a_c_prairiechicken_01`] = { label = "Prairie Chicken" },
    [`a_c_pronghorn_01`] = { label = "Pronghorn" },
    [`a_c_quail_01`] = { label = "Quail" },
    [`a_c_rabbit_01`] = { label = "Rabbit" },
    [`a_c_raccoon_01`] = { label = "Raccoon" },
    [`a_c_rat_01`] = { label = "Rat" },
    [`a_c_raven_01`] = { label = "Raven" },
    [`a_c_robin_01`] = { label = "Robin" },
    [`a_c_rooster_01`] = { label = "Rooster" },
    [`a_c_roseatespoonbill_01`] = { label = "Roseate Spoonbill" },
    [`a_c_seagull_01`] = { label = "Seagull" },
    [`a_c_sharkhammerhead_01`] = { label = "Hammerhead Shark" },
    [`a_c_sharktiger`] = { label = "Tiger Shark" },
    [`a_c_sheep_01`] = { label = "Sheep" },
    [`a_c_skunk_01`] = { label = "Skunk" },
    [`a_c_snakeblacktailrattle_01`] = { label = "Rattlesnake" },
    [`a_c_snakeblacktailrattle_pelt_01`] = { label = "Rattlesnake Skin" },
    [`a_c_snakeferdelance_01`] = { label = "Fer-de-Lance" },
    [`a_c_snakeferdelance_pelt_01`] = { label = "Fer-de-Lance Skin" },
    [`a_c_snakeredboa10ft_01`] = { label = "Giant Red Boa" },
    [`a_c_snakeredboa_01`] = { label = "Red Boa" },
    [`a_c_snakeredboa_pelt_01`] = { label = "Boa Skin" },
    [`a_c_snakewater_01`] = { label = "Water Snake" },
    [`a_c_snakewater_pelt_01`] = { label = "Water Snake Skin" },
    [`a_c_snake_01`] = { label = "Snake" },
    [`a_c_snake_pelt_01`] = { label = "Snake Skin" },
    [`a_c_songbird_01`] = { label = "Songbird" },
    [`a_c_sparrow_01`] = { label = "Sparrow" },
    [`a_c_squirrel_01`] = { label = "Squirrel" },
    [`a_c_toad_01`] = { label = "Toad" },
    [`a_c_turkeywild_01`] = { label = "Wild Turkey" },
    [`a_c_turkey_01`] = { label = "Turkey" },
    [`a_c_turkey_02`] = { label = "Turkey" },
    [`a_c_turtlesea_01`] = { label = "Sea Turtle" },
    [`a_c_turtlesnapping_01`] = { label = "Snapping Turtle" },
    [`a_c_vulture_01`] = { label = "Vulture" },
    [`A_C_Wolf`] = { label = "Wolf" },
    [`a_c_wolf_medium`] = { label = "Medium Wolf" },
    [`a_c_wolf_small`] = { label = "Small Wolf" },
    [`a_c_woodpecker_01`] = { label = "Woodpecker" },
    [`a_c_woodpecker_02`] = { label = "Woodpecker" },

    -- Large Pelts
    [`mp001_p_mp_pelt_xlarge_acbear01`] = { label = "Bear Pelt" },
    [`p_cs_bearskin_xlarge_roll`] = { label = "Bear Pelt" },
    [`p_cs_bfloskin_xlarge_roll`] = { label = "Buffalo Pelt" },
    [`p_cs_bullgator_xlarge_roll`] = { label = "Legendary Alligator Skin" },
    [`p_cs_cowpelt2_xlarge`] = { label = "Cow Hide" },
    [`p_cs_pelt_xlarge`] = { label = "Unnamed Pelt" },
    [`p_cs_pelt_xlarge_alligator`] = { label = "Alligator Skin" },
    [`p_cs_pelt_xlarge_bear`] = { label = "Bear Pelt" },
    [`p_cs_pelt_xlarge_bearlegendary`] = { label = "Legendary Bear Pelt" },
    [`p_cs_pelt_xlarge_buffalo`] = { label = "Buffalo Pelt" },
    [`p_cs_pelt_xlarge_elk`] = { label = "Elk Pelt" },
    [`p_cs_pelt_xlarge_tbuffalo`] = { label = "Tatanka Buffalo Pelt" },
    [`p_cs_pelt_xlarge_wbuffalo`] = { label = "White Buffalo Pelt" },

    ----- Pelts

    [-1544126829] = { label = "Perfect Pronghorn Hide" },
    [554578289] = { label = "Good Pronghorn Hide" },
    [-983605026] = { label = "Poor Pronghorn Hide" },
    [653400939] = { label = "Perfect Wolf Pelt" },
    [1145777975] = { label = "Good Wolf Pelt" },
    [85441452] = { label = "Poor Wolf Pelt" },
    [-1858513856] = { label = "Perfect Boar Pelt" },
    [1248540072] = { label = "Poor Boar Pelt" },
    [-702790226] = { label = "Perfect Deer Hide" },
    [-868657362] = { label = "Good Deer Hide" },
    [1603936352] = { label = "Poor Deer Hide" },
    [-1791452194] = { label = "Perfect Cougar Pelt" },
    [459744337] = { label = "Good Cougar Pelt" },
    [1914602340] = { label = "Poor Cougar Pelt" },
    [1466150167] = { label = "Perfect Sheep Pelt" },
    [-1317365569] = { label = "Good Sheep Pelt" },
    [1729948479] = { label = "Poor Sheep Pelt" },
    [-1035515486] = { label = "Perfect Deer Pelt" },
    [-1827027577] = { label = "Good Deer Pelt" },
    [-662178186] = { label = "Poor Deer Pelt" },
    [-1102272634] = { label = "Perfect Pig Hide" },
    [-57190831] = { label = "Good Pig Hide" },
    [-30896554] = { label = "Poor Pig Hide" },
    [1963510418] = { label = "Perfect Peccary Pelt" },
    [-1379330323] = { label = "Good Peccary Pelt" },
    [-99092070] = { label = "Poor Peccary Pelt" },
    [1969175294] = { label = "Perfect Panther Pelt" },
    [-395646254] = { label = "Good Panther Pelt" },
    [1584468323] = { label = "Poor Panther Pelt" },
    [1795984405] = { label = "Perfect Ram Pelt" },
    [-476045512] = { label = "Good Ram Pelt" },
    [1796037447] = { label = "Poor Ram Pelt" },
    [2088901891] = { label = "Legendary Night Panther Pelt" },
    [-675142890] = { label = "Legendary Gabbro Horn Ram Pelt" },
    [832214437] = { label = "Legendary Iguga Cougar Pelt" },
    [-1946740647] = { label = "Legendary Emerald Wolf Pelt" },
    [-1572330336] = { label = "Legendary Cogi Boar Pelt" },
    [2116849039] = { label = "Standard Pelt" },
    [-1924159110] = { label = "Teca Alligator Skin" },
    [-845037222] = { label = "Perfect Cow Hide" },
    [1150594075] = { label = "Good Cow Hide" },
    [334093551] = { label = "Poor Cow Hide" },
    [-1332163079] = { label = "Perfect Wapiti Pelt" },
    [1181652728] = { label = "Good Wapiti Pelt" },
    [2053771712] = { label = "Poor Wapiti Pelt" },
    [-217731719] = { label = "Perfect Canadian Moose Pelt" },
    [1636891382] = { label = "Good Canadian Moose Pelt" },
    [1868576868] = { label = "Poor Canadian Moose Pelt" },
    [659601266] = { label = "Perfect Ox Hide" },
    [1208128650] = { label = "Good Ox Hide" },
    [462348928] = { label = "Poor Ox Hide" },
    [-53270317] = { label = "Perfect Bull Hide" },
    [-336086818] = { label = "Good Bull Hide" },
    [9293261] = { label = "Poor Bull Hide" },
    [-1475338121] = { label = "Perfect Large Alligator Skin" },
    [-1625078531] = { label = "Perfect Alligator Skin" },
    [-802026654] = { label = "Good Alligator Skin" },
    [-1243878166] = { label = "Poor Alligator Skin" },
    [1292673537] = { label = "Perfect Grizzly Bear Pelt" },
    [143941906] = { label = "Good Grizzly Bear Pelt" },
    [957520252] = { label = "Poor Grizzly Bear Pelt" },
    [-237756948] = { label = "Perfect Buffalo Pelt" },
    [-591117838] = { label = "Good Buffalo Pelt" },
    [-1730060063] = { label = "Poor Buffalo Pelt" },
    [663376218] = { label = "Perfect Bear Pelt" },
    [1490032862] = { label = "Good Bear Pelt" },
    [1083865179] = { label = "Poor Bear Pelt" },
    [854596618] = { label = "Perfect Beaver Pelt" },
    [-2059726619] = { label = "Good Beaver Pelt" },
    [-1569450319] = { label = "Poor Beaver Pelt" },
    [121494806] = { label = "Legendary Beaver Pelt" },
    [-794277189] = { label = "Perfect Coyote Pelt" },
    [1150939141] = { label = "Good Coyote Pelt" },
    [-1558096473] = { label = "Poor Coyote Pelt" },
    [-1061362634] = { label = "Legendary Coyote Pelt" },
    [500722008] = { label = "Perfect Fox Pelt" },
    [238733925] = { label = "Good Fox Pelt" },
    [1647012424] = { label = "Poor Fox Pelt" },
    [-1648383828] = { label = "Perfect Goat Hide" },
    [1710714415] = { label = "Good Goat Hide" },
    [699990316] = { label = "Poor Goat Hide" },
    [1806153689] = { label = "Poor Alligator Skin" },
    [1276143905] = { label = "Legendary Ota Fox Pelt" },
    [`mp007_p_nat_pelt_bearlegend01x`] = { label = "Legendary Bear Pelt 1" },
    [`mp007_p_nat_pelt_bearlegend02x`] = { label = "Legendary Bear Pelt 2" },
    [`mp007_p_nat_pelt_bearlegend03x`] = { label = "Legendary Bear Pelt 3" },
    [`mp007_p_nat_pelt_beaverlegend01x`] = { label = "Legendary Beaver Pelt 1" },
    [`mp007_p_nat_pelt_beaverlegend02x`] = { label = "Legendary Beaver Pelt 2" },
    [`mp007_p_nat_pelt_beaverlegend03x`] = { label = "Legendary Beaver Pelt 3" },
    [`mp007_p_nat_pelt_bighornlegend01x`] = { label = "Legendary Ram Pelt 1" },
    [`mp007_p_nat_pelt_bighornlegend02x`] = { label = "Legendary Ram Pelt 2" },
    [`mp007_p_nat_pelt_bighornlegend03x`] = { label = "Legendary Ram Pelt 3" },
    [`mp007_p_nat_pelt_boarlegend01x`] = { label = "Legendary Boar Pelt 1" },
    [`mp007_p_nat_pelt_boarlegend02x`] = { label = "Legendary Boar Pelt 2" },
    [`mp007_p_nat_pelt_boarlegend03x`] = { label = "Legendary Boar Pelt 3" },
    [`mp007_p_nat_pelt_bucklegend01x`] = { label = "Legendary Deer Pelt 1" },
    [`mp007_p_nat_pelt_bucklegend02x`] = { label = "Legendary Deer Pelt 2" },
    [`mp007_p_nat_pelt_bucklegend03x`] = { label = "Legendary Deer Pelt 3" },
    [`mp007_p_nat_pelt_cougarlegend01x`] = { label = "Legendary Cougar Pelt 1" },
    [`mp007_p_nat_pelt_cougarlegend02x`] = { label = "Legendary Cougar Pelt 2" },
    [`mp007_p_nat_pelt_cougarlegend03x`] = { label = "Legendary Cougar Pelt 3" },
    [`mp007_p_nat_pelt_coyotelegend01x`] = { label = "Legendary Coyote Pelt 1" },
    [`mp007_p_nat_pelt_coyotelegend02x`] = { label = "Legendary Coyote Pelt 2" },
    [`mp007_p_nat_pelt_coyotelegend03x`] = { label = "Legendary Coyote Pelt 3" },
    [`mp007_p_nat_pelt_elklegend01x`] = { label = "Legendary Elk Pelt 1" },
    [`mp007_p_nat_pelt_elklegend02x`] = { label = "Legendary Elk Pelt 2" },
    [`mp007_p_nat_pelt_elklegend03x`] = { label = "Legendary Elk Pelt 3" },
    [`mp007_p_nat_pelt_foxlegend01x`] = { label = "Legendary Fox Pelt 1" },
    [`mp007_p_nat_pelt_foxlegend02x`] = { label = "Legendary Fox Pelt 2" },
    [`mp007_p_nat_pelt_foxlegend03x`] = { label = "Legendary Fox Pelt 3" },
    [`mp007_p_nat_pelt_gatorlegend02x`] = { label = "Legendary Alligator Skin 2" },
    [`mp007_p_nat_pelt_gatorlegend03x`] = { label = "Legendary Alligator Skin 3" },
    [`mp007_p_nat_pelt_mooselegend01x`] = { label = "Legendary Canadian Moose Pelt 1" },
    [`mp007_p_nat_pelt_mooselegend02x`] = { label = "Legendary Canadian Moose Pelt 2" },
    [`mp007_p_nat_pelt_mooselegend03x`] = { label = "Legendary Canadian Moose Pelt 3" },
    [`mp007_p_nat_pelt_wolflegend01x`] = { label = "Legendary Wolf Pelt 1" },
    [`mp007_p_nat_pelt_wolflegend02x`] = { label = "Legendary Wolf Pelt 2" },
    [`mp007_p_nat_pelt_wolflegend03x`] = { label = "Legendary Wolf Pelt 3" },
    [`mp007_p_nat_pelt_pantherlegend01x`] = { label = "Legendary Panther Pelt 1" },
    [`mp007_p_nat_pelt_pantherlegend02x`] = { label = "Legendary Panther Pelt 2" },
    [`mp007_p_nat_pelt_pantherlegend03x`] = { label = "Legendary Panther Pelt 3" },
    [`mp001_p_mp_pelt_xlarge_acbear01`] = { label = "Large Bear Pelt" },
    [`mp005_s_posse_raccoonpelt01x`] = { label = "Raccoon Pelt" },
    [`p_cs_pelt_wolf`] = { label = "Wolf Pelt" },
    [`p_cs_pelt_wolf_roll`] = { label = "Rolled Wolf Pelt" },
    [`p_cs_wolfpelt_large`] = { label = "Large Wolf Pelt" },
    [`p_cs_pelt_ws_alligator`] = { label = "Large Alligator Skin" },
    [`p_cs_gilamonsterpelt01x`] = { label = "Gila Monster Skin" },
    [`p_cs_iguanapelt`] = { label = "Iguana Skin" },
    [`p_cs_iguanapelt02x`] = { label = "Iguana Skin" },
    [`p_cs_pelt_med_armadillo`] = { label = "Armadillo Pelt" },
    [`p_cs_pelt_med_badger`] = { label = "Badger Pelt" },
    [`p_cs_pelt_med_muskrat`] = { label = "Muskrat Pelt" },
    [`p_cs_pelt_med_possum`] = { label = "Opossum Pelt" },
    [`p_cs_pelt_med_raccoon`] = { label = "Raccoon Pelt" },
    [`p_cs_pelt_med_skunk`] = { label = "Skunk Pelt" },
    [`p_cs_pelt_medium`] = { label = "Medium Pelt" },
    [`p_cs_pelt_medium_og`] = { label = "Medium Pelt OG" },
    [`p_cs_pelt_medlarge_roll`] = { label = "Medium-Large Rolled Pelt" },


}


Config.Chop = {
    -- Independent chop shop locations (own coords + blip each).
    Locations = {
        {
            name = 'Chop Shop',
            coords = vector3(1869.22, 1982.52, 246.8),
            blip = true,
        },
    },

    InteractDistance = 10.0, -- how close to the store to show the prompt
    WagonSearchDistance = 30.0, -- wagon search radius around the player
    AllowUnknownWagons = true, -- scrap unlisted vehicles with default payout

    PromptKey = 0x760A9C6F, -- G key (control hash, passed straight to PromptSetControlAction)
    PromptText = 'Scrap Wagon',

    ChopCooldown = 300, -- seconds between chops per player
    NotifyDuration = 1000,
    Debug = false,

    
    RewardItems = {
        wood = { min = 5, max = 15 },
    },
    CashPayout = { min = 5, max = 20 },
    DefaultMultiplier = 1.0,
    MinMultiplier = 0.5,
    MaxMultiplier = 2.5,

    ChopBlip = {
        show = true,
        sprite = 564457427,
        name = 'Wagon Chop',
        scale = 0.8,
    },
}