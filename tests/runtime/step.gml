Ticks++;
try {
    switch (Stage) {
        case 0:
            if (!instance_exists(oTitle)) break;
            Record("title skipping defaults on", variable_global_exists("CanSkipTitle") && global.CanSkipTitle);
            global.CanSkipTitle = false;
            oTitle.AllowStart = false;
            oTitle.ShowBG = false;
            PressEvent(oTitle, "menu_input", oTitle, ev_step, ev_step_normal);
            Stage = 1;
            break;
        case 1:
            Record("disabled title skip waits for animation", room == Room_Title);
            global.CanSkipTitle = true;
            PressEvent(oTitle, "menu_input", oTitle, ev_step, ev_step_normal);
            Stage = 2;
            break;
        case 2:
            Record("enabled title skip opens profiles immediately", room == Room_Menu);
            if (room != Room_Menu) room_goto(Room_Menu);
            Stage = 3;
            break;
        case 3:
            if (!instance_exists(oMenu)) break;
            MenuTests();
            with (oMenu) {
                User_Save();
                MenuWin_Main_Shift = false;
                Menu_Active = true;
                Menu_ActiveIndex = 0;
            }
            PressEvent(oMenu, "escape", oMenu, ev_step, ev_step_normal);
            Stage = 4;
            break;
        case 4:
            Record("Escape returns from profiles to the title", room == Room_Title);
            if (room == Room_Title) PressEvent(oTitle, "menu_input", oTitle, ev_step, ev_step_normal);
            Stage = 5;
            break;
        case 5:
            if (!instance_exists(oMenu)) break;
            global.UserIndex = 0;
            with (oMenu) Menu_StartGame();
            Stage = 6;
            break;
        case 6:
            if (!instance_exists(oHUD) || !instance_exists(oLink) || global.Paused || oLink.State != 1) break;
            PauseTests();
            EnemyTests();
            BackportTests();
            ProgressionTests();
            InventoryTests();
            SwordTests();
            if (file_exists("nova-capture-enabled.txt")) {
                CaptureStart();
                Stage = 7;
                break;
            }
            Complete = true;
            Flush();
            game_end();
            break;
        case 7:
            CaptureStep();
            break;
    }
    if (Ticks > 3600) throw "Runtime harness timed out at stage " + string(Stage);
} catch (error) {
    Record("runtime exception: " + string(error), false);
    Complete = true;
    Flush();
    game_end();
}
