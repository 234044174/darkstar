package.loaded["scripts/globals/bcnm"] = nil;
require("scripts/globals/status");
require("scripts/globals/keyitems");
require("scripts/globals/missions");
require("scripts/globals/quests");

-- NEW SYSTEM BCNM NOTES
-- The "core" functions TradeBCNM EventUpdateBCNM EventTriggerBCNM EventFinishBCNM all return TRUE if the action performed is covered by the function.
-- This means all the old code will still be executed if the new functions don't support it. This means that there is effectively 'backwards compatibility' with the old system.

-- array to map (for each zone) the item id of the valid trade item with the bcnmid in the database
-- e.g. zone, {itemid, bcnmid, itemid, bcnmid, itemid, bcnmid}
-- DO NOT INCLUDE MAAT FIGHTS
itemid_bcnmid_map = {6, {0, 0}, -- Bearclaw_Pinnacle
                   8, {0, 0}, -- Boneyard_Gully
                   10, {0, 0}, -- The_Shrouded_Maw
                   13, {0, 0}, -- Mine_Shaft_2716
                   17, {0, 0}, -- Spire of Holla
                   19, {0, 0}, -- Spire of Dem
                   21, {0, 0}, -- Spire of Mea
                   23, {0, 0}, -- Spire of Vahzl
                   29, {0, 0}, -- Riverne Site #B01
                   31, {0, 0}, -- Monarch Linn
                   32, {0, 0}, -- Sealion's Den
                   35, {0, 0}, -- The Garden of RuHmet
                   36, {0, 0}, -- Empyreal Paradox
                   139, {1177, 4, 1552, 10, 1553, 11, 1131, 12, 1175, 15, 1180, 17}, -- Horlais Peak
                   140, {1551, 34, 1552, 35, 1552, 36}, -- Ghelsba Outpost
                   144, {1166, 68, 1178, 81, 1553, 76, 1180, 82, 1130, 79, 1552, 73}, -- Waughroon Shrine
                   146, {1553, 107, 1551, 105, 1177, 100}, -- Balgas Dias
                   163, {1130, 129}, -- Sacrificial Chamber
                   168, {0, 0}, -- Chamber of Oracles
                   170, {0, 0}, -- Full Moon Fountain
                   180, {1550, 293}, -- LaLoff Amphitheater
                   181, {0, 0}, -- The Celestial Nexus
                   201, {1546, 418, 1174, 417}, -- Cloister of Gales
                   202, {1548, 450, 1172, 449}, -- Cloister of Storms
                   203, {1545, 482, 1171, 481}, -- Cloister of Frost
                   206, {0, 0}, -- Qu'Bia Arena
                   207, {1544, 545}, -- Cloister of Flames
                   209, {1547, 578, 1169, 577}, -- Cloister of Tremors
                   211, {1549, 609}}; -- Cloister of Tides

-- array to map (for each zone) the BCNM ID to the Event Parameter corresponding to this ID.
-- DO NOT INCLUDE MAAT FIGHTS (only included one for testing!)
-- bcnmid, paramid, bcnmid, paramid, etc
-- The BCNMID is found via the database.
-- The paramid is a bitmask which you need to find out. Being a bitmask, it will be one of:
-- 0, 1, 2, 3, 4, 5, ...
battlefield_bitmask_map =
{
    [6] = {640, 641, 642, 643, 644},
    [8] = {672, 673, 674, 675, 676, 677, 678, 679},
    [10] = {704, 705, 706},
    [13] = {736, 737, 738, 739, 740, 741},
    [17] = {768, 769, 770},
    [19] = {800,801,802},
    [21] = {832,833,834},
    [23] = {864,865,866},
    [29] = {896,897},
    [30] = {928},
    [31] = {960,961,962,963,964,965,966,967},
    [32] = {992,993},
    [35] = {1024},
    [36] = {1056,1057},
    [37] = {1298,1299,1300,1301,1302,1303,1304,1305,1306,1307},
    [38] = {1290,1291,1292,1293,1294,1295,1296,1297},
    [39] = {1286},
    [40] = {1287},
    [41] = {1288},
    [42] = {1289},
    [57] = {1088,1089,1090,1091,1092},
    [64] = {1120,1121,1122,1123,1124},
    [67] = {1152,1153,1154,1155,1156},
    [78] = {1184},
    [186] = {1280},
    [185] = {1281},
    [187] = {1282},
    [188] = {1283},
    [134] = {1284},
    [135] = {1285},
    [139] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20},
    [140] = {32,33,34,35,36,37},
    [144] = {64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85},
    [146] = {96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116},
    [156] = {352,353,354},
    [163] = {128,129,130,131,132},
    [165] = {160,161,162,163,164},
    [168] = {192,193,194,195,196,197,198,199,200,201},
    [170] = {224,225,226,227},
    [179] = {256,257,258,259,260,261,262},
    [180] = {288,289,290,291,292,293},
    [181] = {320},
    [182] = {385},
    [201] = {416,417,418,419,420},
    [202] = {448,449,450,451,452},
    [203] = {480,481,482,483,484},
    [206] = {512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533},
    [207] = {544,545,546,547},
    [209] = {576,577,578,579,580},
    [211] = {608,609,610,611},
};

-- Call this onTrade for burning circles
function TradeBCNM(player, zone, trade, npc)
    -- return false;
    if (player:hasStatusEffect(EFFECT_BATTLEFIELD)) then -- cant start a new bc
        player:messageBasic(94, 0, 0);
        return false;
    elseif (player:hasWornItem(trade:getItem())) then -- If already used orb or testimony
        player:messageBasic(56, 0, 0); -- i need correct dialog
        return false;
    end

    if (CheckMaatFights(player, zone, trade, npc)) then -- This function returns true for maat fights
        return true;
    end
    -- the following is for orb battles, etc

    local id = ItemToBCNMID(player, zone, trade);

    if (id == -1) then -- no valid BCNMs with this item
        -- todo: display message based on zone text offset
        player:setVar("trade_bcnmid", 0);
        player:setVar("trade_itemid", 0);
        return false;
    else -- a valid BCNM with this item, start it.
        mask = GetBattleBitmask(id, zone, 1);

        if (mask == -1) then -- Cannot resolve this BCNMID to an event number, edit bcnmid_param_map!
            print("Item is for a valid BCNM but cannot find the event parameter to display to client.");
            player:setVar("trade_bcnmid", 0);
            player:setVar("trade_itemid", 0);
            return false;
        end
        if (player:isBcnmsFull() == 1) then -- temp measure, this will precheck the instances
            print("all bcnm instances are currently occupied.");
            npc:messageBasic(246, 0, 0); -- this wont look right in other languages!
            return true;
        end
        player:setLocalVar("[battlefield]trade", trade:getItem());
        player:setLocalVar("[battlefield]id", id);
        player:startEvent(0x7d00, 0, 0, 0, mask, 0, 0, 0, 0);
        return true;
    end
end;

function EventTriggerBCNM(player, npc)
    --[[
        param1: idk
        param2: idk
        param3: idk
        param4: mask
        param5: idk
        param6: idk
        param7: idk
        param8: 0 for options, 1 plays rank 2 mission without option, 2+ doesnt allow entry? (confirm once loading actually handled)
    ]]--
    if (player:hasStatusEffect(EFFECT_BATTLEFIELD)) then
        if player:getBattlefield() then
            player:startEvent(0x7d03); -- Run Away or Stay menu
            return;
        end;
    end;
    
    if (checkNonTradeBCNM(player, npc)) then
        return true;
    end

    return false;
end;

function EventUpdateBCNM(player, csid, option, entrance)
    local area = player:getLocalVar("[battlefield]area");
    local id = player:getLocalVar("[battlefield]trade");
    -- return false;
    --[[
        what probably happens:
            player is given list of valid bcnms
            that mask is slapped into oneventupdate
            client chooses event
            player gets registered oneventfinish
            
        todo:
            [ ] handle party members conditions
            [ ] attempt to register here
            [ ] return code on registering determines param for updateEvent:
                            -- param1
                            --      2=generic enter cs
                            --      3=spam increment instance requests
                            --      4=cleared to enter but cant while ppl engaged
                            --      5=dont meet req, access denied.
                            --      6=room max cap
                            -- param2 alters the eventfinish option (offset)
                            -- param7/8 = does nothing??
            
            
            
            
            
            
            [ ] EVENT UPDATE:
                    check member requirements
                    load battlefield if trade
                    send item worn message
                    send cap details (and subjob restriction if applicable through textid etc)
            [ ] EVENT FINISH:
                    spam messages including member clearance,, time limit, record
                    
            [ ] retail just spams messages on ending the cutscene, isnt part of event
            [ ] for trades the battlefield is loaded in updateEvent
            




            
            
    ]]
    local skip = CutsceneSkip(player, npc);
    
    if csid == 0x7d00 then
        local zone = player:getZoneID();
        local mask = GetBattleBitmask(id, zone, 1);
        local effect = player:getStatusEffect(EFFECT_BATTLEFIELD);
        local skip = CutsceneSkip(player);
        
        if option == 0 then
            local record, name, cap = 0;
            -- yes there's a bcnm with id 0
            if id == 0 then
                id = -1;
            end;
            
            if area == 0 then
                area = 1;
                player:setLocalVar("[battlefield]area", area);
            end;
            
            if mask == -1 then
                mask = checkNonTradeBCNM(player, nil, 1);
            end;
            
            local result = player:registerBattlefield(id, area);
            local param4 = 0;
            if effect then
                param4 = 1;
            end
            
            player:PrintToPlayer(string.format("UPDATE csid %u option %u mask %u", csid, option, mask));
            if result ~= 2 then
                player:setLocalVar("[battlefield]area", area + 1);
            else
                if id ~= -1 then
                    local battlefield = player:getBattlefield();
                    name, record = battlefield:getRecord();
                    cap = battlefield:getMaxPlayers();
                    mask = battlefield:getID();
                end;
            end;
            player:updateEvent(result, mask, 0, record, cap, skip);
        elseif option == 255 then
            player:updateEvent(2, mask, 0, 0, 0, 0);
        end;
        return;
    end;
--[[
    -- seen: option 2, 3, 0 in that order
    if (csid == 0x7d03 and option == 2) then -- leaving a BCNM the player is currently in.
        player:delStatusEffect(EFFECT_BATTLEFIELD);
        return true;
    end
    ]]
    --[[
    if (option == 255 and csid == 0x7d00) then -- Clicked yes, try to register bcnmid
        if (player:hasStatusEffect(EFFECT_BATTLEFIELD)) then
            -- You're entering a bcnm but you already had the battlefield effect, so you want to go to the
            -- instance that your battlefield effect represents.
            player:registerBattlefield(id);
            return true;
        end
        local result = player:registerBattlefield(id, area);
        if (result ~= 2) then
            player:updateEvent(0, result, 0, 0, 1, 0);
            player:setLocalVar("[battlefield]area", area + 1);
            -- player:tradeComplete();
        else
            -- no free battlefields at the moment!
            -- todo: print message to client
        end
    elseif (option == 0 and csid == 0x7d00) then -- Requesting an Instance
        -- Increment the instance ticker.
        -- The client will send a total of THREE EventUpdate packets for each one of the free instances.
        -- If the first instance is free, it should respond to the first packet
        -- If the second instance is free, it should respond to the second packet, etc
      
            local mask = GetBattleBitmask(id, player:getZoneID(), 2);
            local status = player:addStatusEffect(EFFECT_BATTLEFIELD);
            local playerbcnmid = status:getPower();
            if (mask < playerbcnmid) then
                mask = GetBattleBitmask(playerbcnmid, player:getZoneID(), 2);
            elseif (mask >= playerbcnmid) then
                mask = GetBattleBitmask(id, player:getZoneID(), 2);
            end

            player:updateEvent(2, mask, 0, 1, 1, skip); -- Add mask number for the correct entering CS
            
        -- elseif (player:getVar("bcnm_instanceid") == 255) then -- none free
            -- print("nfa");
            -- player:updateEvent(2, 5, 0, 0, 1, 0);  -- @cs 32000 0 0 0 0 0 0 0 2
            -- param1
            -- 2=generic enter cs
            -- 3=spam increment instance requests
            -- 4=cleared to enter but cant while ppl engaged
            -- 5=dont meet req, access denied.
            -- 6=room max cap
            -- param2 alters the eventfinish option (offset)
            -- param7/8 = does nothing??
       
        -- @pos -517 159 -209
        -- @pos -316 112 -103
        -- player:updateEvent(msgid, bcnmFight, 0, record, numadventurers, skip); skip= 1 to skip anim
        -- msgid 1=wait a little longer, 2=enters
    end
]]
    return true;
end;

function EventFinishBCNM(player, csid, option)
    print("FINISH csid "..csid.." option "..option);
    
    if csid == 0x7d00 then
        player:PrintToPlayer(string.format("bit.band(option, 0x0F) == %u", bit.band(option, 0x0F)));

        if bit.band(option, 0x0F) == 3 then
            local area = player:getLocalVar("[battlefield]area");
            option = bit.rshift(option, 4);
            player:PrintToPlayer(string.format("cs option: %u | battlefield: %u | area: %u", option,battlefield_bitmask_map[player:getZoneID()][option], area));
            player:registerBattlefield(battlefield_bitmask_map[player:getZoneID()][option-2], area);
         end;
    end;
        print("MODIFIED FINISH csid "..csid.." option "..option);
    
    if ((csid == 0x7d03 and option == 4 ) or (csid == 0x7d02)) and player:getBattlefield() and #(player:getBattlefield():getPlayers()) == 1 then
        if player:getBattlefield():getStatus() ~= 0 then player:getBattlefield():cleanup(true); end;
    end;
    
    if (player:hasStatusEffect(EFFECT_BATTLEFIELD) == false) then -- Temp condition for normal bcnm (started with onTrigger)
        return false;
    else
        local item = player:getLocalVar("[battlefield]trade");
        local id = player:getBattlefieldID();
        if item == 0 then   return true end;
        if (id == 68 or id == 418 or id == 450 or id == 482 or id == 545 or id == 578 or id == 609 or id == 293) then
            player:tradeComplete(); -- Removes the item
        elseif ((item >= 1426 and item <= 1440) or item == 1130 or item == 1131 or item == 1175 or item == 1177 or item == 1180 or item == 1178 or item == 1551 or item == 1552 or item == 1553) then -- Orb and Testimony (one time item)
            player:createWornItem(item);
        end
        return true;
    end

end;

-- Returns TRUE if you're trying to do a maat fight, regardless of outcome e.g. if you trade testimony on wrong job, this will return true in order to prevent further execution of TradeBCNM. Returns FALSE if you're not doing a maat fight (in other words, not trading a testimony!!)
function CheckMaatFights(player, zone, trade, npc)
    -- check for maat fights (one maat fight per zone in the db, but >1 mask entries depending on job, so we
    -- need to choose the right one depending on the players job, and make sure the right testimony is traded,
    -- and make sure the level is right!
    local itemid = trade:getItem();
    local job = player:getMainJob();
    local lvl = player:getMainLvl();

    if (itemid >= 1426 and itemid <= 1440) then -- The traded item IS A TESTIMONY
        if (lvl < 66) then
            return true;
        end

        if (player:isBcnmsFull() == 1) then -- temp measure, this will precheck the instances
            print("all bcnm instances are currently occupied.");
            npc:messageBasic(246, 0, 0);
            return true;
        end

        -- Zone, {item, job, menu, bcnmid, ...}
        maatList = {
                            [139] = {1426, 1, 32, 5, 1429, 4, 64, 6, 1436, 11, 128, 7},        -- Horlais Peak [WAR BLM RNG]
                            [144] = {1430, 5, 64, 70, 1431, 6, 128, 71, 1434, 9, 256, 72},        -- Waughroon Shrine [RDM THF BST]
                            [146] = {1427, 2, 32, 101, 1428, 3, 64, 102, 1440, 15, 128, 103},    -- Balga's Dais [MNK WHM SMN]
                            [168] = {1437, 12, 4, 194, 1438, 13, 8, 195, 1439, 14, 16, 196},    -- Chamber of Oracles [SAM NIN DRG]
                            [206] = {1432, 7, 32, 517, 1433, 8, 64, 518, 1435, 10, 128, 519}
                        };-- Qu'Bia Arena [PLD DRK BRD]
                    
        local list = maatList[zone];
        

        for nb = 1, table.getn(maatList), 2 do
            if (maatList[nb] == zone) then
                for nbi = 1, table.getn(maatList[nb + 1]), 4 do
                    if (itemid == maatList[nb + 1][nbi] and job == maatList[nb + 1][nbi + 1]) then
                        player:startEvent(0x7d00, 0, 0, 0, maatList[nb + 1][nbi + 2], 0, 0, 0, 0);
                        player:setVar("trade_bcnmid", maatList[nb + 1][nbi + 3]);
                        player:setVar("trade_itemid", maatList[nb + 1][nbi]);
                        break;
                    end
                end
            end
        end

        return true;
    end
    -- if it got this far then its not a testimony
    return false;
end;

function GetBattleBitmask(id, zone, mode)
    -- normal sweep for NON MAAT FIGHTS
    local ret = -1;
    local mask = 0;
    
    local battlefieldlist = battlefield_bitmask_map[zone]
    
    if battlefieldlist then
        for index, battlefield in ipairs(battlefield_bitmask_map[zone]) do
            if id == battlefield then
                if mode == 1 then
                    ret = mask + bit.lshift(index + 1, 2);
                else
                    ret = mask + index;
                end
            end
        end
    else
        printf("[battlefield] unable to get bitmask for battlefield: %u, zone: %u", id, zone);
    end
    --[[for zoneindex = 1, #battlefield_bitmask_map do
        if (zone == bcnmid_param_map[zoneindex]) then -- matched zone
            for bcnmindex = 1, #bcnmid_param_map[zoneindex + 1], 2 do -- loop bcnms in this zone
                if (id == bcnmid_param_map[zoneindex+1][bcnmindex]) then -- found bcnmid
                    if (mode == 1) then
                        ret = mask + (2^bcnmid_param_map[zoneindex+1][bcnmindex+1]); -- for trigger (mode 1): 1, 2, 4, 8, 16, 32, ...
                    else
                        ret = mask + bcnmid_param_map[zoneindex+1][bcnmindex+1]; -- for update (mode 2): 0, 1, 2, 3, 4, 5, 6, ...
                    end
                end
            end
        end
    end
    ]]--
    return ret;
end;

function ItemToBCNMID(player, zone, trade)
    for zoneindex = 1, table.getn(itemid_bcnmid_map), 2 do
        if (zone==itemid_bcnmid_map[zoneindex]) then -- matched zone
            for bcnmindex = 1, table.getn(itemid_bcnmid_map[zoneindex + 1]), 2 do -- loop bcnms in this zone
                if (trade:getItem() == itemid_bcnmid_map[zoneindex+1][bcnmindex]) then
                    local item = trade:getItem();
                    local questTimelineOK = 0;

                    -- Job/lvl condition for smn battle lvl20
                    if (item >= 1544 and item <= 1549 and player:getMainJob() == 15 and player:getMainLvl() >= 20) then
                        questTimelineOK = 1;
                    elseif (item == 1166 and player:getVar("aThiefinNorgCS") == 6) then -- AF3 SAM condition
                        questTimelineOK = 1;
                    elseif (item == 1551) then -- BCNM20
                        questTimelineOK = 1;
                    elseif (item == 1552) then -- BCNM30
                        questTimelineOK = 1;
                    elseif (item == 1131) then -- BCNM40
                        questTimelineOK = 1;
                    elseif (item == 1177) then -- BCNM50
                        questTimelineOK = 1;
                    elseif (item == 1130) then -- BCNM60
                        questTimelineOK = 1;
                    elseif (item == 1175) then -- KSNM30
                        questTimelineOK = 1;
                    elseif (item == 1178) then -- KSNM30
                        questTimelineOK = 1;
                    elseif (item == 1180) then -- KSNM30
                        questTimelineOK = 1;
                    elseif (item == 1553) then -- KSNM99
                        questTimelineOK = 1;
                    elseif (item == 1550 and (player:getQuestStatus(OUTLANDS, DIVINE_MIGHT) == QUEST_ACCEPTED or player:getQuestStatus(OUTLANDS, DIVINE_MIGHT_REPEAT) == QUEST_ACCEPTED)) then -- Divine Might
                        questTimelineOK = 1;
                    elseif (item == 1169 and player:getVar("ThePuppetMasterProgress") == 2) then -- The Puppet Master
                        questTimelineOK = 1;
                    elseif (item == 1171 and player:getVar("ClassReunionProgress") == 5) then -- Class Reunion
                        questTimelineOK = 1;
                    elseif (item == 1172 and player:getVar("CarbuncleDebacleProgress") == 3) then -- Carbuncle Debacle (Gremlims)
                        questTimelineOK = 1;
                    elseif (item == 1174 and player:getVar("CarbuncleDebacleProgress") == 6) then -- Carbuncle Debacle (Ogmios)
                        questTimelineOK = 1;
                    end

                    if (questTimelineOK == 1) then
                        player:setVar("trade_bcnmid", itemid_bcnmid_map[zoneindex+1][bcnmindex+1]);
                        player:setVar("trade_itemid", itemid_bcnmid_map[zoneindex+1][bcnmindex]);
                        return itemid_bcnmid_map[zoneindex+1][bcnmindex+1];
                    end

                end
            end
        end
    end
    return -1;
end;


-- E.g. mission checks go here, you must know the right bcnmid for the mission you want to code.
--      You also need to know the bitmask (event param) which should be put in bcnmid_param_map

function checkNonTradeBCNM(player, npc, mode)
    mode = mode or 2;
    local mask = 0;
    local Zone = player:getZoneID();

    local tabre = {
        [6] = { -- Bearclaw_Pinnacle
            [640] = function() return player:getCurrentMission(COP) == THREE_PATHS and  player:getVar("COP_Ulmia_s_Path") == 6 end,
        },
        [8] = { -- Boneyard_Gully
            [672] = function() return player:getCurrentMission(COP) == THREE_PATHS and  player:getVar("COP_Ulmia_s_Path") == 5 end,
            [673] = function() return player:hasKeyItem(MIASMA_FILTER) == true end,
        },
        [10] = { -- The_Shrouded_Maw
            [704] = function() return player:getCurrentMission(COP) == DARKNESS_NAMED and  player:getVar("PromathiaStatus") == 2 end,
            [706] = function() return player:hasKeyItem(VIAL_OF_DREAM_INCENSE) == true end,
        },
        [13] = { -- Mine_Shaft_2716
            [736] = function() return player:getCurrentMission(COP) == THREE_PATHS and  player:getVar("COP_Louverance_s_Path") == 5 end,
        },
        [17] = { -- Spire of Holla
            [768] = function() return player:getCurrentMission(COP) == BELOW_THE_ARKS and player:getVar("PromathiaStatus") == 1  end,
            [768] = function() return player:getCurrentMission(COP) == THE_MOTHERCRYSTALS and player:hasKeyItem(LIGHT_OF_HOLLA) == false end,
        },
        [19] = { -- Spire of Dem
            [800] = function() return player:getCurrentMission(COP) == BELOW_THE_ARKS and player:getVar("PromathiaStatus") == 1  end,
            [800] = function() return player:getCurrentMission(COP) == THE_MOTHERCRYSTALS and player:hasKeyItem(LIGHT_OF_DEM) == false end,
        },
        [21] = { -- Spire of Mea
            [832] = function() return player:getCurrentMission(COP) == BELOW_THE_ARKS and player:getVar("PromathiaStatus") == 1  end,
            [832] = function() return player:getCurrentMission(COP) == THE_MOTHERCRYSTALS and player:hasKeyItem(LIGHT_OF_MEA) == false end,
        },
        [23] = { -- Spire of vahzl
            [864] = function() return player:getCurrentMission(COP) == DESIRES_OF_EMPTINESS and player:getVar("PromathiaStatus") == 8 end,
        },
        [29] = { -- Riverne Site #B01
            [896] = function() return player:getQuestStatus(JEUNO,STORMS_OF_FATE) == QUEST_ACCEPTED and player:getVar('StormsOfFate') == 2 end,
        },
        [31] = { -- Monarch Linn
            [960] = function() return player:getCurrentMission(COP) == ANCIENT_VOWS and player:getVar("PromathiaStatus") == 2 end,
            [961] = function() return player:getCurrentMission(COP) == THE_SAVAGE and player:getVar("PromathiaStatus") == 1 end,
        },
        [32] = { -- Sealion's Den
            [992] = function() return player:getCurrentMission(COP) == ONE_TO_BE_FEARED and player:getVar("PromathiaStatus") == 2 end,
            [993] = function() return player:getCurrentMission(COP) == THE_WARRIOR_S_PATH end,
        },
        [35] = { -- The Garden of RuHmet
            [1024] = function() return player:getCurrentMission(COP) == WHEN_ANGELS_FALL and player:getVar("PromathiaStatus") == 4 end,
        },
        [36] = { -- Empyreal Paradox
            [1056] = function() return player:getCurrentMission(COP) ==  DAWN and player:getVar("PromathiaStatus") == 2 end,
        },
        [139] = { -- Horlais Peak
            [0] = function() return (player:getCurrentMission(BASTOK) == THE_EMISSARY_SANDORIA2 or player:getCurrentMission(WINDURST) == THE_THREE_KINGDOMS_SANDORIA2) and player:getVar("MissionStatus") == 9 end,
            [3] = function() return player:getCurrentMission(SANDORIA) == THE_SECRET_WEAPON and player:getVar("SecretWeaponStatus") == 2 end,
        },
        [140] = { -- Ghelsba Outpost
            [32] = function() local MissionStatus = player:getVar("MissionStatus"); local sTcCompleted = player:hasCompletedMission(SANDORIA, SAVE_THE_CHILDREN); return player:getCurrentMission(SANDORIA) == SAVE_THE_CHILDREN and (sTcCompleted and MissionStatus <= 2 or sTcCompleted == false and MissionStatus == 2) end,
            [33] = function() return player:hasKeyItem(DRAGON_CURSE_REMEDY) end,
        },
        [144] = { -- Waughroon Shrine
            [64] = function() return (player:getCurrentMission(SANDORIA) == JOURNEY_TO_BASTOK2 or player:getCurrentMission(WINDURST) == THE_THREE_KINGDOMS_BASTOK2) and player:getVar("MissionStatus") == 10 end,
            [67] = function() return (player:getCurrentMission(BASTOK) == ON_MY_WAY) and (player:getVar("MissionStatus") == 2) end,
        },
        [146] = { -- Balga's Dais
            [96] = function() return player:hasKeyItem(DARK_KEY) end,
            [99] = function() return (player:getCurrentMission(WINDURST) == SAINTLY_INVITATION) and (player:getVar("MissionStatus") == 1) end,
        },
        [163] = { -- Sacrificial Chamber
            [128] = function() return player:getCurrentMission(ZILART) == THE_TEMPLE_OF_UGGALEPIH end,
        },
        [165] = { -- Throne Room
            [160] = function() return player:getCurrentMission(player:getNation()) == 15 and player:getVar("MissionStatus") == 3 end,
            [161] = function() return player:getCurrentMission(BASTOK) == WHERE_TWO_PATHS_CONVERGE and player:getVar("BASTOK92") == 1 end,
        },
        [168] = { -- Chamber of Oracles
            [192] = function() return player:getCurrentMission(ZILART) == THROUGH_THE_QUICKSAND_CAVES or player:getCurrentMission(ZILART) == THE_CHAMBER_OF_ORACLES end,
        },
        [170] = { -- Full Moon Fountain
            [224] = function() return player:hasKeyItem(MOON_BAUBLE) end,
            [225] = function() return (player:getCurrentMission(WINDURST) == MOON_READING) and player:getVar("WINDURST92") == 2 end,
        },
        [179] = { -- Stellar Fulcrum
            [256] = function() return player:getCurrentMission(ZILART) == RETURN_TO_DELKFUTTS_TOWER and player:getVar("ZilartStatus") == 3 end,
        },
        [180] = { -- La'Loff Amphitheater
            [288] = function() return player:getCurrentMission(ZILART) == ARK_ANGELS and player:getVar("ZilartStatus") == 1 and npc:getID() == 17514791 and player:hasKeyItem(SHARD_OF_APATHY) == false end,
            [289] = function() return player:getCurrentMission(ZILART) == ARK_ANGELS and player:getVar("ZilartStatus") == 1 and npc:getID() == 17514792 and player:hasKeyItem(SHARD_OF_COWARDICE) == false end,
            [290] = function() return player:getCurrentMission(ZILART) == ARK_ANGELS and player:getVar("ZilartStatus") == 1 and npc:getID() == 17514793 and player:hasKeyItem(SHARD_OF_ENVY) == false end,
            [291] = function() return player:getCurrentMission(ZILART) == ARK_ANGELS and player:getVar("ZilartStatus") == 1 and npc:getID() == 17514794 and player:hasKeyItem(SHARD_OF_ARROGANCE) == false end,
            [292] = function() return player:getCurrentMission(ZILART) == ARK_ANGELS and player:getVar("ZilartStatus") == 1 and npc:getID() == 17514795 and player:hasKeyItem(SHARD_OF_RAGE) == false end,
        },
        [181] = { -- The Celestial Nexus
            [320] = function() return player:getCurrentMission(ZILART) == THE_CELESTIAL_NEXUS end,
        },
        [201] = { -- Cloister of Gales
            [416] = function() return player:hasKeyItem(TUNING_FORK_OF_WIND) end,
            [420] = function() return player:getCurrentMission(ASA) == SUGAR_COATED_DIRECTIVE and player:hasKeyItem(DOMINAS_EMERALD_SEAL) end,
        },
        [202] = { -- Cloister of Storms
            [448] = function() return player:hasKeyItem(TUNING_FORK_OF_LIGHTNING) end,
            [452] = function() return player:getCurrentMission(ASA) == SUGAR_COATED_DIRECTIVE and player:hasKeyItem(DOMINAS_VIOLET_SEAL) end,
        },
        [203] = { -- Cloister of Frost
            [480] = function() return player:hasKeyItem(TUNING_FORK_OF_ICE) end,
            [484] = function() return player:getCurrentMission(ASA) == SUGAR_COATED_DIRECTIVE and player:hasKeyItem(DOMINAS_AZURE_SEAL) end,
        },
        [206] = { -- Qu'Bia Arena
            [512] = function() return player:getCurrentMission(player:getNation()) == 14 and player:getVar("MissionStatus") == 11 end,
            [516] = function() return player:getCurrentMission(SANDORIA) == THE_HEIR_TO_THE_LIGHT and player:getVar("MissionStatus") == 3 end,
        },
        [207] = { -- Cloister of Flames
            [544] = function() return player:hasKeyItem(TUNING_FORK_OF_FIRE) end,
            [547] = function() return player:getCurrentMission(ASA) == SUGAR_COATED_DIRECTIVE and player:hasKeyItem(DOMINAS_SCARLET_SEAL) end,
        },
        [209] = { -- Cloister of Tremors
            [576] = function() return player:hasKeyItem(TUNING_FORK_OF_EARTH) end,
            [580] = function() return player:getCurrentMission(ASA) == SUGAR_COATED_DIRECTIVE and player:hasKeyItem(DOMINAS_AMBER_SEAL) end,
        },
        [211] = { -- Cloister of Tides
            [608] = function() return player:hasKeyItem(TUNING_FORK_OF_WATER) end,
            [611] = function() return player:getCurrentMission(ASA) == SUGAR_COATED_DIRECTIVE and player:hasKeyItem(DOMINAS_CERULEAN_SEAL) end,
        },
    }
    local mask = nil;
    for keyid, condition in pairs(tabre[Zone]) do
        if condition() and GetBattleBitmask(keyid, Zone, mode) ~= -1 then 
                mask = mask + GetBattleBitmask(keyid, Zone, mode);
        end;
    end;
    if not mask then
        mask = 0x18;
        --player:addStatusEffect(EFFECT_BATTLEFIELD, mask, 0, 0);
        --player:startEvent(0x7d00, 0, 17, 0x0b94, 0x0c, 0x0c, 0x00, 0x00);
    end;
    if mode == 2 then
        player:startEvent(0x7d00, 0, 0, 0, mask, 0, 0, 0, 0);
    end
    return mask;
end;

function CutsceneSkip(player, npc)

    local skip = 0;
    local Zone = player:getZoneID();

    if (Zone == 6) then -- Bearclaw Pinnacle
           if ((player:hasCompletedMission(COP, THREE_PATHS)) or (player:getCurrentMission(COP) == THREE_PATHS and player:getVar("COP_Ulmia_s_Path") > 6)) then -- flames_for_the_dead
            skip = 1;
        end
    elseif (Zone == 8) then -- Boneyard Gully
           if ((player:hasCompletedMission(COP, THREE_PATHS)) or (player:getCurrentMission(COP) == THREE_PATHS and player:getVar("COP_Ulmia_s_Path") > 5)) then -- head_wind
            skip = 1;
        end
    elseif (Zone == 10) then -- The_Shrouded_Maw
        if ((player:hasCompletedMission(COP, DARKNESS_NAMED)) or (player:getCurrentMission(COP) == DARKNESS_NAMED and player:getVar("PromathiaStatus") > 2)) then -- DARKNESS_NAMED
            skip = 1;
        elseif ((player:hasCompleteQuest(WINDURST, WAKING_DREAMS)) or (player:hasKeyItem(WHISPER_OF_DREAMS))) then -- waking_dreams (diabolos avatar quest)
            skip = 1;
        end
    elseif (Zone == 13) then -- Mine Shaft 2716
        if ((player:hasCompletedMission(COP, THREE_PATHS)) or (player:getCurrentMission(COP) == THREE_PATHS and player:getVar("COP_Louverance_s_Path") > 5)) then -- century_of_hardship
            skip = 1;
        end
    elseif (Zone == 17) then -- Spire of Holla
        if ((player:hasCompletedMission(COP, THE_MOTHERCRYSTALS)) or (player:hasKeyItem(LIGHT_OF_HOLLA))) then -- light of holla
            skip = 1;
        end
    elseif (Zone == 19) then -- Spire of Dem
        if ((player:hasCompletedMission(COP, THE_MOTHERCRYSTALS)) or (player:hasKeyItem(LIGHT_OF_DEM))) then -- light of dem
            skip = 1;
        end
    elseif (Zone == 21) then -- Spire of Mea
        if ((player:hasCompletedMission(COP, THE_MOTHERCRYSTALS)) or (player:hasKeyItem(LIGHT_OF_MEA))) then -- light of mea
            skip = 1;
        end
    elseif (Zone == 23) then -- Spire of Vahzl
        if ((player:hasCompletedMission(COP, DESIRES_OF_EMPTINESS)) or (player:getCurrentMission(COP) == DESIRES_OF_EMPTINESS and player:getVar("PromathiaStatus") > 8)) then -- desires of emptiness
            skip = 1;
        end
    elseif (Zone == 29) then -- Riverne Site #B01
        if ((player:getQuestStatus(JEUNO,STORMS_OF_FATE) == QUEST_COMPLETED) or (player:getQuestStatus(JEUNO,STORMS_OF_FATE) == QUEST_ACCEPTED and player:getVar("StormsOfFate") > 2)) then -- Storms of Fate
            skip = 1;
        end
    elseif (Zone == 31) then -- Monarch Linn
        if (player:hasCompletedMission(COP, ANCIENT_VOWS)) then -- Ancient Vows
            skip = 1;
        elseif ((player:hasCompletedMission(COP, THE_SAVAGE)) or (player:getCurrentMission(COP) == THE_SAVAGE and player:getVar("PromathiaStatus") > 1)) then
            skip = 1;
        end
    elseif (Zone == 32) then -- Sealion's Den
        if (player:hasCompletedMission(COP, ONE_TO_BE_FEARED)) then -- one_to_be_feared
            skip = 1;
        elseif (player:hasCompletedMission(COP, THE_WARRIOR_S_PATH)) then -- warriors_path
            skip = 1;
        end
    elseif (Zone == 35) then -- The Garden of RuHmet
        if ((player:hasCompletedMission(COP, WHEN_ANGELS_FALL)) or (player:getCurrentMission(COP) == WHEN_ANGELS_FALL and player:getVar("PromathiaStatus") > 4)) then -- when_angels_fall
            skip = 1;
        end
    elseif (Zone == 36) then -- Empyreal Paradox
        if ((player:hasCompletedMission(COP, DAWN)) or (player:getCurrentMission(COP) == DAWN and player:getVar("PromathiaStatus") > 2)) then -- dawn
            skip = 1;
        end
    elseif (Zone == 139) then -- Horlais Peak
        if ((player:hasCompletedMission(BASTOK, THE_EMISSARY_SANDORIA2) or player:hasCompletedMission(WINDURST, THE_THREE_KINGDOMS_SANDORIA2)) or
        ((player:getCurrentMission(BASTOK) == THE_EMISSARY_SANDORIA2 or player:getCurrentMission(WINDURST) == THE_THREE_KINGDOMS_SANDORIA2) and player:getVar("MissionStatus") > 9)) then -- Mission 2-3
            skip = 1;
        elseif ((player:hasCompletedMission(SANDORIA, THE_SECRET_WEAPON)) or (player:getCurrentMission(SANDORIA) == THE_SECRET_WEAPON and player:getVar("SecretWeaponStatus") > 2)) then
            skip = 1;
        end
    elseif (Zone == 140) then -- Ghelsba Outpost
        if ((player:hasCompletedMission(SANDORIA, SAVE_THE_CHILDREN)) or (player:getCurrentMission(SANDORIA) == SAVE_THE_CHILDREN and player:getVar("MissionStatus") > 2)) then -- Sandy Mission 1-3
            skip = 1;
        elseif (player:hasCompleteQuest(SANDORIA, THE_HOLY_CREST)) then -- DRG Flag Quest
            skip = 1;
        end
    elseif (Zone == 144) then -- Waughroon Shrine
        if ((player:hasCompletedMission(SANDORIA, JOURNEY_TO_BASTOK2) or player:hasCompletedMission(WINDURST, THE_THREE_KINGDOMS_BASTOK2)) or
        ((player:getCurrentMission(SANDORIA) == JOURNEY_TO_BASTOK2 or player:getCurrentMission(WINDURST) == THE_THREE_KINGDOMS_BASTOK2) and player:getVar("MissionStatus") > 10)) then -- Mission 2-3
            skip = 1;
        elseif ((player:hasCompletedMission(BASTOK, ON_MY_WAY)) or (player:getCurrentMission(BASTOK) == ON_MY_WAY and player:getVar("MissionStatus") > 2)) then
            skip = 1;
        end
    elseif (Zone == 146) then -- Balga's Dais
        if ((player:hasCompletedMission(SANDORIA, JOURNEY_TO_WINDURST2) or player:hasCompletedMission(BASTOK, THE_EMISSARY_WINDURST2)) or
        ((player:getCurrentMission(SANDORIA) == JOURNEY_TO_WINDURST2 or player:getCurrentMission(BASTOK) == THE_EMISSARY_WINDURST2) and player:getVar("MissionStatus") > 8)) then -- Mission 2-3
            skip = 1;
        elseif ((player:hasCompletedMission(WINDURST, SAINTLY_INVITATION)) or (player:getCurrentMission(WINDURST) == SAINTLY_INVITATION and player:getVar("MissionStatus") > 1)) then -- Mission 6-2
            skip = 1;
        end
    elseif (Zone == 165) then -- Throne Room
        if ((player:hasCompletedMission(player:getNation(), 15)) or (player:getCurrentMission(player:getNation()) == 15 and player:getVar("MissionStatus") > 3)) then -- Mission 5-2
            skip = 1;
        end
    elseif (Zone == 168) then -- Chamber of Oracles
        if (player:hasCompletedMission(ZILART, THROUGH_THE_QUICKSAND_CAVES)) then -- Zilart Mission 6
            skip = 1;
        end
    elseif (Zone == 170) then -- Full Moon Fountain
        if ((player:hasCompleteQuest(WINDURST, THE_MOONLIT_PATH)) or (player:hasKeyItem(WHISPER_OF_THE_MOON))) then -- The Moonlit Path
            skip = 1;
        end
    elseif (Zone == 179) then -- Stellar Fulcrum
        if (player:hasCompletedMission(ZILART, RETURN_TO_DELKFUTTS_TOWER)) then -- Zilart Mission 8
            skip = 1;
        end
    elseif (Zone == 180) then -- La'Loff Amphitheater
        if (player:hasCompletedMission(ZILART, ARK_ANGELS)) then
            skip = 1;
        end
    elseif (Zone == 181) then -- The Celestial Nexus
        if (player:hasCompletedMission(ZILART, THE_CELESTIAL_NEXUS)) then -- Zilart Mission 16
            skip = 1;
        end
    elseif (Zone == 201) then -- Cloister of Gales
        if ((player:hasCompleteQuest(OUTLANDS, TRIAL_BY_WIND)) or (player:hasKeyItem(WHISPER_OF_GALES))) then -- Trial by Wind
            skip = 1;
        end
    elseif (Zone == 202) then -- Cloister of Storms
        if ((player:hasCompleteQuest(OTHER_AREAS, TRIAL_BY_LIGHTNING)) or (player:hasKeyItem(WHISPER_OF_STORMS))) then -- Trial by Lightning
            skip = 1;
        end
    elseif (Zone == 203) then -- Cloister of Frost
        if ((player:hasCompleteQuest(SANDORIA, TRIAL_BY_ICE)) or (player:hasKeyItem(WHISPER_OF_FROST))) then -- Trial by Ice
            skip = 1;
        end
    elseif (Zone == 206) then -- Qu'Bia Arena
        if ((player:hasCompletedMission(player:getNation(), 14)) or (player:getCurrentMission(player:getNation()) == 14 and player:getVar("MissionStatus") > 11)) then -- Mission 5-1
            skip = 1;
        elseif ((player:hasCompletedMission(player:getNation(), 23)) or (player:getCurrentMission(player:getNation()) == 23 and player:getVar("MissionStatus") > 4)) then -- Mission 9-2
            skip = 1;
        end
    elseif (Zone == 207) then -- Cloister of Flames
        if ((player:hasCompleteQuest(OUTLANDS, TRIAL_BY_FIRE)) or (player:hasKeyItem(WHISPER_OF_FLAMES))) then -- Trial by Fire
            skip = 1;
        end
    elseif (Zone == 209) then -- Cloister of Tremors
        if ((player:hasCompleteQuest(BASTOK, TRIAL_BY_EARTH)) or (player:hasKeyItem(WHISPER_OF_TREMORS))) then -- Trial by Earth
            skip = 1;
        end
    elseif (Zone == 211) then -- Cloister of Tides
        if ((player:hasCompleteQuest(OUTLANDS, TRIAL_BY_WATER)) or (player:hasKeyItem(WHISPER_OF_TIDES))) then -- Trial by Water
            skip = 1;
        end
    end
    return skip;
end;