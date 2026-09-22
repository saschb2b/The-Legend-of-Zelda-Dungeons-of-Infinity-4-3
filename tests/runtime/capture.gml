Capture = "";
CaptureTick = 0;
CaptureIndex = 0;
CaptureNames = ["inventory-gear", "inventory-items", "inventory-bags", "inventory-treasure", "inventory-food", "inventory-pendants", "inventory-overflow", "inventory-actions", "inventory-info", "inventory-keyboard", "inventory-crt", "inventory-overflowextra", "status-default", "status-crt", "status-remapped", "status-keyboard", "inventory-cursed", "map-default", "options-pause"];
function CaptureStart() {
    global.ItemData[1].Type = 3;
    global.ItemData[5].Type = 3;
    Inventory_InitData();
    Inventory_Add(2, 5);
    Inventory_Add(44, 2);
    Inventory_Add(41, 1);
    Inventory_Add(46, 1);
    Inventory_Add(16, 1);
    Inventory_Add(24, 0);
    Inventory_Add(0, 0);
    Inventory_Add(4, 0);
    Inventory_Add(15, 0);
    Inventory_Add(49, 0);
    Inventory_Add(50, 0);
    for (var i = 0; i < 3; i++) { Inventory_Add(13, i); Inventory_Add(34, i); }
    Inventory_Add(14, 2);
    Inventory_Add(23, 1);
    Inventory_Add(47, 0, 3);
    for (var slot = 10; slot < 20; slot++) global.Inventory[slot] = {ItemClass: 13, ItemIndex: slot - 10, Amount: 1, Enabled: true};
    for (var slot = 20; slot < 28; slot++) global.Inventory[slot] = {ItemClass: 36, ItemIndex: slot mod 5, Amount: 1, Enabled: true};
    global.Inventory_ItemData[18].Amount = 20;
    global.Inventory_ItemData[17].Amount = 17.5;
    global.Inventory_ItemData[26].Amount = 32;
    global.Inventory_ItemData[40].Amount = 9999;
    global.Inventory_ItemData[1].Amount[0] = 99;
    global.Inventory_ItemData[5].Amount[0] = 99;
    global.Inventory_ItemData[20].Amount = 99;
    oHUD.AddHealth = 0;
    oHUD.AddMagic = 0;
    oHUD.AddRupees = 0;
    global.Inventory_SlotIndex_Equiped = 6;
    input_profile_set("gamepad");
    with (oLink) UpdateState(24);
    global.Paused = true;
    global.InventoryInst = instance_create_layer(0, 0, "System", oInventory);
    global.InventoryInst.Open = false;
    global.InventoryInst.Alpha = 1;
    global.InventoryInst.NovaPage = 0;
    with (global.InventoryInst) NovaRefresh();
}
function CaptureStep() {
    CaptureTick++;
    if (CaptureTick == 20) {
        if (CaptureIndex == 8) Record("information retains the inventory grid", array_length(global.InventoryInst.NovaSlots) == 6 && global.InventoryInst.Alpha == 1);
        Capture = CaptureNames[CaptureIndex];
        Flush();
    }
    if (!file_exists("nova-capture-done.txt")) return;
    file_delete("nova-capture-done.txt");
    Capture = "";
    CaptureTick = 0;
    CaptureIndex++;
    if (CaptureIndex == array_length(CaptureNames)) {
        Complete = true;
        Flush();
        game_end();
        return;
    }
    if (CaptureIndex == 18) {
        with (oMap) instance_destroy();
        // CRT stays on behind the pause Options to show the live preview.
        global.Users[global.UserIndex].Prefs[3] = true;
        var pause = instance_create_layer(0, 0, "System", oMenu_Game);
        pause.Open = false;
        pause.Alpha = 1;
        pause.NovaOptionsOpen = true;
        pause.NovaOptions = global.NovaOptionsState("pause");
        pause.NovaOptions.tab = 1;
        return;
    }
    if (CaptureIndex == 17) {
        with (oInventory) instance_destroy();
        global.Cursed = false;
        global.MapInst = instance_create_layer(0, 0, "System", oMap);
        global.MapInst.Open = false;
        global.MapInst.Alpha = 1;
        global.MapInst.LinkAlpha = 90;
        return;
    }
    if (CaptureIndex == 16) {
        input_profile_set("gamepad");
        global.Paused = true;
        global.Cursed = true;
        global.CurseEffectStr = "MAGIC DRAIN";
        global.CurseTaskStr = "DEFEAT ENEMIES";
        global.CurseTaskCount = 12;
        global.InventoryInst = instance_create_layer(0, 0, "System", oInventory);
        global.InventoryInst.Open = false;
        global.InventoryInst.Alpha = 1;
        global.InventoryInst.NovaPage = 0;
        with (global.InventoryInst) NovaRefresh();
        return;
    }
    if (CaptureIndex >= 12) {
        with (oInventory) instance_destroy();
        global.Paused = false;
        global.Users[global.UserIndex].Prefs[2] = false;
        global.Users[global.UserIndex].Prefs[3] = CaptureIndex == 13;
        input_profile_set(CaptureIndex == 15 ? "keyboard" : "gamepad");
        if (CaptureIndex == 14) input_binding_set("hud", input_binding_gamepad_button(gp_face3), 0, 0, "gamepad");
        return;
    }
    var ui = global.InventoryInst;
    if (instance_exists(global.DB_Inst)) {
        PressEvent(global.DB_Inst, global.NovaCloseVerb(), oDialogueBox, ev_step, ev_step_end);
        ui.DB_Started = false;
    }
    ui.MenuEnable = false;
    ui.NovaCell = 0;
    ui.NovaPage = min(CaptureIndex, 6);
    input_profile_set("gamepad");
    global.Users[global.UserIndex].Prefs[3] = false;
    switch (CaptureIndex) {
        case 7:
        case 8:
            ui.NovaPage = 0;
            with (ui) { NovaRefresh(); NovaItemMenu(); }
            ui.MenuSelectionIndex = 3;
            if (CaptureIndex == 8) PressEvent(ui, global.NovaConfirmVerb(), oInventory, ev_step, ev_step_normal);
            break;
        case 9:
            ui.NovaPage = 1;
            input_profile_set("keyboard");
            break;
        case 10:
            ui.NovaPage = 2;
            global.Users[global.UserIndex].Prefs[3] = true;
            break;
        case 11:
            global.Inventory_ItemData[2].Index = 0;
            for (var slot = 10; slot <= 31; slot++) global.Inventory[slot] = {ItemClass: 36, ItemIndex: slot mod 5, Amount: 1, Enabled: true};
            ui.NovaPage = 7;
            break;
    }
    with (ui) NovaRefresh();
}
