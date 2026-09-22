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
        bar_x: 246, bar_segment: 8, help_rule_y: 184, help_y: 192, help_x: 44, help_width: 316};
};
global.NovaOptionsState = function(context) {
    var tabs = ["Game", "Display", "Audio", "Controls"];
    if (context == "title") array_push(tabs, "About");
    return {context: context, tabs: tabs, tab: 0, focus: 0, memory: array_create(array_length(tabs), 0),
        page: "list", device: 0, device_focus: 0, confirm: "", confirm_focus: 0};
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
global.NovaRemapStart = function(device) {
    // Gameplay rooms deactivate instances outside the camera; keep the scanner inside it.
    var px = instance_exists(oCamera) ? oCamera.X + 8 : -100;
    var py = instance_exists(oCamera) ? oCamera.Y + 8 : -100;
    instance_create_depth(px, py, 0, oInputRemap, {InputIndex: device});
};
global.NovaOptionsStep = function(state, close) {
    if (global.NovaRemapping) return "";
    var confirm = !keyboard_check(vk_alt) && input_check_pressed("menu_input");
    var vertical = input_check_pressed("down") - input_check_pressed("up");
    var horizontal = input_check_pressed("right") - input_check_pressed("left");
    if (state.page == "confirm" || state.page == "device") {
        var back = state.page == "confirm" && state.confirm == "device" ? "device" : "list";
        if (close) {
            state.page = back;
            audio_play_sound(Sound_Throw, 1, false);
            input_clear_momentary(true);
            return "";
        }
        if (vertical != 0 || horizontal != 0) {
            if (state.page == "confirm") state.confirm_focus = 1 - state.confirm_focus;
            else state.device_focus = 1 - state.device_focus;
            audio_play_sound(Sound_Text, 1, false);
        }
        if (confirm) {
            if (state.page == "confirm") {
                if (state.confirm_focus == 1) global.NovaOptionsReset(state);
                state.page = back;
            } else if (state.device_focus == 0) global.NovaRemapStart(state.device);
            else {
                state.confirm = "device";
                state.confirm_focus = 0;
                state.page = "confirm";
            }
            audio_play_sound(Sound_TextDone, 1, false);
            input_clear_momentary(true);
        }
        return "";
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
    if (input_check_pressed("item") && state.tabs[state.tab] != "About") {
        state.confirm = "tab";
        state.confirm_focus = 0;
        state.page = "confirm";
        audio_play_sound(Sound_TextDone, 1, false);
        input_clear_momentary(true);
        return "";
    }
    if (!confirm) return "";
    audio_play_sound(Sound_TextDone, 1, false);
    input_clear_momentary(true);
    if (info.kind == "toggle") global.NovaOptionSet(row, 1 - global.NovaOptionGet(row));
    else if (row == "gamepad" || row == "keyboard") {
        state.device = row == "gamepad" ? 0 : 1;
        state.device_focus = 0;
        state.page = "device";
    } else if (info.kind == "link") return row;
    return "";
};

global.NovaOptText = function(text, px, py, active = false, scale = 1, align = fa_left) {
    draw_set_color(c_white);
    draw_set_halign(align);
    draw_set_valign(fa_top);
    draw_set_font(active ? global.MenuFont : global.MenuFont_Innactive);
    draw_text_transformed(px, py, text, scale, scale, 0);
};
global.NovaOptArrow = function(px, py, direction) {
    draw_triangle(px - direction * 5, py - 4, px - direction * 5, py + 4, px, py, false);
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
    if (global.NovaRemapping) return prompts;
    if (state.page == "list") {
        var rows = global.NovaOptionRows(state.tabs[state.tab]);
        var info = global.NovaOptionInfo(rows[clamp(state.focus, 0, array_length(rows) - 1)]);
        if (info.kind != "link") array_push(prompts, {binding: global.NovaDirectionBinding("left"), binding2: global.NovaDirectionBinding("right"), label: "Change"});
        if (state.tabs[state.tab] != "About") array_push(prompts, {binding: global.NovaBinding("item"), label: "Defaults"});
        if (info.kind == "link") array_push(prompts, select);
    } else array_push(prompts, select);
    array_push(prompts, {binding: global.NovaBinding(global.NovaCloseVerb()), label: "Close"});
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
global.NovaOptionsDrawList = function(state, selector) {
    var layout = global.NovaOptionsLayout();
    var tabs = global.NovaOptionsTabs(state);
    for (var i = 0; i < array_length(tabs); i++) {
        var active = i == state.tab;
        draw_set_alpha(active ? 1 : 0.6);
        global.NovaOptText(tabs[i].label, tabs[i].x, layout.tabs_y, active, 0.75);
        if (active) draw_rectangle(tabs[i].x, layout.tabs_y + 13, tabs[i].x + tabs[i].width - 1, layout.tabs_y + 14, false);
    }
    draw_set_alpha(1);
    global.NovaPromptDraw(global.NovaBinding("nova_bag_previous"), "", 44, layout.tabs_y + 6, 0.75, 0.75, 16);
    global.NovaPromptDraw(global.NovaBinding("nova_bag_next"), "", 340, layout.tabs_y + 6, 0.75, 0.75, 16);
    draw_set_alpha(0.3);
    draw_rectangle(40, layout.rule_y, 360, layout.rule_y, false);
    draw_rectangle(40, layout.help_rule_y, 360, layout.help_rule_y, false);
    draw_set_alpha(1);
    var rows = global.NovaOptionRows(state.tabs[state.tab]);
    var focus = clamp(state.focus, 0, array_length(rows) - 1);
    for (var i = 0; i < array_length(rows); i++) {
        var info = global.NovaOptionInfo(rows[i]);
        var py = layout.rows_y + i * layout.row_height;
        var focused = i == focus;
        global.NovaOptText(info.label, layout.label_x, py, focused, 0.9);
        if (focused) draw_sprite(sMenu_Selector_Active, selector, layout.label_x - 22, py);
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
        draw_set_alpha(focused ? 1 : 0.45);
        if (info.kind == "link") global.NovaOptArrow(layout.arrow_right, cy, 1);
        else if (focused) {
            global.NovaOptArrow(layout.arrow_left, cy, -1);
            global.NovaOptArrow(layout.arrow_right, cy, 1);
        }
        draw_set_alpha(1);
    }
    var help = global.NovaOptionInfo(rows[focus]).help;
    draw_set_font(global.MenuFont_Innactive);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_alpha(0.85);
    draw_text_ext_transformed(layout.help_x, layout.help_y, help, string_height("A") + 4, layout.help_width / 0.6, 0.6, 0.6, 0);
    draw_set_alpha(1);
};
global.NovaOptionsDrawDevice = function(state, selector) {
    var device = state.device;
    global.NovaOptText("Remap", 60, 26, state.device_focus == 0);
    global.NovaOptText("Restore defaults", 212, 26, state.device_focus == 1);
    draw_sprite(sMenu_Selector_Active, selector, state.device_focus == 0 ? 38 : 190, 26);
    var labels = ["Sword", "Interact", "Item", "Map", "Strafe", "Inventory", "Menu", "Status", "Up", "Down", "Left", "Right", "Previous bag", "Next bag"];
    for (var i = 0; i < global.BindingIconCount[device]; i++) {
        var px = 44 + (i div 7) * 160;
        var py = 66 + (i mod 7) * 20;
        var scanning = global.NovaRemapping && i == global.BindingRemap_VerbIndex;
        global.NovaOptText(labels[global.BindingVerbs[device][i]], px, py, scanning, 0.75);
        var label = scanning ? "Press..." : global.NovaKeyLabel(global.NovaBinding(GetInputVerbStr(global.BindingVerbs[device][i]), device == 0 ? "gamepad" : "keyboard"));
        global.NovaOptText(label, px + 143, py, scanning, 0.6, fa_right);
    }
    if (global.NovaRemapping) global.NovaOptText("Follow the highlighted action", 200, 236, false, 0.75, fa_center);
};
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
    global.NovaOptText("Restore default " + subject + "?", 200, 54, false, 1, fa_center);
    global.NovaOptText(detail, 200, 84, false, 0.8, fa_center);
    var rows = ["Cancel", "Restore defaults"];
    for (var i = 0; i < 2; i++) {
        var py = 142 + i * 40;
        global.NovaOptText(rows[i], 60, py, state.confirm_focus == i);
        if (state.confirm_focus == i) draw_sprite(sMenu_Selector_Active, selector, 38, py);
    }
};
global.NovaOptionsDraw = function(state, selector) {
    var layout = global.NovaMenuLayout();
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_sprite_stretched(sMenuWin, 0, layout.x, layout.y, layout.width, layout.height);
    var title = "Options";
    if (state.page == "device" || (state.page == "confirm" && state.confirm == "device")) title = state.device == 0 ? "Gamepad" : "Keyboard";
    global.NovaOptText(title, layout.left, layout.header_y, false, 1.25);
    switch (state.page) {
        case "device": global.NovaOptionsDrawDevice(state, selector); break;
        case "confirm": global.NovaOptionsDrawConfirm(state, selector); break;
        default: global.NovaOptionsDrawList(state, selector); break;
    }
    draw_set_font(global.MenuFont_Innactive);
    var prompts = global.NovaOptionsFooter(state);
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
};
// Pause renders the menu at the adventure menu's 4x canvas, then scales it like that menu.
global.NovaOptionsOverlay = function(state, alpha, width, height) {
    if (!surface_exists(global.NovaOptionsSurface)) global.NovaOptionsSurface = surface_create(1600, 1200);
    surface_set_target(global.NovaOptionsSurface);
    draw_clear_alpha(c_black, 0);
    var world = matrix_get(matrix_world);
    matrix_set(matrix_world, matrix_build(0, 152, 0, 0, 0, 0, 4, 4, 1));
    global.NovaOptionsDraw(state, (current_time div 133) mod 2);
    matrix_set(matrix_world, world);
    surface_reset_target();
    draw_set_color(c_black);
    draw_set_alpha(0.35 * alpha);
    draw_rectangle(0, 0, width, height, false);
    draw_set_color(c_white);
    draw_surface_stretched_ext(global.NovaOptionsSurface, 0, 0, width, height, c_white, alpha);
    draw_set_alpha(1);
};
