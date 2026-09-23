// New adventure: character preview, bonus, challenge presets and the remembered setup.
// Drawing uses the adventure menu's view coordinates, whose top edge is y = -38.
NovaBonusNames = global.NovaBonusNames;
NovaBonusHelp = ["Start with the standard gear.", "Start with 100 rupees to spend in shops.", "Start with one more inventory slot.",
    "Start with an extra heart container.", "Start with a Wooden Shield that blocks weak projectiles.", "Start with the Rod of Stone.",
    "Start with 10 Fire Orbs.", "Start with an Antidote."];
NovaPresets = global.NovaPresets;
NovaChallengeHelp = ["Hearts at the start of the run. Standard: 4.", "The most heart containers you can hold. Standard: 16.",
    "Caps how much armor protects you. Standard: no cap.", "More dark rooms. Higher settings force darkness and limit lights.",
    "Inventory slots at the start. Standard: 5.", "The most rupees your wallet holds. Standard: no limit.",
    "Multiplies shop prices. Standard: normal prices.", "More enemies in each room. Standard: normal.",
    "Multiplies the chance of curses. Standard: normal.", "Dungeon maps are unavailable.",
    "No food appears, and food shops stay empty.", "A Wall Master follows you through the dungeon and attacks."];
NovaChallengeIcons = [[sHUD_Heart, 4], [sItem_HeartPiece, 0], [sHUD_Icon_Defense, 0], [sHUD_Lamp, 0], [sItem_Bag, 0], [sHUD_Icon_Rupees, 0],
    [sItem_Coupon, 0], [sHUD_Icon_Attack, 0], [sItem_Medallion, 0], [sHUD_Map, 0], [sItem_Food, 0], [sNovaWallmaster, 0]];
NovaChallengeTabs = ["Survival", "Dungeon", "Restrictions"];
NovaChallengeDialog = false;
NovaChallengeDialogFocus = 0;
NovaSetupChanged = make_color_rgb(248, 208, 96);

function NovaChallengeLevel(values) { return global.NovaChallengeLevel(values); }
function NovaPresetIndex(values) { return global.NovaPresetIndex(values); }
function NovaPresetCycle(delta) {
    var current = NovaPresetIndex(NovaDraft.challenges);
    // A custom mix stays reachable as the entry after the presets.
    if (current < 0) NovaDraft.custom = array_create(12, 0);
    if (current < 0) array_copy(NovaDraft.custom, 0, NovaDraft.challenges, 0, 12);
    var count = array_length(NovaPresets) + (is_array(NovaDraft.custom) ? 1 : 0);
    var position = current < 0 ? array_length(NovaPresets) : current;
    position = (position + delta + count) mod count;
    NovaDraft.challenges = array_create(12, 0);
    array_copy(NovaDraft.challenges, 0, position < array_length(NovaPresets) ? NovaPresets[position].values : NovaDraft.custom, 0, 12);
}
function NovaSetupKey(player) { return "Player" + string(player); }
function NovaSetupSave() {
    ini_open("nova-menu.ini");
    // Plain numbers: ini values cannot hold JSON quotes.
    var text = string(NovaDraft.character) + "," + string(NovaDraft.bonus);
    for (var i = 0; i < 12; i++) text += "," + string(NovaDraft.challenges[i]);
    ini_write_string("Setup", NovaSetupKey(global.UserIndex), text);
    ini_close();
}
function NovaSetupForget(player) {
    ini_open("nova-menu.ini");
    ini_key_delete("Setup", NovaSetupKey(player));
    ini_close();
}
// The last setup is remembered per player; without one, a saved run supplies the character.
function NovaSetupLoad(player) {
    var draft = {character: 0, bonus: 0, challenges: array_create(12, 0), custom: undefined};
    ini_open("nova-menu.ini");
    var text = ini_read_string("Setup", NovaSetupKey(player), "");
    ini_close();
    var parts = string_split(text, ",");
    var valid = array_length(parts) == 14;
    for (var i = 0; valid && i < 14; i++) valid = string_digits(parts[i]) == parts[i] && parts[i] != "";
    if (valid) {
        draft.character = clamp(real(parts[0]), 0, 8);
        draft.bonus = clamp(real(parts[1]), 0, 7);
        for (var i = 0; i < 12; i++) draft.challenges[i] = clamp(real(parts[i + 2]), 0, i < 9 ? 3 : 1);
    } else if (global.Users[player].Name != "") draft.character = NovaProfileSummary(player).character;
    return draft;
}
function NovaSetupRandom() {
    var pick = irandom(7);
    NovaDraft.character = pick >= NovaDraft.character ? pick + 1 : pick;
    audio_play_sound(Sound_Text, 1, false);
}

function NovaIconFit(sprite, frame, px, py, size, alpha = 1) {
    var width = sprite_get_width(sprite);
    var height = sprite_get_height(sprite);
    var scale = min(1, size / max(width, height));
    draw_sprite_ext(sprite, frame, px + (size - width * scale) / 2 + sprite_get_xoffset(sprite) * scale,
        py + (size - height * scale) / 2 + sprite_get_yoffset(sprite) * scale, scale, scale, 0, c_white, alpha);
}
// Runs started with challenges carry their level on the save, like a Hero Mode mark.
function NovaChallengeBadge(px, py, level) {
    NovaIconFit(sHUD_Icon_Attack, 0, px, py + 1, 9);
    global.NovaOptText("Level " + string(level), px + 12, py, false, 0.6, fa_left, NovaSetupChanged);
}
function NovaSetupLayout() {
    return {preview_x: 40, preview_y: 20, preview_w: 112, preview_h: 118, column: 194, selector: 160,
        bonus_y: 20, challenges_y: 62, begin_y: 132, begin_h: 22, rule_y: 184, help_y: 192};
}
function NovaSetupFooter() {
    var prompts = [];
    if (NovaFocus == 0) array_push(prompts, {binding: global.NovaBinding("item"), label: "Random"});
    if (NovaFocus < 3) array_push(prompts, {binding: global.NovaDirectionBinding("left"), binding2: global.NovaDirectionBinding("right"), label: "Change"});
    return NovaFooterLayout(NovaFocus == 2 ? "Customize" : "Begin", prompts, "Close");
}
function NovaSetupHelp() {
    switch (NovaFocus) {
        case 0: return "Your hero's look for this adventure. Random picks another.";
        case 1: return NovaBonusHelp[NovaDraft.bonus];
        case 2:
            var preset = NovaPresetIndex(NovaDraft.challenges);
            return preset < 0 ? "Your own mix of challenges. Customize changes each one." : NovaPresets[preset].help;
    }
    return NovaProfileSummary(global.UserIndex).saved ? "Starts on floor 1. You confirm before your saved adventure is replaced." : "Starts on floor 1.";
}
function NovaSetupDraw() {
    var layout = NovaSetupLayout();
    var cx = layout.preview_x + layout.preview_w / 2;
    // Character preview.
    draw_set_color(c_black);
    draw_set_alpha(0.22);
    draw_rectangle(layout.preview_x, layout.preview_y, layout.preview_x + layout.preview_w, layout.preview_y + layout.preview_h, false);
    draw_set_color(c_white);
    draw_set_alpha(NovaFocus == 0 ? 0.6 : 0.25);
    draw_rectangle(layout.preview_x, layout.preview_y, layout.preview_x + layout.preview_w, layout.preview_y + layout.preview_h, true);
    draw_set_color(c_black);
    draw_set_alpha(0.3);
    draw_ellipse(cx - 18, layout.preview_y + 98, cx + 18, layout.preview_y + 106, false);
    draw_set_color(c_white);
    draw_set_alpha(1);
    var bob = (current_time div 400) mod 2;
    draw_sprite_ext(global.CharacterSprites, NovaDraft.character, cx - 24, layout.preview_y + 30 - bob, 3, 3, 0, c_white, 1);
    var name = NovaCharacterNames[NovaDraft.character];
    global.NovaOptText(name, cx, layout.preview_y + layout.preview_h + 6, NovaFocus == 0, 0.9, fa_center);
    draw_set_font(global.MenuFont_Innactive);
    var half = string_width(name) * 0.45 + 12;
    draw_set_alpha(NovaFocus == 0 ? 1 : 0.35);
    global.NovaOptArrow(cx - half, layout.preview_y + layout.preview_h + 13, -1);
    global.NovaOptArrow(cx + half, layout.preview_y + layout.preview_h + 13, 1);
    draw_set_alpha(0.6);
    global.NovaOptText(string(NovaDraft.character + 1) + " / 9", cx, layout.preview_y + layout.preview_h + 24, false, 0.6, fa_center);
    draw_set_alpha(1);
    if (NovaFocus == 0) draw_sprite(sMenu_Selector_Active, Selector_Frame, layout.preview_x - 22, layout.preview_y + layout.preview_h + 5);
    // Bonus.
    var column = layout.column;
    draw_set_alpha(0.55);
    global.NovaOptText("BONUS", column, layout.bonus_y, false, 0.55);
    draw_set_alpha(1);
    var gift = NovaDraft.bonus * 4;
    if (NovaDraft.bonus > 0) NovaIconFit(global.GearSprites[gift], global.GearSprites[gift + 1], column, layout.bonus_y + 12, 16);
    global.NovaOptText(NovaBonusNames[NovaDraft.bonus], column + (NovaDraft.bonus > 0 ? 22 : 0), layout.bonus_y + 13, NovaFocus == 1, 0.85);
    if (NovaFocus == 1) {
        draw_sprite(sMenu_Selector_Active, Selector_Frame, layout.selector, layout.bonus_y + 12);
        global.NovaOptArrow(column - 6, layout.bonus_y + 20, -1);
        global.NovaOptArrow(356, layout.bonus_y + 20, 1);
    }
    // Challenges: preset, total level and the changed challenges as icons.
    var preset = NovaPresetIndex(NovaDraft.challenges);
    var level = NovaChallengeLevel(NovaDraft.challenges);
    draw_set_alpha(0.55);
    global.NovaOptText("CHALLENGES", column, layout.challenges_y, false, 0.55);
    draw_set_alpha(1);
    global.NovaOptText(preset < 0 ? "Custom" : NovaPresets[preset].name, column, layout.challenges_y + 12, NovaFocus == 2, 0.85, fa_left, preset == 0 || NovaFocus == 2 ? c_white : NovaSetupChanged);
    if (NovaFocus == 2) {
        draw_sprite(sMenu_Selector_Active, Selector_Frame, layout.selector, layout.challenges_y + 11);
        global.NovaOptArrow(column - 6, layout.challenges_y + 19, -1);
        global.NovaOptArrow(356, layout.challenges_y + 19, 1);
    }
    for (var s = 0; s < 10; s++) {
        draw_set_alpha(s < ceil(level / 3) ? 1 : 0.2);
        if (s < ceil(level / 3)) draw_set_color(NovaSetupChanged);
        draw_rectangle(column + s * 8, layout.challenges_y + 32, column + s * 8 + 5, layout.challenges_y + 37, false);
        draw_set_color(c_white);
    }
    draw_set_alpha(0.75);
    global.NovaOptText("Level " + string(level), column + 86, layout.challenges_y + 29, false, 0.6);
    draw_set_alpha(1);
    var chip = 0;
    for (var i = 0; i < 12; i++) {
        if (NovaDraft.challenges[i] == 0) continue;
        NovaIconFit(NovaChallengeIcons[i][0], NovaChallengeIcons[i][1], column + chip * 14, layout.challenges_y + 44, 12);
        chip++;
    }
    if (chip == 0) {
        draw_set_alpha(0.45);
        global.NovaOptText("No extra challenges", column, layout.challenges_y + 45, false, 0.6);
        draw_set_alpha(1);
    }
    // Begin adventure is the strongest element on the screen.
    var focused = NovaFocus == 3;
    draw_set_alpha(focused ? 0.2 : 0.08);
    draw_rectangle(column - 8, layout.begin_y, 358, layout.begin_y + layout.begin_h, false);
    draw_set_alpha(1);
    draw_set_color(focused ? NovaSetupChanged : c_white);
    draw_set_alpha(focused ? 1 : 0.35);
    draw_rectangle(column - 8, layout.begin_y, 358, layout.begin_y + layout.begin_h, true);
    draw_set_color(c_white);
    draw_set_alpha(1);
    global.NovaOptText("Begin adventure", (column - 8 + 358) / 2, layout.begin_y + 4, focused, 0.95, fa_center);
    if (focused) draw_sprite(sMenu_Selector_Active, Selector_Frame, layout.selector, layout.begin_y + 3);
    // Help line, as on the Options screen.
    draw_set_alpha(0.3);
    draw_rectangle(40, layout.rule_y, 360, layout.rule_y, false);
    draw_set_alpha(1);
    global.NovaOptionsHelp(NovaSetupHelp());
    var prompts = NovaSetupFooter();
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
}

function NovaChallengeState() {
    return {tabs: NovaChallengeTabs, tab: NovaChallengePage, page: "list"};
}
function NovaChallengeFooter() {
    if (NovaChallengeDialog) return NovaFooterLayout("Select", undefined, "Back");
    return NovaFooterLayout("", [
        {binding: global.NovaDirectionBinding("left"), binding2: global.NovaDirectionBinding("right"), label: "Change"},
        {binding: global.NovaBinding("item"), label: "Defaults"}], "Back");
}
function NovaChallengesDraw() {
    var options = global.NovaOptionsLayout();
    global.NovaOptionsDrawChrome(NovaChallengeState());
    var page = NovaChallengePages[NovaChallengePage];
    for (var i = 0; i < array_length(page); i++) {
        var index = page[i];
        var py = options.rows_y + i * 24;
        var focused = i == NovaFocus && !NovaChallengeDialog;
        var changed = NovaDraft.challenges[index] != 0;
        NovaIconFit(NovaChallengeIcons[index][0], NovaChallengeIcons[index][1], 58, py + 1, 12, changed || focused ? 1 : 0.6);
        global.NovaOptText(NovaChallengeLabels[index], 76, py, focused, 0.85, fa_left, changed && !focused ? NovaSetupChanged : c_white);
        if (focused) draw_sprite(sMenu_Selector_Active, Selector_Frame, 36, py);
        global.NovaOptText(NovaChallengeValues[index][NovaDraft.challenges[index]], options.value_center, py + 1, focused, 0.8, fa_center, changed && !focused ? NovaSetupChanged : c_white);
        if (focused) {
            global.NovaOptArrow(options.arrow_left, py + 7, -1);
            global.NovaOptArrow(options.arrow_right, py + 7, 1);
        }
        if (changed) {
            // A dot beside changed values keeps the cue from relying on colour alone.
            draw_set_color(NovaSetupChanged);
            draw_circle(348, py + 7, 2, false);
            draw_set_color(c_white);
        }
    }
    var level = NovaChallengeLevel(NovaDraft.challenges);
    var preset = NovaPresetIndex(NovaDraft.challenges);
    draw_set_alpha(0.75);
    // The preset and level sit in the header's empty right side, clear of the tabs.
    global.NovaOptText((preset < 0 ? "Custom" : NovaPresets[preset].name) + "  Level " + string(level), 358, global.NovaMenuLayout().header_y + 6, false, 0.7, fa_right, level > 0 ? NovaSetupChanged : c_white);
    draw_set_alpha(1);
    global.NovaOptionsHelp(NovaChallengeHelp[page[clamp(NovaFocus, 0, array_length(page) - 1)]]);
    if (NovaChallengeDialog) global.NovaDialogDraw("Restore standard challenges?", "Every challenge returns to Hero's Path.", NovaChallengeDialogFocus, Selector_Frame);
    var prompts = NovaChallengeFooter();
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
}
// Returns true when the dialog consumed the input.
function NovaChallengeDialogStep(close) {
    if (!NovaChallengeDialog) return false;
    if (close) {
        NovaChallengeDialog = false;
        audio_play_sound(Sound_Throw, 1, false);
    } else if (input_check_pressed("down") || input_check_pressed("up")) {
        NovaChallengeDialogFocus = 1 - NovaChallengeDialogFocus;
        audio_play_sound(Sound_Text, 1, false);
    } else if (!keyboard_check(vk_alt) && input_check_pressed("menu_input")) {
        if (NovaChallengeDialogFocus == 1) NovaDraft.challenges = array_create(12, 0);
        NovaChallengeDialog = false;
        audio_play_sound(Sound_TextDone, 1, false);
    }
    input_clear_momentary(true);
    return true;
}
