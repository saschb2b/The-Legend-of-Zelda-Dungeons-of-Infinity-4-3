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
    var cases = [["setup", "home"], ["players", "home"], ["options", "home"], ["challenges", "setup"], ["replace", "setup"], ["player", "players"], ["rename", "player"], ["credits", "options"]];
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
    oMenu.NovaPage = "player";
    oMenu.NovaPlayerDialog = true;
    oMenu.NovaPlayerDialogFocus = 0;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Default delete choice preserves the player", global.Users[0].Name == "HARNESS" && !oMenu.NovaPlayerDialog && oMenu.NovaPage == "player");
    oMenu.NovaPage = "options";
    oMenu.NovaOptions.page = "device";
    oMenu.NovaOptions.device = 1;
    oMenu.NovaOptions.capture = true;
    global.NovaRemapping = true;
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Close does not interrupt a binding scan", oMenu.NovaPage == "options" && oMenu.NovaOptions.page == "device" && oMenu.NovaOptions.capture);
    PressEvent(oMenu, "menu_access", oMenu, ev_step, ev_step_normal);
    Record("Pause cancels a binding scan", !oMenu.NovaOptions.capture && !global.NovaRemapping && oMenu.NovaOptions.page == "device");
    oMenu.NovaOptions.page = "list";
    global.StartingGear = 0;
}
function PauseOpen() {
    var pause = instance_create_layer(0, 0, "System", oMenu_Game);
    pause.Open = false;
    return pause;
}
function PausePress(pause, verb) {
    PressEvent(pause, verb, oMenu_Game, ev_step, ev_step_normal);
}
function PauseTests() {
    var pause = PauseOpen();
    Record("pause opens on Resume", pause.NovaPauseFocus == 0 && !pause.NovaPauseDialog && !pause.NovaOptionsOpen);
    PausePress(pause, "up");
    Record("pause rows wrap to Quit to desktop", pause.NovaPauseFocus == 5);
    PausePress(pause, "down");
    PausePress(pause, "down");
    Record("pause rows wrap back to Resume and Options", pause.NovaPauseFocus == 1);
    PausePress(pause, "menu_input");
    var trail = global.NovaOptionsTrail(pause.NovaOptions);
    Record("pause Options opens the shared screen under Paused", pause.NovaOptionsOpen && pause.NovaOptions.context == "pause" && trail[0] == "Paused" && trail[1] == "Options");
    var pause_footer = global.NovaOptionsFooter(pause.NovaOptions);
    Record("pause Options labels B as Back", pause_footer[array_length(pause_footer) - 1].label == "Back");
    Record("pause Options omits title-only About", array_length(pause.NovaOptions.tabs) == 4 && array_get_index(pause.NovaOptions.tabs, "About") == -1);
    PausePress(pause, "escape");
    Record("Escape backs out of Options to the pause list", !pause.NovaOptionsOpen && !pause.Close && pause.NovaPauseFocus == 1);
    pause.NovaPauseFocus = 2;
    PausePress(pause, "menu_input");
    trail = global.NovaOptionsTrail(pause.NovaOptions);
    Record("Controls opens the current device's mapping", pause.NovaOptionsOpen && pause.NovaOptions.page == "device" && pause.NovaOptions.device == (input_profile_get() == "keyboard" ? 1 : 0) && trail[0] == "Paused" && trail[1] == "Controls");
    var keyboard_before = input_profile_export("keyboard");
    pause.NovaOptions.device = 1;
    pause.NovaOptions.bind_focus = 1;
    PausePress(pause, "menu_input");
    Record("pause remaps one action without the adventure menu", global.NovaRemapping && pause.NovaOptions.capture && !instance_exists(oMenu));
    PausePress(pause, global.NovaCloseVerb());
    Record("Back during a pause remap keeps Options open", pause.NovaOptionsOpen && pause.NovaOptions.capture && !pause.Close);
    PausePress(pause, "menu_access");
    Record("Select cancels a pause remap without leaving pause", pause.NovaOptionsOpen && !pause.NovaOptions.capture && !global.NovaRemapping && !pause.Close && input_profile_export("keyboard") == keyboard_before);
    PausePress(pause, global.NovaCloseVerb());
    Record("Back from Controls returns to its pause row", !pause.NovaOptionsOpen && pause.NovaPauseFocus == 2 && !pause.Close);
    for (var row = 3; row <= 5; row++) {
        pause.NovaPauseFocus = row;
        PausePress(pause, "menu_input");
        var text = global.NovaPauseDialogText(row);
        Record("pause row " + string(row) + " asks first on Cancel", pause.NovaPauseDialog && pause.NovaPauseDialogFocus == 0 && text.confirm != "OK");
        PausePress(pause, "menu_input");
        Record("Cancel keeps the run " + string(row), !pause.NovaPauseDialog && !pause.Quitting && !pause.Close);
        PausePress(pause, "menu_input");
        PausePress(pause, global.NovaCloseVerb());
        Record("Back closes the dialog, not the pause " + string(row), !pause.NovaPauseDialog && !pause.Quitting && !pause.Close);
    }
    Record("quitting explains lost progress", string_pos("Save Tent", global.NovaPauseHelp(4)) > 0 && string_pos("Save Tent", global.NovaPauseDialogText(5).detail) > 0 && string_pos("floor 1", global.NovaPauseHelp(3)) > 0);
    var summary = global.NovaPauseSummary(pause);
    Record("the run summary reads the live run", summary.floor == global.Level.Index && summary.hearts == global.Inventory_ItemData[18].Amount && summary.character == global.LinkCharacterIndex);
    draw_set_font(global.MenuFont_Innactive);
    var layout = global.NovaPauseLayout();
    var widest = 0;
    for (var i = 0; i < array_length(global.NovaPauseRows); i++) widest = max(widest, string_width(global.NovaPauseRows[i]) * 0.9);
    Record("pause rows clear the run summary", layout.rows_x + widest + 8 < layout.panel_x && layout.rows_y[5] + 14 < layout.rule_y && layout.panel_y + layout.panel_h < layout.rule_y);
    var line = string_height("A") + 4;
    var help_ok = true;
    for (var i = 0; i < 6; i++) help_ok = help_ok && string_height_ext(global.NovaPauseHelp(i), line, global.NovaOptionsLayout().help_width / 0.6) / line <= 2.01;
    Record("pause help fits in two lines", help_ok);
    var footer = global.NovaPauseFooter(pause);
    Record("pause footer offers Select and Resume", footer[0].label == "Select" && footer[1].label == "Resume");
    pause.NovaPauseFocus = 5;
    PausePress(pause, "menu_input");
    PausePress(pause, "down");
    PausePress(pause, "menu_input");
    Record("confirming a quit starts it with the right destination", pause.Quitting && pause.QuitTo == 2);
    with (pause) instance_destroy();
    pause = PauseOpen();
    PausePress(pause, "escape");
    Record("Escape resumes from the pause list", pause.Close && !pause.Quitting);
    with (pause) instance_destroy();
    pause = PauseOpen();
    PausePress(pause, global.NovaCloseVerb());
    Record("Back resumes from the pause list", pause.Close);
    with (pause) instance_destroy();
    pause = PauseOpen();
    PausePress(pause, "menu_access");
    Record("Select resumes from the pause list", pause.Close);
    with (pause) instance_destroy();
    pause = PauseOpen();
    PausePress(pause, "menu_input");
    Record("confirming Resume closes pause", pause.Close);
    with (pause) instance_destroy();
    pause = PauseOpen();
    PausePress(pause, "down");
    PausePress(pause, "menu_input");
    PausePress(pause, "menu_access");
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
