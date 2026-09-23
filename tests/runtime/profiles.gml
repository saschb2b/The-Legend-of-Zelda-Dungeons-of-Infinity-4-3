function ProfileFixture(name, character, hearts, health, level) {
    var user = new User_Create();
    user.Name = name;
    if (hearts > 0) {
        user.SaveData = new User_SaveDataStruct();
        user.SaveData.LinkCharacterIndex = character;
        user.SaveData.Level = level;
        user.SaveData.Inventory_ItemData = array_create(19);
        user.SaveData.Inventory_ItemData[17] = {Amount: health};
        user.SaveData.Inventory_ItemData[18] = {Amount: hearts};
    }
    return user;
}

function ProfileMenuTests() {
    var users = global.Users;
    var user_index = global.UserIndex;
    var profile = input_profile_get();
    global.Users = [ProfileFixture("LINK", 0, 4, 3.5, 5), ProfileFixture("WWWWWWWW", 8, 20, 19.25, 99), ProfileFixture("ZELDA", 2, 0, 0, 0), new User_Create(), new User_Create()];
    global.UserIndex = 0;
    var before = json_stringify(global.Users);
    oMenu.NovaPage = "home";
    oMenu.NovaFocus = 0;
    var home_rows = oMenu.NovaHomeRows();
    Record("Continue leads the saved-player menu", home_rows[0] == "Continue");
    var saved = oMenu.NovaProfileSummary(0);
    Record("Save preview uses recorded health and floor", saved.saved && saved.hearts == 4 && saved.health == 3.5 && saved.floor == 5);
    var maximum = oMenu.NovaProfileSummary(1);
    Record("Save preview retains character and maximum hearts", maximum.character == 8 && maximum.hearts == 20 && maximum.health == 19.25);
    var fresh = oMenu.NovaProfileSummary(2);
    Record("Named player without a run shows no invented progress", !fresh.saved && fresh.hearts == 0);
    var player_rows = oMenu.NovaPlayerRows();
    Record("Players shows occupied slots and one Create player action", array_length(oMenu.NovaPlayerRows()) == 4 && player_rows[3] == 3);
    for (var device = 0; device < 2; device++) {
        input_profile_set(device == 0 ? "gamepad" : "keyboard");
        var layout = oMenu.NovaMenuLayout();
        Record("Menu frame fits the 4:3 view " + string(device), layout.x >= 8 && layout.x + layout.width <= 392 && layout.header_y >= -30 && layout.y + layout.height < 254);
        Record("Menu hints sit below the frame " + string(device), layout.footer_y - 8 >= layout.y + layout.height + 8 && layout.footer_y + 8 <= 258);
        var select = oMenu.NovaFooterLayout("Select");
        var resume = oMenu.NovaFooterLayout("Continue");
        Record("Menu actions precede Close " + string(device), select[0].right < select[1].x && select[1].label == "Close");
        Record("Menu glyphs stay anchored as labels change " + string(device), select[0].icon_x == resume[0].icon_x && select[1].x == resume[1].x && select[1].right == layout.footer_right);
        with (oMenu) NovaAdventureDraw();
        oMenu.NovaPage = "players";
        with (oMenu) NovaAdventureDraw();
        draw_set_font(global.MenuFont_Innactive);
        var cards = oMenu.NovaPlayersLayout();
        Record("Eight-letter names and the current tag clear the stats column " + string(device), cards.name_x + string_width(maximum.name) * 0.8 + 8 + string_width("CURRENT") * 0.5 + 6 <= cards.stats_x);
        oMenu.NovaPage = "home";
    }
    Record("Drawing previews leaves all saves untouched", json_stringify(global.Users) == before);
    with (oMenu) NovaNewDraft();
    Record("Begin is selected when new adventure opens", oMenu.NovaPage == "setup" && oMenu.NovaFocus == 3);
    oMenu.NovaFocus = 0;
    for (var i = 1; i <= 9; i++) {
        PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
        Record("All nine characters are reachable " + string(i), oMenu.NovaDraft.character == i mod 9);
    }
    oMenu.NovaFocus = 1;
    for (var i = 1; i <= 8; i++) {
        PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
        Record("All eight bonus choices are reachable " + string(i), oMenu.NovaDraft.bonus == i mod 8);
    }
    oMenu.NovaDraft.character = 8;
    oMenu.NovaDraft.bonus = 7;
    oMenu.NovaDraft.challenges[9] = 1;
    oMenu.NovaFocus = 3;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Replacing a saved adventure requires explicit confirmation", oMenu.NovaPage == "replace" && oMenu.NovaFocus == 0);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Default replacement choice keeps the save and draft", oMenu.NovaPage == "setup" && oMenu.NovaDraft.character == 8 && json_stringify(global.Users) == before);
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Closing setup preserves all save bytes", json_stringify(global.Users) == before);
    oMenu.NovaPage = "players";
    oMenu.NovaFocus = 3;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Create player opens setup without registering a name", oMenu.NovaPage == "setup" && global.UserIndex == 3 && global.Users[3].Name == "");
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Closing Create player restores the originating row and selected save", oMenu.NovaPage == "players" && oMenu.NovaFocus == 3 && global.UserIndex == 0 && json_stringify(global.Users) == before);
    oMenu.NovaFocus = 1;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Choosing a player returns directly to its adventure", global.UserIndex == 1 && oMenu.NovaPage == "home" && oMenu.NovaFocus == 0);
    oMenu.NovaPage = "players";
    oMenu.NovaFocus = 0;
    PressEvent(oMenu, "item", oMenu, ev_step, ev_step_normal);
    Record("Details opens the highlighted player's records and actions", global.UserIndex == 0 && oMenu.NovaPage == "player" && oMenu.NovaFocus == 0);
    PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
    Record("Details actions move left and right", oMenu.NovaFocus == 1);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    oMenu.NovaName = "Test";
    oMenu.NovaNameCell = string_length(oMenu.NovaLetters) + 1;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Saving a name returns to Rename with the new name", global.Users[0].Name == "Test" && oMenu.NovaPage == "player" && oMenu.NovaFocus == 1);
    PlayerScreenTests();
    global.Users[0].Name = "LINK";
    global.NovaTestContinue = false;
    with (oMenu) NovaContinue();
    Record("Incompatible save cannot be continued", !global.NovaTestContinue && oMenu.NovaPage == "save-error");
    global.Users[0].SaveData.GameVersion = "1.1.6 - VM";
    with (oMenu) NovaGo("home", 0);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("One confirm on Continue resumes the saved adventure", global.NovaTestContinue);
    Record("Continue does not apply discarded character or bonus", global.Users[0].SaveData.LinkCharacterIndex == 0 && oMenu.NovaProfileSummary(0).floor == 5);
    global.UserIndex = 3;
    with (oMenu) NovaNewDraft();
    home_rows = oMenu.NovaHomeRows();
    Record("Fresh player leads with New adventure", home_rows[0] == "New adventure");
    global.NovaTestStart = false;
    oMenu.NovaDraft.character = 4;
    oMenu.NovaDraft.bonus = 2;
    oMenu.NovaDraft.challenges[9] = 1;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("A fresh adventure starts without name entry", global.NovaTestStart && global.Users[3].Name == "Link");
    Record("Begin applies the draft only at the start boundary", global.LinkCharacterIndex == 4 && global.StartingGear == 2 && global.Challenges[3] && !global.Continue);
    with (oMenu) NovaRestorePlayer();
    Record("Last selected player survives menu initialization", global.UserIndex == 3);
    global.Users = users;
    global.UserIndex = user_index;
    global.LinkCharacterIndex = 0;
    global.StartingGear = 0;
    global.NovaResetChallenges();
    input_profile_set(profile);
    with (oMenu) { NovaRememberPlayer(); NovaGo("home", 0); }
}

ProfileCaptureGamepad = "";
function ProfileCaptureStart() {
    ProfileCaptureUsers = global.Users;
    ProfileCaptureUserIndex = global.UserIndex;
    global.Users = [new User_Create(), new User_Create(), new User_Create(), new User_Create(), new User_Create()];
    global.UserIndex = 0;
    input_profile_set("gamepad");
    oMenu.NovaPage = "home";
    oMenu.NovaFocus = 0;
    Capture = "profiles-empty";
    Flush();
}
function ProfileCaptureStep() {
    if (!file_exists("nova-capture-done.txt")) return false;
    file_delete("nova-capture-done.txt");
    if (Capture == "profiles-empty") {
        global.Users = [ProfileFixture("LINK", 0, 4, 3.5, 5), ProfileFixture("WWWWWWWW", 8, 20, 19.25, 99), ProfileFixture("HERO", 2, 0, 0, 0), new User_Create(), ProfileFixture("RAVIO", 3, 8, 5.25, 15)];
        Capture = "profiles-saves";
    } else if (Capture == "profiles-saves") {
        global.UserIndex = 1;
        Capture = "profiles-maximum";
    } else if (Capture == "profiles-maximum") {
        global.UserIndex = 0;
        with (oMenu) NovaNewDraft();
        oMenu.NovaDraft.bonus = 4;
        oMenu.NovaDraft.challenges = array_create(12, 0);
        array_copy(oMenu.NovaDraft.challenges, 0, oMenu.NovaPresets[1].values, 0, 12);
        oMenu.NovaFocus = 2;
        Capture = "profiles-setup";
    } else if (Capture == "profiles-setup") {
        oMenu.NovaFocus = 3;
        Capture = "profiles-begin";
    } else if (Capture == "profiles-begin") {
        oMenu.NovaPage = "challenges";
        oMenu.NovaChallengePage = 0;
        oMenu.NovaFocus = 1;
        Capture = "profiles-challenges";
    } else if (Capture == "profiles-challenges") {
        // Lifetime records, a challenge level and a play date give the cards realistic content.
        global.Users[0].SaveData.NovaChallengeOptions = oMenu.NovaPresets[1].values;
        global.Users[0].SaveData.TimePlayed = 4980000000;
        global.Users[1].SaveData.TimePlayed = 35940000000;
        global.Users[1].SaveData.BossesDefeated = 31;
        global.Users[1].Stats = [42, 3, 39, 5210, 48012, 417, 3288000000, 0];
        global.Users[0].Stats = [5, 0, 4, 190, 1210, 23, 0, 0];
        global.UserIndex = 0;
        with (oMenu) NovaPlayedMark();
        oMenu.NovaPage = "players";
        oMenu.NovaFocus = 0;
        Capture = "profiles-players";
    } else if (Capture == "profiles-players") {
        with (oMenu) { NovaSelectPlayer(1); NovaGo("player", 0); }
        Capture = "profiles-details";
    } else if (Capture == "profiles-details") {
        oMenu.NovaName = "WWWWWWWW";
        oMenu.NovaNameCell = 0;
        oMenu.NovaRenameNotice = "";
        oMenu.NovaPage = "rename";
        Capture = "profiles-rename";
    } else if (Capture == "profiles-rename") {
        oMenu.NovaPage = "player";
        oMenu.NovaFocus = 2;
        oMenu.NovaPlayerDialog = true;
        oMenu.NovaPlayerDialogFocus = 0;
        Capture = "profiles-delete";
    } else if (Capture == "profiles-delete") {
        oMenu.NovaPlayerDialog = false;
        global.UserIndex = 0;
        oMenu.NovaOptions = global.NovaOptionsState("title");
        oMenu.NovaOptions.tab = 2;
        oMenu.NovaPage = "options";
        Capture = "options-audio";
    } else if (Capture == "options-audio") {
        oMenu.NovaOptions.tab = 1;
        Capture = "options-display";
    } else if (Capture == "options-display") {
        // About shows the installed version beside Updates and the base game below the list.
        oMenu.NovaOptions.tab = 4;
        oMenu.NovaOptions.focus = 0;
        Capture = "options-about";
    } else if (Capture == "options-about") {
        oMenu.NovaOptions.tab = 2;
        oMenu.NovaOptions.page = "confirm";
        oMenu.NovaOptions.confirm = "tab";
        Capture = "options-defaults";
    } else if (Capture == "options-defaults") {
        oMenu.NovaOptions.tab = 3;
        oMenu.NovaOptions.page = "device";
        oMenu.NovaOptions.device = 1;
        input_profile_set("keyboard");
        Capture = "profiles-keyboard";
    } else if (Capture == "profiles-keyboard") {
        input_profile_set("gamepad");
        ProfileCaptureGamepad = input_profile_export("gamepad");
        // Item moved to Y swaps Map onto X, so the capture shows two changed actions.
        global.NovaRemapAssign("item", input_binding_gamepad_button(gp_face4), 0);
        oMenu.NovaOptions.device = 0;
        oMenu.NovaOptions.bind_focus = 2;
        oMenu.NovaOptions.notice = "";
        Capture = "options-gamepad";
    } else if (Capture == "options-gamepad") {
        // Show the scan highlight without starting a real binding scan.
        oMenu.NovaOptions.bind_focus = 1;
        oMenu.NovaOptions.capture = true;
        global.NovaRemapping = true;
        Capture = "options-remapping";
    } else if (Capture == "options-remapping") {
        oMenu.NovaOptions.capture = false;
        global.NovaRemapping = false;
        oMenu.NovaOptions.page = "confirm";
        oMenu.NovaOptions.confirm = "device";
        Capture = "options-gamepaddefaults";
    } else if (Capture == "options-gamepaddefaults") {
        oMenu.NovaOptions.page = "list";
        oMenu.NovaCreditPage = 0;
        oMenu.NovaPage = "credits";
        Capture = "options-credits";
    } else {
        input_profile_import(ProfileCaptureGamepad, "gamepad");
        oMenu.NovaOptions = global.NovaOptionsState("title");
        global.Users = ProfileCaptureUsers;
        global.UserIndex = ProfileCaptureUserIndex;
        oMenu.NovaPage = "home";
        Capture = "";
        return true;
    }
    Flush();
    return false;
}

function PlayerScreenTests() {
    var profile = input_profile_get();
    global.UserIndex = 1;
    Record("Players opens on the current player", oMenu.NovaPlayersFocusCurrent() == 1);
    with (oMenu) NovaGo("home", 0);
    var home_rows = oMenu.NovaHomeRows();
    oMenu.NovaFocus = array_get_index(home_rows, "Change player");
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Change player lands on the current player's card", oMenu.NovaPage == "players" && oMenu.NovaFocus == 1);
    Record("play time reads as hours and minutes", oMenu.NovaPlayTime(0) == "0m" && oMenu.NovaPlayTime(30000000) == "1m" && oMenu.NovaPlayTime(5400000000) == "1h 30m");
    global.Users[1].SaveData.TimePlayed = 5400000000;
    global.Users[1].Stats[6] = 3288000000;
    Record("large 64-bit play times and records are read", oMenu.NovaPlayerRun(1).time == 5400000000 && oMenu.NovaPlayerStat(1, 6) == 3288000000);
    with (oMenu) NovaPlayedMark();
    Record("last played reads as today", oMenu.NovaPlayedText(1) == "today" && string_pos("Last played today", oMenu.NovaPlayersHelp()) > 0);
    with (oMenu) NovaPlayedForget(1);
    Record("a player without a date shows none", oMenu.NovaPlayedText(1) == "");
    draw_set_font(global.MenuFont_Innactive);
    var menu = global.NovaMenuLayout();
    for (var device = 0; device < 2; device++) {
        input_profile_set(device == 0 ? "gamepad" : "keyboard");
        oMenu.NovaFocus = 1;
        var cards = oMenu.NovaPlayersFooter();
        Record("player cards offer Details, Select and Close " + string(device), array_length(cards) == 3 && cards[0].label == "Details" && cards[1].label == "Select" && cards[2].label == "Close" && cards[0].x >= menu.footer_left - 0.01);
        oMenu.NovaFocus = 3;
        var empty = oMenu.NovaPlayersFooter();
        Record("the New player card offers Create " + string(device), array_length(empty) == 2 && empty[0].label == "Create");
        var rename = oMenu.NovaRenameFooter();
        Record("rename hints fit " + string(device), rename[0].x >= menu.footer_left - 0.01 && rename[array_length(rename) - 1].right <= menu.footer_right + 0.01 && rename[array_length(rename) - 1].label == "Back");
    }
    input_profile_set(profile);
    var layout = oMenu.NovaPlayersLayout();
    Record("five player cards stay above the help line", layout.top + 5 * layout.height + 4 * layout.gap < layout.rule_y);
    var details = oMenu.NovaDetailsLayout();
    var fits = true;
    for (var i = 0; i < array_length(oMenu.NovaPlayerRecords); i++) fits = fits && 13 + string_width(oMenu.NovaPlayerRecords[i].label) * 0.6 + string_width("999999") * 0.6 + 4 < details.column_w;
    Record("record labels and values fit their columns", fits && details.column_a + details.column_w < details.column_b && details.column_b + details.column_w <= 358);

    // Rename shortcuts, the counter and a blank name.
    with (oMenu) { NovaSelectPlayer(2); NovaGo("player", 1); }
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Rename starts from the current name", oMenu.NovaPage == "rename" && oMenu.NovaName == "ZELDA");
    PressEvent(oMenu, "nova_bag_next", oMenu, ev_step, ev_step_normal);
    Record("R adds a space", oMenu.NovaName == "ZELDA ");
    for (var i = 0; i < 6; i++) PressEvent(oMenu, "nova_bag_previous", oMenu, ev_step, ev_step_normal);
    Record("L erases letters", oMenu.NovaName == "");
    oMenu.NovaNameCell = string_length(oMenu.NovaLetters) + 1;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("a blank name explains itself and keeps the old name", oMenu.NovaPage == "rename" && oMenu.NovaRenameNotice != "" && global.Users[2].Name == "ZELDA");
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Back from Rename returns to Details", oMenu.NovaPage == "player");

    // Delete asks first, starts on Cancel and forgets the player's setup and date.
    with (oMenu) { NovaPlayedMark(); NovaSetupSave(); NovaGo("player", 2); }
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Delete player opens a dialog on Cancel", oMenu.NovaPlayerDialog && oMenu.NovaPlayerDialogFocus == 0 && oMenu.NovaPage == "player");
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Back closes the dialog and keeps the player", !oMenu.NovaPlayerDialog && oMenu.NovaPage == "player" && global.Users[2].Name == "ZELDA");
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    PressEvent(oMenu, "down", oMenu, ev_step, ev_step_normal);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("confirming deletes the player and returns to Players", global.Users[2].Name == "" && oMenu.NovaPage == "players" && !oMenu.NovaPlayerDialog);
    Record("deleting forgets the setup and last played date", oMenu.NovaPlayedText(2) == "" && oMenu.NovaSetupLoad(2).bonus == 0);
    global.UserIndex = 0;
    with (oMenu) NovaGo("player", 0);
}
