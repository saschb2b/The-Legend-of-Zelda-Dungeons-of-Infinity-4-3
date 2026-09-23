using System;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;
Data.SetGMS2Version(2024, 6);
Data.FORM.FUNC.CodeLocals ??= new UndertaleModLib.UndertaleSimpleList<UndertaleCodeLocals>();
var group = new CodeImportGroup(Data) { AutoCreateAssets = true };
group.QueueReplace("gml_Object_oNovaVillageTest_Create_0", "persistent = true; Stage = 0; Ticks = 0;");
group.QueueReplace("gml_Object_oNovaVillageTest_Step_0", @"
Ticks++;
switch (Stage) {
    case 0:
        if (!instance_exists(oTitle)) break;
        room_goto(Room_Menu);
        Stage = 1;
        break;
    case 1:
        if (!instance_exists(oMenu)) break;
        global.UserIndex = 0;
        global.Users[0] = new User_Create();
        global.Users[0].Name = ""ARCADE"";
        global.LinkCharacterIndex = 0;
        global.StartingGear = 0;
        global.NovaResetChallenges();
        global.SaveLevel = false;
        global.Continue = false;
        DungeonSeq_Init(0);
        with (oMenu) Menu_StartGame();
        Stage = 2;
        break;
    case 2:
        if (!instance_exists(oLink) || !instance_exists(oHUD) || global.Paused || oLink.State != 1) break;
        with (oIntro) instance_destroy();
        Dungeon_InitLevel(6);
        Stage = 3;
        break;
    case 3:
        instance_activate_object(oClawMachine);
        Machine = instance_find(oClawMachine,0);
        if (!instance_exists(Machine)) throw ""Village has no claw machine"";
        var inside = Machine.RoomIndex;
        instance_activate_object(oHouseDoor);
        Door = noone;
        with (oHouseDoor) if (House_RoomIndex == inside) other.Door = id;
        if (!instance_exists(Door)) throw ""Arcade entrance is missing"";
        var outside = Dungeon_GetRoomIndex(Door.x,Door.y);
        oLink.x = Door.x+8;
        oLink.y = Door.y+12;
        oLink.Facing = 1;
        oLink.RoomIndex = outside;
        oLink.FloorLevel = GetFloorLevelID(oLink.x,oLink.y);
        oLink.FloorLevelStr = GetFloorLevelString(oLink.FloorLevel);
        oLink.FallSpawnX = oLink.x;
        oLink.FallSpawnY = oLink.y;
        oLink.FallSpawnFacing = oLink.Facing;
        oLink.FallSpawnFloorLevel = oLink.FloorLevel;
        oLink.House_Inside = false;
        with (oCamera) {
            if (global.CurrentRoomIndex != outside) SetToRoomIndex(outside,true);
            Cam_UpdatePos();
        }
        global.Inventory_ItemData[40].Amount = 500;
        oHUD.AddRupees = 0;
        global.Paused = false;
        with (oLink) UpdateState(1);
        input_profile_set(""gamepad"");
        input_clear_momentary(true);
        var file = file_text_open_write(""village-ready.txt"");
        file_text_write_string(file,""Village ready. Physical controls enabled."");
        file_text_close(file);
        instance_destroy();
        break;
}
if (Ticks > 1800) throw ""Village preview timed out"";
");
group.QueueAppend("gml_Object_oTitle_Create_0", "if (!instance_exists(oNovaVillageTest)) instance_create_depth(0,0,-100000,oNovaVillageTest);");
group.Import();
Console.WriteLine("NOVA VILLAGE PREVIEW COMPILED");
