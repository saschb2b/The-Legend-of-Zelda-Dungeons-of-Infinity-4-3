// Leaving adventure menu pages with Close, Back and Escape.
Suite("Adventure menu navigation", "menu", function() {
    BeforeAll(function() {
        global.UserIndex = 0;
        global.Users[0] = new User_Create();
        global.Users[0].Name = "HARNESS";
        DungeonSeq_Init(0);
        oMenu.NovaTransition = 36;
    });
    Test("Close and Escape return to each page's parent", function() {
        var cases = [["setup", "home"], ["players", "home"], ["options", "home"], ["challenges", "setup"], ["replace", "setup"], ["player", "players"], ["rename", "player"], ["credits", "options"]];
        for (var i = 0; i < array_length(cases); i++) {
            for (var key = 0; key < 2; key++) {
                oMenu.NovaPage = cases[i][0];
                PressEvent(oMenu, key == 0 ? global.NovaCloseVerb() : "escape", oMenu, ev_step, ev_step_normal);
                Check(cases[i][0] + " returns to " + cases[i][1] + " via " + (key == 0 ? "Close" : "Escape"), oMenu.NovaPage == cases[i][1]);
            }
        }
    });
    Test("closing rename discards the draft", function() {
        oMenu.NovaPage = "rename";
        oMenu.NovaName = "UNSAVED";
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("the saved name is unchanged", global.Users[0].Name == "HARNESS");
    });
    Test("the delete dialog defaults to keeping the player", function() {
        oMenu.NovaPage = "player";
        oMenu.NovaPlayerDialog = true;
        oMenu.NovaPlayerDialogFocus = 0;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("confirming the default keeps the player", global.Users[0].Name == "HARNESS" && !oMenu.NovaPlayerDialog && oMenu.NovaPage == "player");
    });
    Test("Close waits for a binding scan and Pause cancels it", function() {
        oMenu.NovaPage = "options";
        oMenu.NovaOptions.page = "device";
        oMenu.NovaOptions.device = 1;
        oMenu.NovaOptions.capture = true;
        global.NovaRemapping = true;
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("Close does not interrupt the scan", oMenu.NovaPage == "options" && oMenu.NovaOptions.page == "device" && oMenu.NovaOptions.capture);
        PressEvent(oMenu, "menu_access", oMenu, ev_step, ev_step_normal);
        Check("Pause cancels the scan", !oMenu.NovaOptions.capture && !global.NovaRemapping && oMenu.NovaOptions.page == "device");
        oMenu.NovaOptions.page = "list";
        global.StartingGear = 0;
    });
});
