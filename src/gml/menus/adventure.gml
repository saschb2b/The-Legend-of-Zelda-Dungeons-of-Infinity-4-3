NovaPage = "home";
NovaFocus = 0;
NovaFocusMemory = {};
NovaDraft = {character: 0, bonus: 0, challenges: array_create(12, 0), custom: undefined};
NovaTransition = variable_global_exists("NovaTitleFrame") && surface_exists(global.NovaTitleFrame) ? 0 : 36;
NovaCharacterNames = [];
for (var i = 0; i < 9; i++) array_push(NovaCharacterNames, string_replace(sprite_get_name(global.LinkCharacterSpr[i]), "sLinkCharacter_", ""));
NovaCreditPage = 0;
NovaName = "";
NovaLetters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-., ";
NovaNameCell = 0;
NovaSetupParent = "home";
NovaSetupPlayer = 0;
NovaOptions = global.NovaOptionsState("title");
Menu_Active = true;
MenuWin_Main_Shift = false;

function NovaRememberPlayer() {
    ini_open("nova-menu.ini");
    ini_write_real("Menu", "Player", global.UserIndex);
    ini_close();
}
function NovaSelectPlayer(index) {
    global.UserIndex = index;
    User_VerifyIntegrity();
    input_profile_import(global.Users[index].InputProfile_Gamepad, "gamepad");
    input_profile_import(global.Users[index].InputProfile_Keyboard, "keyboard");
    Bindings_GetIcons(0);
    Bindings_GetIcons(1);
    NovaRememberPlayer();
}
function NovaRestorePlayer() {
    ini_open("nova-menu.ini");
    var index = floor(ini_read_real("Menu", "Player", -1));
    ini_close();
    if (index < 0 || index >= global.MaxUsers || global.Users[index].Name == "") {
        index = 0;
        for (var i = 0; i < global.MaxUsers; i++) {
            if (global.Users[i].Name != "") { index = i; break; }
        }
    }
    global.UserIndex = index;
    NovaSelectPlayer(index);
}
function NovaGo(page, focus = undefined) {
    variable_struct_set(NovaFocusMemory, NovaPage, NovaFocus);
    NovaPage = page;
    NovaFocus = focus == undefined ? (variable_struct_exists(NovaFocusMemory, page) ? variable_struct_get(NovaFocusMemory, page) : 0) : focus;
    input_clear_momentary(true);
}
function NovaHomeRows() {
    var rows = [];
    if (NovaProfileSummary(global.UserIndex).saved) array_push(rows, "Continue");
    array_push(rows, "New adventure", "Change player", "Options", "Quit game");
    return rows;
}
function NovaPlayerRows() {
    var rows = [];
    var empty = -1;
    for (var i = 0; i < global.MaxUsers; i++) {
        if (global.Users[i].Name != "") array_push(rows, i);
        else if (empty == -1) empty = i;
    }
    if (empty != -1) array_push(rows, empty);
    return rows;
}
function NovaNewDraft(player = -1) {
    NovaSetupParent = NovaPage;
    NovaSetupPlayer = global.UserIndex;
    if (player >= 0) global.UserIndex = player;
    NovaDraft = NovaSetupLoad(global.UserIndex);
    NovaChallengeDialog = false;
    NovaGo("setup", 3);
}
function NovaBegin() {
    if (global.Users[global.UserIndex].Name == "") {
        global.Users[global.UserIndex] = new User_Create();
        global.Users[global.UserIndex].Name = "Link";
        DungeonSeq_Init(global.UserIndex);
        User_Save();
    }
    NovaRememberPlayer();
    NovaSetupSave();
    NovaPlayedMark();
    global.LinkCharacterIndex = NovaDraft.character;
    global.StartingGear = NovaDraft.bonus;
    global.NovaResetChallenges();
    global.NovaChallengeOptions = StructCopy(NovaDraft.challenges);
    global.Challenges[3] = global.NovaOption(9) == 1;
    global.Challenges[4] = global.NovaOption(3) == 3;
    global.Continue = false;
    global.SaveLevel = false;
    Menu_StartGame();
}
function NovaContinue() {
    var save = global.Users[global.UserIndex].SaveData;
    if (!is_struct(save)) return;
    if (global.SaveVersionCheck && (!variable_struct_exists(save, "GameVersion") || save.GameVersion != "1.1.6 - VM")) {
        NovaGo("save-error", 0);
        return;
    }
    NovaRememberPlayer();
    NovaPlayedMark();
    Menu_ContinueGame();
}
function NovaClose() {
    switch (NovaPage) {
        case "home": audio_stop_all(); room_goto(Room_Title); break;
        case "setup":
            global.UserIndex = NovaSetupPlayer;
            NovaGo(NovaSetupParent == "players" ? "players" : "home");
            break;
        case "players": case "options": case "save-error": NovaGo("home"); break;
        case "challenges": case "replace": NovaGo("setup"); break;
        case "player": NovaGo("players"); break;
        case "rename": NovaGo("player"); break;
        case "credits": NovaGo("options"); break;
    }
    audio_play_sound(Sound_Throw, 1, false);
    input_clear_momentary(true);
}
function NovaCycle(delta) {
    if (NovaPage == "setup") {
        if (NovaFocus == 0) NovaDraft.character = (NovaDraft.character + delta + 9) mod 9;
        if (NovaFocus == 1) NovaDraft.bonus = (NovaDraft.bonus + delta + 8) mod 8;
        if (NovaFocus == 2) NovaPresetCycle(delta);
    } else if (NovaPage == "challenges") {
        var page = NovaChallengePages[NovaChallengePage];
        var index = page[clamp(NovaFocus, 0, array_length(page) - 1)];
        var count = array_length(NovaChallengeValues[index]);
        NovaDraft.challenges[index] = (NovaDraft.challenges[index] + delta + count) mod count;
    }
    audio_play_sound(Sound_Text, 1, false);
}
function NovaRowCount() {
    switch (NovaPage) {
        case "home": return array_length(NovaHomeRows());
        case "setup": return 4;
        case "players": return array_length(NovaPlayerRows());
        case "player": return 3;
        case "replace": return 2;
        case "challenges": return array_length(NovaChallengePages[NovaChallengePage]);
    }
    return 1;
}
function NovaConfirm() {
    switch (NovaPage) {
        case "home":
            var rows = NovaHomeRows();
            switch (rows[NovaFocus]) {
                case "Continue": NovaContinue(); break;
                case "New adventure": NovaNewDraft(); break;
                case "Change player": NovaGo("players", NovaPlayersFocusCurrent()); break;
                case "Options": NovaOptions.page = "list"; NovaGo("options", 0); break;
                case "Quit game": game_end(); break;
            }
            break;
        case "setup":
            // Begin is one press away from every row except Challenges, which opens its page.
            if (NovaFocus == 2) { NovaChallengePage = 0; NovaGo("challenges", 0); }
            else if (NovaProfileSummary(global.UserIndex).saved) NovaGo("replace", 0);
            else NovaBegin();
            break;
        case "replace": if (NovaFocus == 0) NovaClose(); else NovaBegin(); break;
        case "challenges": NovaCycle(1); break;
        case "players":
            var rows = NovaPlayerRows();
            var index = rows[NovaFocus];
            if (global.Users[index].Name == "") {
                NovaNewDraft(index);
            } else { NovaSelectPlayer(index); NovaGo("home", 0); }
            break;
        case "player":
            if (NovaFocus == 0) NovaGo("home", 0);
            else if (NovaFocus == 1) {
                NovaName = global.Users[global.UserIndex].Name;
                NovaNameCell = 0;
                NovaRenameNotice = "";
                NovaGo("rename", 0);
            } else {
                NovaPlayerDialog = true;
                NovaPlayerDialogFocus = 0;
            }
            break;
        case "rename":
            if (NovaNameCell < string_length(NovaLetters)) {
                if (string_length(NovaName) < 8) NovaName += string_char_at(NovaLetters, NovaNameCell + 1);
            } else if (NovaNameCell == string_length(NovaLetters)) NovaName = string_delete(NovaName, string_length(NovaName), 1);
            else NovaRenameSave();
            if (NovaPage == "rename" && NovaNameCell < string_length(NovaLetters)) NovaRenameNotice = "";
            break;
        case "save-error": NovaClose(); break;
    }
    audio_play_sound(Sound_TextDone, 1, false);
    input_clear_momentary(true);
}
function NovaAdventureStep(close) {
    NovaTransition = min(36, NovaTransition + 1);
    if (NovaTransition == 36 && variable_global_exists("NovaTitleFrame") && surface_exists(global.NovaTitleFrame)) surface_free(global.NovaTitleFrame);
    if (NovaUpdateOpen) { NovaUpdateStep(); return; }
    if (instance_exists(ErrorMsgInst) || global.AltTab || Bindings_Remap) return;
    if (NovaPage == "options") {
        var result = global.NovaOptionsStep(NovaOptions, close);
        if (result == "close") { User_Save(); NovaGo("home"); }
        else if (result == "updates") NovaUpdateEnter();
        else if (result == "credits") { NovaCreditPage = 0; NovaGo("credits", 0); }
        return;
    }
    if (NovaPage == "challenges" && NovaChallengeDialogStep(close)) return;
    if (NovaPage == "player" && NovaPlayerDialogStep(close)) return;
    if (close) { NovaClose(); return; }
    if (NovaPage == "rename" && (input_check_pressed("nova_bag_previous") || input_check_pressed("nova_bag_next"))) {
        // L erases and R adds a space, so names need fewer trips across the grid.
        if (input_check_pressed("nova_bag_previous")) NovaName = string_delete(NovaName, string_length(NovaName), 1);
        else if (string_length(NovaName) < 8) NovaName += " ";
        NovaRenameNotice = "";
        audio_play_sound(Sound_Text, 1, false);
        input_clear_momentary(true);
        return;
    }
    if (NovaPage == "player" && (input_check_pressed("left") || input_check_pressed("right"))) {
        NovaFocus = (NovaFocus + input_check_pressed("right") - input_check_pressed("left") + 3) mod 3;
        audio_play_sound(Sound_Text, 1, false);
        return;
    }
    if (NovaPage == "challenges" && input_check_pressed("item")) {
        NovaChallengeDialog = true;
        NovaChallengeDialogFocus = 0;
        audio_play_sound(Sound_TextDone, 1, false);
        input_clear_momentary(true);
        return;
    }
    if (NovaPage == "setup" && NovaFocus == 0 && input_check_pressed("item")) {
        NovaSetupRandom();
        input_clear_momentary(true);
        return;
    }
    if (NovaPage == "players" && input_check_pressed("item")) {
        var rows = NovaPlayerRows();
        var index = rows[NovaFocus];
        if (global.Users[index].Name != "") { NovaSelectPlayer(index); NovaGo("player", 0); }
        return;
    }
    if (NovaPage == "rename") {
        var count = string_length(NovaLetters) + 2;
        if (input_check_pressed("right")) NovaNameCell = (NovaNameCell + 1) mod count;
        if (input_check_pressed("left")) NovaNameCell = (NovaNameCell + count - 1) mod count;
        if (input_check_pressed("down")) NovaNameCell = min(count - 1, NovaNameCell + 13);
        if (input_check_pressed("up")) NovaNameCell = max(0, NovaNameCell - 13);
    } else {
        var count = NovaRowCount();
        if (input_check_pressed("down")) { NovaFocus = (NovaFocus + 1) mod count; audio_play_sound(Sound_Text, 1, false); }
        if (input_check_pressed("up")) { NovaFocus = (NovaFocus + count - 1) mod count; audio_play_sound(Sound_Text, 1, false); }
        if (input_check_pressed("left")) NovaCycle(-1);
        if (input_check_pressed("right")) NovaCycle(1);
    }
    var page_delta = input_check_pressed("nova_bag_next") - input_check_pressed("nova_bag_previous");
    if (page_delta != 0) {
        if (NovaPage == "challenges") { NovaChallengePage = (NovaChallengePage + page_delta + 3) mod 3; NovaFocus = 0; }
        if (NovaPage == "credits") NovaCreditPage = clamp(NovaCreditPage + page_delta, 0, ceil(array_length(NovaCredits) / 10) - 1);
    }
    if (!keyboard_check(vk_alt) && input_check_pressed("menu_input")) NovaConfirm();
}

function NovaText(text, px, py, active = false, scale = 1, align = fa_left) {
    draw_set_color(c_white);
    draw_set_halign(align);
    draw_set_valign(fa_top);
    draw_set_font(active ? global.MenuFont : global.MenuFont_Innactive);
    draw_text_transformed(px, py - 38, text, scale, scale, 0);
}
function NovaRow(label, row, py, value = "", px = 60) {
    NovaText(label, px, py, NovaFocus == row);
    if (value != "") NovaText(value, 340, py, false, 0.85, fa_right);
    if (NovaFocus == row) draw_sprite(sMenu_Selector_Active, Selector_Frame, px - 22, py - 38);
}
// Pages reached from Options say Back, matching the Options screen's nested pages.
// Extra hints come before Select; pass one hint or an array of them.
function NovaFooterLayout(label = "Select", extra = undefined, close = "Close") {
    var font = draw_get_font();
    draw_set_font(global.MenuFont_Innactive);
    var layout = NovaMenuLayout();
    var prompts = [];
    if (is_array(extra)) for (var i = 0; i < array_length(extra); i++) array_push(prompts, extra[i]);
    else if (extra != undefined) array_push(prompts, extra);
    if (label != "") array_push(prompts, {binding: NovaMenuConfirmBinding(), label: label, reserve: label == "Install update" || label == "Check again" ? "Install update" : "Continue"});
    array_push(prompts, {binding: global.NovaBinding(global.NovaCloseVerb()), label: close});
    prompts = global.NovaHintRow(prompts, layout.footer_right, layout.footer_y, 0.75, 0.75, 16, 12, layout.footer_right - layout.footer_left);
    draw_set_font(font);
    return prompts;
}
function NovaFooter(label = "Select", extra = undefined, close = "Close") {
    draw_set_font(global.MenuFont_Innactive);
    var prompts = NovaFooterLayout(label, extra, close);
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
}
function NovaPageHeading(label) {
    NovaText(label, 200, 60, false, 0.85, fa_center);
    global.NovaPromptDraw(global.NovaBinding("nova_bag_previous"), "", 52, 28, 0.75, 0.75, 16);
    global.NovaPromptDraw(global.NovaBinding("nova_bag_next"), "", 332, 28, 0.75, 0.75, 16);
}
function NovaLandscape() {
    // The scene spans the widened menu view: mountains at its left edge, the castle at its right.
    var left = -global.NovaMenuInset;
    var right = 400 + global.NovaMenuInset;
    draw_set_alpha(1);
    draw_clear(make_color_rgb(0, 150, 216));
    draw_sprite_stretched(sTitle_Foreground_Sky, 0, left, 176, right - left, 21);
    draw_sprite(sTitle_Foreground_Mountain, 0, left, 174);
    for (var px = left; px < right; px += 16) draw_sprite(sTitle_Foreground_Trees, 0, px, 193);
    var clouds = [left + 1, left + 48, right - 63];
    for (var i = 0; i < 3; i++) draw_sprite(sTitle_Foreground_Cloud, 0, clouds[i], 167);
    draw_sprite(sTitle_Foreground_Castle, 0, right - 48, 121);
    for (var px = left; px < right; px += 16) draw_sprite_stretched(sTitle_Water_Sky, 0, px, 215, 16, 47);
    for (var px = left; px < right; px += 16) draw_sprite(sTitle_Water_Trees, 0, px, 205);
    draw_sprite(sTitle_Water_Mountain, 0, left, 217);
    draw_sprite_stretched(sTitle_Water_Castle, 0, right - 48, 232, 41, 32);
    draw_set_color(make_color_rgb(8, 15, 27));
    draw_set_alpha(0.78);
    draw_rectangle(left, -38, right, 262, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}
function NovaHearts(summary, px, py) {
    for (var i = 0; i < summary.hearts; i++) {
        var amount = clamp(summary.health - i, 0, 1);
        var frame = amount >= 1 ? 4 : (amount > 0 ? max(1, floor(amount * 4)) : 0);
        draw_sprite(sHUD_Heart, frame, px + (i mod 10) * 8, py - 38 + (i div 10) * 8);
    }
}
function NovaAdventureDraw() {
    NovaLandscape();
    if (NovaUpdateOpen) { NovaUpdateDraw(); return; }
    if (instance_exists(ErrorMsgInst)) return;
    if (NovaPage == "options") { global.NovaOptionsDraw(NovaOptions, Selector_Frame); return; }
    if (NovaPage == "home") {
        var t = clamp((NovaTransition - 12) / 24, 0, 1);
        t = t * t * (3 - 2 * t);
        var scale = lerp(4 / 3, 1, t);
        draw_sprite_ext(sTitle, 0, lerp(280 / 3, 32, t), lerp(64 / 3, 14, t) - 38, scale, scale, 0, c_white, 1);
        var summary = NovaProfileSummary(global.UserIndex);
        draw_set_alpha(t);
        var rows = NovaHomeRows();
        NovaFocus = clamp(NovaFocus, 0, array_length(rows) - 1);
        for (var i = 0; i < array_length(rows); i++) {
            var py = summary.saved && i > 0 ? 187 + (i - 1) * 20 : 151 + i * 24;
            NovaRow(rows[i], i, py, "", 55);
        }
        if (summary.saved) {
            draw_set_alpha(t * 0.8);
            NovaText(summary.name, 55, 169, false, 0.75);
            var separator = 55 + string_width(summary.name) * 0.75 + 6;
            // Sprite fonts contain ASCII only; the separator shares the text baseline.
            draw_rectangle(separator, 169 - 38 + 5, separator + 1, 169 - 38 + 6, false);
            NovaText("Floor " + string(summary.floor), separator + 8, 169, false, 0.75);
            if (summary.level > 0) NovaChallengeBadge(separator + 8 + string_width("Floor " + string(summary.floor)) * 0.75 + 8, 169 - 38, summary.level);
            draw_set_alpha(t);
        }
        NovaFooter(NovaFocus == 0 && summary.saved ? "Continue" : "Select");
        var version = global.NovaMenuLayout();
        global.NovaVersionDraw(version.footer_left, version.footer_y, 0.75, t * 0.55);
        draw_set_alpha(1);
        if (variable_global_exists("NovaTitleFrame") && surface_exists(global.NovaTitleFrame) && NovaTransition < 12)
            draw_surface_ext(global.NovaTitleFrame, -global.NovaMenuInset, -38, (400 + 2 * global.NovaMenuInset) / surface_get_width(global.NovaTitleFrame), 300 / surface_get_height(global.NovaTitleFrame), 0, c_white, 1 - NovaTransition / 12);
        return;
    }
    var name = global.Users[global.UserIndex].Name;
    var titles = {setup: "New adventure", players: "Players", player: ["Players", name], challenges: ["New adventure", "Challenges"], replace: "New adventure", rename: ["Players", name, "Rename"], credits: ["Options", "About", "Credits"]};
    NovaMenuFrame(variable_struct_exists(titles, NovaPage) ? variable_struct_get(titles, NovaPage) : "Saved adventure");
    switch (NovaPage) {
        case "setup": NovaSetupDraw(); break;
        case "challenges": NovaChallengesDraw(); break;
        case "players": NovaPlayersDraw(); break;
        case "player": NovaDetailsDraw(); break;
        case "replace":
            NovaText("Replace your saved adventure?", 200, 90, false, 1, fa_center);
            NovaText("Your player and records stay.", 200, 120, false, 0.8, fa_center);
            NovaRow("Keep save", 0, 180);
            NovaRow("Begin adventure", 1, 220);
            NovaFooter();
            break;
        case "rename":
            NovaText(NovaName + "_", 200, 60, false, 1.2, fa_center);
            draw_set_alpha(0.7);
            global.NovaOptText(NovaRenameNotice != "" ? NovaRenameNotice : string(string_length(NovaName)) + " / 8", 200, 44, false, 0.6, fa_center, NovaRenameNotice != "" ? NovaSetupChanged : c_white);
            draw_set_alpha(1);
            for (var i = 0; i < string_length(NovaLetters); i++) {
                var px = 53 + (i mod 13) * 24;
                var py = 103 + (i div 13) * 24;
                if (NovaNameCell == i) draw_sprite(sMenu_Selector_Active, Selector_Frame, px - 12, py - 38);
                NovaText(string_char_at(NovaLetters, i + 1), px, py, NovaNameCell == i);
            }
            NovaText("Erase letter", 60, 239, NovaNameCell == string_length(NovaLetters));
            NovaText("Save name", 230, 239, NovaNameCell == string_length(NovaLetters) + 1);
            var rename_hints = NovaRenameFooter();
            for (var i = 0; i < array_length(rename_hints); i++) global.NovaHintDraw(rename_hints[i]);
            break;
        case "credits":
            NovaPageHeading(string(NovaCreditPage + 1) + " / " + string(ceil(array_length(NovaCredits) / 10)));
            for (var i = 0; i < 10; i++) {
                var index = NovaCreditPage * 10 + i;
                if (index < array_length(NovaCredits)) NovaText(NovaCredits[index], 200, 88 + i * 16, false, 0.65, fa_center);
            }
            NovaFooter("", undefined, "Back");
            break;
        case "save-error":
            NovaText("This save uses a different game version.", 200, 110, false, 0.8, fa_center);
            NovaText("Your saved adventure has been kept.", 200, 145, false, 0.8, fa_center);
            NovaFooter("");
            break;
    }
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}
NovaRestorePlayer();
input_clear_momentary(true);
