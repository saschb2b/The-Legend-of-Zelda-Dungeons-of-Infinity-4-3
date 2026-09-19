// The action button remains backspace during name entry. Escape discards the edit.
if (Menu_Active && !Bindings_Remap && (keyboard_check_pressed(vk_escape) || (Menu_ActiveIndex != 5 && !keyboard_check(vk_alt) && input_check_pressed("action")))) {
    switch (Menu_ActiveIndex) {
        case 0:
            audio_stop_all();
            room_goto(Room_Title);
            break;
        case 1:
        case 2:
            Win_Main_Activate(0);
            break;
        case 3:
        case 4:
        case 8:
            Win_Main_Activate(global.Users[global.UserIndex].SaveData == -1 ? 1 : 2);
            break;
        case 5:
            Win_Main_Activate(NameEntry_Rename ? 6 : 0);
            NameEntry_Rename = false;
            NameEntry_Name = "";
            break;
        case 6:
        case 12:
            Win_Main_Activate(4, false);
            break;
        case 7:
            Win_Main_Activate(6, false);
            break;
        case 9:
        case 10:
            Menu_ActiveIndex = 3;
            MenuWin_Options_MenuIndex = 3;
            Selector_Index_Options = 0;
            break;
        case 11:
            Win_Options_Activate(3);
            break;
        case 13:
        case 14:
            Win_Main_Activate(12, false);
            break;
    }
    audio_play_sound(Sound_Throw, 1, false);
    input_clear_momentary(true);
    exit;
}
