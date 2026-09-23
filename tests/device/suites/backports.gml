// Kinstones, backported fixes, progression and recovered dungeon data, and floor travel.
function FloorTravelStart() {
    FloorTravelSavedCRT = global.Users[global.UserIndex].Prefs[3];
    FloorTravelCase = 0;
    FloorTravelPlace();
}

function FloorTravelPlace() {
    global.Paused = false;
    global.SaveLevel = false;
    global.Continue = false;
    global.NovaTestHeld = [];
    global.Users[global.UserIndex].Prefs[3] = (FloorTravelCase mod 2) == 1;
    with (oIntro) instance_destroy();
    instance_activate_all();
    random_set_seed(713 + FloorTravelCase div 2);
    Dungeon_InitLevel(2);
    oLink.DescendingLocation = 1 + FloorTravelCase div 2;
    with (oLink) UpdateState(22);
    FloorTravelTick = 0;
}

function FloorTravelStep() {
    FloorTravelTick++;
    if (FloorTravelTick > 360) {
        global.Users[global.UserIndex].Prefs[3] = FloorTravelSavedCRT;
        throw "Floor 2 to 3 transition timed out: " + string(FloorTravelCase);
    }
    if (global.Level.Index != 3 || oLink.State != 1) return false;
    Check("floor 2 to 3 completes with staircase and CRT combination " + string(FloorTravelCase),
        !oLink.InitNewDungeon && oLink.DescendingPhase == 0 && !global.SaveLevel
        && global.CurrentRoomIndex == global.Level.RoomIndex_Entrance && instance_exists(oHUD));
    FloorTravelCase++;
    if (FloorTravelCase < 4) { FloorTravelPlace(); return false; }
    global.Users[global.UserIndex].Prefs[3] = FloorTravelSavedCRT;
    return true;
}

Suite("Kinstones", "gameplay", function() {
    Test("each color spawns lit and matches an inventory piece", function() {
        var inventory = StructCopy(global.Inventory);
        var items = StructCopy(global.Inventory_ItemData);
        var colors = [[0.15,0.5,0.15], [0.2,0.2,0.6], [0.65,0.25,0.25], [0.6,0.5,0.1]];
        for (var color = 0; color < 4; color++) {
            var stone = instance_create_layer(oLink.x + 48, oLink.y, "ObjsHigher_Lower", oItem_Kinstone_Main,
                {Index: color, RoomIndex: oLink.RoomIndex});
            Check("Kinstone " + string(color) + " spawns with its original frame", stone.Index == color && stone.image_index == color);
            var light = global.Level.Rooms[stone.RoomIndex].Lights_RGB;
            var lit = stone.LightIndex >= 0;
            if (lit) for (var channel = 0; channel < 3; channel++) lit = lit && abs(light[stone.LightIndex * 3 + channel] - colors[color][channel]) < 0.0001;
            Check("Kinstone " + string(color) + " has its colored light", lit);
            Inventory_Add(23, color, 1);
            var matches = false;
            with (stone) matches = DBScriptFunction_KinstoneMatch();
            Check("Kinstone " + string(color) + " recognizes a matching inventory piece", matches);
            with (stone) instance_destroy();
        }
        global.Inventory = inventory;
        global.Inventory_ItemData = items;
    });
});

// The tests run in order on one run; the last one restores what the suite changed.
Suite("Backported fixes", "gameplay", function() {
    BeforeAll(function() {
        global.Paused = false;
        oLink.Invincible = false;
        oLink.Cape = false;
        with (oLink) UpdateState(1);
        BackportSavedInventory = StructCopy(global.Inventory);
        BackportSavedItems = StructCopy(global.Inventory_ItemData);
        BackportSavedChallenges = StructCopy(global.Challenges);
        BackportSavedFloor = oLink.FloorLevel;
        BackportSavedFacing = oLink.Facing;
    });
    Test("a Bari shock outlives the sword and its attacker", function() {
        var saved_health = global.Inventory_ItemData[17].Amount;
        var bari = EnemyFixture(oEnemy_Bari);
        global.Inventory_ItemData[44].Index = 1;
        var shocked = false;
        try {
            with (oLink) UpdateState(12);
            with (oSword) with (bari) Enemy_Hit_ShockLink();
            shocked = oLink.State == 18 && oLink.ShockEnemyInst == bari && !instance_exists(oSword);
        } catch (error) { shocked = false; }
        Check("Bari shock retains the enemy after destroying the sword", shocked);
        with (bari) instance_destroy();
        var health_before = global.Inventory_ItemData[17].Amount;
        var damage_applied = false;
        try {
            oLink.Invincible = false;
            with (oLink) event_perform_object(oLink, ev_alarm, 2);
            damage_applied = oLink.State != 18 && global.Inventory_ItemData[17].Amount < health_before;
        } catch (error) { damage_applied = false; }
        Check("shock completes after its attacker disappears", damage_applied);
        global.Inventory_ItemData[17].Amount = saved_health;
        with (oLink) UpdateState(1);
        oLink.Invincible = false;
        oLink.BounceBack = false;
    });
    Test("a Guru bar tolerates an expired child", function() {
        var guru = instance_create_layer(oLink.x + 80, oLink.y, "Objs_Lower", oEnemy_Guru_Bar,
            {FloorLevel: 0, RoomIndex: oLink.RoomIndex, SectionID: 0, Angle: 0, GurusDestroyed: false});
        with (guru.GuruInst[1]) instance_destroy();
        guru.State = 15;
        var guru_ok = false;
        try {
            with (guru) Gurus_Update();
            guru_ok = guru.GuruInst[0].State == 15 && guru.GuruInst[2].State == 15;
        } catch (error) { guru_ok = false; }
        Check("frozen Guru bar updates surviving children", guru_ok);
        guru.DestroyGurus = true;
        guru_ok = false;
        try {
            with (guru) event_perform_object(oEnemy_Guru_Bar, ev_step, ev_step_end);
            guru_ok = guru.GuruCount == 0 && guru.GurusDestroyed;
        } catch (error) { guru_ok = false; }
        Check("Guru bar cleanup tolerates an expired child", guru_ok);
        with (oEnemy_Guru) instance_destroy();
        with (guru) instance_destroy();
    });
    Test("arrows start at their firing position and initialize once", function() {
        var arrow_offsets = [[-4, -6, -7, 0], [6, -6, 7, 0], [0, -14, 0, -7], [0, 0, 0, 7]];
        var facings = [3, 4, 1, 2];
        for (var i = 0; i < 4; i++) {
            oLink.Facing = facings[i];
            var arrow = instance_create_layer(oLink.x, oLink.y, "Objs_Lower", oArrow);
            var expected = arrow_offsets[i];
            Check("arrow starts at its firing position direction " + string(facings[i]),
                arrow.x == oLink.x + expected[0] && arrow.y_base == oLink.y + expected[1]
                && arrow.vx == expected[2] && arrow.vy == expected[3] && !arrow.Setup);
            var first_x = arrow.x;
            var first_y = arrow.y_base;
            with (arrow) event_perform_object(oArrow, ev_step, ev_step_begin);
            Check("arrow initialization runs once direction " + string(facings[i]), arrow.x == first_x && arrow.y_base == first_y);
            with (arrow) instance_destroy();
        }
    });
    Test("pickups accept only items on Link's floor", function() {
        var pickup = instance_create_layer(oLink.x, oLink.y, "Objs_Lower", oItem_Orb, {From: 22});
        pickup.ShopItem = false;
        pickup.FloorLevel = BackportSavedFloor == 0 ? 1 : 0;
        var picked = noone;
        with (oLink) picked = CheckPickupItem(oItem_Orb, pickup);
        Check("pickup rejects another floor", picked == noone && oLink.State == 1);
        with (oLink) UpdateState(1);
        pickup.FloorLevel = BackportSavedFloor;
        with (oLink) picked = CheckPickupItem(oItem_Orb, pickup);
        Check("pickup still accepts the current floor", picked == pickup && oLink.State == 6);
        with (oLink) UpdateState(1);
        oLink.ItemHolding = noone;
        with (pickup) instance_destroy();
    });
    Test("explorers withhold a sword in a swordless run", function() {
        var explorer = instance_create_layer(oLink.x + 64, oLink.y, "Objs_Lower", oDeadGuy);
        explorer.ItemHolding = 44;
        global.Swordless = true;
        var has_loot = true;
        with (explorer) has_loot = DBScriptFunction_DeadGuy_CheckLoot();
        Check("explorer cannot grant a sword in a swordless run", !has_loot && explorer.ItemHolding == -1);
        global.Swordless = false;
        explorer.ItemHolding = 40;
        with (explorer) has_loot = DBScriptFunction_DeadGuy_CheckLoot();
        Check("explorer keeps allowed loot", has_loot);
        with (explorer) instance_destroy();
    });
    Test("forest lightning stays off during death", function() {
        var lighting = global.GlobalLighting;
        global.LinkDead = true;
        global.GlobalLighting = true;
        with (oIntro) event_perform_object(oIntro, ev_alarm, 1);
        Check("forest lightning stays off during death", global.GlobalLighting);
        global.LinkDead = false;
        global.GlobalLighting = lighting;
    });
    Test("the crystal fanfare ends even if its music loops", function() {
        var crystal = instance_create_layer(oLink.x, oLink.y, "ObjsHigher_Upper", oItem_Crystal);
        HoldUpItem(crystal, 2, false, false);
        audio_play_sound(Music_Boss_Defeated, 1, true);
        var bosses = oHUD.BossesDefeated;
        var music_playing = audio_is_playing(Music_Boss_Defeated);
        oLink.NovaCrystalTicks = room_speed * 15;
        with (oLink) event_perform_object(oLink, ev_step, ev_step_normal);
        Check("crystal fanfare has a bounded hold even if audio loops", music_playing && oLink.State == 1 && oHUD.BossesDefeated == bosses + 1);
        if (instance_exists(crystal)) with (crystal) instance_destroy();
        audio_stop_sound(Music_Boss_Defeated);
        global.Inventory = BackportSavedInventory;
        global.Inventory_ItemData = BackportSavedItems;
        global.Challenges = BackportSavedChallenges;
        oLink.FloorLevel = BackportSavedFloor;
        oLink.Facing = BackportSavedFacing;
        oLink.ItemHolding = noone;
        with (oLink) UpdateState(1);
        global.Paused = false;
    });
});

Suite("Progression", "gameplay", function() {
    Test("the Moon Pearl lowers a nearby block without pausing enemies", function() {
        global.Paused = false;
        with (oLink) UpdateState(1);
        var moon = global.Inventory_ItemData[31].Owns[0];
        global.Inventory_ItemData[31].Owns[0] = true;
        var block = instance_create_layer(oLink.x + 16, oLink.y, "Objs_Lower", oSwitchBlock);
        var wall = WallObj_Create("Objs_Lower", oLink.x + 8, oLink.y, 2, 2);
        wall.IsSwitchBlock = true;
        wall.SwitchBlockInst = block;
        with (oLink) event_perform_object(oLink, ev_step, ev_step_normal);
        Check("Moon Pearl lowers a nearby block without pausing enemies", block.Toggle && !global.Paused);
        global.Inventory_ItemData[31].Owns[0] = moon;
        with (wall) instance_destroy();
        with (block) instance_destroy();
        global.Paused = false;
    });
    Test("the Treeman transforms in water and needs the powder bag", function() {
        var tree = instance_create_layer(oLink.x + 60, oLink.y - 30, "Objs_Lower", oVillager_Treeman, {Name: "Villager_Treeman", AddWall: false});
        oLink.State = 5;
        tree.TransformInit = true;
        with (tree) event_perform_object(oVillager_Treeman, ev_step, ev_step_normal);
        Check("Treeman transformation starts while Link is in water", !tree.TransformInit && tree.alarm[2] == 40 && oLink.State == 0 && global.Paused);
        tree.TransformInit = false;
        tree.DB_Started_GrandChild = true;
        tree.ResponseIndex = 2;
        var medallions = instance_number(oItem_Medallion);
        with (tree) event_perform_object(oVillager_Treeman, ev_step, ev_step_normal);
        Check("Treeman cannot grant a medallion without the powder bag", instance_number(oItem_Medallion) == medallions && tree.ItemHolding == 29 && tree.ResponseIndex == 3);
        with (tree) instance_destroy();
        global.Paused = false;
        with (oLink) UpdateState(1);
    });
    Test("the Red Armos stomps when its jump stalls and lands to jump again", function() {
        var controller = instance_create_layer(oLink.x + 80, oLink.y, "Objs_Lower", oBoss_Armos_C,
            {RoomIndex: oLink.RoomIndex, SectionID: 0});
        controller.LastArmos_Inst = controller.ArmosInst[0];
        controller.ArmosLeft = 1;
        controller.State = 7;
        var armos = controller.LastArmos_Inst;
        armos.State = 7;
        armos.vx = 0;
        armos.vy = 0;
        armos.WaypointX = armos.x + 30;
        armos.WaypointY = armos.y_base + 30;
        controller.LastArmos_Jump = true;
        controller.z = controller.LastArmos_JumpZ + 16;
        controller.vz = 1;
        with (controller) event_perform_object(oBoss_Armos_C, ev_step, ev_step_begin);
        Check("Red Armos starts a stomp if horizontal travel stalls", !controller.LastArmos_Jump && controller.alarm[5] == 5);
        with (controller) {
            event_perform_object(oBoss_Armos_C, ev_alarm, 5);
            repeat (12) event_perform_object(oBoss_Armos_C, ev_step, ev_step_begin);
        }
        Check("Red Armos reaches the floor and rearms its next jump", controller.z == 0 && !controller.LastArmos_Stomp && controller.alarm[6] > 0);
        with (oBoss_Armos) instance_destroy();
        with (controller) instance_destroy();
    });
    Test("Zora upgrades a basic bow and then offers rupees", function() {
        var bow = global.Inventory_ItemData[7].Index;
        var old_prize = global.GemPrize[0][0];
        global.GemPrize[0][0] = {Class: 7, Index: 0, Amount: 1};
        var zora = instance_create_layer(oLink.x, oLink.y, "Objs_Lower", oZora, {GemCombo: [0, 0]});
        global.Inventory_ItemData[7].Index = 0;
        with (zora) event_perform_object(oZora, ev_alarm, 3);
        Check("Zora offers an upgrade to a basic bow", zora.PrizeClass == 7);
        with (oDialogueBox) instance_destroy();
        global.DB_Inst = noone;
        global.Inventory_ItemData[7].Index = 1;
        with (zora) event_perform_object(oZora, ev_alarm, 3);
        Check("Zora substitutes rupees after the bow is fully upgraded", zora.PrizeClass == 40);
        with (oDialogueBox) instance_destroy();
        global.DB_Inst = noone;
        with (zora) instance_destroy();
        global.Inventory_ItemData[7].Index = bow;
        global.GemPrize[0][0] = old_prize;
        global.Paused = false;
        with (oLink) UpdateState(1);
    });
    Test("dungeon templates keep their doors through every transformation", function() {
        for (var t = 0; t < 8; t++) {
            Check("locked progression door survives transformation " + string(t), global.Templates_Dungeon[0][t][13].Rooms[6].Doors[0].Status == 1 && global.Templates_Dungeon[2][t][6].Rooms[4].Doors[0].Status == 1);
            var layout_room = global.Templates_Dungeon[2][t][32].Rooms[5];
            Check("corrected side doors survive transformation " + string(t), layout_room.Doors[0].Position == GetTransformedDoorPosition(8, t) && layout_room.Doors[1].Position == GetTransformedDoorPosition(4, t) && layout_room.Doors[1].ConnectedRoomIndex == 10);
        }
    });
    Test("the progression key and its barrier move together", function() {
        Check("progression key and barrier move together", global.Templates_Dungeon[1][0][14].Rooms[8].SpecialObj == 1 && global.Templates_Dungeon[1][0][14].Rooms[9].SpecialObj == 0 && global.Templates_Dungeon[1][0][14].Rooms[9].Doors[1].Status == 2);
    });
    Test("large chests and the wishing pond offer the hookshot and boomerang", function() {
        Check("large chests include the hookshot and boomerang", ds_list_find_index(global.PossibleItemLists[3], 6) >= 0 && ds_list_find_index(global.PossibleItemLists[3], 19) >= 0);
        Check("wishing pond includes the hookshot and boomerang", ds_list_find_index(global.PossibleItemLists[12], 6) >= 0 && ds_list_find_index(global.PossibleItemLists[12], 19) >= 0);
    });
    Test("rods damage vulnerable bosses and respect immunities", function() {
        Check("rods deal two base damage to vulnerable bosses", global.EnemyData[oBoss_Armos].LinkWeaponEffects[6][0] == 2 && global.EnemyData[oBoss_Lanmola].LinkWeaponEffects[7] == 2);
        Check("rod boss immunities stay intact", global.EnemyData[oBoss_Moldorm].LinkWeaponEffects[6] == -1 && global.EnemyData[oBoss_Armos].LinkWeaponEffects[6][1] == -1);
    });
    Test("the keyboard has menu and direction bindings", function() {
        Check("keyboard supports menu and all four directions", global.BindingIconCount[1] >= 12 && GetInputVerbStr(6) == "menu_access" && GetInputVerbStr(8) == "up" && GetInputVerbStr(11) == "right");
    });
});

Suite("Floor travel", "travel", function() {
    AsyncTest("floor 2 to 3 completes with every staircase and CRT combination", FloorTravelStart, FloorTravelStep);
});
