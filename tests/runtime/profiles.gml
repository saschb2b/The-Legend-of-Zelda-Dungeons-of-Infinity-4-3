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
        Record("Eight-letter names clear the progress column " + string(device), 86 + string_width(maximum.name) + 8 <= 190);
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
    Record("Manage opens the highlighted player's records and settings", global.UserIndex == 0 && oMenu.NovaPage == "player");
    oMenu.NovaFocus = 2;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    oMenu.NovaName = "Test";
    oMenu.NovaNameCell = string_length(oMenu.NovaLetters) + 1;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Saving a name returns to Rename with the new name", global.Users[0].Name == "Test" && oMenu.NovaPage == "player" && oMenu.NovaFocus == 2);
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
        Capture = "profiles-setup";
    } else if (Capture == "profiles-setup") {
        oMenu.NovaPage = "challenges";
        oMenu.NovaFocus = 0;
        Capture = "profiles-challenges";
    } else if (Capture == "profiles-challenges") {
        oMenu.NovaPage = "players";
        Capture = "profiles-players";
    } else if (Capture == "profiles-players") {
        oMenu.NovaOptions = global.NovaOptionsState("title");
        oMenu.NovaOptions.tab = 2;
        oMenu.NovaPage = "options";
        Capture = "options-audio";
    } else if (Capture == "options-audio") {
        oMenu.NovaOptions.tab = 1;
        Capture = "options-display";
    } else if (Capture == "options-display") {
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
    } else {
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
