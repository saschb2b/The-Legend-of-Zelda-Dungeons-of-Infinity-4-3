// New adventure setup: the challenge list, presets, the remembered setup and the page layout.
// Opens a fresh draft with default challenges and moves from setup's Challenges row to its list.
function ChallengesOpen() {
    global.NovaResetChallenges();
    with (oMenu) { NovaNewDraft(); NovaFocus = 2; }
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
}

Suite("Challenges", "menu", function() {
    Test("setup's Challenges row opens the list in the same frame", function() {
        ChallengesOpen();
        Check("Challenges replace setup in the same frame", oMenu.NovaPage == "challenges");
    });
    Test("left and confirm cycle a draft challenge", function() {
        ChallengesOpen();
        PressEvent(oMenu, "left", oMenu, ev_step, ev_step_normal);
        Check("draft challenge wraps backwards", oMenu.NovaDraft.challenges[0] == 3);
        Check("draft challenge leaves gameplay settings alone", global.NovaOption(0) == 0);
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("confirm cycles the draft challenge", oMenu.NovaDraft.challenges[0] == 0);
    });
    Test("every challenge option is reachable", function() {
        ChallengesOpen();
        for (var page = 0; page < 3; page++) {
            oMenu.NovaChallengePage = page;
            var indexes = oMenu.NovaChallengePages[page];
            for (var row = 0; row < array_length(indexes); row++) {
                oMenu.NovaFocus = row;
                PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
                Check("challenge option " + string(indexes[row]) + " is reachable", oMenu.NovaDraft.challenges[indexes[row]] == 1);
            }
        }
    });
    Test("the shoulders wrap between challenge pages", function() {
        ChallengesOpen();
        oMenu.NovaChallengePage = 2;
        oMenu.NovaFocus = array_length(oMenu.NovaChallengePages[2]) - 1;
        PressEvent(oMenu, "nova_bag_next", oMenu, ev_step, ev_step_normal);
        Check("next shoulder wraps to Survival", oMenu.NovaChallengePage == 0 && oMenu.NovaFocus == 0);
        PressEvent(oMenu, "nova_bag_previous", oMenu, ev_step, ev_step_normal);
        Check("previous shoulder wraps to Restrictions", oMenu.NovaChallengePage == 2);
    });
    Test("Defaults clears the draft challenges only after confirmation", function() {
        ChallengesOpen();
        // Every challenge raised one step, as after visiting each option.
        for (var i = 0; i < 12; i++) oMenu.NovaDraft.challenges[i] = 1;
        var before_defaults = json_stringify(oMenu.NovaDraft.challenges);
        PressEvent(oMenu, "item", oMenu, ev_step, ev_step_normal);
        Check("Defaults asks before clearing challenges", oMenu.NovaChallengeDialog && oMenu.NovaChallengeDialogFocus == 0);
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("Back from the dialog keeps challenges and the page", !oMenu.NovaChallengeDialog && oMenu.NovaPage == "challenges" && json_stringify(oMenu.NovaDraft.challenges) == before_defaults);
        PressEvent(oMenu, "item", oMenu, ev_step, ev_step_normal);
        PressEvent(oMenu, "down", oMenu, ev_step, ev_step_normal);
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("Restore defaults clears all draft challenges", !oMenu.NovaChallengeDialog && json_stringify(oMenu.NovaDraft.challenges) == json_stringify(array_create(12, 0)));
    });
    Test("closing Challenges returns to its setup row", function() {
        ChallengesOpen();
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("closing challenges restores its setup row", oMenu.NovaPage == "setup" && oMenu.NovaFocus == 2);
    });
});

// The tests run in order on one player fixture: player 0 has a saved run with character 4.
Suite("New adventure setup", "menu", function() {
    BeforeAll(function() {
        SetupUsers = global.Users;
        SetupUserIndex = global.UserIndex;
        global.Users = [ProfileFixture("LINK", 4, 4, 3.5, 5), new User_Create(), new User_Create(), new User_Create(), new User_Create()];
        global.UserIndex = 0;
    });
    Test("without a remembered setup the saved run's character is kept", function() {
        with (oMenu) NovaSetupForget(0);
        with (oMenu) NovaNewDraft();
        Check("the saved run's character and Hero's Path are selected", oMenu.NovaDraft.character == 4 && oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 0);
    });
    Test("right cycles through the challenge presets", function() {
        with (oMenu) NovaNewDraft();
        oMenu.NovaFocus = 2;
        PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
        Check("right selects Second Quest", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 1 && oMenu.NovaChallengeLevel(oMenu.NovaDraft.challenges) > 0);
        PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
        var master = oMenu.NovaChallengeLevel(oMenu.NovaDraft.challenges);
        Check("Master Quest is harder than Second Quest", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 2 && master > oMenu.NovaChallengeLevel(oMenu.NovaPresets[1].values));
        PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
        Check("presets wrap to Hero's Path", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 0);
    });
    Test("a custom mix reads as Custom and stays reachable", function() {
        with (oMenu) NovaNewDraft();
        oMenu.NovaFocus = 2;
        oMenu.NovaDraft.challenges[10] = 1;
        Check("a changed mix reads as Custom", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == -1);
        PressEvent(oMenu, "right", oMenu, ev_step, ev_step_normal);
        PressEvent(oMenu, "left", oMenu, ev_step, ev_step_normal);
        Check("a custom mix stays reachable after browsing presets", oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == -1 && oMenu.NovaDraft.challenges[10] == 1);
    });
    Test("Random picks a different character", function() {
        with (oMenu) NovaNewDraft();
        oMenu.NovaFocus = 0;
        var before_random = oMenu.NovaDraft.character;
        PressEvent(oMenu, "item", oMenu, ev_step, ev_step_normal);
        Check("Random changes the character and stays on setup", oMenu.NovaDraft.character != before_random && oMenu.NovaPage == "setup");
    });
    Test("Begin remembers the setup for each player", function() {
        with (oMenu) NovaNewDraft();
        oMenu.NovaFocus = 0;
        oMenu.NovaDraft.challenges[10] = 1;
        oMenu.NovaDraft.character = 6;
        oMenu.NovaDraft.bonus = 4;
        global.NovaTestStart = false;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("confirm on the character row goes to Begin's replacement check", oMenu.NovaPage == "replace");
        PressEvent(oMenu, "down", oMenu, ev_step, ev_step_normal);
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("beginning starts the run", global.NovaTestStart);
        with (oMenu) NovaNewDraft();
        Check("the last setup is remembered for this player", oMenu.NovaDraft.character == 6 && oMenu.NovaDraft.bonus == 4 && oMenu.NovaDraft.challenges[10] == 1);
        global.UserIndex = 1;
        with (oMenu) NovaNewDraft();
        Check("another player keeps its own setup", oMenu.NovaDraft.character == 0 && oMenu.NovaDraft.bonus == 0 && oMenu.NovaPresetIndex(oMenu.NovaDraft.challenges) == 0);
        global.UserIndex = 0;
        with (oMenu) NovaSetupForget(0);
        Check("deleting a player forgets its setup", oMenu.NovaSetupLoad(0).bonus == 0);
    });
    Test("a damaged remembered setup falls back safely", function() {
        ini_open("nova-menu.ini");
        ini_write_string("Setup", "Player0", "3,x,{");
        ini_close();
        Check("the saved run's character and no bonus are used", oMenu.NovaSetupLoad(0).bonus == 0 && oMenu.NovaSetupLoad(0).character == 4);
    });
    Test("save cards carry the challenge level", function() {
        global.Users[0].SaveData.NovaChallengeOptions = oMenu.NovaPresets[2].values;
        Check("the card shows Master Quest's level", oMenu.NovaProfileSummary(0).level == oMenu.NovaChallengeLevel(oMenu.NovaPresets[2].values));
    });
    Test("the bonus, preview and Begin fit the setup page", function() {
        draw_set_font(global.MenuFont_Innactive);
        var layout = oMenu.NovaSetupLayout();
        var longest = 0;
        for (var i = 0; i < array_length(oMenu.NovaBonusNames); i++) longest = max(longest, string_width(oMenu.NovaBonusNames[i]) * 0.85);
        Check("the longest bonus fits beside its icon", layout.column + 22 + longest < 350);
        Check("the preview and Begin stay above the help line", layout.preview_y + layout.preview_h + 34 < layout.rule_y && layout.begin_y + layout.begin_h < layout.rule_y);
    });
    Test("setup and challenge help fits in two lines", function() {
        draw_set_font(global.MenuFont_Innactive);
        var options = global.NovaOptionsLayout();
        var help_ok = true;
        var line = string_height("A") + 4;
        for (var i = 0; i < 12; i++) help_ok = help_ok && string_height_ext(oMenu.NovaChallengeHelp[i], line, options.help_width / 0.6) / line <= 2.01;
        for (var i = 0; i < 3; i++) help_ok = help_ok && string_height_ext(oMenu.NovaPresets[i].help, line, options.help_width / 0.6) / line <= 2.01;
        for (var i = 0; i < 8; i++) help_ok = help_ok && string_height_ext(oMenu.NovaBonusHelp[i], line, options.help_width / 0.6) / line <= 2.01;
        Check("challenge, preset and bonus help fit in two lines", help_ok);
    });
    Test("the challenge summary clears the breadcrumb", function() {
        var crumbs = global.NovaMenuTitleParts(["New adventure", "Challenges"]);
        draw_set_font(global.MenuFont_Innactive);
        var summary_width = string_width("Custom  Level 30") * 0.7;
        Check("the widest summary clears the breadcrumb", crumbs[1].x + crumbs[1].width + 8 < 358 - summary_width);
    });
    Test("setup selectors clear the value arrows", function() {
        var layout = oMenu.NovaSetupLayout();
        Check("the selector ends before the arrows", layout.selector + 18 < layout.column - 11);
    });
    Test("the setup footer fits every row", function() {
        draw_set_font(global.MenuFont_Innactive);
        for (var device = 0; device < 2; device++) {
            input_profile_set(device == 0 ? "gamepad" : "keyboard");
            var menu = global.NovaMenuLayout();
            for (var focus = 0; focus < 4; focus++) {
                oMenu.NovaFocus = focus;
                var hints = oMenu.NovaSetupFooter();
                var last = hints[array_length(hints) - 1];
                Check("setup footer fits row " + string(focus) + " with the " + (device == 0 ? "gamepad" : "keyboard"), hints[0].x >= menu.footer_left - 0.01 && last.right <= menu.footer_right + 0.01 && last.label == "Close");
            }
        }
        input_profile_set("gamepad");
        with (oMenu) NovaSetupForget(0);
        global.Users = SetupUsers;
        global.UserIndex = SetupUserIndex;
        global.LinkCharacterIndex = 0;
        global.StartingGear = 0;
        global.NovaResetChallenges();
        with (oMenu) NovaGo("home", 0);
    });
});
