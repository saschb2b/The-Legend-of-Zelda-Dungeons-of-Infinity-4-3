persistent = true;
Stage = 0;
Ticks = 0;
Results = [];
Complete = false;
Capture = "";
global.NovaTestInput = "";
global.NovaTestHeld = [];
global.NovaTestHUDDraws = 0;
global.NovaTestStatusDraws = 0;
function Flush() {
    var file = file_text_open_write("nova-test-report.json");
    file_text_write_string(file, json_stringify({complete: Complete, results: Results, capture: Capture}));
    file_text_close(file);
}
function Record(name, passed) {
    array_push(Results, {name: name, passed: passed});
    Flush();
}
function PressEvent(target, verb, object, kind, number) {
    input_clear_momentary(false);
    global.NovaTestInput = verb;
    // Each simulated press starts a fresh frame, including after a profile change.
    var verbs = is_array(verb) ? verb : [verb];
    for (var i = 0; i < array_length(verbs); i++) {
        var state = variable_struct_get(__input_global().__players[0].__verb_state_dict, verbs[i]);
        if (is_struct(state)) state.__inactive = false;
    }
    with (target) event_perform_object(object, kind, number);
    global.NovaTestInput = "";
}
function MenuCase(index, expected, verb = "action") {
    with (oMenu) {
        MenuWin_Main_Shift = false;
        Menu_Active = true;
        Menu_ActiveIndex = index;
        MenuWin_Main_MenuIndex = index;
        MenuWin_Options_MenuIndex = index;
        MenuWin_Main_Active = index <= 2 || index == 4 || index == 6 || index == 12;
        MenuWin_Options_Active = !MenuWin_Main_Active;
        Selector_Index_Options = 1;
        Bindings_Remap = false;
        ErrorMsgInst = noone;
    }
    PressEvent(oMenu, verb, oMenu, ev_step, ev_step_normal);
    Record("menu " + string(index) + " back via " + verb, oMenu.Menu_ActiveIndex == expected);
}
function MenuTests() {
    global.UserIndex = 0;
    global.Users[0] = new User_Create();
    global.Users[0].Name = "HARNESS";
    DungeonSeq_Init(0);
    var name = global.Users[0].Name;
    var cases = [[1, 0], [2, 0], [3, 1], [4, 1], [6, 4], [7, 6], [8, 1], [9, 3], [10, 3], [11, 3], [12, 4], [13, 12], [14, 12]];
    for (var i = 0; i < array_length(cases); i++) MenuCase(cases[i][0], cases[i][1]);
    Record("cancel deletion keeps the profile", global.Users[0].Name == name);
    global.StartingGear = 2;
    MenuCase(10, 3);
    Record("cancel bonus selection keeps equipped bonus", global.StartingGear == 2);
    oMenu.NameEntry_Rename = true;
    oMenu.NameEntry_Name = "UNSAVED";
    MenuCase(5, 6, "escape");
    Record("cancel rename keeps the saved name", global.Users[0].Name == name);
    oMenu.NameEntry_Rename = false;
    MenuCase(5, 0, "escape");
    oMenu.NameEntry_Name = "ABC";
    MenuCase(5, 5);
    Record("action still deletes one letter", oMenu.NameEntry_Name == "AB");
    oMenu.MenuWin_Main_Shift = false;
    oMenu.Menu_Active = true;
    oMenu.Menu_ActiveIndex = 13;
    oMenu.Bindings_Remap = true;
    PressEvent(oMenu, "action", oMenu, ev_step, ev_step_normal);
    Record("cancel does not interrupt binding capture", oMenu.Menu_ActiveIndex == 13);
    oMenu.Bindings_Remap = false;
    MenuCase(12, 4, "escape");
    var keyboard_before = input_profile_export("keyboard");
    var remap = instance_create_layer(0, 0, "System", oInputRemap, {InputIndex: 1});
    input_binding_scan_set_Success(input_binding_key(ord("Q")));
    input_binding_scan_set_Failure(-20);
    Record("aborted remapping restores every previous binding", input_profile_export("keyboard") == keyboard_before && !instance_exists(remap));
    remap = instance_create_layer(0, 0, "System", oInputRemap, {InputIndex: 1});
    var keys = [ord("Z"), ord("X"), ord("C"), ord("M"), ord("S"), ord("I"), vk_escape, vk_f1, vk_up, vk_down, vk_left, vk_right, vk_pageup, vk_pagedown];
    for (var k = 0; k < array_length(keys); k++) input_binding_scan_set_Success(input_binding_key(keys[k]));
    Record("completed keyboard remapping saves menu and directions", input_binding_get("menu_access", undefined, undefined, "keyboard").__value == vk_escape && input_binding_get("right", undefined, undefined, "keyboard").__value == vk_right && json_stringify(global.Users[0].InputProfile_Keyboard) == input_profile_export("keyboard"));
    input_profile_import(keyboard_before, "keyboard");
    global.StartingGear = 0;
}
function PauseTests() {
    var pause = instance_create_layer(0, 0, "System", oMenu_Game);
    pause.Open = false;
    for (var index = 1; index <= 2; index++) {
        pause.Index = index;
        pause.SelectorPos = 1;
        PressEvent(pause, "action", oMenu_Game, ev_step, ev_step_normal);
        Record("pause submenu " + string(index) + " cancels", pause.Index == 0 && !pause.Close && !pause.Quitting);
    }
    pause.Index = 1;
    PressEvent(pause, "escape", oMenu_Game, ev_step, ev_step_normal);
    Record("Escape backs out of options without closing pause", pause.Index == 0 && !pause.Close);
    PressEvent(pause, "action", oMenu_Game, ev_step, ev_step_normal);
    Record("action resumes from pause root", pause.Close && !pause.Quitting);
    with (pause) instance_destroy();
}
function EnemyFixture(object) {
    return instance_create_layer(oLink.x + 48, oLink.y, "Objs_Lower", object, {FloorLevel: 0, RoomIndex: oLink.RoomIndex});
}
function EnemyTests() {
    global.Paused = false;
    oLink.Cape = false;
    var medusa = EnemyFixture(oEnemy_Medusa);
    var cannon = EnemyFixture(oEnemy_Cannon);
    cannon.WallInit = false;
    var statuses = [[3, false, false, false, true, "active"], [15, true, false, false, false, "frozen"], [17, false, true, false, false, "stoned"], [3, true, false, false, false, "stopwatch flag"], [3, false, true, false, false, "stone flag"], [15, false, false, false, false, "frozen state"], [17, false, false, false, false, "stone state"], [3, false, false, true, false, "paused"], [3, false, false, false, true, "recovered"]];
    for (var i = 0; i < array_length(statuses); i++) {
        var status = statuses[i];
        for (var e = 0; e < 2; e++) {
            var enemy = e == 0 ? medusa : cannon;
            enemy.State = status[0];
            enemy.StopWatch = status[1];
            enemy.Stoned = status[2];
            enemy.ShootReady = true;
            global.Paused = status[3];
            oLink.State = 12;
            var count = instance_number(oRedBall);
            if (e == 0) {
                enemy.alarm[0] = -1;
                with (enemy) event_perform_object(oEnemy_Medusa, ev_alarm, 0);
            }
            else with (enemy) event_perform_object(oEnemy_Cannon, ev_step, ev_step_normal);
            Record((e == 0 ? "Medusa " : "cannon ") + status[5], instance_number(oRedBall) - count == (status[4] ? 1 : 0));
            if (e == 0) Record("Medusa alarm remains armed " + status[5], enemy.alarm[0] > 0);
        }
    }
    var count = instance_number(oRedBall);
    with (cannon) event_perform_object(oEnemy_Cannon, ev_step, ev_step_normal);
    Record("cannon fires once per sword swing", instance_number(oRedBall) == count);
    oLink.State = 1;
    with (cannon) event_perform_object(oEnemy_Cannon, ev_step, ev_step_normal);
    oLink.State = 12;
    with (cannon) event_perform_object(oEnemy_Cannon, ev_step, ev_step_normal);
    Record("cannon rearms for the next swing", instance_number(oRedBall) == count + 1);
    oLink.Cape = true;
    count = instance_number(oRedBall);
    with (medusa) event_perform_object(oEnemy_Medusa, ev_alarm, 0);
    Record("Medusa respects the magic cape", instance_number(oRedBall) == count);
    oLink.Cape = false;
    with (medusa) instance_destroy();
    with (cannon) instance_destroy();
    with (oRedBall) instance_destroy();
    PikitTests();
}
function PikitTests() {
    var parent = EnemyFixture(oEnemy_Pikit);
    parent.State = 7;
    var scenarios = [[20, false, false, "falling into a pit"], [21, false, false, "falling over an edge"], [1, true, false, "invincibility"], [1, false, true, "magic cape"], [1, false, false, "landed"]];
    for (var i = 0; i < array_length(scenarios); i++) {
        var scenario = scenarios[i];
        var tongue = instance_create_layer(oLink.x, oLink.y - 6, "Objs_Lower", oEnemy_Pikit_Tongue);
        tongue.ParentInst = parent;
        tongue.Dist = 24;
        oLink.State = scenario[0];
        oLink.Invincible = scenario[1];
        oLink.Cape = scenario[2];
        global.Inventory_ItemData[40].Amount = 100;
        var before = json_stringify(global.Inventory);
        with (tongue) event_perform_object(oEnemy_Pikit_Tongue, ev_step, ev_step_normal);
        if (i < 4) Record("Pikit respects " + scenario[3], !tongue.ItemGrabbed && global.Inventory_ItemData[40].Amount == 100 && json_stringify(global.Inventory) == before);
        else Record("Pikit can steal after landing", tongue.ItemGrabbed);
        with (tongue) {
            if (instance_exists(ItemInst)) instance_destroy(ItemInst);
            instance_destroy();
        }
    }
    with (parent) instance_destroy();
}
Flush();
