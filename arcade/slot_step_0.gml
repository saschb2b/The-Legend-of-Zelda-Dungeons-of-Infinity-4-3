if (global.AltTab) exit;
if (State == 0) {
    if (global.Paused) exit;
    event_inherited();
    if (State != 1) exit;
    global.Arcade_ActiveInst = id;
    Arcade_SetCam(CamW, CamH);
    global.ArcadeVP_Show = true;
    global.Paused = true;
    oLink.actionVideoGame = true;
    with (oLink) UpdateState(26);
    Music_Fade(0.25,12);
    State = 2;
    input_clear_momentary(true);
    exit;
}
if (input_check_pressed(global.NovaCloseVerb()) || keyboard_check_pressed(vk_escape)) { CloseMachine(); exit; }
if (Cooldown > 0) Cooldown--;
if (!Paid) {
    if (input_check_pressed("nova_bag_previous")) Bet = (Bet + 4) mod 5;
    if (input_check_pressed("nova_bag_next")) Bet = (Bet + 1) mod 5;
    if (input_check_pressed(global.NovaConfirmVerb())) StartRound();
    exit;
}
StopDelay--;
for (var i = 0; i < 3; i++) {
    if (!ReelSpinning[i]) continue;
    ReelPos[i] = (ReelPos[i] + ReelSpeed[i]) mod 832;
    if (i != StopReel || StopDelay > 0) continue;
    var index = floor(ReelPos[i] / 16);
    if (global.NovaSlotSymbols[index] == ResultSymbols[i]) {
        ReelPos[i] = index * 16;
        ReelSpinning[i] = false;
        audio_play_sound(StopSounds[i],1,false);
        StopReel++;
        StopDelay = 45;
    }
}
if (StopReel == 3) SettleRound();
