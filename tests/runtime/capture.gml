Capture = "";
CaptureTick = 0;
CaptureIndex = 0;
CaptureNames = ["inventory-gear", "inventory-items", "inventory-bags", "inventory-treasure", "inventory-food", "inventory-pendants", "inventory-overflow"];
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
    global.InventoryInst.NovaPage = CaptureIndex;
    with (global.InventoryInst) NovaRefresh();
}
