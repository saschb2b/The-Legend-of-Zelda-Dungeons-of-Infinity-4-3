// Shared Options screen for the adventure menu and the pause menu.
// Drawing uses the adventure menu's 400x300 view, whose top edge is y = -38.
global.NovaRemapping = false;
global.NovaOptionsSurface = -1;
global.NovaMenuLayout = function() {
    return {
        x: 24, y: 10, width: 352, height: 216,
        header_y: -20, header_width: 352, header_height: 20,
        left: 42, right: 358, footer_y: 242, footer_left: 28, footer_right: 372
    };
};
global.NovaOptionsLayout = function() {
    return {tabs_y: 21, tabs_left: 72, tabs_right: 328, rule_y: 42, rows_y: 56, row_height: 28,
        label_x: 60, value_center: 285, arrow_left: 236, arrow_right: 334,
        bar_x: 246, bar_segment: 8, help_rule_y: 184, help_y: 192, help_x: 44, help_width: 316,
        list_top: 47, list_bottom: 181, header_height: 13, binding_height: 16};
};
global.NovaOptionsState = function(context) {
    var tabs = ["Game", "Display", "Audio", "Controls"];
    if (context == "title") array_push(tabs, "About");
    return {context: context, tabs: tabs, tab: 0, focus: 0, memory: array_create(array_length(tabs), 0),
        page: "list", device: 0, confirm: "", confirm_focus: 0,
        bind_focus: 1, bind_scroll: 0, capture: false, notice: "", notice_time: 0, origin: "options", closed: false};
};
global.NovaOptionRows = function(tab) {
    switch (tab) {
        case "Game": return ["item_messages", "skip_title"];
        case "Display": return ["crt", "gore"];
        case "Audio": return ["music", "sfx"];
        case "Controls": return ["gamepad", "keyboard"];
        case "About": return ["updates", "credits"];
    }
    return [];
};
global.NovaOptionInfo = function(row) {
    switch (row) {
        case "item_messages": return {label: "Item messages", kind: "toggle", fallback: 1, help: "Show a message when you pick up an item."};
        case "skip_title": return {label: "Skip title intro", kind: "toggle", fallback: 1, help: "Press Start or confirm to skip the opening title animation."};
        case "crt": return {label: "CRT effect", kind: "toggle", fallback: 0, help: "Scanlines, a phosphor grille and soft bloom on the playfield. The HUD stays sharp. Saved for this player."};
        case "gore": return {label: "Blood and remains", kind: "toggle", fallback: 1, help: "Show blood and remains in dungeons. Takes effect on the next floor."};
        case "music": return {label: "Music", kind: "volume", fallback: 7, help: "Volume of the background music."};
        case "sfx": return {label: "Sound effects", kind: "volume", fallback: 10, help: "Volume of combat, item and menu sounds."};
        case "gamepad": return {label: "Gamepad", kind: "link", fallback: 0, help: "Remap controller buttons. Saved for this player."};
        case "keyboard": return {label: "Keyboard", kind: "link", fallback: 0, help: "Remap keyboard keys. Saved for this player."};
        case "updates": return {label: "Updates", kind: "link", fallback: 0, help: "Check for a newer patch and read what changed."};
        case "credits": return {label: "Credits", kind: "link", fallback: 0, help: "The people behind Dungeons of Infinity."};
    }
    return {label: row, kind: "link", fallback: 0, help: ""};
};
global.NovaOptionWrite = function(section, key, value) {
    ini_open("options.ini");
    ini_write_real(section, key, value);
    ini_close();
};
global.NovaOptionGet = function(row) {
    var user = global.Users[global.UserIndex];
    switch (row) {
        case "item_messages": return user.Prefs[4] ? 1 : 0;
        case "skip_title": return global.CanSkipTitle ? 1 : 0;
        case "crt": return user.Prefs[3] ? 1 : 0;
        case "gore": return global.Gore ? 1 : 0;
        // A muted player keeps the device volume for when they unmute.
        case "music": return user.Prefs[1] ? round(global.MusicVol * 10) : 0;
        case "sfx": return user.Prefs[0] ? round(global.SFXVol * 10) : 0;
    }
    return 0;
};
global.NovaOptionSet = function(row, value) {
    var user = global.UserIndex;
    switch (row) {
        case "item_messages": global.Users[user].Prefs[4] = value == 1; break;
        case "crt": global.Users[user].Prefs[3] = value == 1; break;
        case "skip_title":
            global.CanSkipTitle = value == 1;
            global.NovaOptionWrite("Preferences", "CanSkipTitle", value);
            break;
        case "gore":
            global.Gore = value == 1;
            global.NovaOptionWrite("Preferences", "Gore", value);
            break;
        case "music":
            global.Users[user].Prefs[1] = value > 0;
            if (value > 0) {
                global.MusicVol = value / 10;
                global.NovaOptionWrite("Audio", "MusicVol", global.MusicVol);
            }
            User_UpdateMusicSFX();
            break;
        case "sfx":
            global.Users[user].Prefs[0] = value > 0;
            if (value > 0) {
                global.SFXVol = value / 10;
                global.NovaOptionWrite("Audio", "SFXVol", global.SFXVol);
            }
            User_UpdateMusicSFX();
            break;
    }
};
global.NovaResetBindings = function(device) {
    input_profile_reset_bindings(device == 0 ? "gamepad" : "keyboard");
    User_SaveControls();
    Bindings_GetIcons(device);
};
global.NovaOptionsReset = function(state) {
    if (state.confirm == "device") {
        global.NovaResetBindings(state.device);
        global.NovaRemapNotice(state, "Every action uses its default again.");
        return;
    }
    var tab = state.tabs[state.tab];
    if (tab == "Controls") {
        global.NovaResetBindings(0);
        global.NovaResetBindings(1);
        return;
    }
    var rows = global.NovaOptionRows(tab);
    for (var i = 0; i < array_length(rows); i++) global.NovaOptionSet(rows[i], global.NovaOptionInfo(rows[i]).fallback);
    User_Save();
};
// Remapper: one action at a time. Menu Confirm, Back and Pause stay fixed so a player cannot lock themselves out.
global.NovaRemapProfile = function(device) { return device == 0 ? "gamepad" : "keyboard"; };
global.NovaRemapItems = function(device) {
    var items = [];
    var groups = device == 1 ? [["Movement", [["up", "Up"], ["down", "Down"], ["left", "Left"], ["right", "Right"]]]] : [];
    array_push(groups,
        ["Combat", [["sword", "Sword"], ["item", "Item"], ["strafe", "Strafe"]]],
        ["World", [["action", "Interact"], ["map", "Map"], ["hud", "Status"]]],
        ["Menus", [["inventory", "Inventory"], ["nova_bag_previous", "Previous bag"], ["nova_bag_next", "Next bag"]]]);
    for (var g = 0; g < array_length(groups); g++) {
        array_push(items, {kind: "header", label: groups[g][0]});
        var actions = groups[g][1];
        for (var a = 0; a < array_length(actions); a++) array_push(items, {kind: "action", verb: actions[a][0], label: actions[a][1]});
    }
    array_push(items, {kind: "reset", label: "Restore all defaults"});
    array_push(items, {kind: "header", label: "Fixed"});
    array_push(items, {kind: "fixed", verb: "nova_confirm", label: "Confirm"}, {kind: "fixed", verb: "nova_back", label: "Back"}, {kind: "fixed", verb: "menu_access", label: "Pause"});
    return items;
};
global.NovaRemapFocusable = function(item) { return item.kind == "action" || item.kind == "reset"; };
global.NovaRemapVerbs = function(device) {
    var verbs = [];
    var items = global.NovaRemapItems(device);
    for (var i = 0; i < array_length(items); i++) if (items[i].kind == "action") array_push(verbs, items[i].verb);
    return verbs;
};
global.NovaDefaultBindings = undefined;
global.NovaDefaultBinding = function(verb, device) {
    if (global.NovaDefaultBindings == undefined) global.NovaDefaultBindings = __input_config_verbs();
    var set = device == 0 ? global.NovaDefaultBindings.gamepad : global.NovaDefaultBindings.keyboard;
    if (!variable_struct_exists(set, verb)) return input_binding_empty();
    var value = variable_struct_get(set, verb);
    return is_array(value) ? value[0] : value;
};
global.NovaBindingKey = function(binding) {
    if (!is_struct(binding) || binding.__type == undefined) return "none";
    var value = binding.__value;
    // Left and right modifier keys count as the same key.
    if (binding.__type == "key") {
        if (value == 160 || value == 161) value = vk_shift;
        if (value == 162 || value == 163) value = vk_control;
        if (value == 164 || value == 165) value = vk_alt;
    }
    var axis = variable_struct_exists(binding, "__axis_negative") && binding.__type == "gamepad axis" ? string(binding.__axis_negative) : "";
    return string(binding.__type) + ":" + string(value) + ":" + axis;
};
global.NovaRemapBinding = function(verb, device) {
    return input_binding_get(verb, 0, 0, global.NovaRemapProfile(device));
};
global.NovaRemapChanged = function(verb, device) {
    return global.NovaBindingKey(global.NovaRemapBinding(verb, device)) != global.NovaBindingKey(global.NovaDefaultBinding(verb, device));
};
global.NovaRemapCustom = function(device) {
    var verbs = global.NovaRemapVerbs(device);
    for (var i = 0; i < array_length(verbs); i++) if (global.NovaRemapChanged(verbs[i], device)) return true;
    return false;
};
global.NovaRemapLabel = function(verb, device) {
    var items = global.NovaRemapItems(device);
    for (var i = 0; i < array_length(items); i++) if (items[i].kind != "header" && items[i].verb == verb) return items[i].label;
    return verb;
};
// Assigning a button another action already uses swaps the two, so no action is left without one.
global.NovaRemapAssign = function(verb, binding, device) {
    var profile = global.NovaRemapProfile(device);
    var previous = input_binding_get(verb, 0, 0, profile);
    var moved = "";
    var verbs = global.NovaRemapVerbs(device);
    for (var i = 0; i < array_length(verbs); i++) {
        if (verbs[i] == verb || global.NovaBindingKey(input_binding_get(verbs[i], 0, 0, profile)) != global.NovaBindingKey(binding)) continue;
        input_binding_set(verbs[i], previous.__type == undefined ? input_binding_empty() : previous, 0, 0, profile);
        moved = global.NovaRemapLabel(verbs[i], device);
    }
    input_binding_set(verb, binding, 0, 0, profile);
    User_SaveControls();
    Bindings_GetIcons(device);
    return moved;
};
global.NovaRemapNotice = function(state, text) {
    state.notice = text;
    state.notice_time = current_time;
};
global.NovaRemapState = undefined;
global.NovaRemapEnd = function() {
    global.NovaRemapping = false;
    input_binding_scan_abort();
    input_binding_scan_params_clear();
    input_clear_momentary(true);
};
global.NovaRemapSuccess = function(binding) {
    var state = global.NovaRemapState;
    if (!is_struct(state) || !state.capture) return;
    var items = global.NovaRemapItems(state.device);
    var item = items[state.bind_focus];
    var moved = global.NovaRemapAssign(item.verb, binding, state.device);
    state.capture = false;
    global.NovaRemapEnd();
    global.NovaRemapNotice(state, item.label + " changed." + (moved == "" ? "" : " " + moved + " took its old " + (state.device == 0 ? "button." : "key.")));
    audio_play_sound(Sound_TextDone, 1, false);
};
global.NovaRemapFailure = function(code) {
    var state = global.NovaRemapState;
    if (!is_struct(state) || !state.capture) return;
    // An ignored or momentarily invalid source restarts the scan without leaving it.
    if (code == -10 || code == -11 || code == -21) {
        input_binding_scan_start(global.NovaRemapSuccess, global.NovaRemapFailure);
        return;
    }
    var items = global.NovaRemapItems(state.device);
    var item = items[state.bind_focus];
    state.capture = false;
    global.NovaRemapEnd();
    global.NovaRemapNotice(state, (code == -20 ? "Nothing pressed. " : "Stopped. ") + item.label + " is unchanged.");
};
global.NovaRemapBegin = function(state) {
    var device = state.device;
    if (device == 0) input_binding_scan_params_set([gp_axislh, gp_axislv, gp_axisrh, gp_axisrv, gp_padl, gp_padr, gp_padu, gp_padd],
        [gp_face1, gp_face2, gp_face3, gp_face4, gp_start, gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb, gp_stickl, gp_stickr]);
    else input_binding_scan_params_set([], [37, 39, 38, 40, 162, 163, 164, 165, 32, 16, 13, 36, 35, 33, 34, 45, 46, 188, 190, 220, 222, 189, 187, 186, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 110, 111, 106, 109, 107, "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]);
    state.capture = true;
    state.notice = "";
    global.NovaRemapState = state;
    global.NovaRemapping = true;
    input_binding_scan_start(global.NovaRemapSuccess, global.NovaRemapFailure);
};
global.NovaRemapCancelPressed = function() {
    if (keyboard_check_pressed(vk_escape) || input_check_pressed("menu_access")) return true;
    for (var pad = 0; pad < gamepad_get_device_count(); pad++) if (gamepad_is_connected(pad) && gamepad_button_check_pressed(pad, gp_select)) return true;
    return false;
};
global.NovaRemapMove = function(state, delta) {
    var items = global.NovaRemapItems(state.device);
    var count = array_length(items);
    var index = state.bind_focus;
    repeat (count) {
        index = (index + delta + count) mod count;
        if (global.NovaRemapFocusable(items[index])) break;
    }
    state.bind_focus = index;
    global.NovaRemapScroll(state);
};
global.NovaRemapStep = function(state, close, confirm, vertical, reset) {
    if (state.capture) {
        if (global.NovaRemapCancelPressed()) {
            input_binding_scan_abort();
            state.capture = false;
            global.NovaRemapEnd();
            global.NovaRemapNotice(state, "Cancelled.");
            audio_play_sound(Sound_Throw, 1, false);
        }
        return;
    }
    var items = global.NovaRemapItems(state.device);
    if (!global.NovaRemapFocusable(items[clamp(state.bind_focus, 0, array_length(items) - 1)])) global.NovaRemapMove(state, 1);
    var item = items[state.bind_focus];
    if (close) {
        state.page = "list";
        audio_play_sound(Sound_Throw, 1, false);
        input_clear_momentary(true);
        // Controls opened straight from pause returns to the pause list.
        if (state.origin == "controls") state.closed = true;
    } else if (vertical != 0) {
        global.NovaRemapMove(state, vertical);
        state.notice = "";
        audio_play_sound(Sound_Text, 1, false);
    } else if (reset && item.kind == "action" && global.NovaRemapChanged(item.verb, state.device)) {
        var moved = global.NovaRemapAssign(item.verb, global.NovaDefaultBinding(item.verb, state.device), state.device);
        global.NovaRemapNotice(state, item.label + " restored." + (moved == "" ? "" : " " + moved + " took its old " + (state.device == 0 ? "button." : "key.")));
        audio_play_sound(Sound_TextDone, 1, false);
        input_clear_momentary(true);
    } else if (confirm) {
        input_clear_momentary(true);
        if (item.kind == "reset") {
            if (global.NovaRemapCustom(state.device)) global.NovaOptionsConfirmOpen(state, "device");
        } else {
            audio_play_sound(Sound_TextDone, 1, false);
            global.NovaRemapBegin(state);
        }
    }
};
global.NovaOptionsConfirmOpen = function(state, kind) {
    state.confirm = kind;
    state.confirm_focus = 0;
    state.page = "confirm";
    audio_play_sound(Sound_TextDone, 1, false);
    input_clear_momentary(true);
};
global.NovaOptionsStep = function(state, close) {
    if (global.NovaRemapping && !(state.page == "device" && state.capture)) return "";
    var confirm = !keyboard_check(vk_alt) && input_check_pressed("menu_input");
    var vertical = input_check_pressed("down") - input_check_pressed("up");
    var horizontal = input_check_pressed("right") - input_check_pressed("left");
    var defaults = input_check_pressed("item");
    if (state.page == "confirm") {
        var back = state.confirm == "device" ? "device" : "list";
        if (close) {
            state.page = back;
            audio_play_sound(Sound_Throw, 1, false);
            input_clear_momentary(true);
            return "";
        }
        if (vertical != 0) {
            state.confirm_focus = 1 - state.confirm_focus;
            audio_play_sound(Sound_Text, 1, false);
        }
        if (confirm) {
            if (state.confirm_focus == 1) global.NovaOptionsReset(state);
            state.page = back;
            audio_play_sound(Sound_TextDone, 1, false);
            input_clear_momentary(true);
        }
        return "";
    }
    if (state.page == "device") {
        state.closed = false;
        global.NovaRemapStep(state, close, confirm, vertical, defaults);
        return state.closed ? "close" : "";
    }
    if (close) {
        audio_play_sound(Sound_Throw, 1, false);
        input_clear_momentary(true);
        return "close";
    }
    var tabs = array_length(state.tabs);
    var tab_delta = input_check_pressed("nova_bag_next") - input_check_pressed("nova_bag_previous");
    if (tab_delta != 0) {
        state.memory[state.tab] = state.focus;
        state.tab = (state.tab + tab_delta + tabs) mod tabs;
        state.focus = state.memory[state.tab];
        audio_play_sound(Sound_Text, 1, false);
        return "";
    }
    var rows = global.NovaOptionRows(state.tabs[state.tab]);
    var count = array_length(rows);
    state.focus = clamp(state.focus, 0, count - 1);
    if (vertical != 0) {
        state.focus = (state.focus + vertical + count) mod count;
        audio_play_sound(Sound_Text, 1, false);
    }
    var row = rows[state.focus];
    var info = global.NovaOptionInfo(row);
    if (horizontal != 0 && info.kind != "link") {
        var value = global.NovaOptionGet(row);
        var next = info.kind == "toggle" ? 1 - value : clamp(value + horizontal, 0, 10);
        if (next != value) global.NovaOptionSet(row, next);
        // The menu sound previews the new effects volume.
        audio_play_sound(Sound_Text, 1, false);
    }
    if (defaults && state.tabs[state.tab] != "About") {
        global.NovaOptionsConfirmOpen(state, "tab");
        return "";
    }
    if (!confirm) return "";
    audio_play_sound(Sound_TextDone, 1, false);
    input_clear_momentary(true);
    if (info.kind == "toggle") global.NovaOptionSet(row, 1 - global.NovaOptionGet(row));
    else if (row == "gamepad" || row == "keyboard") {
        state.device = row == "gamepad" ? 0 : 1;
        state.page = "device";
        state.bind_focus = 1;
        state.bind_scroll = 0;
        state.notice = "";
    } else if (info.kind == "link") return row;
    return "";
};

global.NovaOptText = function(text, px, py, active = false, scale = 1, align = fa_left, color = c_white) {
    draw_set_color(color);
    draw_set_halign(align);
    draw_set_valign(fa_top);
    draw_set_font(active ? global.MenuFont : global.MenuFont_Innactive);
    draw_text_transformed(px, py, text, scale, scale, 0);
    draw_set_color(c_white);
};
global.NovaOptArrow = function(px, py, direction) {
    draw_triangle(px - direction * 5, py - 4, px - direction * 5, py + 4, px, py, false);
};
// Nested pages name their parents in the header, so the player always knows the way back.
global.NovaMenuTitleParts = function(trail) {
    if (!is_array(trail)) trail = [trail];
    var font = draw_get_font();
    draw_set_font(global.MenuFont_Innactive);
    var parts = [];
    var cursor = global.NovaMenuLayout().left;
    for (var i = 0; i < array_length(trail); i++) {
        var width = string_width(trail[i]) * 1.25;
        array_push(parts, {label: trail[i], x: cursor, width: width, current: i == array_length(trail) - 1});
        cursor += width + 18;
    }
    draw_set_font(font);
    return parts;
};
global.NovaMenuTitle = function(trail) {
    var layout = global.NovaMenuLayout();
    var parts = global.NovaMenuTitleParts(trail);
    var alpha = draw_get_alpha();
    for (var i = 0; i < array_length(parts); i++) {
        draw_set_alpha(alpha * (parts[i].current ? 1 : 0.5));
        global.NovaOptText(parts[i].label, parts[i].x, layout.header_y, false, 1.25);
        if (!parts[i].current) global.NovaOptArrow(parts[i].x + parts[i].width + 11, layout.header_y + 10, 1);
    }
    draw_set_alpha(alpha);
};
global.NovaOptionsTrail = function(state) {
    var device = state.device == 0 ? "Gamepad" : "Keyboard";
    if (state.page == "device" || (state.page == "confirm" && state.confirm == "device"))
        return state.origin == "controls" ? ["Paused", "Controls", device] : ["Options", "Controls", device];
    return state.context == "pause" ? ["Paused", "Options"] : ["Options"];
};
// Menus show the D-pad for left and right; stick direction glyphs are hard to tell apart.
global.NovaDirectionBinding = function(verb) {
    var alternate = input_binding_get(verb, 0, 1);
    if (alternate.__type == "gamepad button" && alternate.__value >= gp_padu && alternate.__value <= gp_padr) return alternate;
    return global.NovaBinding(verb);
};
global.NovaMenuConfirmBinding = function() {
    var binding = input_binding_get("menu_input", 0, 1);
    return binding.__type == undefined ? global.NovaBinding("menu_input") : binding;
};
global.NovaOptionsFooter = function(state) {
    var prompts = [];
    var select = {binding: global.NovaMenuConfirmBinding(), label: "Select"};
    var defaults = {binding: global.NovaBinding("item"), label: "Defaults"};
    if (global.NovaRemapping && !(state.page == "device" && state.capture)) return prompts;
    if (state.page == "list") {
        var rows = global.NovaOptionRows(state.tabs[state.tab]);
        var info = global.NovaOptionInfo(rows[clamp(state.focus, 0, array_length(rows) - 1)]);
        if (info.kind != "link") array_push(prompts, {binding: global.NovaDirectionBinding("left"), binding2: global.NovaDirectionBinding("right"), label: "Change"});
        if (state.tabs[state.tab] != "About") array_push(prompts, defaults);
        if (info.kind == "link") array_push(prompts, select);
    } else if (state.page == "device") {
        var items = global.NovaRemapItems(state.device);
        var item = items[clamp(state.bind_focus, 0, array_length(items) - 1)];
        if (state.capture) array_push(prompts, {binding: global.NovaBinding("menu_access"), label: "Cancel"});
        else {
            if (item.kind == "action" && global.NovaRemapChanged(item.verb, state.device)) array_push(prompts, {binding: global.NovaBinding("item"), label: "Reset"});
            array_push(prompts, {binding: global.NovaMenuConfirmBinding(), label: item.kind == "reset" ? "Select" : "Remap"});
        }
    } else array_push(prompts, select);
    if (!(state.page == "device" && state.capture)) array_push(prompts, {binding: global.NovaBinding(global.NovaCloseVerb()), label: state.page == "list" && state.context == "title" ? "Close" : "Back"});
    var layout = global.NovaMenuLayout();
    var font = draw_get_font();
    draw_set_font(global.MenuFont_Innactive);
    prompts = global.NovaHintRow(prompts, layout.footer_right, layout.footer_y, 0.75, 0.75, 16, 12, layout.footer_right - layout.footer_left);
    draw_set_font(font);
    return prompts;
};
global.NovaOptionsTabs = function(state) {
    var layout = global.NovaOptionsLayout();
    var font = draw_get_font();
    draw_set_font(global.MenuFont_Innactive);
    var widths = [];
    var total = 0;
    for (var i = 0; i < array_length(state.tabs); i++) {
        widths[i] = string_width(state.tabs[i]) * 0.75;
        total += widths[i];
    }
    var gap = (layout.tabs_right - layout.tabs_left - total) / max(1, array_length(state.tabs) - 1);
    var tabs = [];
    var cursor = layout.tabs_left;
    for (var i = 0; i < array_length(state.tabs); i++) {
        array_push(tabs, {label: state.tabs[i], x: cursor, width: widths[i]});
        cursor += widths[i] + gap;
    }
    draw_set_font(font);
    return tabs;
};
global.NovaOptionsHelp = function(text) {
    var layout = global.NovaOptionsLayout();
    draw_set_font(global.MenuFont_Innactive);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(0.85);
    draw_text_ext_transformed(layout.help_x, layout.help_y, text, string_height("A") + 4, layout.help_width / 0.6, 0.6, 0.6, 0);
    draw_set_alpha(1);
};
// The tab strip stays in place on nested pages; only the list below it changes.
global.NovaOptionsDrawChrome = function(state) {
    var layout = global.NovaOptionsLayout();
    var tabs = global.NovaOptionsTabs(state);
    var browsing = state.page == "list";
    for (var i = 0; i < array_length(tabs); i++) {
        var active = i == state.tab;
        draw_set_alpha(active ? 1 : (browsing ? 0.6 : 0.3));
        global.NovaOptText(tabs[i].label, tabs[i].x, layout.tabs_y, active, 0.75);
        if (active) draw_rectangle(tabs[i].x, layout.tabs_y + 13, tabs[i].x + tabs[i].width - 1, layout.tabs_y + 14, false);
    }
    draw_set_alpha(1);
    if (browsing) {
        global.NovaPromptDraw(global.NovaBinding("nova_bag_previous"), "", 44, layout.tabs_y + 6, 0.75, 0.75, 16);
        global.NovaPromptDraw(global.NovaBinding("nova_bag_next"), "", 340, layout.tabs_y + 6, 0.75, 0.75, 16);
    }
    draw_set_alpha(0.3);
    draw_rectangle(40, layout.rule_y, 360, layout.rule_y, false);
    draw_rectangle(40, layout.help_rule_y, 360, layout.help_rule_y, false);
    draw_set_alpha(1);
};
global.NovaOptionsDrawList = function(state, selector, show_focus = true) {
    var layout = global.NovaOptionsLayout();
    var rows = global.NovaOptionRows(state.tabs[state.tab]);
    var focus = clamp(state.focus, 0, array_length(rows) - 1);
    for (var i = 0; i < array_length(rows); i++) {
        var info = global.NovaOptionInfo(rows[i]);
        var py = layout.rows_y + i * layout.row_height;
        var focused = i == focus;
        global.NovaOptText(info.label, layout.label_x, py, focused, 0.9);
        if (focused && show_focus) draw_sprite(sMenu_Selector_Active, selector, layout.label_x - 22, py);
        var cy = py + 7;
        draw_set_color(c_white);
        if (info.kind == "toggle") {
            var on = global.NovaOptionGet(rows[i]) == 1;
            draw_set_alpha(on || focused ? 1 : 0.6);
            global.NovaOptText(on ? "On" : "Off", layout.value_center, py + 1, focused, 0.85, fa_center);
        } else if (info.kind == "volume") {
            var value = global.NovaOptionGet(rows[i]);
            for (var s = 0; s < 10; s++) {
                var sx = layout.bar_x + s * layout.bar_segment;
                draw_set_alpha(s < value ? 1 : 0.22);
                draw_rectangle(sx, cy - 4, sx + layout.bar_segment - 3, cy + 4, false);
            }
            draw_set_alpha(focused ? 1 : 0.7);
            global.NovaOptText(string(value), 356, py + 1, false, 0.75, fa_right);
        }
        if (rows[i] == "gamepad" || rows[i] == "keyboard") {
            var custom = global.NovaRemapCustom(rows[i] == "gamepad" ? 0 : 1);
            draw_set_alpha(focused ? 1 : 0.7);
            global.NovaOptText(custom ? "Custom" : "Default", layout.value_center, py + 1, false, 0.85, fa_center, custom ? global.NovaRemapChangedColor : c_white);
        }
        draw_set_alpha(focused ? 1 : 0.45);
        if (info.kind == "link") global.NovaOptArrow(layout.arrow_right, cy, 1);
        else if (focused) {
            global.NovaOptArrow(layout.arrow_left, cy, -1);
            global.NovaOptArrow(layout.arrow_right, cy, 1);
        }
        draw_set_alpha(1);
    }
    global.NovaOptionsHelp(global.NovaOptionInfo(rows[focus]).help);
};
global.NovaRemapChangedColor = make_color_rgb(248, 208, 96);
global.NovaRemapRows = function(state) {
    var layout = global.NovaOptionsLayout();
    var items = global.NovaRemapItems(state.device);
    var rows = [];
    var cursor = 0;
    for (var i = 0; i < array_length(items); i++) {
        var height = items[i].kind == "header" ? layout.header_height : layout.binding_height;
        array_push(rows, {item: items[i], y: cursor, height: height});
        cursor += height;
    }
    return {rows: rows, total: cursor, visible: layout.list_bottom - layout.list_top};
};
// Keeps the highlighted action, and the group heading above it, inside the list area.
global.NovaRemapScroll = function(state) {
    var list = global.NovaRemapRows(state);
    var row = list.rows[state.bind_focus];
    var top = row.y;
    if (state.bind_focus > 0 && list.rows[state.bind_focus - 1].item.kind == "header") top = list.rows[state.bind_focus - 1].y;
    if (top < state.bind_scroll) state.bind_scroll = top;
    if (row.y + row.height > state.bind_scroll + list.visible) state.bind_scroll = row.y + row.height - list.visible;
    state.bind_scroll = clamp(state.bind_scroll, 0, max(0, list.total - list.visible));
};
global.NovaBindingDraw = function(binding, right, py, alpha) {
    draw_set_alpha(alpha);
    if (global.NovaGlyph(binding) >= 0) draw_sprite_stretched_ext(sNovaButtons, global.NovaGlyph(binding), right - 14, py - 1, 14, 14, c_white, alpha);
    else global.NovaOptText(binding.__type == undefined ? "-" : global.NovaKeyLabel(binding), right, py, false, 0.6, fa_right);
    draw_set_alpha(1);
};
global.NovaOptionsDrawDevice = function(state, selector) {
    var layout = global.NovaOptionsLayout();
    var device = state.device;
    var list = global.NovaRemapRows(state);
    var custom = global.NovaRemapCustom(device);
    for (var i = 0; i < array_length(list.rows); i++) {
        var row = list.rows[i];
        var item = row.item;
        var py = layout.list_top + row.y - state.bind_scroll;
        if (py < layout.list_top - 0.5 || py + row.height > layout.list_bottom + 0.5) continue;
        var focused = i == state.bind_focus && state.page == "device";
        if (item.kind == "header") {
            draw_set_alpha(0.55);
            global.NovaOptText(string_upper(item.label), 44, py + 3, false, 0.55);
            draw_set_alpha(1);
            continue;
        }
        var capturing = focused && state.capture;
        if (capturing) {
            draw_set_alpha(0.15);
            draw_rectangle(52, py - 1, 346, py + row.height - 3, false);
            draw_set_alpha(1);
        }
        if (focused && !state.capture) draw_sprite(sMenu_Selector_Active, selector, 38, py - 1);
        if (item.kind == "reset") {
            draw_set_alpha(custom ? 1 : 0.4);
            global.NovaOptText(item.label, 60, py, focused, 0.75);
            draw_set_alpha(1);
            continue;
        }
        var binding = global.NovaRemapBinding(item.verb, device);
        if (item.kind == "fixed") {
            draw_set_alpha(0.45);
            global.NovaOptText(item.label, 60, py, false, 0.75);
            global.NovaBindingDraw(binding, 330, py, 0.45);
            continue;
        }
        var changed = global.NovaRemapChanged(item.verb, device);
        // Changed actions use both a colour and a dot, so the cue does not rely on colour alone.
        global.NovaOptText(item.label, 60, py, focused, 0.75, fa_left, changed && !focused ? global.NovaRemapChangedColor : c_white);
        if (changed) {
            draw_set_color(global.NovaRemapChangedColor);
            draw_circle(339, py + 6, 2, false);
            draw_set_color(c_white);
        }
        if (capturing) global.NovaOptText("Press...", 330, py, true, 0.6, fa_right);
        else global.NovaBindingDraw(binding, 330, py, 1);
    }
    draw_set_alpha(0.6);
    if (state.bind_scroll > 0) draw_triangle(352, layout.list_top + 6, 360, layout.list_top + 6, 356, layout.list_top + 1, false);
    if (state.bind_scroll < list.total - list.visible) draw_triangle(352, layout.list_bottom - 6, 360, layout.list_bottom - 6, 356, layout.list_bottom - 1, false);
    draw_set_alpha(1);
    var noun = device == 0 ? "button" : "key";
    var item = list.rows[state.bind_focus].item;
    if (state.capture) {
        var seconds = ceil(max(0, input_binding_scan_time_remaining()) / 1000);
        global.NovaOptionsHelp("Press the new " + noun + " for " + item.label + ". " + (device == 0 ? "Select" : "Esc") + " cancels." + (seconds > 0 ? " " + string(seconds) : ""));
    } else if (state.notice != "" && current_time - state.notice_time < 4000) global.NovaOptionsHelp(state.notice);
    else if (item.kind == "reset") global.NovaOptionsHelp(custom ? "Return every action on this page to its default." : "Every action already uses its default.");
    else if (global.NovaRemapChanged(item.verb, device)) {
        var text = "Changed. Default:";
        global.NovaOptionsHelp(text);
        draw_set_font(global.MenuFont_Innactive);
        var right = layout.help_x + string_width(text) * 0.6 + 20;
        global.NovaBindingDraw(global.NovaDefaultBinding(item.verb, device), right, layout.help_y, 0.85);
    } else global.NovaOptionsHelp("Remap to choose a new " + noun + ". One already in use swaps with this action.");
};
// Confirmations open over the dimmed page they affect instead of replacing it.
global.NovaOptionsDrawConfirm = function(state, selector) {
    var subject, detail;
    if (state.confirm == "device") {
        subject = state.device == 0 ? "gamepad controls" : "keyboard controls";
        detail = "Your custom mapping will be replaced.";
    } else if (state.tabs[state.tab] == "Controls") {
        subject = "controls";
        detail = "Gamepad and keyboard mappings are both replaced.";
    } else {
        subject = string_lower(state.tabs[state.tab]) + " settings";
        detail = "Other tabs keep their settings.";
    }
    global.NovaDialogDraw("Restore default " + subject + "?", detail, state.confirm_focus, selector);
};
// A Cancel-first confirmation drawn over the dimmed page it affects.
global.NovaDialogDraw = function(question, detail, focus, selector, confirm = "Restore defaults") {
    var menu = global.NovaMenuLayout();
    var dialog = global.NovaOptionsDialog();
    draw_set_color(c_black);
    draw_set_alpha(0.55);
    draw_rectangle(menu.x, menu.y, menu.x + menu.width, menu.y + menu.height, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_sprite_stretched(sMenuWin, 0, dialog.x, dialog.y, dialog.width, dialog.height);
    global.NovaOptText(question, 200, dialog.y + 14, false, 0.9, fa_center);
    global.NovaOptText(detail, 200, dialog.y + 36, false, 0.7, fa_center);
    var rows = ["Cancel", confirm];
    for (var i = 0; i < 2; i++) {
        var py = dialog.y + 62 + i * 24;
        global.NovaOptText(rows[i], dialog.x + 60, py, focus == i, 0.9);
        if (focus == i) draw_sprite(sMenu_Selector_Active, selector, dialog.x + 38, py);
    }
};
global.NovaOptionsDialog = function() {
    return {x: 60, y: 54, width: 280, height: 118};
};
global.NovaOptionsDraw = function(state, selector) {
    var layout = global.NovaMenuLayout();
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_sprite_stretched(sMenuWin, 0, layout.x, layout.y, layout.width, layout.height);
    global.NovaMenuTitle(global.NovaOptionsTrail(state));
    global.NovaOptionsDrawChrome(state);
    var underneath = state.page == "confirm" ? (state.confirm == "device" ? "device" : "list") : state.page;
    if (underneath == "device") global.NovaOptionsDrawDevice(state, selector);
    else global.NovaOptionsDrawList(state, selector, state.page != "confirm");
    if (state.page == "confirm") global.NovaOptionsDrawConfirm(state, selector);
    draw_set_font(global.MenuFont_Innactive);
    var prompts = global.NovaOptionsFooter(state);
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
};
