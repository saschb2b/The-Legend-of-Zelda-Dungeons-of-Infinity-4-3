function ContentMenuTests() {
    global.NovaResetChallenges();
    with (oMenu) { NovaNewDraft(); NovaFocus = 2; }
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Challenges replace setup in the same frame", oMenu.NovaPage == "challenges");
    PressEvent(oMenu, "left", oMenu, ev_step, ev_step_normal);
    Record("Draft challenge wraps backwards", oMenu.NovaDraft.challenges[0] == 3);
    Record("Draft challenge leaves gameplay settings alone", global.NovaOption(0) == 0);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Confirm cycles the draft challenge", oMenu.NovaDraft.challenges[0] == 0);
    for (var page = 0; page < 3; page++) {
        oMenu.NovaChallengePage = page;
        var indexes = oMenu.NovaChallengePages[page];
        for (var row = 0; row < array_length(indexes); row++) {
            oMenu.NovaFocus = row;
            PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
            Record("Challenge option is reachable " + string(indexes[row]), oMenu.NovaDraft.challenges[indexes[row]] == 1);
        }
    }
    PressEvent(oMenu, "nova_bag_next", oMenu, ev_step, ev_step_normal);
    Record("Shoulder paging wraps to Survival", oMenu.NovaChallengePage == 0 && oMenu.NovaFocus == 0);
    PressEvent(oMenu, "nova_bag_previous", oMenu, ev_step, ev_step_normal);
    Record("Previous shoulder wraps to Restrictions", oMenu.NovaChallengePage == 2);
    var before_defaults = json_stringify(oMenu.NovaDraft.challenges);
    PressEvent(oMenu, "item", oMenu, ev_step, ev_step_normal);
    Record("Defaults asks before clearing challenges", oMenu.NovaChallengeDialog && oMenu.NovaChallengeDialogFocus == 0);
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Back from the dialog keeps challenges and the page", !oMenu.NovaChallengeDialog && oMenu.NovaPage == "challenges" && json_stringify(oMenu.NovaDraft.challenges) == before_defaults);
    PressEvent(oMenu, "item", oMenu, ev_step, ev_step_normal);
    PressEvent(oMenu, "down", oMenu, ev_step, ev_step_normal);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Restore defaults clears all draft challenges", !oMenu.NovaChallengeDialog && json_stringify(oMenu.NovaDraft.challenges) == json_stringify(array_create(12, 0)));
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Closing challenges restores its setup row", oMenu.NovaPage == "setup" && oMenu.NovaFocus == 2);
    SetupScreenTests();
}
function SetupScreenTests() {
    var users = global.Users;
    var user_index = global.UserIndex;
    global.Users = [ProfileFixture("LINK", 4, 4, 3.5, 5), new User_Create(), new User_Create(), new User_Create(), new User_Create()];
    global.UserIndex = 0;
    with (oMenu) NovaSetupForget(0);
    with (oMenu) NovaNewDraft();
    Record("without a remembered setup the saved run's character is kept", oMenu.NovaDraft.character == 4 && oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 0);
    oMenu.NovaFocus = 2;
    PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
    Record("right selects Second Quest", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 1 && oMenu.NovaChallengeLevel(oMenu.NovaDraft.challenges) > 0);
    PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
    var master = oMenu.NovaChallengeLevel(oMenu.NovaDraft.challenges);
    Record("Master Quest is harder than Second Quest", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 2 && master > oMenu.NovaChallengeLevel(oMenu.NovaPresets[1].values));
    PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
    Record("presets wrap to Hero's Path", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 0);
    oMenu.NovaDraft.challenges[10] = 1;
    Record("a changed mix reads as Custom", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == -1);
    PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
    PressEvent(oMenu, "left", oMenu, ev_step, ev_step_normal);
    Record("a custom mix stays reachable after browsing presets", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == -1 && oMenu.NovaDraft.challenges[10] == 1);
    oMenu.NovaFocus = 0;
    var before_random = oMenu.NovaDraft.character;
    PressEvent(oMenu, "item", oMenu, ev_step, ev_step_normal);
    Record("Random picks a different character", oMenu.NovaDraft.character != before_random && oMenu.NovaPage == "setup");
    oMenu.NovaDraft.character = 6;
    oMenu.NovaDraft.bonus = 4;
    global.NovaTestStart = false;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("confirm on the character row goes to Begin's replacement check", oMenu.NovaPage == "replace");
    PressEvent(oMenu, "down", oMenu, ev_step, ev_step_normal);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("beginning starts the run", global.NovaTestStart);
    with (oMenu) NovaNewDraft();
    Record("the last setup is remembered for this player", oMenu.NovaDraft.character == 6 && oMenu.NovaDraft.bonus == 4 && oMenu.NovaDraft.challenges[10] == 1);
    global.UserIndex = 1;
    with (oMenu) NovaNewDraft();
    Record("another player keeps its own setup", oMenu.NovaDraft.character == 0 && oMenu.NovaDraft.bonus == 0 && oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 0);
    global.UserIndex = 0;
    with (oMenu) NovaSetupForget(0);
    Record("deleting a player forgets its setup", oMenu.NovaSetupLoad(0).bonus == 0);
    ini_open("nova-menu.ini");
    ini_write_string("Setup", "Player0", "3,x,{");
    ini_close();
    Record("a damaged remembered setup falls back safely", oMenu.NovaSetupLoad(0).bonus == 0 && oMenu.NovaSetupLoad(0).character == 4);
    global.Users[0].SaveData.NovaChallengeOptions = oMenu.NovaPresets[2].values;
    Record("save cards carry the challenge level", oMenu.NovaProfileSummary(0).level == master);
    draw_set_font(global.MenuFont_Innactive);
    var layout = oMenu.NovaSetupLayout();
    var options = global.NovaOptionsLayout();
    var longest = 0;
    for (var i = 0; i < array_length(oMenu.NovaBonusNames); i++) longest = max(longest, string_width(oMenu.NovaBonusNames[i]) * 0.85);
    Record("the longest bonus fits beside its icon", layout.column + 22 + longest < 350);
    Record("the preview and Begin stay above the help line", layout.preview_y + layout.preview_h + 34 < layout.rule_y && layout.begin_y + layout.begin_h < layout.rule_y);
    var help_ok = true;
    var line = string_height("A") + 4;
    for (var i = 0; i < 12; i++) help_ok = help_ok && string_height_ext(oMenu.NovaChallengeHelp[i], line, options.help_width / 0.6) / line <= 2.01;
    for (var i = 0; i < 3; i++) help_ok = help_ok && string_height_ext(oMenu.NovaPresets[i].help, line, options.help_width / 0.6) / line <= 2.01;
    for (var i = 0; i < 8; i++) help_ok = help_ok && string_height_ext(oMenu.NovaBonusHelp[i], line, options.help_width / 0.6) / line <= 2.01;
    Record("setup and challenge help fits in two lines", help_ok);
    var crumbs = global.NovaMenuTitleParts(["New adventure", "Challenges"]);
    draw_set_font(global.MenuFont_Innactive);
    var summary_width = string_width("Custom  Level 30") * 0.7;
    Record("the challenge summary clears the breadcrumb", crumbs[1].x + crumbs[1].width + 8 < 358 - summary_width);
    Record("setup selectors clear the value arrows", layout.selector + 18 < layout.column - 11);
    for (var device = 0; device < 2; device++) {
        input_profile_set(device == 0 ? "gamepad" : "keyboard");
        var menu = global.NovaMenuLayout();
        for (var focus = 0; focus < 4; focus++) {
            oMenu.NovaFocus = focus;
            var hints = oMenu.NovaSetupFooter();
            var last = hints[array_length(hints) - 1];
            Record("setup footer fits row " + string(focus) + " " + string(device), hints[0].x >= menu.footer_left - 0.01 && last.right <= menu.footer_right + 0.01 && last.label == "Close");
        }
    }
    input_profile_set("gamepad");
    with (oMenu) NovaSetupForget(0);
    global.Users = users;
    global.UserIndex = user_index;
    global.LinkCharacterIndex = 0;
    global.StartingGear = 0;
    global.NovaResetChallenges();
    with (oMenu) NovaGo("home", 0);
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
