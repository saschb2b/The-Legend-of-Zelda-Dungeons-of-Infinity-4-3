FloorLevelStr = GetFloorLevelString(x,y);
FloorLevel = GetFloorLevelID(FloorLevelStr);
WallInst = WallObj_Create("ObjsHigher_" + FloorLevelStr,x-4,y+3,5,4);
WallInst.FloorLevel = FloorLevel;
LightIndex = Lighting_CreateLight(RoomIndex,x+12,y+20,0.4,[0.8,0.8,0.8]);
State = 0;
ClawX = 0; ClawY = 0; ClawImg = 0;
DropItem = false; DropItemY = 0; DropItemSpeed = 0.25;
Win = false;
WinRate = 0.65;
Prizes = 5;
HeartContainerAvailable = true;
WishStoneAvailable = true;
Paid = false;
Grabbed = false;
Timer = 0;
DB_Init = false;
DB_Started = false;
function CheckPrizes() { return Prizes > 0; }
function CheckCost() { return global.Inventory_ItemData[40].Amount >= 10; }
function Instructions() { return "Move the claw left or right. Grab a prize when the claw is over the pile."; }
DB_Script = ds_grid_create(5,8);
var rows = [
    [2,"1 Play: 10 rupees",1,6,5],
    [5,method(self,CheckPrizes),3,2],
    [4,"No more prizes left.",6],
    [5,method(self,CheckCost),7,4],
    [4,"You don't have enough rupees.",6],
    [0,method(self,Instructions),0],
    [7,0],
    [7,1]
];
for (var row = 0; row < 8; row++) for (var col = 0; col < array_length(rows[row]); col++) ds_grid_set(DB_Script,col,row,rows[row][col]);
function StartRound() {
    if (Paid || Prizes <= 0 || !CheckCost()) return false;
    global.Inventory_ItemData[40].Amount -= 10;
    Paid = true;
    Grabbed = false;
    Win = Prob(WinRate);
    State = 2;
    ClawX = 0; ClawY = 0; ClawImg = 0;
    DropItem = false; DropItemY = 0; DropItemSpeed = 0.25;
    Music_Fade(0.25,12);
    global.Paused = true;
    with (oLink) UpdateState(0);
    audio_play_sound(Music_ClawMachine,1,true);
    input_clear_momentary(true);
    return true;
}
function GrabPrize() {
    if (!Paid || Grabbed || State != 2 || ClawX <= 6) return false;
    Grabbed = true;
    ClawImg = 1;
    State = 3;
    audio_stop_sound(Sound_ClawMachine_Motor);
    audio_play_sound(Sound_ClawMachine_Drop,1,false);
    return true;
}
function SettleRound() {
    if (!Paid) return noone;
    Paid = false;
    State = 0;
    audio_stop_sound(Music_ClawMachine);
    audio_stop_sound(Sound_ClawMachine_Motor);
    audio_stop_sound(Sound_ClawMachine_Raise);
    Music_Fade(1,12);
    var prize = noone;
    if (!Grabbed) {
        global.Inventory_ItemData[40].Amount = global.NovaRupeeLimit(global.Inventory_ItemData[40].Amount + 10);
    } else if (Win) {
        Prizes--;
        var pool = global.NovaClawPrizePool(Item_Allowed(13),HeartContainerAvailable && Item_Allowed(18),WishStoneAvailable);
        var item_class = pool[irandom(array_length(pool)-1)];
        var item_index = global.NovaClawPrizeIndex(item_class);
        if (item_class == 18) HeartContainerAvailable = false;
        if (item_class == 47) WishStoneAvailable = false;
        prize = instance_create_layer(x,y,"ObjsHigher_Upper",ObjIndexFromItemClass(item_class),{From:2});
        with (prize) { Setup = false; Amount = 1; Item_SetIndex(item_index); }
        HoldUpItem(prize);
    }
    if (prize == noone) {
        global.Paused = false;
        with (oLink) UpdateState(1);
    }
    input_clear_momentary(true);
    return prize;
}
