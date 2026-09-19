function ContentMenuTests() {
    if (!variable_global_exists("NovaOption")) { Record("variable challenges are available", false); return; }
    global.NovaResetChallenges();
    with (oMenu) {
        Win_Options_Activate(3);
        MenuWin_Main_Shift = false;
        Menu_Active = true;
        Selector_Index_Options = 3;
    }
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("opening challenges resizes the actual window", oMenu.Menu_ActiveIndex == 11 && inst_100005.W == 224 && inst_100005.x + inst_100005.W <= 400);
    var previous_font = draw_get_font();
    draw_set_font(global.MenuFont);
    var columns_fit = true;
    for (var row = 0; row < 12; row++) {
        var values = oMenu.NovaChallengeValues[row];
        for (var value = 0; value < array_length(values); value++)
            columns_fit = columns_fit && string_width(oMenu.NovaChallengeLabels[row]) + string_width(values[value]) + 52 <= inst_100005.W;
    }
    draw_set_font(previous_font);
    Record("challenge labels and every value have separate columns", columns_fit);
    with (oMenu) {
        Menu_Active = true;
        Menu_ActiveIndex = 11;
        MenuWin_Options_MenuIndex = 11;
        MenuWin_Main_Active = false;
        MenuWin_Options_Active = true;
        MenuWin_Main_Shift = false;
        NovaChallengePage = 0;
        NovaChallengeMenu();
        Selector_Index_Options = 1;
    }
    PressEvent(oMenu, "left", oMenu, ev_step, ev_step_normal);
    Record("challenge values wrap backwards", global.NovaOption(0) == 3);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("confirm cycles a challenge value", global.NovaOption(0) == 0);
    oMenu.Selector_Index_Options = 6;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("challenge pages fit the existing menu height", oMenu.NovaChallengePage == 1 && oMenu.Menu_Count[11] == 7);
    oMenu.Selector_Index_Options = 5;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    oMenu.Selector_Index_Options = 1;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("no-map toggle updates the existing map guard", global.NovaOption(9) == 1 && global.Challenges[3]);
    oMenu.Selector_Index_Options = 5;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("reset clears every challenge", !global.NovaChallengeActive());
    MenuCase(11, 3);
    Record("cancel restores the start-menu window width", inst_100005.W == 144);
}
function ContentTests() {
    if (!variable_global_exists("NovaOption")) { Record("1.2.1 content is available", false); return; }
    global.NovaResetChallenges();
    var inventory_before = StructCopy(global.Inventory);
    var items_before = StructCopy(global.Inventory_ItemData);
    var gear_before = global.StartingGear;
    var data_before = StructCopy(global.ItemData);
    Inventory_InitData();
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
    Record("all 100 ordered gem pairs consume exactly two gems", pairs_valid);
    Record("all 55 gem recipes have valid rewards", recipes_valid);
    var incomplete = {GemCount: array_create(10)};
    incomplete.GemCount[9] = 1;
    Record("an incomplete Topaz pair is retained", GetGemCombo(incomplete) == -1 && GemsInPond(incomplete) == 1);
    var examples = [[9, 0, 13, 2, 2], [9, 9, 27, 0, 1], [9, 5, 2, 0, 1], [6, 6, 6, 0, 1], [7, 7, 19, 0, 1], [5, 1, 49, 0, 1], [5, 4, 50, 0, 1], [8, 8, 44, 0, 1]];
    for (var i = 0; i < array_length(examples); i++) {
        var example = examples[i];
        var prize = global.GemPrize[max(example[0], example[1])][min(example[0], example[1])];
        Record("poster recipe " + string(i), prize.Class == example[2] && prize.Index == example[3] && prize.Amount == example[4]);
    }
    var caps = [20, 16, 16, 16, 12, 12];
    for (var i = 0; i < 6; i++) Record("upstream rod capacity " + string(i), Inventory_MaxAmount(39, i) == caps[i]);
    var old_gems = StructCopy(global.Inventory_ItemData[14]);
    old_gems.Amount = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    global.Inventory_ItemData[14] = old_gems;
    global.NovaGemSaveInit();
    Record("legacy gem counters retain their identities", global.Inventory_ItemData[14].Amount[8] == 9 && global.Inventory_ItemData[14].Amount[9] == 0 && global.GemNames[1] == "Amethyst" && global.GemNames[9] == "Topaz");
    global.Inventory_ItemData[14].Amount[9] = 3;
    global.NovaGemSaveInit();
    Record("repeated gem migration preserves Topaz", global.Inventory_ItemData[14].Amount[9] == 3);
    Inventory_InitData();
    Inventory_Add(14, 9, 3);
    var topaz_slot = Inventory_ItemIndexExists(14, 9);
    User_SaveGame();
    Inventory_InitData();
    User_LoadGame();
    Record("Topaz survives a real save and load", topaz_slot >= 0 && global.Inventory[topaz_slot].ItemIndex == 9 && global.Inventory[topaz_slot].Amount == 3);
    var health_caps = [16, 8, 6, 5];
    var defense_caps = [8, 4, 3, 2];
    var rupee_caps = [1234, 400, 300, 200];
    var shop_prices = [50, 75, 100, 125];
    for (var option = 0; option < 4; option++) {
        global.NovaChallengeOptions = [option, option, option, 0, option, option, option, 0, 0, 0, 0, 0];
        Inventory_InitData();
        global.StartingGear = 0;
        Link_SetStartingItems();
        Record("starting hearts choice " + string(option), global.Inventory_ItemData[18].Amount == 4 - option);
        Record("starting capacity choice " + string(option), Inventory_MaxSlots_Useable() == 5 - option && global.Inventory_ItemData[2].Index_Max == 5 + option);
        global.Inventory_ItemData[2].Index = global.Inventory_ItemData[2].Index_Max;
        Record("reduced starting inventory can reach ten slots " + string(option), Inventory_MaxSlots_Useable() == 10);
        global.Inventory_ItemData[18].Amount = health_caps[option];
        Record("heart cap blocks further containers " + string(option), global.NovaMaxHearts() == health_caps[option] && !Item_Allowed(18));
        global.Inventory_ItemData[46].Index = 5;
        global.Inventory_ItemData[41].Index = 1;
        global.Inventory_ItemData[16].Index = 1;
        Record("defense cap choice " + string(option), DEFENSE() == defense_caps[option]);
        Record("shop multiplier choice " + string(option), Item_Price(18, 0, 1) == shop_prices[option]);
        Record("rupee cap choice " + string(option), global.NovaRupeeLimit(1234) == rupee_caps[option] && global.NovaRupeeLimit(-5) == 0);
    }
    var rupees_before = global.Inventory_ItemData[40].Amount;
    var pending_rupees = oHUD.AddRupees;
    global.Inventory_ItemData[40].Amount = 198;
    oHUD.AddRupees = 500;
    with (oHUD) event_perform_object(oHUD, ev_step, ev_step_end);
    Record("rupee pickup stops at the challenge cap", global.Inventory_ItemData[40].Amount == 200 && oHUD.AddRupees == 0);
    oHUD.AddRupees = -5;
    with (oHUD) event_perform_object(oHUD, ev_step, ev_step_end);
    Record("spending rupees still works at the cap", global.Inventory_ItemData[40].Amount == 199 && oHUD.AddRupees == -4);
    global.Inventory_ItemData[40].Amount = rupees_before;
    oHUD.AddRupees = pending_rupees;
    global.NovaResetChallenges();
    Inventory_InitData();
    global.NovaChallengeOptions[10] = 1;
    Record("no-food challenge blocks food and food bags", !Item_Allowed(13, 0) && !Item_Allowed(49, 0));
    var food_shop = instance_create_layer(oLink.x, oLink.y, "Objs_Lower", oShop, {ShopType: 2, ShopW: 48, ShopH: 32, RoomIndex: oLink.RoomIndex});
    Record("no-food challenge closes food stalls", food_shop.Slots == 0 && array_length(food_shop.Inventory) == 0);
    with (food_shop) instance_destroy();
    global.NovaChallengeOptions = [3, 2, 1, 2, 3, 2, 1, 3, 2, 0, 1, 1];
    var options_saved = json_stringify(global.NovaChallengeOptions);
    User_SaveGame();
    global.NovaResetChallenges();
    User_LoadGame();
    Record("all challenge settings survive save and load", json_stringify(global.NovaChallengeOptions) == options_saved);
    global.Challenges = [true, true, true, true, true, true, true];
    global.NovaLoadChallenges({});
    Record("older saves keep legacy challenge restrictions", global.NovaMaxHearts() == 5 && global.Challenges[1] && global.Challenges[2] && global.Challenges[3] && global.Challenges[4] && global.Challenges[5] && global.Challenges[6]);
    global.NovaResetChallenges();
    global.Inventory = inventory_before;
    global.Inventory_ItemData = items_before;
    global.ItemData = data_before;
    global.StartingGear = gear_before;
    with (oLink) UpdateState(1);
    global.Paused = false;
    WallmasterTests();
}
function WallmasterTests() {
    var level = global.Level.Index;
    var door = oLink.InDoor_Full;
    var invincible = oLink.Invincible;
    var saved_health = global.Inventory_ItemData[17].Amount;
    var transition = global.TransitionRoomIndex;
    var facing = oLink.Facing;
    var cape = oLink.Cape;
    global.Level.Index = 1;
    global.TransitionRoomIndex = -1;
    global.NovaChallengeOptions[11] = 1;
    oLink.InDoor_Full = false;
    oLink.Invincible = false;
    oLink.Cape = false;
    var hand = instance_create_layer(oLink.x + 60, oLink.y, "ObjsHighest", oNovaWallmaster);
    var offsets = [[0, 80], [0, -80], [80, 0], [-80, 0]];
    for (var i = 0; i < 4; i++) {
        oLink.Facing = i + 1;
        hand.RoomIndex = -1;
        with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
        Record("Wallmaster enters behind Link facing " + string(i + 1), abs(hand.x - oLink.x - offsets[i][0]) < 0.01 && abs(hand.y - oLink.y - offsets[i][1]) < 0.01 && hand.SpawnWait == 59 && !hand.visible);
    }
    hand.x = oLink.x + 60;
    hand.y = oLink.y;
    hand.SpawnWait = 0;
    var before_x = hand.x;
    global.Paused = true;
    with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
    Record("Wallmaster stops while paused", hand.x == before_x && hand.Wait == hand.IdleFrames);
    global.Paused = false;
    with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
    Record("Wallmaster follows Link", hand.x < before_x && hand.visible);
    hand.x = oLink.x + 8;
    hand.y = oLink.y - 6;
    hand.Wait = 0;
    with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
    Record("Wallmaster commits to a bounded attack", hand.AttackTicks == 36);
    hand.Hover = 0;
    with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
    Record("Wallmaster uses normal damage and invulnerability", global.Inventory_ItemData[17].Amount < saved_health && hand.AttackTicks == 0);
    with (oLink) UpdateState(20);
    with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
    Record("Wallmaster suspends attacks while Link falls", !hand.visible && hand.AttackTicks == 0);
    global.Level.Index = 6;
    with (hand) event_perform_object(oNovaWallmaster, ev_step, ev_step_normal);
    Record("Wallmaster leaves safe village levels", !instance_exists(hand));
    global.Level.Index = level;
    global.TransitionRoomIndex = transition;
    global.Inventory_ItemData[17].Amount = saved_health;
    oLink.InDoor_Full = door;
    oLink.Invincible = invincible;
    oLink.Facing = facing;
    oLink.Cape = cape;
    with (oLink) UpdateState(1);
    global.NovaResetChallenges();
}
