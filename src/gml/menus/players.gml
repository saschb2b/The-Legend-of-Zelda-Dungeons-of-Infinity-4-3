// Players: save cards, the Details page with lifetime records, rename and a safe delete.
// Drawing uses the adventure menu's view coordinates, whose top edge is y = -38.
NovaPlayerDialog = false;
NovaPlayerDialogFocus = 0;
NovaRenameNotice = "";
NovaPlayerRecords = [
    {label: "Games played", stat: 0, icon: sHUD_Map, frame: 0},
    {label: "Games won", stat: 1, icon: sHUD_Crystal, frame: 0},
    {label: "Deaths", stat: 2, icon: sHUD_Heart, frame: 0},
    {label: "Monsters defeated", stat: 3, icon: sHUD_Icon_Attack, frame: 0},
    {label: "Rupees collected", stat: 4, icon: sHUD_Icon_Rupees, frame: 0},
    {label: "Treasures opened", stat: 5, icon: sItem_Treasure, frame: 0},
    {label: "Best time", stat: 6, icon: -1, frame: 0}
];

function NovaPlayTime(microseconds) {
    var minutes = floor(max(0, microseconds) / 60000000);
    if (minutes >= 60) return string(minutes div 60) + "h " + string(minutes mod 60) + "m";
    return string(max(minutes, microseconds > 0 ? 1 : 0)) + "m";
}
function NovaPlayedKey(player) { return "Player" + string(player); }
function NovaPlayedMark() {
    ini_open("nova-menu.ini");
    ini_write_real("LastPlayed", NovaPlayedKey(global.UserIndex), date_current_datetime());
    ini_close();
}
function NovaPlayedForget(player) {
    ini_open("nova-menu.ini");
    ini_key_delete("LastPlayed", NovaPlayedKey(player));
    ini_close();
}
// Returns "", "today", "yesterday" or "N days ago"; an unset or future clock shows nothing.
function NovaPlayedText(player) {
    ini_open("nova-menu.ini");
    var played = ini_read_real("LastPlayed", NovaPlayedKey(player), 0);
    ini_close();
    if (played <= 0) return "";
    var now = date_current_datetime();
    var days = floor(now) - floor(played);
    if (days < 0) return "";
    if (days == 0) return "today";
    if (days == 1) return "yesterday";
    return string(days) + " days ago";
}
function NovaPlayerStat(player, stat) {
    var stats = global.Users[player].Stats;
    return is_array(stats) && array_length(stats) > stat && is_numeric(stats[stat]) ? stats[stat] : 0;
}
function NovaPlayerRun(player) {
    var summary = NovaProfileSummary(player);
    var run = {summary: summary, time: 0, bosses: 0, bonus: 0, preset: 0};
    if (!summary.saved) return run;
    var save = global.Users[player].SaveData;
    if (variable_struct_exists(save, "TimePlayed") && is_numeric(save.TimePlayed)) run.time = save.TimePlayed;
    if (variable_struct_exists(save, "BossesDefeated") && is_numeric(save.BossesDefeated)) run.bosses = save.BossesDefeated;
    if (variable_struct_exists(save, "BonusItem") && is_numeric(save.BonusItem)) run.bonus = clamp(floor(save.BonusItem), 0, 7);
    if (variable_struct_exists(save, "NovaChallengeOptions") && is_array(save.NovaChallengeOptions) && array_length(save.NovaChallengeOptions) == 12)
        run.preset = NovaPresetIndex(save.NovaChallengeOptions);
    return run;
}
function NovaPlayersFocusCurrent() {
    var rows = NovaPlayerRows();
    var focus = 0;
    for (var i = 0; i < array_length(rows); i++) if (rows[i] == global.UserIndex && global.Users[rows[i]].Name != "") focus = i;
    return focus;
}

function NovaPlayersLayout() {
    return {x: 52, right: 364, top: 16, height: 32, gap: 4, sprite_x: 58, name_x: 80, stats_x: 292, selector: 30, rule_y: 204, help_y: 208};
}
function NovaPlayerCardFrame(px, py, right, height, focused, dashed) {
    if (focused) {
        draw_set_alpha(0.14);
        draw_rectangle(px, py, right, py + height, false);
    }
    draw_set_color(focused ? NovaSetupChanged : c_white);
    draw_set_alpha(focused ? 1 : 0.22);
    if (dashed) {
        for (var dx = px; dx < right; dx += 8) {
            draw_line(dx, py, min(dx + 4, right), py);
            draw_line(dx, py + height, min(dx + 4, right), py + height);
        }
        for (var dy = py; dy < py + height; dy += 8) {
            draw_line(px, dy, px, min(dy + 4, py + height));
            draw_line(right, dy, right, min(dy + 4, py + height));
        }
    } else draw_rectangle(px, py, right, py + height, true);
    draw_set_color(c_white);
    draw_set_alpha(1);
}
function NovaPlayersDraw() {
    var layout = NovaPlayersLayout();
    var rows = NovaPlayerRows();
    for (var i = 0; i < array_length(rows); i++) {
        var player = rows[i];
        var py = layout.top + i * (layout.height + layout.gap);
        var focused = i == NovaFocus;
        var empty = global.Users[player].Name == "";
        NovaPlayerCardFrame(layout.x, py, layout.right, layout.height, focused, empty);
        if (focused) draw_sprite(sMenu_Selector_Active, Selector_Frame, layout.selector, py + 8);
        if (empty) {
            global.NovaOptText("+  New player", (layout.x + layout.right) / 2, py + 9, focused, 0.85, fa_center);
            continue;
        }
        var run = NovaPlayerRun(player);
        var summary = run.summary;
        var remembered = summary.saved ? summary.character : NovaSetupLoad(player).character;
        draw_sprite_ext(global.CharacterSprites, remembered, layout.sprite_x, py + 4, 1, 1, 0, c_white, summary.saved ? 1 : 0.55);
        global.NovaOptText(summary.name, layout.name_x, py + 3, focused, 0.8);
        if (player == global.UserIndex) {
            draw_set_font(global.MenuFont_Innactive);
            var tag_x = layout.name_x + string_width(summary.name) * 0.8 + 8;
            global.NovaOptText("CURRENT", tag_x, py + 6, false, 0.5, fa_left, NovaSetupChanged);
        }
        var line = summary.saved ? "Floor " + string(summary.floor) + "  " + NovaPlayTime(run.time) : "No saved run";
        draw_set_alpha(summary.saved ? 0.9 : 0.55);
        global.NovaOptText(line, layout.name_x, py + 18, false, 0.6);
        draw_set_alpha(1);
        if (summary.level > 0) {
            draw_set_font(global.MenuFont_Innactive);
            NovaChallengeBadge(layout.name_x + string_width(line) * 0.6 + 8, py + 18, summary.level);
        }
        // Headline stats: hearts on the current run, then lifetime wins and deaths.
        if (summary.saved) {
            draw_sprite(sHUD_Heart, 4, layout.stats_x, py + 5);
            global.NovaOptText(string(floor(summary.health)) + "/" + string(summary.hearts), layout.stats_x + 10, py + 3, false, 0.6);
        }
        NovaIconFit(sHUD_Crystal, 0, layout.stats_x, py + 18, 9);
        global.NovaOptText(string(NovaPlayerStat(player, 1)), layout.stats_x + 11, py + 18, false, 0.6);
        draw_sprite(sHUD_Heart, 0, layout.stats_x + 36, py + 19);
        global.NovaOptText(string(NovaPlayerStat(player, 2)), layout.stats_x + 46, py + 18, false, 0.6);
    }
    draw_set_alpha(0.3);
    draw_rectangle(40, layout.rule_y, 360, layout.rule_y, false);
    draw_set_alpha(1);
    global.NovaOptText(NovaPlayersHelp(), 44, layout.help_y, false, 0.6);
    var prompts = NovaPlayersFooter();
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
}
function NovaPlayersHelp() {
    var rows = NovaPlayerRows();
    var player = rows[clamp(NovaFocus, 0, array_length(rows) - 1)];
    if (global.Users[player].Name == "") return "Create a player with their own saves, records and controls.";
    var summary = NovaProfileSummary(player);
    var played = NovaPlayedText(player);
    var text = summary.saved ? "Resume on floor " + string(summary.floor) + "." : "Start a new adventure.";
    return played == "" ? text : text + " Last played " + played + ".";
}
function NovaPlayersFooter() {
    var rows = NovaPlayerRows();
    var player = rows[clamp(NovaFocus, 0, array_length(rows) - 1)];
    var details = global.Users[player].Name != "" ? {binding: global.NovaBinding("item"), label: "Details"} : undefined;
    return NovaFooterLayout(global.Users[player].Name == "" ? "Create" : "Select", details);
}

function NovaDetailsLayout() {
    return {sprite_x: 44, sprite_y: 20, info_x: 92, records_y: 86, record_h: 15, column_a: 44, column_b: 206, column_w: 150,
        actions_y: 160, action_x: [60, 150, 240], rule_y: 184, help_y: 192};
}
function NovaDetailsActions() { return ["Play", "Rename", "Delete player"]; }
function NovaDetailsDraw() {
    var layout = NovaDetailsLayout();
    var player = global.UserIndex;
    var run = NovaPlayerRun(player);
    var summary = run.summary;
    draw_sprite_ext(global.CharacterSprites, summary.saved ? summary.character : NovaSetupLoad(player).character, layout.sprite_x, layout.sprite_y, 2, 2, 0, c_white, 1);
    global.NovaOptText(summary.name, layout.info_x, layout.sprite_y, false, 1);
    if (summary.saved) {
        global.NovaOptText("Floor " + string(summary.floor) + "   " + NovaPlayTime(run.time) + "   Bosses " + string(run.bosses), layout.info_x, layout.sprite_y + 18, false, 0.65);
        draw_sprite(sHUD_Heart, 4, layout.info_x, layout.sprite_y + 33);
        global.NovaOptText(string(floor(summary.health)) + "/" + string(summary.hearts) + "   " + (run.bonus == 0 ? "No bonus" : NovaBonusNames[run.bonus]), layout.info_x + 10, layout.sprite_y + 31, false, 0.65);
        var preset = run.preset < 0 ? "Custom" : NovaPresets[run.preset].name;
        global.NovaOptText(preset + (summary.level > 0 ? "  Level " + string(summary.level) : ""), layout.info_x, layout.sprite_y + 44, false, 0.65, fa_left, summary.level > 0 ? NovaSetupChanged : c_white);
    } else {
        draw_set_alpha(0.6);
        global.NovaOptText("No saved run", layout.info_x, layout.sprite_y + 18, false, 0.65);
        draw_set_alpha(1);
    }
    draw_set_alpha(0.55);
    global.NovaOptText("RECORDS", layout.column_a, layout.records_y - 12, false, 0.55);
    draw_set_alpha(1);
    for (var i = 0; i < array_length(NovaPlayerRecords); i++) {
        var record = NovaPlayerRecords[i];
        var px = i mod 2 == 0 ? layout.column_a : layout.column_b;
        var py = layout.records_y + (i div 2) * layout.record_h;
        var value = NovaPlayerStat(player, record.stat);
        var best = record.stat == 6;
        if (record.icon != -1) NovaIconFit(record.icon, record.frame, px, py, 9);
        global.NovaOptText(record.label, px + 13, py, false, 0.6, fa_left, best && value > 0 ? NovaSetupChanged : c_white);
        global.NovaOptText(best ? (value > 0 ? Time_Str(value) : "-") : string(value), px + layout.column_w, py, false, 0.6, fa_right, best && value > 0 ? NovaSetupChanged : c_white);
    }
    var actions = NovaDetailsActions();
    for (var i = 0; i < array_length(actions); i++) {
        var focused = i == NovaFocus && !NovaPlayerDialog;
        global.NovaOptText(actions[i], layout.action_x[i], layout.actions_y, focused, 0.85);
        if (focused) draw_sprite(sMenu_Selector_Active, Selector_Frame, layout.action_x[i] - 22, layout.actions_y);
    }
    draw_set_alpha(0.3);
    draw_rectangle(40, layout.rule_y, 360, layout.rule_y, false);
    draw_set_alpha(1);
    var help = ["Return to the adventure menu as " + summary.name + ".", "Change this player's name.", "Erase this player's save and records after you confirm."];
    global.NovaOptionsHelp(help[clamp(NovaFocus, 0, 2)]);
    if (NovaPlayerDialog)
        global.NovaDialogDraw("Delete " + summary.name + "?", summary.saved ? "The floor " + string(summary.floor) + " run and all records are erased." : "All of this player's records are erased.", NovaPlayerDialogFocus, Selector_Frame, "Delete player");
    var prompts = NovaFooterLayout("Select", undefined, "Back");
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
}
// Returns true when the dialog consumed the input.
function NovaPlayerDialogStep(close) {
    if (!NovaPlayerDialog) return false;
    if (close) {
        NovaPlayerDialog = false;
        audio_play_sound(Sound_Throw, 1, false);
    } else if (input_check_pressed("down") || input_check_pressed("up")) {
        NovaPlayerDialogFocus = 1 - NovaPlayerDialogFocus;
        audio_play_sound(Sound_Text, 1, false);
    } else if (!keyboard_check(vk_alt) && input_check_pressed("menu_input")) {
        NovaPlayerDialog = false;
        if (NovaPlayerDialogFocus == 1) {
            NovaSetupForget(global.UserIndex);
            NovaPlayedForget(global.UserIndex);
            User_Delete();
            NovaRestorePlayer();
            NovaGo("players", 0);
        }
        audio_play_sound(Sound_TextDone, 1, false);
    }
    input_clear_momentary(true);
    return true;
}

function NovaRenameSave() {
    if (string_length(string_trim(NovaName)) == 0) {
        NovaRenameNotice = "Enter at least one letter.";
        return;
    }
    global.Users[global.UserIndex].Name = NovaName;
    User_Save();
    NovaGo("player");
}
function NovaRenameFooter() {
    return NovaFooterLayout("Select", [
        {binding: global.NovaBinding("nova_bag_previous"), label: "Erase"},
        {binding: global.NovaBinding("nova_bag_next"), label: "Space"}], "Back");
}
