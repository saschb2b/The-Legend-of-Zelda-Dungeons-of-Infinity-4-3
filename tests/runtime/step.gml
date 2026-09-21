// Screenshot transfer time is bounded by the host's wall-clock deadline.
if (Capture == "") Ticks++;
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
            Record("enabled title skip opens the adventure menu", room == Room_Menu);
            if (room != Room_Menu) room_goto(Room_Menu);
            Stage = 3;
            break;
        case 3:
            if (!instance_exists(oMenu)) break;
            MenuTests();
            ContentMenuTests();
            ProfileMenuTests();
            UpdateMenuTests();
            if (file_exists("nova-capture-enabled.txt") || file_exists("nova-profile-capture-enabled.txt")) {
                ProfileCaptureStart();
                Stage = 10;
                break;
            }
            Stage = 11;
            break;
        case 10:
            if (ProfileCaptureStep()) Stage = 11;
            break;
        case 11:
            if (file_exists("nova-capture-enabled.txt") || file_exists("nova-update-capture-enabled.txt")) {
                input_profile_set("gamepad");
                with (oMenu) NovaUpdateEnter();
                UpdateStatus("available", oMenu.NovaUpdateId, "An update is available.");
                with (oMenu) NovaUpdatePoll();
                Capture = "updates-available";
                Flush();
                Stage = 8;
                break;
            }
            Stage = 9;
            break;
        case 8:
            if (!file_exists("nova-capture-done.txt")) break;
            file_delete("nova-capture-done.txt");
            if (Capture == "updates-available") {
                oMenu.NovaUpdateState.state = "error";
                oMenu.NovaUpdateState.message = "Update failed. Check Wi-Fi and try again.";
                file_delete("nova-update-status.json");
                Capture = "updates-error";
                Flush();
                break;
            }
            with (oMenu) NovaUpdateClose();
            input_profile_set("keyboard");
            Capture = "";
            Stage = 9;
            break;
        case 9:
            with (oMenu) {
                User_Save();
                MenuWin_Main_Shift = false;
                Menu_Active = true;
                Menu_ActiveIndex = 0;
                NovaPage = "home";
            }
            PressEvent(oMenu, "escape", oMenu, ev_step, ev_step_normal);
            Stage = 4;
            break;
        case 4:
            Record("Escape returns from home to the title", room == Room_Title);
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
            MovementTests();
            PauseTests();
            EnemyTests();
            BackportTests();
            ProgressionTests();
            InventoryTests();
            SwordTests();
            ContentTests();
            ControlTests();
            HUDTests();
            CRTTests();
            ShopTests();
            ContextTests();
            ArcadeTests();
            CRTBenchmarkStart();
            Stage = 16;
            break;
        case 16:
            if (!CRTBenchmarkStep()) break;
            ArcadeTravelStart();
            Stage = 15;
            break;
        case 15:
            if (!ArcadeTravelStep()) break;
            if (file_exists("nova-arcade-capture-enabled.txt")) { ArcadeCaptureStart(); Stage = 14; break; }
            if (file_exists("nova-context-capture-enabled.txt")) { ContextCaptureStart(); Stage = 13; break; }
            if (file_exists("nova-capture-enabled.txt")) {
                CaptureStart();
                Stage = 7;
                break;
            }
            Complete = true;
            Flush();
            game_end();
            break;
        case 14:
            ArcadeCaptureStep();
            break;
        case 13:
            ContextCaptureStep();
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
