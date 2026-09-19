if (keyboard_check_pressed(vk_escape) || input_check_pressed("action")) {
    if (Index == 0) {
        Close = true;
        Music_Fade(1, 6);
    } else {
        if (Index == 1) User_Save();
        Index = 0;
        SelectorPos = 0;
    }
    audio_play_sound(Sound_Throw, 1, false);
    input_clear_momentary(true);
    exit;
}
