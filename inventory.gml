function NovaGearSlot(item_class) {
    switch (item_class) {
        case 44: return 0;
        case 41: return 1;
        case 46: return 2;
        case 16: return 3;
        case 24: return 4;
        case 51: return 4;
        case 0: return 5;
        case 4: return 6;
        case 15: return 7;
        case 49: return 8;
        case 50: return 9;
    }
    return -1;
}
function NovaBagRange(item_class) {
    if ((item_class == 14 || item_class == 23 || item_class == 47) && global.Inventory_ItemData[15].Owns[0]) return [32, 37];
    if (item_class == 13 && global.Inventory_ItemData[49].Owns[0]) return [38, 40];
    if (item_class == 34 && global.Inventory_ItemData[50].Owns[0]) return [41, 43];
    return [-1, -1];
}
function NovaEmptyRange(first, last) {
    if (first < 0) return -1;
    for (var slot = first; slot <= last; slot++) if (global.Inventory[slot].ItemClass == -1) return slot;
    return -1;
}
function NovaEmptySlot(item_class) {
    var gear = NovaGearSlot(item_class);
    if (gear >= 0) return gear;
    var range = NovaBagRange(item_class);
    var slot = NovaEmptyRange(range[0], range[1]);
    return slot >= 0 ? slot : Inventory_FindEmptySlot();
}
function Inventory_CalculateSlotIndexes(arg0 = global.Inventory_ItemData[2].Index, arg1 = true) {
    global.Inventory_SlotIndex_RowStart = [0, 10, 15, 20, 32, 34, 36];
    global.Inventory_SlotIndex_RowEnd = [9, 14, 19, 31, 33, 35, 37];
    global.Inventory_SlotIndex_ArrowQuiver = 5;
    global.Inventory_SlotIndex_BombBag = 6;
    global.Inventory_SlotIndex_GemBag = 7;
    global.Inventory_SlotIndex_Gems = 32;
    global.Inventory_SlotIndex_Last = 43;
    if (arg1) {
        global.Inventory_SlotIndex_Selected = 10;
        global.Inventory_SlotIndex_Equiped = -1;
        global.Inventory_ShowGems = false;
    }
}
function Inventory_MaxSlots(arg0 = global.Inventory_ItemData[2].Index) {
    return 15 + clamp(arg0, 0, 5);
}
function Inventory_MaxSlots_Useable(arg0 = global.Inventory_ItemData[2].Index) {
    return 5 + clamp(arg0, 0, 5);
}
function Inventory_SlotsPerRow(arg0 = global.Inventory_ItemData[2].Index) {
    return 5;
}
function Inventory_Defrag() {
    Inventory_TransferGems();
    var last_main = Inventory_MaxSlots() - 1;
    for (var slot = 10; slot <= last_main; slot++) {
        if (global.Inventory[slot].ItemClass != -1) continue;
        for (var source = slot + 1; source <= 31; source++) {
            if (global.Inventory[source].ItemClass == -1) continue;
            Inventory_MoveSlot(source, slot);
            break;
        }
    }
    for (var bag = 0; bag < 3; bag++) {
        var starts = [32, 38, 41];
        var ends = [37, 40, 43];
        var first = starts[bag];
        var last = ends[bag];
        for (var slot = first; slot < last; slot++) {
            if (global.Inventory[slot].ItemClass != -1) continue;
            for (var source = slot + 1; source <= last; source++) {
                if (global.Inventory[source].ItemClass == -1) continue;
                Inventory_MoveSlot(source, slot);
                break;
            }
        }
    }
}
function Inventory_TransferGems() {
    for (var slot = 10; slot <= 31; slot++) {
        var item_class = global.Inventory[slot].ItemClass;
        if (item_class < 0) continue;
        var range = NovaBagRange(item_class);
        var target = NovaEmptyRange(range[0], range[1]);
        if (target >= 0) Inventory_MoveSlot(slot, target);
    }
}
function NovaInventoryInit() {
    global.Inventory_ItemData[2].Index_Max = 5;
    for (var slot = 38; slot <= 43; slot++) global.Inventory[slot] = {ItemClass: -1, ItemIndex: -1, Amount: 0, Enabled: true};
    global.Inventory[2].ItemClass = 46;
    global.Inventory[2].ItemIndex = 0;
    global.NovaCandleInit();
}
function NovaInventoryMigrate(save) {
    var version = variable_struct_exists(save, "NovaInventoryVersion") ? save.NovaInventoryVersion : 0;
    if (version >= 2) return;
    if (version == 1) { global.NovaCandleInit(); return; }
    var old_slots = StructCopy(global.Inventory);
    var old_equipped = global.Inventory_SlotIndex_Equiped;
    ItemDataInit(2, 2, 0, 0, 6, 3);
    ItemDataInit(49, 1, 0, 0, 0, 7);
    ItemDataInit(50, 1, 0, 0, 0, 7);
    global.Inventory_ItemData[49] = {Owns: [false]};
    global.Inventory_ItemData[50] = {Owns: [false]};
    var old_capacities = [0, 3, 5];
    global.Inventory_ItemData[2].Index = old_capacities[clamp(global.Inventory_ItemData[2].Index, 0, 2)];
    if (global.Inventory_ItemData[2].Index == 0 && global.StartingGear == 2) global.Inventory_ItemData[2].Index = 1;
    global.Inventory_ItemData[2].Index_Max = 5;
    global.Inventory = array_create(44);
    for (var slot = 0; slot < 44; slot++) global.Inventory[slot] = {ItemClass: -1, ItemIndex: -1, Amount: 0, Enabled: true};
    global.Inventory_SlotIndex_Equiped = -1;
    for (var slot = 0; slot < array_length(old_slots); slot++) {
        var item = old_slots[slot];
        if (item.ItemClass < 0) continue;
        var target = NovaEmptySlot(item.ItemClass);
        if (target < 0) target = NovaEmptyRange(20, 31);
        if (target < 0) throw "Inventory migration cannot retain every item.";
        global.Inventory[target] = item;
        if (slot == old_equipped) global.Inventory_SlotIndex_Equiped = target;
    }
    if (global.Inventory[2].ItemClass == -1 && global.Inventory_ItemData[46].Owns) {
        global.Inventory[2].ItemClass = 46;
        global.Inventory[2].ItemIndex = global.Inventory_ItemData[46].Index;
    }
    global.NovaCandleInit();
    Inventory_Defrag();
}

function NovaCandleInit() {
    ItemDataInit(51, 1, 0, 0, 0, 0);
    var owns = !global.Inventory_ItemData[24].Owns[0];
    global.Inventory_ItemData[51] = {Owns: [owns, false]};
    if (owns) global.Inventory[4] = {ItemClass: 51, ItemIndex: 0, Amount: 1, Enabled: true};
}
