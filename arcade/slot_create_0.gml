event_inherited();
CamW = 200; CamH = 150;
GameSurface = -1;
ReelSurface = -1;
State = 0;
Bet = 0;
Paid = false;
Cooldown = 0;
WinAmount = 0;
Result = 0;
ResultSymbols = [1,2,3];
ReelPos = [irandom(52)*16,irandom(52)*16,irandom(52)*16];
ReelSpeed = [8,8,8];
ReelSpinning = [false,false,false];
ReelTarget = [-1,-1,-1];
StopReel = 0;
StopDelay = 45;
StatusText = "MOTHULA'S MONEY";
StopSounds = [Sound_SlotStop1,Sound_SlotStop2,Sound_SlotStop3];
WinSounds = [noone,Sound_SlotWin1,Sound_SlotWin1,Sound_SlotWin1,Sound_SlotWin2,Sound_SlotWin3,Sound_SlotWin4];
function StartRound() {
    if (Paid || Cooldown > 0 || State == 0) return false;
    var amount = global.Inventory_ItemData[40].Amount;
    if (amount < Bet + 1) { StatusText = "NOT ENOUGH RUPEES"; return false; }
    global.Inventory_ItemData[40].Amount = amount - (Bet + 1);
    Paid = true;
    WinAmount = 0;
    Result = global.NovaSlotResult(irandom(10000));
    ResultSymbols = Result == 0 ? global.NovaSlotLosingSymbols() : [Result,Result,Result];
    ReelSpinning = [true,true,true];
    ReelTarget = [-1,-1,-1];
    for (var i = 0; i < 3; i++) ReelSpeed[i] = 8 * random_range(0.75,1);
    StopReel = 0;
    StopDelay = 45;
    State = 4;
    StatusText = "GOOD LUCK";
    audio_play_sound(Sound_SlotSpin, 1, true);
    return true;
}
function SettleRound() {
    if (!Paid) return false;
    Paid = false;
    WinAmount = global.NovaSlotMultipliers[Result] * (Bet + 1);
    global.Inventory_ItemData[40].Amount = global.NovaRupeeLimit(global.Inventory_ItemData[40].Amount + WinAmount);
    audio_stop_sound(Sound_SlotSpin);
    if (WinSounds[Result] != noone) audio_play_sound(WinSounds[Result], 1, false);
    StatusText = WinAmount > 0 ? "YOU WIN " + string(WinAmount) + "!" : "GAME OVER";
    Cooldown = 10;
    State = 2;
    return true;
}
function CloseMachine() {
    SettleRound();
    State = 0;
    GameAllowed = false;
    global.ArcadeVP_Show = false;
    global.Arcade_ActiveInst = noone;
    oLink.actionVideoGame = false;
    global.Paused = false;
    with (oLink) UpdateState(1);
    Music_Fade(1, 12);
    audio_stop_sound(Sound_SlotSpin);
    input_clear_momentary(true);
}
