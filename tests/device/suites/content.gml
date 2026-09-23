// Recovered 1.2.1 content in play: gems, rods, challenge effects and the Wall Master.
// Both content suites change the live inventory; these keep and restore the run's state.
function ContentSave() {
    global.NovaResetChallenges();
    ContentInventory = StructCopy(global.Inventory);
    ContentItems = StructCopy(global.Inventory_ItemData);
    ContentGear = global.StartingGear;
    ContentData = StructCopy(global.ItemData);
}
function ContentRestore() {
    global.NovaResetChallenges();
    global.Inventory = ContentInventory;
    global.Inventory_ItemData = ContentItems;
    global.ItemData = ContentData;
    global.StartingGear = ContentGear;
    with (oLink) UpdateState(1);
    global.Paused = false;
}

Suite("Recovered 1.2.1 items", "gameplay", function() {
    BeforeAll(function() {
        // A build without the recovered content fails the suite's setup instead of every test.
        if (!variable_global_exists("NovaOption")) throw "1.2.1 content is not available";
        ContentSave();
        Inventory_InitData();
    });
    Test("every gem pair has a valid recipe", function() {
        var recipes_valid = true;
        var pairs_valid = true;
        for (var first = 0; first < 10; first++) {
            for (var second = 0; second < 10; second++) {
                var pond = {GemCount: array_create(10)};
                pond.GemCount[first]++;
                pond.GemCount[second]++;
                var combo = GetGemCombo(pond);
                pairs_valid = pairs_valid && GemsInPond(pond) == 0 && combo[0] == max(first, second) && combo[1] == min(first, second);
                var prize = global.GemPrize[combo[0]][combo[1]];
                recipes_valid = recipes_valid && prize.Class >= 0 && prize.Class <= 50 && prize.Amount > 0;
            }
        }
        Check("all 100 ordered gem pairs consume exactly two gems", pairs_valid);
        Check("all 55 gem recipes have valid rewards", recipes_valid);
    });
    Test("an incomplete gem pair stays in the pond", function() {
        var incomplete = {GemCount: array_create(10)};
        incomplete.GemCount[9] = 1;
        Check("an incomplete Topaz pair is retained", GetGemCombo(incomplete) == -1 && GemsInPond(incomplete) == 1);
    });
    Test("the poster recipes match the recipe table", function() {
        var examples = [[9, 0, 13, 2, 2], [9, 9, 27, 0, 1], [9, 5, 2, 0, 1], [6, 6, 6, 0, 1], [7, 7, 19, 0, 1], [5, 1, 49, 0, 1], [5, 4, 50, 0, 1], [8, 8, 44, 0, 1]];
        for (var i = 0; i < array_length(examples); i++) {
            var example = examples[i];
            var prize = global.GemPrize[max(example[0], example[1])][min(example[0], example[1])];
            Check("poster recipe " + string(i), prize.Class == example[2] && prize.Index == example[3] && prize.Amount == example[4]);
        }
    });
    Test("rods keep their upstream capacities", function() {
        var caps = [20, 16, 16, 16, 12, 12];
        for (var i = 0; i < 6; i++) Check("upstream rod capacity " + string(i), Inventory_MaxAmount(39, i) == caps[i]);
    });
    Test("gem migration keeps each gem's identity", function() {
        var old_gems = StructCopy(global.Inventory_ItemData[14]);
        old_gems.Amount = [1, 2, 3, 4, 5, 6, 7, 8, 9];
        global.Inventory_ItemData[14] = old_gems;
        global.NovaGemSaveInit();
        Check("legacy gem counters retain their identities", global.Inventory_ItemData[14].Amount[8] == 9 && global.Inventory_ItemData[14].Amount[9] == 0 && global.GemNames[1] == "Amethyst" && global.GemNames[9] == "Topaz");
        global.Inventory_ItemData[14].Amount[9] = 3;
        global.NovaGemSaveInit();
        Check("repeated gem migration preserves Topaz", global.Inventory_ItemData[14].Amount[9] == 3);
    });
    Test("Topaz survives a real save and load", function() {
        Inventory_InitData();
        Inventory_Add(14, 9, 3);
        var topaz_slot = Inventory_ItemIndexExists(14, 9);
        User_SaveGame();
        Inventory_InitData();
        User_LoadGame();
        Check("the loaded slot holds three Topaz", topaz_slot >= 0 && global.Inventory[topaz_slot].ItemIndex == 9 && global.Inventory[topaz_slot].Amount == 3);
        ContentRestore();
    });
});

Suite("Challenge effects", "gameplay", function() {
    BeforeAll(function() {
        ContentSave();
    });
    Test("each challenge option sets its limit", function() {
        var health_caps = [16, 8, 6, 5];
        var defense_caps = [8, 4, 3, 2];
        var rupee_caps = [1234, 400, 300, 200];
        var shop_prices = [50, 75, 100, 125];
        for (var option = 0; option < 4; option++) {
            global.NovaChallengeOptions = [option, option, option, 0, option, option, option, 0, 0, 0, 0, 0];
            Inventory_InitData();
            global.StartingGear = 0;
            Link_SetStartingItems();
            Check("starting hearts choice " + string(option), global.Inventory_ItemData[18].Amount == 4 - option);
            Check("starting capacity choice " + string(option), Inventory_MaxSlots_Useable() == 5 - option && global.Inventory_ItemData[2].Index_Max == 5 + option);
            global.Inventory_ItemData[2].Index = global.Inventory_ItemData[2].Index_Max;
            Check("reduced starting inventory can reach ten slots " + string(option), Inventory_MaxSlots_Useable() == 10);
            global.Inventory_ItemData[18].Amount = health_caps[option];
            Check("heart cap blocks further containers " + string(option), global.NovaMaxHearts() == health_caps[option] && !Item_Allowed(18));
            global.Inventory_ItemData[46].Index = 5;
            global.Inventory_ItemData[41].Index = 1;
            global.Inventory_ItemData[16].Index = 1;
            Check("defense cap choice " + string(option), DEFENSE() == defense_caps[option]);
            Check("shop multiplier choice " + string(option), Item_Price(18, 0, 1) == shop_prices[option]);
            Check("rupee cap choice " + string(option), global.NovaRupeeLimit(1234) == rupee_caps[option] && global.NovaRupeeLimit(-5) == 0);
        }
    });
    Test("the rupee cap limits pickups but not spending", function() {
        // The last choices of the test above, which cap the wallet at 200 rupees.
        global.NovaChallengeOptions = [3, 3, 3, 0, 3, 3, 3, 0, 0, 0, 0, 0];
        var rupees_before = global.Inventory_ItemData[40].Amount;
        var pending_rupees = oHUD.AddRupees;
        global.Inventory_ItemData[40].Amount = 198;
        oHUD.AddRupees = 500;
        with (oHUD) event_perform_object(oHUD, ev_step, ev_step_end);
        Check("rupee pickup stops at the challenge cap", global.Inventory_ItemData[40].Amount == 200 && oHUD.AddRupees == 0);
        oHUD.AddRupees = -5;
        with (oHUD) event_perform_object(oHUD, ev_step, ev_step_end);
        Check("spending rupees still works at the cap", global.Inventory_ItemData[40].Amount == 199 && oHUD.AddRupees == -4);
        global.Inventory_ItemData[40].Amount = rupees_before;
        oHUD.AddRupees = pending_rupees;
    });
    Test("the no-food challenge removes food", function() {
        global.NovaResetChallenges();
        Inventory_InitData();
        global.NovaChallengeOptions[10] = 1;
        Check("no-food challenge blocks food and food bags", !Item_Allowed(13, 0) && !Item_Allowed(49, 0));
        var food_shop = instance_create_layer(oLink.x, oLink.y, "Objs_Lower", oShop, {ShopType: 2, ShopW: 48, ShopH: 32, RoomIndex: oLink.RoomIndex});
        Check("no-food challenge closes food stalls", food_shop.Slots == 0 && array_length(food_shop.Inventory) == 0);
        with (food_shop) instance_destroy();
    });
    Test("all challenge settings survive save and load", function() {
        global.NovaChallengeOptions = [3, 2, 1, 2, 3, 2, 1, 3, 2, 0, 1, 1];
        var options_saved = json_stringify(global.NovaChallengeOptions);
        User_SaveGame();
        global.NovaResetChallenges();
        User_LoadGame();
        Check("the loaded options match the saved ones", json_stringify(global.NovaChallengeOptions) == options_saved);
    });
    Test("older saves keep legacy challenge restrictions", function() {
        global.Challenges = [true, true, true, true, true, true, true];
        global.NovaLoadChallenges({});
        Check("legacy restrictions stay on and cap hearts at five", global.NovaMaxHearts() == 5 && global.Challenges[1] && global.Challenges[2] && global.Challenges[3] && global.Challenges[4] && global.Challenges[5] && global.Challenges[6]);
        ContentRestore();
    });
});

// The tests run in order against one Wall Master in a dungeon level with the challenge on.
Suite("Wall Master", "gameplay", function() {
    BeforeAll(function() {
        WallmasterLevel = global.Level.Index;
        WallmasterDoor = oLink.InDoor_Full;
        WallmasterInvincible = oLink.Invincible;
        WallmasterHealth = global.Inventory_ItemData[17].Amount;
        WallmasterTransition = global.TransitionRoomIndex;
        WallmasterFacing = oLink.Facing;
        WallmasterCape = oLink.Cape;
        global.Level.Index = 1;
        global.TransitionRoomIndex = -1;
        global.NovaChallengeOptions[11] = 1;
        oLink.InDoor_Full = false;
        oLink.Invincible = false;
        oLink.Cape = false;
        WallmasterHand = instance_create_layer(oLink.x + 60, oLink.y, "ObjsHighest", oNovaWallmaster);
    });
    Test("the Wall Master enters behind Link", function() {
        var hand = WallmasterHand;
        var offsets = [[0, 80], [0, -80], [80, 0], [-80, 0]];
        for (var i = 0; i < 4; i++) {
            oLink.Facing = i + 1;
            hand.RoomIndex = -1;
            with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
            Check("Wall Master enters behind Link facing " + string(i + 1), abs(hand.x - oLink.x - offsets[i][0]) < 0.01 && abs(hand.y - oLink.y - offsets[i][1]) < 0.01 && hand.SpawnWait == 59 && !hand.visible);
        }
    });
    Test("the Wall Master stops while paused and follows Link", function() {
        var hand = WallmasterHand;
        hand.x = oLink.x + 60;
        hand.y = oLink.y;
        hand.SpawnWait = 0;
        var before_x = hand.x;
        global.Paused = true;
        with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
        Check("Wall Master stops while paused", hand.x == before_x && hand.Wait == hand.IdleFrames);
        global.Paused = false;
        with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
        Check("Wall Master follows Link", hand.x < before_x && hand.visible);
    });
    Test("the Wall Master makes one bounded attack with normal damage", function() {
        var hand = WallmasterHand;
        hand.x = oLink.x + 8;
        hand.y = oLink.y - 6;
        hand.Wait = 0;
        with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
        Check("Wall Master commits to a bounded attack", hand.AttackTicks == 36);
        hand.Hover = 0;
        with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
        Check("Wall Master uses normal damage and invulnerability", global.Inventory_ItemData[17].Amount < WallmasterHealth && hand.AttackTicks == 0);
    });
    Test("the Wall Master waits while Link falls", function() {
        var hand = WallmasterHand;
        with (oLink) UpdateState(20);
        with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
        Check("Wall Master suspends attacks while Link falls", !hand.visible && hand.AttackTicks == 0);
    });
    Test("the Wall Master leaves safe village levels", function() {
        var hand = WallmasterHand;
        global.Level.Index = 6;
        with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
        Check("Wall Master is removed in the village", !instance_exists(hand));
        with (hand) instance_destroy();
        global.Level.Index = WallmasterLevel;
        global.TransitionRoomIndex = WallmasterTransition;
        global.Inventory_ItemData[17].Amount = WallmasterHealth;
        oLink.InDoor_Full = WallmasterDoor;
        oLink.Invincible = WallmasterInvincible;
        oLink.Facing = WallmasterFacing;
        oLink.Cape = WallmasterCape;
        with (oLink) UpdateState(1);
        global.NovaResetChallenges();
    });
});
