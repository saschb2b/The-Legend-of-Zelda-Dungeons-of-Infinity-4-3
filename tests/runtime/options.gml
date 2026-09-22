function OptionsPress(verb) {
    PressEvent(oMenu, verb, oMenu, ev_step, ev_step_normal);
}
function OptionsOpenTab(name, focus = 0) {
    var state = oMenu.NovaOptions;
    state.page = "list";
    state.tab = array_get_index(state.tabs, name);
    state.focus = focus;
    return state;
}
function OptionsIni(section, key) {
    ini_open("options.ini");
    var value = ini_read_real(section, key, -1);
    ini_close();
    return value;
}
function OptionsMenuTests() {
    var users = global.Users;
    var user_index = global.UserIndex;
    var profile = input_profile_get();
    var audio = [global.MusicVol, global.SFXVol, global.Gore, global.CanSkipTitle];
    global.Users = [ProfileFixture("LINK", 0, 4, 3.5, 5), new User_Create(), new User_Create(), new User_Create(), new User_Create()];
    global.UserIndex = 0;
    input_profile_set("gamepad");
    with (oMenu) { NovaGo("home", 0); NovaOptions = global.NovaOptionsState("title"); }
    var rows = oMenu.NovaHomeRows();
    oMenu.NovaFocus = array_get_index(rows, "Options");
    OptionsPress("menu_input");
    var state = oMenu.NovaOptions;
    Record("home opens the Options list", oMenu.NovaPage == "options" && state.page == "list" && state.tab == 0);
    Record("title Options ends with About", array_length(state.tabs) == 5 && state.tabs[4] == "About");
    OptionsPress("nova_bag_previous");
    Record("left shoulder wraps to the last tab", state.tab == 4);
    OptionsPress("nova_bag_next");
    Record("right shoulder wraps to the first tab", state.tab == 0);
    OptionsOpenTab("Audio", 1);
    OptionsPress("nova_bag_next");
    OptionsPress("nova_bag_previous");
    Record("tabs remember their highlighted row", state.tab == 2 && state.focus == 1);
    OptionsPress("down");
    Record("rows wrap downward", state.focus == 0);
    OptionsPress("up");
    Record("rows wrap upward", state.focus == 1);

    OptionsOpenTab("Game", 0);
    global.Users[0].Prefs[4] = true;
    OptionsPress("right");
    Record("right changes a toggle", !global.Users[0].Prefs[4]);
    OptionsPress("menu_input");
    Record("confirm changes a toggle", global.Users[0].Prefs[4]);
    OptionsOpenTab("Display", 0);
    global.Users[0].Prefs[3] = false;
    OptionsPress("left");
    Record("CRT changes immediately for this player", global.Users[0].Prefs[3]);
    OptionsPress("down");
    OptionsPress("right");
    Record("blood setting is stored for the device", !global.Gore && OptionsIni("Preferences", "Gore") == 0);

    OptionsOpenTab("Audio", 0);
    global.Users[0].Prefs[1] = true;
    global.MusicVol = 0.7;
    OptionsPress("right");
    Record("music volume rises by one step", global.NovaOptionGet("music") == 8 && abs(global.MusicVol - 0.8) < 0.001 && abs(OptionsIni("Audio", "MusicVol") - 0.8) < 0.001);
    for (var i = 0; i < 4; i++) OptionsPress("right");
    Record("music volume stops at ten", global.NovaOptionGet("music") == 10);
    for (var i = 0; i < 12; i++) OptionsPress("left");
    Record("music volume zero mutes the player", global.NovaOptionGet("music") == 0 && !global.Users[0].Prefs[1] && global.MusicVol > 0);
    OptionsPress("right");
    Record("raising muted music restores sound", global.NovaOptionGet("music") == 1 && global.Users[0].Prefs[1]);
    OptionsPress("menu_input");
    Record("confirm leaves a volume unchanged", global.NovaOptionGet("music") == 1);

    OptionsPress("item");
    Record("Defaults asks before restoring a tab", state.page == "confirm" && state.confirm == "tab" && state.confirm_focus == 0);
    OptionsPress("menu_input");
    Record("Cancel keeps the current settings", state.page == "list" && global.NovaOptionGet("music") == 1);
    OptionsPress("item");
    OptionsPress(global.NovaCloseVerb());
    Record("Close leaves the confirmation unchanged", state.page == "list" && global.NovaOptionGet("music") == 1);
    global.Users[0].Prefs[0] = false;
    OptionsPress("item");
    OptionsPress("down");
    OptionsPress("menu_input");
    Record("Restore defaults resets only the current tab", state.page == "list" && global.NovaOptionGet("music") == 7 && global.NovaOptionGet("sfx") == 10 && !global.Gore);

    OptionsOpenTab("Controls", 1);
    var keyboard_before = input_profile_export("keyboard");
    input_binding_set("sword", input_binding_key(ord("Q")), 0, 0, "keyboard");
    OptionsPress("menu_input");
    Record("Keyboard opens its remapping page", state.page == "device" && state.device == 1 && state.device_focus == 0);
    OptionsPress("right");
    OptionsPress("menu_input");
    Record("restoring one device asks first", state.page == "confirm" && state.confirm == "device");
    OptionsPress(global.NovaCloseVerb());
    Record("Close returns from the device confirmation", state.page == "device" && input_binding_get("sword", 0, 0, "keyboard").__value == ord("Q"));
    OptionsPress("menu_input");
    OptionsPress("down");
    OptionsPress("menu_input");
    Record("restoring a device resets and saves its bindings", state.page == "device" && input_binding_get("sword", 0, 0, "keyboard").__value != ord("Q") && json_stringify(global.Users[0].InputProfile_Keyboard) == input_profile_export("keyboard"));
    OptionsPress(global.NovaCloseVerb());
    Record("Close returns from a device page to the list", state.page == "list" && state.tab == 3 && state.focus == 1);
    input_profile_import(keyboard_before, "keyboard");

    OptionsOpenTab("About", 1);
    OptionsPress("menu_input");
    Record("Credits opens from About", oMenu.NovaPage == "credits");
    OptionsPress(global.NovaCloseVerb());
    Record("Credits returns to its About row", oMenu.NovaPage == "options" && state.tab == 4 && state.focus == 1);
    OptionsPress("item");
    Record("About has no defaults", state.page == "list");

    draw_set_font(global.MenuFont_Innactive);
    var layout = global.NovaOptionsLayout();
    var menu = global.NovaMenuLayout();
    var tabs = global.NovaOptionsTabs(state);
    Record("tab strip fits between the shoulder glyphs", tabs[0].x >= 64 && tabs[array_length(tabs) - 1].x + tabs[array_length(tabs) - 1].width <= 336.01);
    for (var t = 0; t < array_length(state.tabs); t++) {
        var tab_rows = global.NovaOptionRows(state.tabs[t]);
        for (var r = 0; r < array_length(tab_rows); r++) {
            var info = global.NovaOptionInfo(tab_rows[r]);
            var line = string_height("A") + 4;
            var lines = string_height_ext(info.help, line, layout.help_width / 0.6) / line;
            Record("help fits in two lines: " + tab_rows[r], lines <= 2.01 && layout.help_y + lines * line * 0.6 <= menu.y + menu.height - 2);
            Record("label clears its value: " + tab_rows[r], layout.label_x + string_width(info.label) * 0.9 < layout.arrow_left - 8);
        }
        Record("tab rows stay above the help text: " + state.tabs[t], layout.rows_y + array_length(tab_rows) * layout.row_height <= layout.help_rule_y);
    }
    for (var device = 0; device < 2; device++) {
        input_profile_set(device == 0 ? "gamepad" : "keyboard");
        var cases = [["Audio", 0, "Change", "Defaults"], ["Controls", 0, "Defaults", "Select"], ["About", 0, "Select", "Close"]];
        for (var c = 0; c < array_length(cases); c++) {
            OptionsOpenTab(cases[c][0], cases[c][1]);
            var hints = global.NovaOptionsFooter(state);
            var last = hints[array_length(hints) - 1];
            Record("Options footer fits " + cases[c][0] + " " + string(device), hints[0].x >= menu.footer_left - 0.01 && last.right <= menu.footer_right + 0.01 && last.label == "Close");
            Record("Options footer order " + cases[c][0] + " " + string(device), hints[0].label == cases[c][2] && hints[1].label == cases[c][3]);
        }
    }
    input_profile_set("gamepad");
    OptionsOpenTab("Audio", 0);
    var footer = global.NovaOptionsFooter(state);
    var change = footer[0];
    Record("Change shows distinct D-pad glyphs", global.NovaGlyph(change.binding) == 13 && global.NovaGlyph(change.binding2) == 14);
    OptionsOpenTab("Game", 0);
    OptionsPress(global.NovaCloseVerb());
    var home_rows = oMenu.NovaHomeRows();
    Record("Close returns to the home Options row", oMenu.NovaPage == "home" && home_rows[oMenu.NovaFocus] == "Options");

    global.MusicVol = audio[0];
    global.SFXVol = audio[1];
    global.Gore = audio[2];
    global.CanSkipTitle = audio[3];
    global.NovaOptionWrite("Audio", "MusicVol", audio[0]);
    global.NovaOptionWrite("Audio", "SFXVol", audio[1]);
    global.NovaOptionWrite("Preferences", "Gore", audio[2]);
    global.NovaOptionWrite("Preferences", "CanSkipTitle", audio[3]);
    global.Users = users;
    global.UserIndex = user_index;
    User_Save();
    User_UpdateMusicSFX();
    input_profile_set(profile);
    with (oMenu) { NovaOptions = global.NovaOptionsState("title"); NovaGo("home", 0); }
}
