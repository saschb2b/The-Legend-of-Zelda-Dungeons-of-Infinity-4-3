if (NovaOptionsOpen) {
    var options_close = keyboard_check_pressed(vk_escape) || input_check_pressed(global.NovaCloseVerb());
    // Select leaves the whole pause menu, as it does from the pause root.
    if (!options_close && !global.NovaRemapping && input_check_pressed("menu_access")) {
        NovaOptionsOpen = false;
        User_Save();
        Close = true;
        Music_Fade(1, 6);
        input_clear_momentary(true);
        exit;
    }
    if (global.NovaOptionsStep(NovaOptions, options_close) == "close") {
        NovaOptionsOpen = false;
        SelectorPos = 2;
        User_Save();
    }
    exit;
}
if (keyboard_check_pressed(vk_escape) || input_check_pressed(global.NovaCloseVerb())) {
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
