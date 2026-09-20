function SlotPixelsMatch(actual, expected, left, top, width, height) {
    for (var row = top; row < top+height; row++) {
        for (var column = left; column < left+width; column++) {
            var offset = (row*200+column)*4;
            if (buffer_peek(actual,offset,buffer_u32) != buffer_peek(expected,offset,buffer_u32)) return false;
        }
    }
    return true;
}
function SlotRenderTests(slots) {
    var original = global.ArcadeVP_Surface;
    global.ArcadeVP_Surface = surface_create(200,150);
    var reference = surface_create(200,150);
    var actual = buffer_create(200*150*4,buffer_fixed,1);
    var expected = buffer_create(200*150*4,buffer_fixed,1);
    slots.ReelPos = [832,816,827];
    slots.StatusText = "MOTHULA'S MONEY";
    with (slots) event_perform_object(oArcade_Mothula,ev_draw,73);
    buffer_get_surface(actual,global.ArcadeVP_Surface,0);
    surface_set_target(reference);
    draw_clear(make_color_rgb(6,106,181));
    draw_set_color(c_white); draw_set_alpha(1);
    draw_set_valign(fa_top); draw_set_halign(fa_center);
    draw_set_font(global.ArcadeFont2);
    // Coordinates and fonts from 1.2.1's Draw GUI End, before the CRT pass.
    draw_text(100,36,"MOTHULA'S MONEY");
    draw_sprite(sPoker_Button_Bet,0,132,135);
    draw_sprite(sPoker_Button_Spin,0,162,135);
    draw_set_halign(fa_left); draw_set_font(global.HUDFont2); draw_set_color(c_black);
    draw_text(151,138,"1");
    draw_set_color(c_white); draw_set_font(global.ArcadeFont);
    draw_text(50,8,"1x"); draw_text(50,21,"2x");
    draw_text(107,8,"5x"); draw_text(107,21,"10x");
    draw_text(170,8,"25x"); draw_text(170,21,"100x");
    draw_sprite(sArcade_Mothula_ReelLine,0,68,88);
    draw_sprite(sArcade_Mothula_ReelLine,0,128,88);
    draw_sprite_stretched(sArcade_Mothula_Reel,0,12,56,56,72);
    draw_sprite_stretched(sArcade_Mothula_Reel,0,72,56,56,72);
    draw_sprite_stretched(sArcade_Mothula_Reel,0,132,56,56,72);
    // The wrapped final symbol is Mothula; the next symbol is cherries.
    draw_sprite_part(sArcade_Mothula_Symbols,5,0,8,48,16,16,68);
    draw_sprite_part(sArcade_Mothula_Symbols,5,0,0,48,32,76,76);
    draw_sprite_part(sArcade_Mothula_Symbols,0,0,0,48,8,76,108);
    draw_sprite_part(sArcade_Mothula_Symbols,5,0,3,48,29,136,68);
    draw_sprite_part(sArcade_Mothula_Symbols,0,0,0,48,11,136,97);
    surface_reset_target();
    buffer_get_surface(expected,reference,0);
    Record("slot title uses the original tall font and baseline",SlotPixelsMatch(actual,expected,40,36,120,16));
    Record("slot Bet and Spin retain original artwork and placement",SlotPixelsMatch(actual,expected,132,135,56,11));
    Record("slot payline markers sit between the reels",SlotPixelsMatch(actual,expected,68,88,4,8) && SlotPixelsMatch(actual,expected,128,88,4,8));
    Record("slot payout multipliers follow their native suffix notation",SlotPixelsMatch(actual,expected,50,8,12,21) && SlotPixelsMatch(actual,expected,107,8,18,21) && SlotPixelsMatch(actual,expected,170,8,24,21));
    Record("slot reel wrap preserves original symbol offsets",SlotPixelsMatch(actual,expected,16,72,48,12) && SlotPixelsMatch(actual,expected,76,76,48,36) && SlotPixelsMatch(actual,expected,136,72,48,36));
    Record("original CRT shader compiles on this device",shader_is_compiled(shd_CRT));
    var crt = surface_create(800,600);
    surface_set_target(reference); draw_clear(c_white); surface_reset_target();
    surface_set_target(crt);
    CRT_Do_Stretch(reference,0,0,800,600,[200,150,400,300],true,0.2,true,0.025,80,true,true,true,0.04);
    surface_reset_target();
    var corner = surface_getpixel(crt,0,0);
    var center = surface_getpixel(crt,400,300);
    Record("CRT border and effects change rendered pixels",color_get_red(corner) < 10 && color_get_red(center) > 50 && center != c_white);
    surface_free(crt); surface_free(reference); surface_free(global.ArcadeVP_Surface);
    global.ArcadeVP_Surface = original;
    buffer_delete(actual); buffer_delete(expected);
}
function ArcadeTests() {
    var inventory = StructCopy(global.Inventory);
    var items = StructCopy(global.Inventory_ItemData);
    var before_rupees = oHUD.AddRupees;
    var seed = random_get_seed();
    var options = StructCopy(global.NovaChallengeOptions);
    var profile = input_profile_get();
    var level = global.Level.Index;
    global.NovaResetChallenges();
    oHUD.AddRupees = 0;
    var counts = array_create(7,0);
    for (var roll = 0; roll <= 10000; roll++) counts[global.NovaSlotResult(roll)]++;
    Record("slot odds match all 10001 native roll outcomes", json_stringify(counts) == json_stringify([7275,1600,500,350,175,85,16]));
    var losing = true;
    repeat (1000) {
        var symbols = global.NovaSlotLosingSymbols();
        if (symbols[0] > 0 && symbols[0] == symbols[1] && symbols[1] == symbols[2]) losing = false;
    }
    Record("losing slot outcomes never display a winning triple", losing);
    var slots = instance_create_layer(oLink.x+40,oLink.y,"Objs_Lower",oArcade_Mothula,{RoomIndex:oLink.RoomIndex});
    slots.State = 2;
    global.Arcade_ActiveInst = slots;
    SlotRenderTests(slots);
    var multipliers = [0,1,2,5,10,25,100];
    for (var bet = 0; bet < 5; bet++) {
        for (var result = 0; result <= 6; result++) {
            global.Inventory_ItemData[40].Amount = 100;
            slots.Bet = bet;
            slots.Cooldown = 0;
            Record("slot charges stake " + string(bet) + "/" + string(result), slots.StartRound() && global.Inventory_ItemData[40].Amount == 99-bet);
            Record("paid slot rejects another start", !slots.StartRound() && global.Inventory_ItemData[40].Amount == 99-bet);
            slots.Result = result;
            var paid = slots.SettleRound();
            var expected = 100-(bet+1)+multipliers[result]*(bet+1);
            Record("slot pays native multiplier " + string(bet) + "/" + string(result), paid && global.Inventory_ItemData[40].Amount == expected);
            Record("slot payout is single-use", !slots.SettleRound() && global.Inventory_ItemData[40].Amount == expected);
        }
    }
    for (var result = 0; result <= 6; result++) {
        global.Inventory_ItemData[40].Amount = 100;
        slots.Bet = 0; slots.Cooldown = 0;
        slots.StartRound();
        slots.Result = result;
        slots.ResultSymbols = result == 0 ? [0,1,2] : [result,result,result];
        slots.ReelPos = [0,0,0];
        PressEvent(slots,"",oArcade_Mothula,ev_step,ev_step_normal);
        Record("slot reels scroll downward through the strip " + string(result),slots.ReelPos[0] >= 824 && slots.ReelPos[0] <= 826);
        for (var frame = 0; frame < 1000 && slots.Paid; frame++) PressEvent(slots,"",oArcade_Mothula,ev_step,ev_step_normal);
        var aligned = !slots.Paid;
        for (var reel = 0; reel < 3; reel++) aligned = aligned && global.NovaSlotSymbols[floor(slots.ReelPos[reel]/16)] == slots.ResultSymbols[reel];
        Record("animated reels stop on their paid result " + string(result), aligned && global.Inventory_ItemData[40].Amount == 99+multipliers[result]);
    }
    slots.Cooldown = 0;
    global.Inventory_ItemData[40].Amount = 0;
    Record("unaffordable slot costs nothing", !slots.StartRound() && !slots.Paid && global.Inventory_ItemData[40].Amount == 0);
    global.Inventory_ItemData[40].Amount = 50;
    slots.Bet = 0;
    slots.StartRound();
    slots.Result = 6;
    PressEvent(slots,global.NovaCloseVerb(),oArcade_Mothula,ev_step,ev_step_normal);
    Record("closing a spinning slot settles its paid result once", slots.State == 0 && !slots.Paid && global.Inventory_ItemData[40].Amount == 149 && !global.ArcadeVP_Show && !global.Paused);
    slots.State = 2; slots.Cooldown = 0;
    global.NovaChallengeOptions[5] = 3;
    global.Inventory_ItemData[40].Amount = 199;
    slots.StartRound(); slots.Result = 6; slots.SettleRound();
    Record("slot winnings obey challenge wallet caps", global.Inventory_ItemData[40].Amount == 200);
    global.NovaResetChallenges();
    slots.CloseMachine();
    with (slots.WallInst) instance_destroy();
    with (slots) instance_destroy();
    var pool = global.NovaClawPrizePool(true,true,true);
    counts = array_create(52,0);
    for (var i = 0; i < array_length(pool); i++) counts[pool[i]]++;
    Record("claw prize weights match the native pool", array_length(pool) == 97 && counts[13] == 75 && counts[48] == 4 && counts[14] == 4 && counts[23] == 4 && counts[27] == 4 && counts[33] == 4 && counts[18] == 1 && counts[47] == 1);
    pool = global.NovaClawPrizePool(false,false,false);
    counts = array_create(52,0);
    for (var i = 0; i < array_length(pool); i++) counts[pool[i]]++;
    Record("claw replaces forbidden food and omits exhausted rare prizes", array_length(pool) == 95 && counts[13] == 0 && counts[18] == 0 && counts[47] == 0 && counts[48] == 19 && counts[14] == 19 && counts[23] == 19 && counts[27] == 19 && counts[33] == 19);
    var claw = instance_create_layer(oLink.x+60,oLink.y-40,"Objs_Lower",oClawMachine,{RoomIndex:oLink.RoomIndex});
    Record("claw machine inherits room cleanup and interaction", object_is_ancestor(oClawMachine,oPopMachine) && instance_position(claw.x+12,claw.y+40,oPopMachine) == claw);
    Record("claw original defaults", claw.Prizes == 5 && claw.WinRate == 0.65);
    for (var device = 0; device < 2; device++) {
        input_profile_set(device == 0 ? "keyboard" : "gamepad");
        global.Inventory_ItemData[40].Amount = 100;
        global.DB_ExitCode = 1;
        claw.DB_Init = true;
        PressEvent(claw,"action",oClawMachine,ev_step,ev_step_normal);
        var dialogue = global.DB_Inst;
        Record("claw dialogue consumes its opening press", instance_exists(dialogue) && global.DB_ExitCode == 0 && !claw.Paid);
        ShopWait(dialogue);
        PressEvent(dialogue,global.NovaCloseVerb(),oDialogueBox,ev_step,ev_step_end);
        PressEvent(claw,"",oClawMachine,ev_step,ev_step_normal);
        Record("claw purchase closes without paying " + string(device), !instance_exists(dialogue) && !claw.Paid && global.Inventory_ItemData[40].Amount == 100);
    }
    input_profile_set(profile);
    global.Inventory_ItemData[40].Amount = 9;
    Record("unaffordable claw costs nothing", !claw.StartRound() && global.Inventory_ItemData[40].Amount == 9);
    global.Inventory_ItemData[40].Amount = 100;
    Record("claw charges ten once", claw.StartRound() && !claw.StartRound() && global.Inventory_ItemData[40].Amount == 90);
    Record("claw cannot grab above the chute", !claw.GrabPrize());
    global.NovaTestHeld = ["right"];
    repeat (200) PressEvent(claw,"",oClawMachine,ev_step,ev_step_normal);
    Record("claw movement stops at the cabinet edge", claw.ClawX == 11);
    global.NovaTestHeld = [];
    PressEvent(claw,global.NovaCloseVerb(),oClawMachine,ev_step,ev_step_normal);
    Record("closing before grabbing refunds the unused play", !claw.Paid && claw.Prizes == 5 && global.Inventory_ItemData[40].Amount == 100 && !global.Paused);
    claw.StartRound(); claw.ClawX = 8; claw.Win = false;
    PressEvent(claw,global.NovaConfirmVerb(),oClawMachine,ev_step,ev_step_normal);
    Record("confirm grabs after moving over the prize pile", claw.Grabbed && claw.State == 3);
    PressEvent(claw,global.NovaCloseVerb(),oClawMachine,ev_step,ev_step_normal);
    Record("closing a lost grab does not refund its played stake", !claw.Paid && claw.Prizes == 5 && global.Inventory_ItemData[40].Amount == 90);
    claw.StartRound(); claw.ClawX = 8; claw.Win = true;
    claw.GrabPrize();
    var prize = claw.SettleRound();
    Record("winning claw delivers an original item through the item-get flow", instance_exists(prize) && oLink.ItemHolding == prize && oLink.State == 9 && claw.Prizes == 4 && prize.Amount == 1);
    Record("claw cannot award twice", claw.SettleRound() == noone && claw.Prizes == 4);
    with (prize) instance_destroy();
    oLink.ItemHolding = noone;
    oLink.alarm[0] = -1;
    claw.Prizes = 0;
    Record("empty claw cannot take payment", !claw.StartRound());
    with (claw.WallInst) instance_destroy();
    with (claw) instance_destroy();
    global.Level.Index = level;
    global.Inventory = inventory;
    global.Inventory_ItemData = items;
    global.NovaChallengeOptions = options;
    oHUD.AddRupees = before_rupees;
    random_set_seed(seed);
    global.Paused = false;
    with (oLink) UpdateState(1);
}
function ArcadeTravelPlace() {
    instance_activate_object(oHouseDoor);
    ArcadeDoor = noone;
    with (oHouseDoor) if (House_RoomIndex == other.ArcadeRooms[other.ArcadeTravelIndex]) other.ArcadeDoor = id;
    if (!instance_exists(ArcadeDoor)) throw "Village entrance missing";
    ArcadeOutside = Dungeon_GetRoomIndex(ArcadeDoor.x,ArcadeDoor.y);
    oLink.x = ArcadeDoor.x+8;
    oLink.y = ArcadeDoor.y+12;
    oLink.RoomIndex = ArcadeOutside;
    oLink.FloorLevel = GetFloorLevelID(oLink.x,oLink.y);
    oLink.FloorLevelStr = GetFloorLevelString(oLink.FloorLevel);
    oLink.Facing = 1;
    oLink.House_Inside = false;
    with (oCamera) {
        if (global.CurrentRoomIndex != other.ArcadeOutside) SetToRoomIndex(other.ArcadeOutside,true);
        Cam_UpdatePos();
    }
    with (oLink) UpdateState(1);
    global.NovaTestHeld = ["up"];
    ArcadeTravelPhase = 0;
    ArcadeTravelTick = 0;
}
function ArcadeTravelStart() {
    global.Paused = false;
    global.SaveLevel = false;
    global.Continue = false;
    with (oIntro) instance_destroy();
    Dungeon_InitLevel(6);
    instance_activate_object(oClawMachine);
    instance_activate_object(oArcade_Mothula);
    ArcadeRooms = [instance_find(oClawMachine,0).RoomIndex,instance_find(oArcade_Mothula,0).RoomIndex];
    ArcadeTravelIndex = 0;
    ArcadeTravelPlace();
}
function ArcadeTravelStep() {
    ArcadeTravelTick++;
    if (ArcadeTravelTick > 600) throw "Village doorway timed out: " + string(ArcadeTravelIndex) + "/" + string(ArcadeTravelPhase);
    if (ArcadeTravelPhase == 0 && oLink.House_Inside) {
        global.NovaTestHeld = [];
        if (oLink.State != 1) return false;
        Record("village building records its entrance " + string(ArcadeTravelIndex), oLink.House_OldRoomIndex == ArcadeOutside && oLink.House_DoorInst == ArcadeDoor && global.CurrentRoomIndex == ArcadeRooms[ArcadeTravelIndex]);
        global.NovaTestHeld = ["down"];
        ArcadeTravelPhase = 1;
    } else if (ArcadeTravelPhase == 1 && !oLink.House_Inside) {
        global.NovaTestHeld = [];
        if (oLink.State != 1) return false;
        Record("village building exits to its entrance " + string(ArcadeTravelIndex), global.CurrentRoomIndex == ArcadeOutside && !oLink.House_Leaving && !oLink.House_Entering && oCamera.RoomTransition == 0);
        ArcadeTravelIndex++;
        if (ArcadeTravelIndex == 2) return true;
        ArcadeTravelPlace();
    }
    return false;
}
function ArcadeCaptureRoom(machine) {
    global.Paused = false;
    oLink.x = machine.x;
    oLink.y = machine.y+6;
    oLink.Facing = 1;
    oLink.RoomIndex = machine.RoomIndex;
    oLink.FloorLevel = machine.FloorLevel;
    oLink.FloorLevelStr = machine.FloorLevelStr;
    with (oCamera) {
        if (global.CurrentRoomIndex != other.ArcadeMachine.RoomIndex) SetToRoomIndex(other.ArcadeMachine.RoomIndex,true);
        Cam_UpdatePos();
    }
    with (oLink) UpdateState(1);
}
function ArcadeCaptureStart() {
    input_profile_set("gamepad");
    global.Paused = false;
    global.SaveLevel = false;
    global.Continue = false;
    instance_activate_all();
    with (oIntro) instance_destroy();
    Dungeon_InitLevel(6);
    instance_activate_object(oArcade_Mothula);
    instance_activate_object(oClawMachine);
    Record("generated village contains four slot machines", instance_number(oArcade_Mothula) == 4);
    Record("generated village contains one claw machine", instance_number(oClawMachine) == 1);
    ArcadeMachine = instance_find(oArcade_Mothula,0);
    ArcadeCaptureRoom(ArcadeMachine);
    ArcadeMachine.GameAllowed = false;
    oLink.y += 8;
    global.Inventory_ItemData[40].Amount = 200;
    CaptureIndex = 0;
    CaptureTick = 0;
    ArcadeCaptureNames = ["arcade-pub","arcade-slots","arcade-claw","arcade-grab","arcade-prize"];
}
function ArcadeCaptureStep() {
    CaptureTick++;
    if (CaptureTick == 30) { Capture = ArcadeCaptureNames[CaptureIndex]; Flush(); }
    if (!file_exists("nova-capture-done.txt")) return;
    file_delete("nova-capture-done.txt");
    Capture = ""; CaptureTick = 0; CaptureIndex++;
    switch (CaptureIndex) {
        case 1:
            oLink.x = ArcadeMachine.x; oLink.y = ArcadeMachine.y+6;
            ArcadeMachine.GameAllowed = true;
            break;
        case 2:
            ArcadeMachine.CloseMachine();
            instance_activate_object(oClawMachine);
            ArcadeMachine = instance_find(oClawMachine,0);
            ArcadeCaptureRoom(ArcadeMachine);
            oLink.x = ArcadeMachine.x+12;
            oLink.y = ArcadeMachine.y+40;
            break;
        case 3:
            ArcadeMachine.StartRound();
            ArcadeMachine.ClawX = 9;
            ArcadeMachine.Win = true;
            break;
        case 4:
            ArcadeMachine.GrabPrize();
            ArcadeMachine.SettleRound();
            break;
        default:
            Complete = true; Flush(); game_end();
    }
}
