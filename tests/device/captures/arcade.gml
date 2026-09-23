// Arcade screenshots: the village pub, a slot machine and the claw machine from play to prize.
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
    Check("generated village contains four slot machines", instance_number(oArcade_Mothula) == 4);
    Check("generated village contains one claw machine", instance_number(oClawMachine) == 1);
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
    if (!file_exists("nova-capture-done.txt")) return false;
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
            return true;
    }
    return false;
}
