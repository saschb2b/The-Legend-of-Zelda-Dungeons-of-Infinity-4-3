// The expanded inventory: gear and bag slots, candles, migration and saves; sword poke and spin.
// The inventory tests build one run's bag in order; the last one restores the original inventory.
Suite("Inventory", "gameplay", function() {
    BeforeAll(function() {
        InventorySavedInventory = StructCopy(global.Inventory);
        InventorySavedItems = StructCopy(global.Inventory_ItemData);
        InventorySavedData = StructCopy(global.ItemData);
        InventorySavedEquipped = global.Inventory_SlotIndex_Equiped;
        global.ItemData[1].Type = 3;
        global.ItemData[5].Type = 3;
    });
    Test("the expanded inventory is available", function() {
        Check("expanded inventory is available", variable_global_exists("NovaInventoryMigrate"));
    });
    Test("a new run starts with five main slots and a candle", function() {
        Inventory_InitData();
        Check("new run has five main slots", Inventory_MaxSlots_Useable() == 5);
        Check("new run has a real candle in the light slot", global.Inventory[4].ItemClass == 51 && global.Inventory_ItemData[51].Owns[0]);
    });
    Test("a dropped candle stays dropped through saving and loading", function() {
        var candle_ui = instance_create_layer(0, 0, "System", oInventory);
        candle_ui.Open = false;
        candle_ui.NovaPage = 0;
        candle_ui.NovaCell = 4;
        oLink.InDoor_Facing = false;
        with (candle_ui) { NovaRefresh(); NovaItemMenu(); }
        candle_ui.MenuSelectionIndex = 2;
        PressEvent(candle_ui, global.NovaConfirmVerb(), oInventory, ev_step, ev_step_normal);
        Lighting_UpdateLinkLight(undefined, 1);
        Check("dropping the starting candle removes the owned light", global.Inventory[4].ItemClass == -1 && !global.Inventory_ItemData[51].Owns[0] && global.LinkLight_Pos[2] == 0 && instance_exists(oNovaCandle));
        User_SaveGame();
        User_LoadGame();
        Check("save and load keep a dropped candle absent", global.Inventory[4].ItemClass == -1 && !global.Inventory_ItemData[51].Owns[0]);
        with (candle_ui) instance_destroy();
    });
    Test("a dropped candle stays lit and can be picked up again", function() {
        var dropped_candle = instance_find(oNovaCandle, 0);
        Check("dropped candle keeps the lit frame", dropped_candle.image_index == 1);
        dropped_candle.Spawning = false;
        dropped_candle.Get_Allowed = true;
        var original_x = oLink.x;
        var original_y = oLink.y;
        oLink.x = dropped_candle.x;
        oLink.y = dropped_candle.y;
        with (oLink) CheckItems();
        oLink.x = original_x;
        oLink.y = original_y;
        Lighting_UpdateLinkLight(undefined, 1);
        Check("walking onto a dropped candle restores light without granting a lamp", !instance_exists(dropped_candle) && global.LinkLight_Pos[2] == 1 && !global.Inventory_ItemData[24].Owns[0] && global.Inventory[4].ItemClass == 51);
        with (oNovaCandle) instance_destroy();
    });
    Test("the oil lamp replaces the candle for good", function() {
        Inventory_Add(44, 0);
        Inventory_Add(41, 0);
        Inventory_Add(16, 0);
        Inventory_Add(24, 0);
        Check("oil lamp upgrades the candle and cannot be replaced by it", !global.Inventory_ItemData[51].Owns[0] && global.Inventory[4].ItemClass == 24 && Inventory_CanAdd(51, 0) == -1);
    });
    Test("six gear slots leave the main bag empty", function() {
        Inventory_Add(0, 0);
        Check("six gear slots leave the main bag empty", global.Inventory[0].ItemClass == 44 && global.Inventory[1].ItemClass == 41 && global.Inventory[2].ItemClass == 46 && global.Inventory[3].ItemClass == 16 && global.Inventory[4].ItemClass == 24 && global.Inventory[5].ItemClass == 0 && Inventory_FindEmptySlot() == 10);
    });
    Test("bags and treasure storage fill before the main bag", function() {
        Inventory_Add(49, 0);
        Inventory_Add(50, 0);
        Inventory_Add(15, 0);
        for (var i = 0; i < 4; i++) Inventory_Add(13, i, 1);
        Check("food bag holds three items before using main storage", global.Inventory[38].ItemClass == 13 && global.Inventory[40].ItemIndex == 2 && Inventory_ItemIndexExists(13, 3) == 10);
        for (var i = 0; i < 4; i++) Inventory_Add(34, i);
        Check("pendant bag holds three pendants before using main storage", global.Inventory[41].ItemClass == 34 && global.Inventory[43].ItemIndex == 2 && Inventory_ItemIndexExists(34, 3) == 11);
        Inventory_Add(47, 0, 3);
        Check("wishstones use treasure storage and retain their count", global.Inventory[32].ItemClass == 47 && global.Inventory[32].Amount == 3 && global.Inventory_ItemData[47].Amount[0] == 3);
    });
    Test("bag compaction keeps the equipped pendant", function() {
        var equipped_slot = Inventory_ItemIndexExists(34, 3);
        global.Inventory_SlotIndex_Equiped = equipped_slot;
        Inventory_DeleteSlot(41);
        Inventory_Defrag();
        Check("bag compaction keeps the equipped pendant", global.Inventory[global.Inventory_SlotIndex_Equiped].ItemClass == 34 && global.Inventory[global.Inventory_SlotIndex_Equiped].ItemIndex == 3 && global.Inventory_SlotIndex_Equiped >= 41);
    });
    Test("slot upgrades grow the main bag to ten", function() {
        for (var upgrade = 1; upgrade <= 5; upgrade++) {
            Inventory_Add(2, upgrade);
            Check("slot upgrade " + string(upgrade) + " adds one space", Inventory_MaxSlots_Useable() == 5 + upgrade);
        }
        Inventory_Add(2, 99);
        Check("main bag capacity stops at ten", Inventory_MaxSlots_Useable() == 10);
    });
    Test("slot upgrades cost and limit like heart containers", function() {
        Check("slot upgrades use heart-container price and limiter", Item_Price(2, 1, 1) == Item_Price(18, 0, 1) && global.ItemData[2].LimitMin == global.ItemData[18].LimitMin && global.ItemData[2].LimitStart == global.ItemData[18].LimitStart);
    });
    Test("rods cap new charges and keep legacy ones", function() {
        for (var rod = 0; rod < 6; rod++) {
            Inventory_Add(39, rod, 99);
            var slot = Inventory_ItemIndexExists(39, rod);
            Check("rod " + string(rod) + " caps new charges", global.Inventory[slot].Amount == Inventory_MaxAmount(39, rod));
            global.Inventory[slot].Amount = 16;
            Inventory_Add(39, rod, -1, slot);
            Check("rod " + string(rod) + " retains legacy charges when used", global.Inventory[slot].Amount == 15);
            Inventory_DeleteSlot(slot);
        }
    });
    Test("current and first-schema saves keep their layout", function() {
        var before = json_stringify(global.Inventory);
        global.NovaInventoryMigrate({NovaInventoryVersion: 2});
        Check("current saves do not migrate twice", json_stringify(global.Inventory) == before);
        global.Inventory_ItemData[51] = undefined;
        global.NovaInventoryMigrate({NovaInventoryVersion: 1});
        Check("first inventory-schema saves gain candle metadata without moving gear", json_stringify(global.Inventory) == before && !global.Inventory_ItemData[51].Owns[0]);
    });
    Test("a full legacy bag migrates without losing items", function() {
        // A full legacy bag can contain more consumables than the new main bag fits.
        var legacy = array_create(38);
        for (var slot = 0; slot < 38; slot++) legacy[slot] = {ItemClass: -1, ItemIndex: -1, Amount: 0, Enabled: true};
        for (var slot = 6; slot < 24; slot++) legacy[slot] = {ItemClass: 36, ItemIndex: slot mod 5, Amount: slot, Enabled: true};
        legacy[32] = {ItemClass: 14, ItemIndex: 2, Amount: 1, Enabled: true};
        global.Inventory = legacy;
        global.Inventory_SlotIndex_Equiped = 23;
        global.Inventory_ItemData[2].Index = 2;
        global.NovaInventoryMigrate({});
        var total = 0;
        var count = 0;
        var overflow = 0;
        for (var slot = 0; slot <= global.Inventory_SlotIndex_Last; slot++) {
            if (global.Inventory[slot].ItemClass != 36) continue;
            count++;
            total += global.Inventory[slot].Amount;
            if (slot >= 20 && slot <= 31) overflow++;
        }
        Check("legacy migration retains every item and amount", count == 18 && total == 261 && Inventory_ItemIndexExists(14, 2) >= 32);
        Check("legacy migration exposes excess items without enlarging the main bag", overflow == 8 && Inventory_MaxSlots_Useable() == 10);
        Check("legacy migration retains the equipped item", global.Inventory[global.Inventory_SlotIndex_Equiped].Amount == 23);
    });
    Test("using an item moves overflow back into the main bag", function() {
        Inventory_DeleteSlot(10);
        Inventory_Defrag();
        var overflow_after = 0;
        for (var slot = 20; slot <= 31; slot++) if (global.Inventory[slot].ItemClass != -1) overflow_after++;
        Check("using an item moves retained overflow back into the main bag", overflow_after == 7 && global.Inventory[10].ItemClass == 36);
    });
    Test("overflow items are selectable in the inventory", function() {
        var ui = instance_create_layer(0, 0, "System", oInventory);
        ui.Open = false;
        ui.Alpha = 1;
        ui.NovaPage = 6;
        with (ui) NovaRefresh();
        Check("overflow items are selectable in the inventory", array_length(ui.NovaSlots) == 7);
        with (ui) instance_destroy();
    });
    Test("the oil lamp and sword can be dropped from dedicated gear", function() {
        var ui = instance_create_layer(0, 0, "System", oInventory);
        ui.Open = false;
        ui.Alpha = 1;
        ui.NovaPage = 0;
        with (ui) NovaRefresh();
        ui.NovaCell = 4;
        global.Inventory[4].ItemClass = 24;
        global.Inventory[4].ItemIndex = 0;
        oLink.InDoor_Facing = false;
        with (ui) { NovaRefresh(); NovaItemMenu(); }
        Check("oil lamp has a drop action in dedicated gear", ds_grid_get(ui.MenuItemGrid, 1, 2));
        ui.MenuEnable = false;
        ui.NovaCell = 0;
        global.Inventory[0].ItemClass = 44;
        global.Inventory[0].ItemIndex = 0;
        with (ui) { NovaRefresh(); NovaItemMenu(); }
        Check("sword can still be dropped for a swordless run", ds_grid_get(ui.MenuItemGrid, 1, 2));
        with (ui) instance_destroy();
    });
    Test("saving and loading preserves the migrated inventory", function() {
        var round_trip = json_stringify(global.Inventory);
        var equipped_before_save = global.Inventory_SlotIndex_Equiped;
        User_SaveGame();
        Inventory_InitData();
        User_LoadGame();
        Check("saving and loading preserves migrated inventory", json_stringify(global.Inventory) == round_trip && global.Inventory_SlotIndex_Equiped == equipped_before_save && global.Users[global.UserIndex].SaveData.NovaInventoryVersion == 2);
        global.Inventory = InventorySavedInventory;
        global.Inventory_ItemData = InventorySavedItems;
        global.ItemData = InventorySavedData;
        global.Inventory_SlotIndex_Equiped = InventorySavedEquipped;
        Inventory_CalculateSlotIndexes(undefined, false);
    });
});

// Each sword test sets the sword level it needs and restores the player's level afterwards.
Suite("Sword charge", "gameplay", function() {
    Test("poke, spin and the charge cue are available", function() {
        Check("sword poke and spin are available", variable_instance_exists(oLink, "NovaSwordMode"));
        Check("sword charge cue shares the attack readiness condition", variable_instance_exists(oLink, "NovaSwordIsCharged"));
    });
    Test("every level holds a poke and only level three spins", function() {
        var sword_level = global.Inventory_ItemData[44].Index;
        var has_readiness = variable_instance_exists(oLink, "NovaSwordIsCharged");
        for (var level = 0; level <= 2; level++) {
            global.Inventory_ItemData[44].Index = level;
            global.NovaTestHeld = ["sword"];
            oLink.Facing = 4;
            with (oLink) {
                UpdateState(12);
                NovaSwordFinishSwing();
                repeat (48) NovaSwordStep();
            }
            Check("level " + string(level + 1) + " can hold a sword poke", oLink.State == 12 && oLink.NovaSwordMode == 1 && instance_exists(oSword));
            if (has_readiness) Check("charge cue respects sword level " + string(level + 1), oLink.NovaSwordIsCharged() == (level == 2));
            var charge = oLink.NovaSwordCharge;
            global.Paused = true;
            with (oLink) NovaSwordStep();
            Check("sword charge stops during pause level " + string(level + 1), oLink.NovaSwordCharge == charge);
            global.Paused = false;
            global.NovaTestHeld = [];
            with (oLink) NovaSwordStep();
            Check("spin unlocks at level three: sword " + string(level + 1), level < 2 ? oLink.State == 1 : (oLink.State == 12 && oLink.NovaSwordMode == 2));
            if (level == 2) {
                with (oLink) repeat (16) NovaSwordStep();
                Check("spin finishes and restores facing", oLink.State == 1 && oLink.Facing == 4 && !instance_exists(oSword));
            }
        }
        global.Inventory_ItemData[44].Index = sword_level;
        with (oLink) UpdateState(1);
    });
    Test("the spin is ready after exactly 48 charge updates", function() {
        var sword_level = global.Inventory_ItemData[44].Index;
        var has_readiness = variable_instance_exists(oLink, "NovaSwordIsCharged");
        global.Inventory_ItemData[44].Index = 2;
        var thresholds = [0, 1, 44, 45, 47, 48, 49];
        for (var i = 0; i < array_length(thresholds); i++) {
            global.NovaTestHeld = ["sword"];
            with (oLink) {
                UpdateState(12);
                NovaSwordFinishSwing();
                repeat (thresholds[i]) NovaSwordStep();
            }
            var ready = thresholds[i] >= 48;
            if (has_readiness) Check("charge cue at update " + string(thresholds[i]), oLink.NovaSwordIsCharged() == ready);
            global.NovaTestHeld = [];
            with (oLink) NovaSwordStep();
            Check("spin release at update " + string(thresholds[i]), ready ? oLink.NovaSwordMode == 2 : oLink.State == 1);
            if (has_readiness) Check("charge cue clears after release at update " + string(thresholds[i]), !oLink.NovaSwordIsCharged());
        }
        global.Inventory_ItemData[44].Index = sword_level;
        with (oLink) UpdateState(1);
    });
    Test("pause cannot advance the charge", function() {
        var sword_level = global.Inventory_ItemData[44].Index;
        var has_readiness = variable_instance_exists(oLink, "NovaSwordIsCharged");
        global.Inventory_ItemData[44].Index = 2;
        global.NovaTestHeld = ["sword"];
        with (oLink) { UpdateState(12); NovaSwordFinishSwing(); repeat (47) NovaSwordStep(); }
        global.Paused = true;
        with (oLink) repeat (5) NovaSwordStep();
        Check("pause cannot advance the last uncharged update", oLink.NovaSwordCharge == 47);
        if (has_readiness) Check("pause cannot reveal the charge cue early", !oLink.NovaSwordIsCharged());
        global.Paused = false;
        with (oLink) NovaSwordStep();
        Check("charge reaches 48 on the first resumed update", oLink.NovaSwordCharge == 48);
        if (has_readiness) Check("charge cue appears on the first resumed update", oLink.NovaSwordIsCharged());
        global.NovaTestHeld = [];
        global.Inventory_ItemData[44].Index = sword_level;
        with (oLink) UpdateState(1);
    });
    Test("an early release cancels without a spin", function() {
        var sword_level = global.Inventory_ItemData[44].Index;
        global.Inventory_ItemData[44].Index = 2;
        global.NovaTestHeld = ["sword"];
        with (oLink) { UpdateState(12); NovaSwordFinishSwing(); repeat (5) NovaSwordStep(); }
        global.NovaTestHeld = [];
        with (oLink) NovaSwordStep();
        Check("early sword release cancels without a spin", oLink.State == 1 && !instance_exists(oSword));
        global.Inventory_ItemData[44].Index = sword_level;
        with (oLink) UpdateState(1);
    });
    Test("a sword poke moves without turning", function() {
        var sword_level = global.Inventory_ItemData[44].Index;
        global.Inventory_ItemData[44].Index = 2;
        oLink.Facing = 4;
        global.NovaTestHeld = ["sword", "right"];
        with (oLink) { UpdateState(12); NovaSwordFinishSwing(); NovaSwordStep(); }
        Check("sword poke allows movement while preserving facing", oLink.vx > 0 && oLink.Facing == 4);
        global.NovaTestHeld = [];
        global.Inventory_ItemData[44].Index = sword_level;
        with (oLink) UpdateState(1);
    });
    Test("falling interrupts the charge and removes the blade", function() {
        var sword_level = global.Inventory_ItemData[44].Index;
        global.Inventory_ItemData[44].Index = 2;
        oLink.Facing = 4;
        global.NovaTestHeld = ["sword", "right"];
        with (oLink) { UpdateState(12); NovaSwordFinishSwing(); NovaSwordStep(); }
        with (oLink) UpdateState(20);
        Check("falling interrupts sword charge and removes the blade", oLink.NovaSwordMode == 0 && !instance_exists(oSword));
        global.NovaTestHeld = [];
        global.Inventory_ItemData[44].Index = sword_level;
        with (oLink) UpdateState(1);
    });
    Test("pots break from sword level two", function() {
        var sword_level = global.Inventory_ItemData[44].Index;
        for (var level = 0; level < 2; level++) {
            global.Inventory_ItemData[44].Index = level;
            with (oLink) { Facing = 4; UpdateState(12); image_index = 6; }
            var pot = instance_create_layer(oLink.x + 14, oLink.y - 4, "Objs_Lower", oPot, {FloorLevel: oLink.FloorLevel});
            with (oSword) event_perform_object(oSword, ev_step, ev_step_end);
            Check("pot breaking starts at sword level two: " + string(level + 1), level == 0 ? pot.State != 5 : pot.State == 5);
            with (pot) instance_destroy();
            with (oLink) UpdateState(1);
        }
        global.Inventory_ItemData[44].Index = sword_level;
    });
    Test("a spin hits enemies behind Link only on his floor", function() {
        var sword_level = global.Inventory_ItemData[44].Index;
        global.Inventory_ItemData[44].Index = 2;
        with (oLink) { Facing = 4; UpdateState(12); image_index = 6; NovaSwordMode = 2; }
        var target = EnemyFixture(oEnemy_Rat);
        target.x = oLink.x - 10;
        target.y = oLink.y - 6;
        target.FloorLevel = oLink.FloorLevel == 0 ? 1 : 0;
        target.State = 3;
        var energy = target.Energy;
        with (oSword) event_perform_object(oSword, ev_step, ev_step_end);
        Check("spin cannot damage an enemy on another floor", !target.Hit && target.Energy == energy);
        target.FloorLevel = oLink.FloorLevel;
        with (oSword) event_perform_object(oSword, ev_step, ev_step_end);
        with (target) Enemy_CheckHit();
        Check("spin damages an enemy behind Link", target.Energy < energy);
        with (target) instance_destroy();
        global.Inventory_ItemData[44].Index = sword_level;
        with (oLink) UpdateState(1);
    });
});
