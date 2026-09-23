// Players in the adventure menu: save previews, choosing and creating players, Continue,
// and the Players screen with its cards, Details, Rename and Delete.
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
// Two saved runs, a named player without a run and two empty slots.
function ProfileFixtureUsers() {
    return [ProfileFixture("LINK", 0, 4, 3.5, 5), ProfileFixture("WWWWWWWW", 8, 20, 19.25, 99), ProfileFixture("ZELDA", 2, 0, 0, 0), new User_Create(), new User_Create()];
}

// The tests run in order on one set of players; ProfileSaves holds their bytes before any test.
Suite("Player profiles", "menu", function() {
    BeforeAll(function() {
        ProfileUsers = global.Users;
        ProfileUserIndex = global.UserIndex;
        ProfileInput = input_profile_get();
        global.Users = ProfileFixtureUsers();
        global.UserIndex = 0;
        ProfileSaves = json_stringify(global.Users);
        oMenu.NovaPage = "home";
        oMenu.NovaFocus = 0;
    });
    Test("Continue leads the menu of a saved player", function() {
        var home_rows = oMenu.NovaHomeRows();
        Check("Continue is the first row", home_rows[0] == "Continue");
    });
    Test("save previews show only recorded progress", function() {
        var saved = oMenu.NovaProfileSummary(0);
        Check("save preview uses recorded health and floor", saved.saved && saved.hearts == 4 && saved.health == 3.5 && saved.floor == 5);
        var maximum = oMenu.NovaProfileSummary(1);
        Check("save preview retains character and maximum hearts", maximum.character == 8 && maximum.hearts == 20 && maximum.health == 19.25);
        var fresh = oMenu.NovaProfileSummary(2);
        Check("named player without a run shows no invented progress", !fresh.saved && fresh.hearts == 0);
    });
    Test("Players lists occupied slots and one Create player action", function() {
        var player_rows = oMenu.NovaPlayerRows();
        Check("three players and one empty slot are listed", array_length(oMenu.NovaPlayerRows()) == 4 && player_rows[3] == 3);
    });
    Test("the menu frame, hints and player cards fit", function() {
        var maximum = oMenu.NovaProfileSummary(1);
        for (var device = 0; device < 2; device++) {
            var device_name = device == 0 ? "gamepad" : "keyboard";
            input_profile_set(device_name);
            var layout = oMenu.NovaMenuLayout();
            Check("menu frame fits the 4:3 view with the " + device_name, layout.x >= 8 && layout.x + layout.width <= 392 && layout.header_y >= -30 && layout.y + layout.height < 254);
            Check("menu hints sit below the frame with the " + device_name, layout.footer_y - 8 >= layout.y + layout.height + 8 && layout.footer_y + 8 <= 258);
            var select = oMenu.NovaFooterLayout("Select");
            var resume = oMenu.NovaFooterLayout("Continue");
            Check("menu actions precede Close with the " + device_name, select[0].right < select[1].x && select[1].label == "Close");
            Check("menu glyphs stay anchored as labels change with the " + device_name, select[0].icon_x == resume[0].icon_x && select[1].x == resume[1].x && select[1].right == layout.footer_right);
            with (oMenu) NovaAdventureDraw();
            oMenu.NovaPage = "players";
            with (oMenu) NovaAdventureDraw();
            draw_set_font(global.MenuFont_Innactive);
            var cards = oMenu.NovaPlayersLayout();
            Check("eight-letter names and the current tag clear the stats column with the " + device_name, cards.name_x + string_width(maximum.name) * 0.8 + 8 + string_width("CURRENT") * 0.5 + 6 <= cards.stats_x);
            oMenu.NovaPage = "home";
        }
        Check("drawing previews leaves all saves untouched", json_stringify(global.Users) == ProfileSaves);
    });
    Test("New adventure opens on Begin", function() {
        with (oMenu) NovaNewDraft();
        Check("Begin is selected when new adventure opens", oMenu.NovaPage == "setup" && oMenu.NovaFocus == 3);
    });
    Test("every character and bonus is reachable", function() {
        with (oMenu) NovaNewDraft();
        oMenu.NovaFocus = 0;
        for (var i = 1; i <= 9; i++) {
            PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
            Check("character " + string(i mod 9) + " is reachable", oMenu.NovaDraft.character == i mod 9);
        }
        oMenu.NovaFocus = 1;
        for (var i = 1; i <= 8; i++) {
            PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
            Check("bonus " + string(i mod 8) + " is reachable", oMenu.NovaDraft.bonus == i mod 8);
        }
    });
    Test("replacing a saved adventure asks first and Close keeps the save", function() {
        with (oMenu) NovaNewDraft();
        oMenu.NovaDraft.character = 8;
        oMenu.NovaDraft.bonus = 7;
        oMenu.NovaDraft.challenges[9] = 1;
        oMenu.NovaFocus = 3;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("replacing a saved adventure requires explicit confirmation", oMenu.NovaPage == "replace" && oMenu.NovaFocus == 0);
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("default replacement choice keeps the save and draft", oMenu.NovaPage == "setup" && oMenu.NovaDraft.character == 8 && json_stringify(global.Users) == ProfileSaves);
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("closing setup preserves all save bytes", json_stringify(global.Users) == ProfileSaves);
    });
    Test("Create player opens setup without naming the player", function() {
        oMenu.NovaPage = "players";
        oMenu.NovaFocus = 3;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("Create player opens setup without registering a name", oMenu.NovaPage == "setup" && global.UserIndex == 3 && global.Users[3].Name == "");
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("closing Create player restores the originating row and selected save", oMenu.NovaPage == "players" && oMenu.NovaFocus == 3 && global.UserIndex == 0 && json_stringify(global.Users) == ProfileSaves);
    });
    Test("choosing a player returns to its adventure", function() {
        oMenu.NovaPage = "players";
        oMenu.NovaFocus = 1;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("the chosen player's home page opens", global.UserIndex == 1 && oMenu.NovaPage == "home" && oMenu.NovaFocus == 0);
    });
    Test("Details opens the highlighted player's records and actions", function() {
        oMenu.NovaPage = "players";
        oMenu.NovaFocus = 0;
        PressEvent(oMenu, "item", oMenu, ev_step, ev_step_normal);
        Check("Details opens for the highlighted player", global.UserIndex == 0 && oMenu.NovaPage == "player" && oMenu.NovaFocus == 0);
        PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
        Check("Details actions move left and right", oMenu.NovaFocus == 1);
    });
    Test("saving a name returns to Rename on Details", function() {
        oMenu.NovaPage = "player";
        oMenu.NovaFocus = 1;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        oMenu.NovaName = "Test";
        oMenu.NovaNameCell = string_length(oMenu.NovaLetters) + 1;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("the new name is saved and Rename stays selected", global.Users[0].Name == "Test" && oMenu.NovaPage == "player" && oMenu.NovaFocus == 1);
    });
    Test("an incompatible save cannot be continued", function() {
        global.Users[0].Name = "LINK";
        global.NovaTestContinue = false;
        with (oMenu) NovaContinue();
        Check("the save error page opens instead", !global.NovaTestContinue && oMenu.NovaPage == "save-error");
    });
    Test("one confirm on Continue resumes the saved adventure", function() {
        global.Users[0].SaveData.GameVersion = "1.1.6 - VM";
        with (oMenu) NovaGo("home", 0);
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("Continue resumes the run", global.NovaTestContinue);
        Check("Continue does not apply discarded character or bonus", global.Users[0].SaveData.LinkCharacterIndex == 0 && oMenu.NovaProfileSummary(0).floor == 5);
    });
    Test("a fresh player begins without name entry", function() {
        global.UserIndex = 3;
        with (oMenu) NovaNewDraft();
        var home_rows = oMenu.NovaHomeRows();
        Check("fresh player leads with New adventure", home_rows[0] == "New adventure");
        global.NovaTestStart = false;
        oMenu.NovaDraft.character = 4;
        oMenu.NovaDraft.bonus = 2;
        oMenu.NovaDraft.challenges[9] = 1;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("a fresh adventure starts without name entry", global.NovaTestStart && global.Users[3].Name == "Link");
        Check("Begin applies the draft only at the start boundary", global.LinkCharacterIndex == 4 && global.StartingGear == 2 && global.Challenges[3] && !global.Continue);
    });
    Test("the last selected player survives menu initialization", function() {
        with (oMenu) NovaRestorePlayer();
        Check("the player who began is selected again", global.UserIndex == 3);
        global.Users = ProfileUsers;
        global.UserIndex = ProfileUserIndex;
        global.LinkCharacterIndex = 0;
        global.StartingGear = 0;
        global.NovaResetChallenges();
        input_profile_set(ProfileInput);
        with (oMenu) { NovaRememberPlayer(); NovaGo("home", 0); }
    });
});

// The tests run in order on one set of players, as the Players screen is used.
Suite("Players screen", "menu", function() {
    BeforeAll(function() {
        PlayersUsers = global.Users;
        PlayersUserIndex = global.UserIndex;
        global.Users = ProfileFixtureUsers();
    });
    Test("Change player opens on the current player's card", function() {
        global.UserIndex = 1;
        Check("Players focuses the current player", oMenu.NovaPlayersFocusCurrent() == 1);
        with (oMenu) NovaGo("home", 0);
        var home_rows = oMenu.NovaHomeRows();
        oMenu.NovaFocus = array_get_index(home_rows, "Change player");
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("Change player lands on the current player's card", oMenu.NovaPage == "players" && oMenu.NovaFocus == 1);
    });
    Test("play time reads as hours and minutes", function() {
        Check("minutes round up and hours split off", oMenu.NovaPlayTime(0) == "0m" && oMenu.NovaPlayTime(30000000) == "1m" && oMenu.NovaPlayTime(5400000000) == "1h 30m");
    });
    Test("large 64-bit play times and records are read", function() {
        global.Users[1].SaveData.TimePlayed = 5400000000;
        global.Users[1].Stats[6] = 3288000000;
        Check("the run time and record keep their values", oMenu.NovaPlayerRun(1).time == 5400000000 && oMenu.NovaPlayerStat(1, 6) == 3288000000);
    });
    Test("the last played date reads as today and can be forgotten", function() {
        global.UserIndex = 1;
        oMenu.NovaPage = "players";
        oMenu.NovaFocus = 1;
        with (oMenu) NovaPlayedMark();
        Check("last played reads as today", oMenu.NovaPlayedText(1) == "today" && string_pos("Last played today", oMenu.NovaPlayersHelp()) > 0);
        with (oMenu) NovaPlayedForget(1);
        Check("a player without a date shows none", oMenu.NovaPlayedText(1) == "");
    });
    Test("player card and rename hints fit", function() {
        var profile = input_profile_get();
        draw_set_font(global.MenuFont_Innactive);
        var menu = global.NovaMenuLayout();
        for (var device = 0; device < 2; device++) {
            var device_name = device == 0 ? "gamepad" : "keyboard";
            input_profile_set(device_name);
            oMenu.NovaFocus = 1;
            var cards = oMenu.NovaPlayersFooter();
            Check("player cards offer Details, Select and Close with the " + device_name, array_length(cards) == 3 && cards[0].label == "Details" && cards[1].label == "Select" && cards[2].label == "Close" && cards[0].x >= menu.footer_left - 0.01);
            oMenu.NovaFocus = 3;
            var empty = oMenu.NovaPlayersFooter();
            Check("the New player card offers Create with the " + device_name, array_length(empty) == 2 && empty[0].label == "Create");
            var rename = oMenu.NovaRenameFooter();
            Check("rename hints fit with the " + device_name, rename[0].x >= menu.footer_left - 0.01 && rename[array_length(rename) - 1].right <= menu.footer_right + 0.01 && rename[array_length(rename) - 1].label == "Back");
        }
        input_profile_set(profile);
    });
    Test("five player cards stay above the help line", function() {
        var layout = oMenu.NovaPlayersLayout();
        Check("the fifth card ends above the rule", layout.top + 5 * layout.height + 4 * layout.gap < layout.rule_y);
    });
    Test("record labels and values fit their columns", function() {
        draw_set_font(global.MenuFont_Innactive);
        var details = oMenu.NovaDetailsLayout();
        var fits = true;
        for (var i = 0; i < array_length(oMenu.NovaPlayerRecords); i++) fits = fits && 13 + string_width(oMenu.NovaPlayerRecords[i].label) * 0.6 + string_width("999999") * 0.6 + 4 < details.column_w;
        Check("every record fits and the columns stay apart", fits && details.column_a + details.column_w < details.column_b && details.column_b + details.column_w <= 358);
    });
    Test("Rename shortcuts edit the name and a blank name is refused", function() {
        with (oMenu) { NovaSelectPlayer(2); NovaGo("player", 1); }
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("Rename starts from the current name", oMenu.NovaPage == "rename" && oMenu.NovaName == "ZELDA");
        PressEvent(oMenu, "nova_bag_next", oMenu, ev_step, ev_step_normal);
        Check("R adds a space", oMenu.NovaName == "ZELDA ");
        for (var i = 0; i < 6; i++) PressEvent(oMenu, "nova_bag_previous", oMenu, ev_step, ev_step_normal);
        Check("L erases letters", oMenu.NovaName == "");
        oMenu.NovaNameCell = string_length(oMenu.NovaLetters) + 1;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("a blank name explains itself and keeps the old name", oMenu.NovaPage == "rename" && oMenu.NovaRenameNotice != "" && global.Users[2].Name == "ZELDA");
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("Back from Rename returns to Details", oMenu.NovaPage == "player");
    });
    Test("Delete asks first and forgets the player's setup and date", function() {
        with (oMenu) { NovaSelectPlayer(2); NovaPlayedMark(); NovaSetupSave(); NovaGo("player", 2); }
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("Delete player opens a dialog on Cancel", oMenu.NovaPlayerDialog && oMenu.NovaPlayerDialogFocus == 0 && oMenu.NovaPage == "player");
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("Back closes the dialog and keeps the player", !oMenu.NovaPlayerDialog && oMenu.NovaPage == "player" && global.Users[2].Name == "ZELDA");
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        PressEvent(oMenu, "down", oMenu, ev_step, ev_step_normal);
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("confirming deletes the player and returns to Players", global.Users[2].Name == "" && oMenu.NovaPage == "players" && !oMenu.NovaPlayerDialog);
        Check("deleting forgets the setup and last played date", oMenu.NovaPlayedText(2) == "" && oMenu.NovaSetupLoad(2).bonus == 0);
        global.Users = PlayersUsers;
        global.UserIndex = PlayersUserIndex;
        with (oMenu) { NovaRememberPlayer(); NovaGo("home", 0); }
    });
});
