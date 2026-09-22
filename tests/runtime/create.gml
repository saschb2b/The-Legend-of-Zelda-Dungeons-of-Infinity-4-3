persistent = true;
Stage = 0;
Ticks = 0;
Results = [];
Complete = false;
Capture = "";
CRTBenchmark = {};
global.NovaTestInput = "";
global.NovaTestHeld = [];
global.NovaTestHUDDraws = 0;
global.NovaTestStatusDraws = 0;
function Flush() {
    var file = file_text_open_write("nova-test-report.json");
    file_text_write_string(file, json_stringify({complete: Complete, results: Results, capture: Capture, crt_benchmark: CRTBenchmark}));
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
function MenuTests() {
    global.UserIndex = 0;
    global.Users[0] = new User_Create();
    global.Users[0].Name = "HARNESS";
    DungeonSeq_Init(0);
    oMenu.NovaTransition = 36;
    var cases = [["setup", "home"], ["players", "home"], ["options", "home"], ["challenges", "setup"], ["replace", "setup"], ["player", "players"], ["rename", "player"], ["delete", "player"], ["records", "player"], ["credits", "options"]];
    for (var i = 0; i < array_length(cases); i++) {
        for (var key = 0; key < 2; key++) {
            oMenu.NovaPage = cases[i][0];
            PressEvent(oMenu, key == 0 ? global.NovaCloseVerb() : "escape", oMenu, ev_step, ev_step_normal);
            Record("Close returns from " + cases[i][0] + " via " + string(key), oMenu.NovaPage == cases[i][1]);
        }
    }
    oMenu.NovaPage = "rename";
    oMenu.NovaName = "UNSAVED";
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Closing rename discards the draft", global.Users[0].Name == "HARNESS");
    oMenu.NovaPage = "delete";
    oMenu.NovaFocus = 0;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Default delete choice preserves the player", global.Users[0].Name == "HARNESS");
    oMenu.NovaPage = "options";
    oMenu.NovaOptions.page = "device";
    oMenu.Bindings_Remap = true;
    global.NovaRemapping = true;
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Close does not interrupt a binding scan", oMenu.NovaPage == "options" && oMenu.NovaOptions.page == "device");
    oMenu.Bindings_Remap = false;
    global.NovaRemapping = false;
    oMenu.NovaOptions.page = "list";
    var keyboard_before = input_profile_export("keyboard");
    var remap = instance_create_layer(0, 0, "System", oInputRemap, {InputIndex: 1});
    Record("remapping blocks the Options screen", global.NovaRemapping && oMenu.Bindings_Remap);
    input_binding_scan_set_Success(input_binding_key(ord("Q")));
    input_binding_scan_set_Failure(-20);
    Record("aborted remapping restores every previous binding", input_profile_export("keyboard") == keyboard_before && !instance_exists(remap) && !global.NovaRemapping && !oMenu.Bindings_Remap);
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
    pause.Index = 2;
    pause.SelectorPos = 1;
    PressEvent(pause, global.NovaCloseVerb(), oMenu_Game, ev_step, ev_step_normal);
    Record("pause confirmation cancels", pause.Index == 0 && !pause.Close && !pause.Quitting);
    pause.SelectorPos = 2;
    PressEvent(pause, "menu_input", oMenu_Game, ev_step, ev_step_normal);
    Record("pause Options opens the shared screen", pause.NovaOptionsOpen && pause.NovaOptions.context == "pause" && pause.Index == 0);
    Record("pause Options omits title-only About", array_length(pause.NovaOptions.tabs) == 4 && array_get_index(pause.NovaOptions.tabs, "About") == -1);
    PressEvent(pause, "escape", oMenu_Game, ev_step, ev_step_normal);
    Record("Escape backs out of Options without closing pause", !pause.NovaOptionsOpen && !pause.Close && pause.SelectorPos == 2);
    PressEvent(pause, "menu_input", oMenu_Game, ev_step, ev_step_normal);
    PressEvent(pause, global.NovaCloseVerb(), oMenu_Game, ev_step, ev_step_normal);
    Record("Close returns to the pause Options row", !pause.NovaOptionsOpen && !pause.Close && pause.SelectorPos == 2);
    PressEvent(pause, "menu_input", oMenu_Game, ev_step, ev_step_normal);
    var keyboard_before = input_profile_export("keyboard");
    pause.NovaOptions.page = "device";
    pause.NovaOptions.device = 1;
    pause.NovaOptions.device_focus = 0;
    PressEvent(pause, "menu_input", oMenu_Game, ev_step, ev_step_normal);
    Record("pause starts remapping without the adventure menu", global.NovaRemapping && instance_exists(oInputRemap) && !instance_exists(oMenu));
    PressEvent(pause, global.NovaCloseVerb(), oMenu_Game, ev_step, ev_step_normal);
    PressEvent(pause, "menu_access", oMenu_Game, ev_step, ev_step_normal);
    Record("buttons during a pause remap do not leave Options", pause.NovaOptionsOpen && pause.NovaOptions.page == "device" && !pause.Close);
    input_binding_scan_set_Success(input_binding_key(ord("Q")));
    input_binding_scan_set_Failure(-20);
    Record("aborted pause remap restores the keyboard", !global.NovaRemapping && !instance_exists(oInputRemap) && input_profile_export("keyboard") == keyboard_before);
    pause.NovaOptions.page = "list";
    PressEvent(pause, "menu_access", oMenu_Game, ev_step, ev_step_normal);
    Record("Select leaves pause from Options", !pause.NovaOptionsOpen && pause.Close && !pause.Quitting);
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
