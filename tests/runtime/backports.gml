function BackportTests() {
    global.Paused = false;
    oLink.Invincible = false;
    oLink.Cape = false;
    with (oLink) UpdateState(1);
    var saved_inventory = StructCopy(global.Inventory);
    var saved_items = StructCopy(global.Inventory_ItemData);
    var saved_challenges = StructCopy(global.Challenges);
    var saved_floor = oLink.FloorLevel;
    var saved_facing = oLink.Facing;
    var saved_health = global.Inventory_ItemData[17].Amount;
    var bari = EnemyFixture(oEnemy_Bari);
    global.Inventory_ItemData[44].Index = 1;
    var shocked = false;
    try {
        with (oLink) UpdateState(12);
        with (oSword) with (bari) Enemy_Hit_ShockLink();
        shocked = oLink.State == 18 && oLink.ShockEnemyInst == bari && !instance_exists(oSword);
    } catch (error) { shocked = false; }
    Record("Bari shock retains the enemy after destroying the sword", shocked);
    with (bari) instance_destroy();
    var health_before = global.Inventory_ItemData[17].Amount;
    var damage_applied = false;
    try {
        oLink.Invincible = false;
        with (oLink) event_perform_object(oLink, ev_alarm, 2);
        damage_applied = oLink.State != 18 && global.Inventory_ItemData[17].Amount < health_before;
    } catch (error) { damage_applied = false; }
    Record("shock completes after its attacker disappears", damage_applied);
    global.Inventory_ItemData[17].Amount = saved_health;
    with (oLink) UpdateState(1);
    oLink.Invincible = false;
    oLink.BounceBack = false;
    var guru = instance_create_layer(oLink.x + 80, oLink.y, "Objs_Lower", oEnemy_Guru_Bar,
        {FloorLevel: 0, RoomIndex: oLink.RoomIndex, SectionID: 0, Angle: 0, GurusDestroyed: false});
    with (guru.GuruInst[1]) instance_destroy();
    guru.State = 15;
    var guru_ok = false;
    try {
        with (guru) Gurus_Update();
        guru_ok = guru.GuruInst[0].State == 15 && guru.GuruInst[2].State == 15;
    } catch (error) { guru_ok = false; }
    Record("frozen Guru bar updates surviving children", guru_ok);
    guru.DestroyGurus = true;
    guru_ok = false;
    try {
        with (guru) event_perform_object(oEnemy_Guru_Bar, ev_step, ev_step_end);
        guru_ok = guru.GuruCount == 0 && guru.GurusDestroyed;
    } catch (error) { guru_ok = false; }
    Record("Guru bar cleanup tolerates an expired child", guru_ok);
    with (oEnemy_Guru) instance_destroy();
    with (guru) instance_destroy();
    var arrow_offsets = [[-4, -6, -7, 0], [6, -6, 7, 0], [0, -14, 0, -7], [0, 0, 0, 7]];
    var facings = [3, 4, 1, 2];
    for (var i = 0; i < 4; i++) {
        oLink.Facing = facings[i];
        var arrow = instance_create_layer(oLink.x, oLink.y, "Objs_Lower", oArrow);
        var expected = arrow_offsets[i];
        Record("arrow starts at its firing position direction " + string(facings[i]),
            arrow.x == oLink.x + expected[0] && arrow.y_base == oLink.y + expected[1]
            && arrow.vx == expected[2] && arrow.vy == expected[3] && !arrow.Setup);
        var first_x = arrow.x;
        var first_y = arrow.y_base;
        with (arrow) event_perform_object(oArrow, ev_step, ev_step_begin);
        Record("arrow initialization runs once direction " + string(facings[i]), arrow.x == first_x && arrow.y_base == first_y);
        with (arrow) instance_destroy();
    }
    var pickup = instance_create_layer(oLink.x, oLink.y, "Objs_Lower", oItem_Orb, {From: 22});
    pickup.ShopItem = false;
    pickup.FloorLevel = saved_floor == 0 ? 1 : 0;
    var picked = noone;
    with (oLink) picked = CheckPickupItem(oItem_Orb, pickup);
    Record("pickup rejects another floor", picked == noone && oLink.State == 1);
    with (oLink) UpdateState(1);
    pickup.FloorLevel = saved_floor;
    with (oLink) picked = CheckPickupItem(oItem_Orb, pickup);
    Record("pickup still accepts the current floor", picked == pickup && oLink.State == 6);
    with (oLink) UpdateState(1);
    oLink.ItemHolding = noone;
    with (pickup) instance_destroy();
    var explorer = instance_create_layer(oLink.x + 64, oLink.y, "Objs_Lower", oDeadGuy);
    explorer.ItemHolding = 44;
    global.Swordless = true;
    var has_loot = true;
    with (explorer) has_loot = DBScriptFunction_DeadGuy_CheckLoot();
    Record("explorer cannot grant a sword in a swordless run", !has_loot && explorer.ItemHolding == -1);
    global.Swordless = false;
    explorer.ItemHolding = 40;
    with (explorer) has_loot = DBScriptFunction_DeadGuy_CheckLoot();
    Record("explorer keeps allowed loot", has_loot);
    with (explorer) instance_destroy();
    var lighting = global.GlobalLighting;
    global.LinkDead = true;
    global.GlobalLighting = true;
    with (oIntro) event_perform_object(oIntro, ev_alarm, 1);
    Record("forest lightning stays off during death", global.GlobalLighting);
    global.LinkDead = false;
    global.GlobalLighting = lighting;
    var crystal = instance_create_layer(oLink.x, oLink.y, "ObjsHigher_Upper", oItem_Crystal);
    HoldUpItem(crystal, 2, false, false);
    audio_play_sound(Music_Boss_Defeated, 1, true);
    var bosses = oHUD.BossesDefeated;
    var music_playing = audio_is_playing(Music_Boss_Defeated);
    oLink.NovaCrystalTicks = room_speed * 15;
    with (oLink) event_perform_object(oLink, ev_step, ev_step_normal);
    Record("crystal fanfare has a bounded hold even if audio loops", music_playing && oLink.State == 1 && oHUD.BossesDefeated == bosses + 1);
    if (instance_exists(crystal)) with (crystal) instance_destroy();
    audio_stop_sound(Music_Boss_Defeated);
    global.Inventory = saved_inventory;
    global.Inventory_ItemData = saved_items;
    global.Challenges = saved_challenges;
    oLink.FloorLevel = saved_floor;
    oLink.Facing = saved_facing;
    oLink.ItemHolding = noone;
    with (oLink) UpdateState(1);
    global.Paused = false;
}
function ProgressionTests() {
    global.Paused = false;
    with (oLink) UpdateState(1);
    var moon = global.Inventory_ItemData[31].Owns[0];
    global.Inventory_ItemData[31].Owns[0] = true;
    var block = instance_create_layer(oLink.x + 16, oLink.y, "Objs_Lower", oSwitchBlock);
    var wall = WallObj_Create("Objs_Lower", oLink.x + 8, oLink.y, 2, 2);
    wall.IsSwitchBlock = true;
    wall.SwitchBlockInst = block;
    with (oLink) event_perform_object(oLink, ev_step, ev_step_normal);
    Record("Moon Pearl lowers a nearby block without pausing enemies", block.Toggle && !global.Paused);
    global.Inventory_ItemData[31].Owns[0] = moon;
    with (wall) instance_destroy();
    with (block) instance_destroy();
    global.Paused = false;
    var tree = instance_create_layer(oLink.x + 60, oLink.y - 30, "Objs_Lower", oVillager_Treeman, {Name: "Villager_Treeman", AddWall: false});
    oLink.State = 5;
    tree.TransformInit = true;
    with (tree) event_perform_object(oVillager_Treeman, ev_step, ev_step_normal);
    Record("Treeman transformation starts while Link is in water", !tree.TransformInit && tree.alarm[2] == 40 && oLink.State == 0 && global.Paused);
    tree.TransformInit = false;
    tree.DB_Started_GrandChild = true;
    tree.ResponseIndex = 2;
    var medallions = instance_number(oItem_Medallion);
    with (tree) event_perform_object(oVillager_Treeman, ev_step, ev_step_normal);
    Record("Treeman cannot grant a medallion without the powder bag", instance_number(oItem_Medallion) == medallions && tree.ItemHolding == 29 && tree.ResponseIndex == 3);
    with (tree) instance_destroy();
    global.Paused = false;
    with (oLink) UpdateState(1);
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
    Record("Red Armos starts a stomp if horizontal travel stalls", !controller.LastArmos_Jump && controller.alarm[5] == 5);
    with (controller) {
        event_perform_object(oBoss_Armos_C, ev_alarm, 5);
        repeat (12) event_perform_object(oBoss_Armos_C, ev_step, ev_step_begin);
    }
    Record("Red Armos reaches the floor and rearms its next jump", controller.z == 0 && !controller.LastArmos_Stomp && controller.alarm[6] > 0);
    with (oBoss_Armos) instance_destroy();
    with (controller) instance_destroy();
    var bow = global.Inventory_ItemData[7].Index;
    var old_prize = global.GemPrize[0][0];
    global.GemPrize[0][0] = {Class: 7, Index: 0, Amount: 1};
    var zora = instance_create_layer(oLink.x, oLink.y, "Objs_Lower", oZora, {GemCombo: [0, 0]});
    global.Inventory_ItemData[7].Index = 0;
    with (zora) event_perform_object(oZora, ev_alarm, 3);
    Record("Zora offers an upgrade to a basic bow", zora.PrizeClass == 7);
    with (oDialogueBox) instance_destroy();
    global.DB_Inst = noone;
    global.Inventory_ItemData[7].Index = 1;
    with (zora) event_perform_object(oZora, ev_alarm, 3);
    Record("Zora substitutes rupees after the bow is fully upgraded", zora.PrizeClass == 40);
    with (oDialogueBox) instance_destroy();
    global.DB_Inst = noone;
    with (zora) instance_destroy();
    global.Inventory_ItemData[7].Index = bow;
    global.GemPrize[0][0] = old_prize;
    global.Paused = false;
    with (oLink) UpdateState(1);
    for (var t = 0; t < 8; t++) {
        Record("locked progression door survives transformation " + string(t), global.Templates_Dungeon[0][t][13].Rooms[6].Doors[0].Status == 1 && global.Templates_Dungeon[2][t][6].Rooms[4].Doors[0].Status == 1);
        var layout_room = global.Templates_Dungeon[2][t][32].Rooms[5];
        Record("corrected side doors survive transformation " + string(t), layout_room.Doors[0].Position == GetTransformedDoorPosition(8, t) && layout_room.Doors[1].Position == GetTransformedDoorPosition(4, t) && layout_room.Doors[1].ConnectedRoomIndex == 10);
    }
    Record("progression key and barrier move together", global.Templates_Dungeon[1][0][14].Rooms[8].SpecialObj == 1 && global.Templates_Dungeon[1][0][14].Rooms[9].SpecialObj == 0 && global.Templates_Dungeon[1][0][14].Rooms[9].Doors[1].Status == 2);
    Record("large chests include the hookshot and boomerang", ds_list_find_index(global.PossibleItemLists[3], 6) >= 0 && ds_list_find_index(global.PossibleItemLists[3], 19) >= 0);
    Record("wishing pond includes the hookshot and boomerang", ds_list_find_index(global.PossibleItemLists[12], 6) >= 0 && ds_list_find_index(global.PossibleItemLists[12], 19) >= 0);
    Record("rods deal two base damage to vulnerable bosses", global.EnemyData[oBoss_Armos].LinkWeaponEffects[6][0] == 2 && global.EnemyData[oBoss_Lanmola].LinkWeaponEffects[7] == 2);
    Record("rod boss immunities stay intact", global.EnemyData[oBoss_Moldorm].LinkWeaponEffects[6] == -1 && global.EnemyData[oBoss_Armos].LinkWeaponEffects[6][1] == -1);
    Record("keyboard supports menu and all four directions", global.BindingIconCount[1] >= 12 && GetInputVerbStr(6) == "menu_access" && GetInputVerbStr(8) == "up" && GetInputVerbStr(11) == "right");
}
