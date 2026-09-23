// Pause menu in the Options panel style: safe choices first, a run summary and explicit quit consequences.
// Drawing uses the adventure menu's 400x300 view, whose top edge is y = -38.
global.NovaPauseRows = ["Resume", "Options", "Controls", "Start over", "Quit to title", "Quit to desktop"];
// The menu's portrait sprite is freed when the dungeon starts, so gameplay draws from the sheet directly.
global.NovaCharacterDraw = function(index, px, py, scale) {
    var sheet = global.LinkCharacterSpr[clamp(index, 0, 8)];
    draw_sprite_part_ext(sheet, 0, 48, 16, 16, 16, px, py + 8 * scale, scale, scale, c_white, 1);
    draw_sprite_part_ext(sheet, 0, 16, 0, 16, 16, px, py, scale, scale, c_white, 1);
};
global.NovaPauseLayout = function() {
    return {rows_x: 60, rows_y: [26, 48, 70, 106, 128, 150], panel_x: 196, panel_y: 20, panel_w: 164, panel_h: 152, rule_y: 184, help_y: 192};
};
global.NovaPauseHelp = function(row) {
    switch (row) {
        case 0: return "Return to the adventure.";
        case 1: return "Game, display, audio and control settings.";
        case 2: return "Check or change your " + (input_profile_get() == "keyboard" ? "keys." : "buttons.");
        case 3: return "Begin again on floor 1 with the same character, bonus and challenges. This run ends.";
        case 4: return "Progress since your last Save Tent is lost. Continue resumes from that tent.";
        case 5: return "Close the game. Progress since your last Save Tent is lost.";
    }
    return "";
};
// Confirmation wording for Start over, Quit to title and Quit to desktop.
global.NovaPauseDialogText = function(row) {
    switch (row) {
        case 3: return {question: "Start over?", detail: "This run ends. You begin again on floor 1.", confirm: "Start over"};
        case 4: return {question: "Quit to title?", detail: "Progress since your last Save Tent is lost.", confirm: "Quit"};
    }
    return {question: "Quit to desktop?", detail: "Progress since your last Save Tent is lost.", confirm: "Quit"};
};
global.NovaPauseSummary = function(pause) {
    var user = global.Users[global.UserIndex];
    var summary = {name: user.Name == "" ? "Link" : user.Name, character: global.LinkCharacterIndex, floor: 0, time: pause.NovaPauseTime,
        health: 0, hearts: 0, bosses: 0, bonus: clamp(global.StartingGear, 0, 7), preset: global.NovaPresetIndex(global.NovaChallengeOptions),
        level: global.NovaChallengeLevel(global.NovaChallengeOptions), cursed: global.Cursed, curse: "", task: ""};
    if (is_struct(global.Level)) summary.floor = global.Level.Index;
    summary.health = global.Inventory_ItemData[17].Amount;
    summary.hearts = global.Inventory_ItemData[18].Amount;
    if (instance_exists(oHUD)) summary.bosses = oHUD.BossesDefeated;
    if (summary.cursed) {
        summary.curse = global.CurseEffectStr;
        summary.task = global.CurseTaskStr + (global.CurseTaskCount > 0 ? " " + string(global.CurseTaskCount) : "");
    }
    return summary;
};
global.NovaPauseTimeText = function(microseconds) {
    var minutes = floor(max(0, microseconds) / 60000000);
    if (minutes >= 60) return string(minutes div 60) + "h " + string(minutes mod 60) + "m";
    return string(max(minutes, microseconds > 0 ? 1 : 0)) + "m";
};
global.NovaPauseFooter = function(pause) {
    var layout = global.NovaMenuLayout();
    var font = draw_get_font();
    draw_set_font(global.MenuFont_Innactive);
    var prompts = [{binding: global.NovaMenuConfirmBinding(), label: "Select"},
        {binding: global.NovaBinding(global.NovaCloseVerb()), label: pause.NovaPauseDialog ? "Back" : "Resume"}];
    prompts = global.NovaHintRow(prompts, layout.footer_right, layout.footer_y, 0.75, 0.75, 16, 12, layout.footer_right - layout.footer_left);
    draw_set_font(font);
    return prompts;
};
global.NovaPauseDraw = function(pause, selector) {
    var menu = global.NovaMenuLayout();
    var layout = global.NovaPauseLayout();
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_sprite_stretched(sMenuWin, 0, menu.x, menu.y, menu.width, menu.height);
    global.NovaMenuTitle("Paused");
    for (var i = 0; i < array_length(global.NovaPauseRows); i++) {
        var focused = i == pause.NovaPauseFocus && !pause.NovaPauseDialog;
        var py = layout.rows_y[i];
        global.NovaOptText(global.NovaPauseRows[i], layout.rows_x, py, focused, 0.9);
        if (focused) draw_sprite(sMenu_Selector_Active, selector, layout.rows_x - 22, py);
    }
    // The destructive choices sit below a rule, away from Resume.
    draw_set_alpha(0.25);
    draw_rectangle(layout.rows_x, layout.rows_y[3] - 9, layout.panel_x - 16, layout.rows_y[3] - 9, false);
    draw_set_alpha(1);
    // Run summary.
    var run = global.NovaPauseSummary(pause);
    var px = layout.panel_x;
    var py = layout.panel_y;
    draw_set_color(c_black);
    draw_set_alpha(0.22);
    draw_rectangle(px, py, px + layout.panel_w, py + layout.panel_h, false);
    draw_set_color(c_white);
    draw_set_alpha(0.25);
    draw_rectangle(px, py, px + layout.panel_w, py + layout.panel_h, true);
    draw_set_alpha(1);
    global.NovaCharacterDraw(run.character, px + 8, py + 8, 2);
    global.NovaOptText(run.name, px + 48, py + 8, false, 0.85);
    global.NovaOptText("Floor " + string(run.floor) + "   " + global.NovaPauseTimeText(run.time), px + 48, py + 26, false, 0.6);
    draw_sprite(sHUD_Heart, 4, px + 48, py + 41);
    global.NovaOptText(string(floor(run.health)) + "/" + string(run.hearts) + "   Bosses " + string(run.bosses), px + 58, py + 39, false, 0.6);
    var gift = run.bonus * 4;
    var line = py + 66;
    if (run.bonus > 0) {
        draw_sprite(global.GearSprites[gift], global.GearSprites[gift + 1], px + 16 + global.GearSprites[gift + 2], line + 14 + global.GearSprites[gift + 3]);
        global.NovaOptText(global.NovaBonusNames[run.bonus], px + 30, line + 2, false, 0.6);
    } else {
        draw_set_alpha(0.6);
        global.NovaOptText("No bonus", px + 8, line + 2, false, 0.6);
        draw_set_alpha(1);
    }
    var gold = make_color_rgb(248, 208, 96);
    global.NovaOptText(run.preset < 0 ? "Custom challenges" : global.NovaPresets[run.preset].name, px + 8, line + 22, false, 0.6, fa_left, run.level > 0 ? gold : c_white);
    if (run.level > 0) global.NovaOptText("Level " + string(run.level), px + layout.panel_w - 8, line + 22, false, 0.6, fa_right, gold);
    if (run.cursed) {
        global.NovaOptText("Curse: " + run.curse, px + 8, line + 42, false, 0.6, fa_left, gold);
        draw_set_alpha(0.75);
        global.NovaOptText(run.task, px + 8, line + 56, false, 0.55);
        draw_set_alpha(1);
    }
    draw_set_alpha(0.3);
    draw_rectangle(40, layout.rule_y, 360, layout.rule_y, false);
    draw_set_alpha(1);
    global.NovaOptionsHelp(global.NovaPauseHelp(pause.NovaPauseFocus));
    if (pause.NovaPauseDialog) {
        var text = global.NovaPauseDialogText(pause.NovaPauseFocus);
        global.NovaDialogDraw(text.question, text.detail, pause.NovaPauseDialogFocus, selector, text.confirm);
    }
    var prompts = global.NovaPauseFooter(pause);
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
};
// Pause and its Options render at the adventure menu's 4x canvas, then scale like that menu.
global.NovaPauseOverlay = function(pause, width, height, left = 0, top = 0) {
    if (!surface_exists(global.NovaOptionsSurface)) global.NovaOptionsSurface = surface_create(1600, 1200);
    surface_set_target(global.NovaOptionsSurface);
    draw_clear_alpha(c_black, 0);
    var world = matrix_get(matrix_world);
    matrix_set(matrix_world, matrix_build(0, 152, 0, 0, 0, 0, 4, 4, 1));
    var selector = (current_time div 133) mod 2;
    // Accumulate coverage so the dialog's dimming darkens the panel instead of making it translucent.
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
    if (pause.NovaOptionsOpen) global.NovaOptionsDraw(pause.NovaOptions, selector);
    else global.NovaPauseDraw(pause, selector);
    gpu_set_blendmode(bm_normal);
    matrix_set(matrix_world, world);
    surface_reset_target();
    draw_set_color(c_black);
    draw_set_alpha(0.35 * pause.Alpha);
    draw_rectangle(left, top, left + width, top + height, false);
    draw_set_color(c_white);
    draw_surface_stretched_ext(global.NovaOptionsSurface, left, top, width, height, c_white, pause.Alpha);
    draw_set_alpha(1);
};
