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
    Record("square pixels are stored for the device", global.NovaSquarePixels && OptionsIni("Display", "SquarePixels") == 1
        && global.NovaHUDLayout(1920, 1080).world_width == round(1080 * 8 / 7));
    OptionsPress("left");
    Record("square pixels turn off again", !global.NovaSquarePixels && OptionsIni("Display", "SquarePixels") == 0);
    OptionsPress("down");
    OptionsPress("right");
    Record("integer scaling is stored for the device", global.NovaIntegerScale && OptionsIni("Display", "IntegerScale") == 1
        && global.NovaHUDLayout(1920, 1080).world_height == 896);
    OptionsPress("left");
    Record("integer scaling turns off again", !global.NovaIntegerScale && OptionsIni("Display", "IntegerScale") == 0);
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
    var gamepad_before = input_profile_export("gamepad");
    input_profile_reset_bindings("keyboard");
    input_profile_reset_bindings("gamepad");
    Record("Controls shows Default for untouched bindings", !global.NovaRemapCustom(0) && !global.NovaRemapCustom(1));
    OptionsPress("menu_input");
    var items = global.NovaRemapItems(1);
    Record("Keyboard opens on its first action", state.page == "device" && state.device == 1 && items[state.bind_focus].kind == "action" && items[state.bind_focus].verb == "up");
    var trail = global.NovaOptionsTrail(state);
    Record("device page names its place in Options", array_length(trail) == 3 && trail[0] == "Options" && trail[1] == "Controls" && trail[2] == "Keyboard");
    var fixed_ok = true;
    var headers = 0;
    for (var i = 0; i < array_length(items); i++) {
        if (items[i].kind == "header") headers++;
        if (items[i].kind == "fixed") fixed_ok = fixed_ok && (items[i].verb == "nova_confirm" || items[i].verb == "nova_back" || items[i].verb == "menu_access");
        if (items[i].kind == "action") fixed_ok = fixed_ok && items[i].verb != "menu_access" && items[i].verb != "menu_input";
    }
    Record("keyboard actions are grouped and menu buttons stay fixed", headers == 5 && fixed_ok);
    var visited = true;
    for (var i = 0; i < array_length(items); i++) {
        OptionsPress("down");
        var kind = items[state.bind_focus].kind;
        visited = visited && (kind == "action" || kind == "reset");
    }
    Record("navigation skips headings and fixed buttons", visited);
    OptionsOpenTab("Controls", 1);
    OptionsPress("menu_input");
    OptionsPress("up");
    Record("moving up from the first action wraps to Restore all defaults", items[state.bind_focus].kind == "reset");
    var list = global.NovaRemapRows(state);
    var row = list.rows[state.bind_focus];
    Record("scrolling keeps the last row visible", state.bind_scroll > 0 && row.y - state.bind_scroll >= 0 && row.y + row.height - state.bind_scroll <= list.visible);
    OptionsPress("menu_input");
    Record("Restore all defaults does nothing when nothing changed", state.page == "device");
    OptionsPress("down");
    Record("moving down wraps to the first action and scrolls back", items[state.bind_focus].verb == "up" && state.bind_scroll == 0);

    while (items[state.bind_focus].kind != "action" || items[state.bind_focus].verb != "sword") OptionsPress("down");
    var footer_plain = global.NovaOptionsFooter(state);
    Record("an unchanged action offers Remap and Back", array_length(footer_plain) == 2 && footer_plain[0].label == "Remap" && footer_plain[1].label == "Back");
    OptionsPress("menu_input");
    Record("Remap waits for one new key", state.capture && global.NovaRemapping);
    var footer_capture = global.NovaOptionsFooter(state);
    Record("a waiting remap offers only Cancel", array_length(footer_capture) == 1 && footer_capture[0].label == "Cancel");
    global.NovaRemapSuccess(input_binding_key(ord("Q")));
    Record("one key changes only its action", !state.capture && !global.NovaRemapping && input_binding_get("sword", 0, 0, "keyboard").__value == ord("Q") && input_binding_get("item", 0, 0, "keyboard").__value == ord("Z"));
    Record("a changed action is marked and saved", global.NovaRemapChanged("sword", 1) && global.NovaRemapCustom(1) && json_stringify(global.Users[0].InputProfile_Keyboard) == input_profile_export("keyboard") && string_pos("Sword changed", state.notice) == 1);
    var footer_changed = global.NovaOptionsFooter(state);
    Record("a changed action offers Reset first", footer_changed[0].label == "Reset" && footer_changed[1].label == "Remap");
    OptionsPress("down");
    OptionsPress("menu_input");
    global.NovaRemapSuccess(input_binding_key(ord("Q")));
    Record("a key already in use swaps with the other action", input_binding_get("item", 0, 0, "keyboard").__value == ord("Q") && input_binding_get("sword", 0, 0, "keyboard").__value == ord("Z") && string_pos("Sword took its old key", state.notice) > 0);
    OptionsPress("up");
    OptionsPress("item");
    Record("Reset restores only the highlighted action", input_binding_get("sword", 0, 0, "keyboard").__value == vk_control && input_binding_get("item", 0, 0, "keyboard").__value == ord("Q") && !global.NovaRemapChanged("sword", 1));
    var before_cancel = input_profile_export("keyboard");
    OptionsPress("menu_input");
    OptionsPress("menu_access");
    Record("Pause cancels without changing the action", !state.capture && !global.NovaRemapping && input_profile_export("keyboard") == before_cancel && state.notice == "Cancelled.");
    OptionsPress("menu_input");
    global.NovaRemapFailure(-10);
    Record("an ignored input keeps waiting", state.capture && global.NovaRemapping);
    global.NovaRemapFailure(-20);
    Record("a timeout leaves the action unchanged", !state.capture && !global.NovaRemapping && input_profile_export("keyboard") == before_cancel && string_pos("Nothing pressed", state.notice) == 1);
    OptionsPress("up");
    while (items[state.bind_focus].kind != "reset") OptionsPress("up");
    OptionsPress("menu_input");
    Record("Restore all defaults asks first", state.page == "confirm" && state.confirm == "device");
    OptionsPress("down");
    OptionsPress("menu_input");
    Record("Restore all defaults returns every key", state.page == "device" && !global.NovaRemapCustom(1));
    OptionsPress(global.NovaCloseVerb());
    Record("Back returns from a device page to the list", state.page == "list" && state.tab == 3 && state.focus == 1);

    OptionsOpenTab("Controls", 0);
    OptionsPress("menu_input");
    var pad_items = global.NovaRemapItems(0);
    while (pad_items[state.bind_focus].kind != "action" || pad_items[state.bind_focus].verb != "item") OptionsPress("down");
    OptionsPress("menu_input");
    global.NovaRemapSuccess(input_binding_gamepad_button(gp_face1));
    Record("gamepad Item can take B and Sword swaps to X", global.NovaGlyph(input_binding_get("item", 0, 0, "gamepad")) == 1 && global.NovaGlyph(input_binding_get("sword", 0, 0, "gamepad")) == 2);
    Record("menu Back stays on B after gameplay moves", global.NovaGlyph(global.NovaBinding("nova_back", "gamepad")) == 1 && global.NovaGlyph(global.NovaBinding("nova_confirm", "gamepad")) == 0);
    Record("Gamepad shows Custom after a change", global.NovaRemapCustom(0));
    OptionsPress(global.NovaCloseVerb());
    input_profile_import(keyboard_before, "keyboard");
    input_profile_import(gamepad_before, "gamepad");
    User_SaveControls();

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
    var trails = [["Options", "Controls", "Keyboard"], ["Options", "Controls", "Gamepad"], ["Options", "About", "Updates"], ["Options", "About", "Credits"]];
    for (var t = 0; t < array_length(trails); t++) {
        var parts = global.NovaMenuTitleParts(trails[t]);
        var last_part = parts[array_length(parts) - 1];
        Record("breadcrumb fits the header: " + trails[t][2] + " " + trails[t][1], last_part.current && last_part.x + last_part.width <= menu.x + menu.width - 8);
    }
    var glyphs = true;
    for (var i = 0; i < global.BindingIconCount[0]; i++) glyphs = glyphs && global.NovaGlyph(global.NovaBinding(GetInputVerbStr(global.BindingVerbs[0][i]), "gamepad")) >= 0;
    Record("default gamepad bindings all draw as glyphs", glyphs);
    var dialog = global.NovaOptionsDialog();
    Record("confirmation dialog sits inside the Options panel", dialog.x > menu.x && dialog.x + dialog.width < menu.x + menu.width && dialog.y > layout.rule_y && dialog.y + dialog.height < layout.help_rule_y);
    Record("binding list stays between the tabs and the help text", layout.list_top > layout.rule_y && layout.list_bottom < layout.help_rule_y);
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
