// The redesigned pause menu handles all input here; the original list below never runs.
var pause_back = keyboard_check_pressed(vk_escape) || input_check_pressed(global.NovaCloseVerb());
if (NovaOptionsOpen) {
    // Select leaves the whole pause menu, as it does from the pause list.
    if (!pause_back && !global.NovaRemapping && input_check_pressed("menu_access")) {
        NovaOptionsOpen = false;
        User_Save();
        Close = true;
        Music_Fade(1, 6);
        input_clear_momentary(true);
        exit;
    }
    if (global.NovaOptionsStep(NovaOptions, pause_back) == "close") {
        NovaPauseFocus = NovaOptions.origin == "controls" ? 2 : 1;
        NovaOptionsOpen = false;
        User_Save();
    }
    exit;
}
if (NovaPauseDialog) {
    if (pause_back) {
        NovaPauseDialog = false;
        audio_play_sound(Sound_Throw, 1, false);
    } else if (input_check_pressed("down") || input_check_pressed("up")) {
        NovaPauseDialogFocus = 1 - NovaPauseDialogFocus;
        audio_play_sound(Sound_Text, 1, false);
    } else if (!keyboard_check(vk_alt) && input_check_pressed("menu_input")) {
        NovaPauseDialog = false;
        if (NovaPauseDialogFocus == 1) {
            QuitTo = NovaPauseFocus == 3 ? 0 : (NovaPauseFocus == 4 ? 1 : 2);
            Music_Stop();
            audio_stop_all();
            Quitting = true;
            alarm[0] = QuitDelay;
        }
        audio_play_sound(Sound_TextDone, 1, false);
    }
    input_clear_momentary(true);
    exit;
}
if (pause_back || input_check_pressed("menu_access")) {
    Close = true;
    Music_Fade(1, 6);
    audio_play_sound(Sound_Throw, 1, false);
    input_clear_momentary(true);
    exit;
}
var pause_rows = array_length(global.NovaPauseRows);
var pause_move = input_check_pressed("down") - input_check_pressed("up");
if (pause_move != 0) {
    NovaPauseFocus = (NovaPauseFocus + pause_move + pause_rows) mod pause_rows;
    audio_play_sound(Sound_Text, 1, false);
}
if (!keyboard_check(vk_alt) && input_check_pressed("menu_input")) {
    input_clear_momentary(true);
    audio_play_sound(Sound_TextDone, 1, false);
    switch (NovaPauseFocus) {
        case 0:
            Close = true;
            Music_Fade(1, 6);
            break;
        case 1:
            NovaOptions = global.NovaOptionsState("pause");
            NovaOptionsOpen = true;
            break;
        case 2:
            // Controls opens the current device's mapping directly; Back returns here.
            NovaOptions = global.NovaOptionsState("pause");
            NovaOptions.origin = "controls";
            NovaOptions.tab = array_get_index(NovaOptions.tabs, "Controls");
            NovaOptions.focus = input_profile_get() == "keyboard" ? 1 : 0;
            NovaOptions.device = NovaOptions.focus;
            NovaOptions.page = "device";
            NovaOptionsOpen = true;
            break;
        default:
            NovaPauseDialog = true;
            NovaPauseDialogFocus = 0;
            break;
    }
}
exit;
