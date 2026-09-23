// The title screen and the way back to it. Both suites also move the game to the
// next context, so they run even when a filter selects other suites.
Suite("Title screen", "title", function() {
    AsyncTest("the title skip option controls the intro", function() {
        TitleStep = 0;
        Check("title skipping defaults on", variable_global_exists("CanSkipTitle") && global.CanSkipTitle);
        // The runner bundles a version file only when asked to, as the installer does.
        Check("start screens label the bundled version", global.NovaVersionLabel == (global.NovaPatchVersion == "" ? "dev" : "v" + global.NovaPatchVersion)
            && string_pos("1.1.6 VM", global.NovaVersionDetail) > 0);
        global.CanSkipTitle = false;
        oTitle.AllowStart = false;
        oTitle.ShowBG = false;
        PressEvent(oTitle, "menu_input", oTitle, ev_step, ev_step_normal);
    }, function() {
        TitleStep++;
        if (TitleStep == 1) {
            Check("disabled title skip waits for the animation", room == Room_Title);
            global.CanSkipTitle = true;
            PressEvent(oTitle, "menu_input", oTitle, ev_step, ev_step_normal);
            return false;
        }
        Check("enabled title skip opens the adventure menu", room == Room_Menu);
        if (room != Room_Menu) room_goto(Room_Menu);
        return true;
    });
}, true);

Suite("Adventure menu exit", "menu-exit", function() {
    AsyncTest("Escape on the home page returns to the title", function() {
        MenuExitStep = 0;
        with (oMenu) {
            User_Save();
            MenuWin_Main_Shift = false;
            Menu_Active = true;
            Menu_ActiveIndex = 0;
            NovaPage = "home";
        }
        PressEvent(oMenu, "escape", oMenu, ev_step, ev_step_normal);
    }, function() {
        Check("Escape returns from home to the title", room == Room_Title);
        if (room == Room_Title) PressEvent(oTitle, "menu_input", oTitle, ev_step, ev_step_normal);
        return true;
    });
}, true);
