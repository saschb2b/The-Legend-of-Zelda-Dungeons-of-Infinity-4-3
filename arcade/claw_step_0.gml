if (global.AltTab) exit;
if (DB_Init && !Paid) {
    global.DB_ExitCode = 0;
    global.DB_Inst = instance_create_layer(0,0,"System",oDialogueBox);
    global.DB_Inst.Script = DB_Script;
    global.DB_Inst.NovaShopDialogue = true;
    DB_Init = false;
    DB_Started = true;
    input_clear_momentary(true);
}
if (DB_Started && !instance_exists(global.DB_Inst)) {
    DB_Started = false;
    if (global.DB_ExitCode == 1) StartRound();
}
if (!Paid) exit;
if (input_check_pressed(global.NovaCloseVerb()) || keyboard_check_pressed(vk_escape)) { SettleRound(); exit; }
switch (State) {
    case 2:
        var move_x = input_check("right") - input_check("left");
        ClawX = clamp(ClawX + move_x*0.1,0,11);
        if (move_x != 0) {
            if (!audio_is_playing(Sound_ClawMachine_Motor)) audio_play_sound(Sound_ClawMachine_Motor,1,true);
        } else audio_stop_sound(Sound_ClawMachine_Motor);
        if (input_check_pressed(global.NovaConfirmVerb())) GrabPrize();
        break;
    case 3:
        ClawY = min(4,ClawY+0.08);
        if (ClawY >= 4) {
            State = 4; Timer = 45;
            audio_play_sound(Sound_ClawMachine_Land,1,false);
        }
        break;
    case 4:
        Timer--;
        if (Timer == 0) { ClawImg = 0; State = 9; Timer = 45; }
        break;
    case 9:
        Timer--;
        if (Timer == 0) { State = 5; audio_play_sound(Sound_ClawMachine_Raise,1,false); }
        break;
    case 5:
        ClawX = max(0,ClawX-0.1);
        ClawY = max(0,ClawY-0.08);
        if (ClawX == 0 && ClawY == 0) {
            State = 6;
            Timer = Win ? 60 : 100;
            audio_stop_sound(Sound_ClawMachine_Raise);
            audio_play_sound(Win ? Sound_ClawMachine_GotItem : Sound_ClawMachine_Lose,1,false);
        }
        break;
    case 6:
        Timer--;
        if (Timer == 0) {
            if (!Win) { SettleRound(); break; }
            DropItem = true; ClawImg = 1;
        }
        if (DropItem) {
            DropItemY += DropItemSpeed;
            DropItemSpeed += 0.02;
            if (DropItemY >= 12) { State = 7; Timer = 45; }
        }
        break;
    case 7:
        Timer--;
        if (Timer == 0) SettleRound();
        break;
}
