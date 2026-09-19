NovaPage = 1;
NovaCell = 0;
NovaSlots = [];
NovaColumns = 5;
NovaPages = [];
NovaTitles = ["GEAR", "ITEMS", "BAGS", "TREASURE", "FOOD", "PENDANTS", "OVERFLOW"];
W = 208;
H = 132;
X = oCamera.X + floor((oCamera.W - W) / 2);
Y = oCamera.Y + 64;
Y_DialogueBox = Y + 28;
OpenGems = false;
CloseGems = false;
function NovaRefresh() {
    Inventory_Defrag();
    NovaPages = [0, 1, 2];
    if (global.Inventory_ItemData[15].Owns[0]) array_push(NovaPages, 3);
    if (global.Inventory_ItemData[49].Owns[0]) array_push(NovaPages, 4);
    if (global.Inventory_ItemData[50].Owns[0]) array_push(NovaPages, 5);
    var overflow = [];
    for (var slot = Inventory_MaxSlots(); slot <= 31; slot++) {
        if (global.Inventory[slot].ItemClass != -1) array_push(overflow, slot);
    }
    NovaOverflowPages = ceil(array_length(overflow) / 12);
    var overflow_pages = NovaOverflowPages;
    for (var page = 0; page < overflow_pages; page++) array_push(NovaPages, 6 + page);
    var page_exists = false;
    for (var i = 0; i < array_length(NovaPages); i++) if (NovaPages[i] == NovaPage) page_exists = true;
    if (!page_exists) NovaPage = overflow_pages > 0 && NovaPage >= 6 ? 6 : 1;
    switch (NovaPage) {
        case 0: NovaSlots = [0, 1, 2, 3, 4, 5]; NovaColumns = 3; break;
        case 1:
            NovaSlots = [];
            for (var slot = 10; slot < Inventory_MaxSlots(); slot++) array_push(NovaSlots, slot);
            NovaColumns = 5;
            break;
        case 2: NovaSlots = [6, 7, 8, 9]; NovaColumns = 4; break;
        case 3: NovaSlots = [32, 33, 34, 35, 36, 37]; NovaColumns = 3; break;
        case 4: NovaSlots = [38, 39, 40]; NovaColumns = 3; break;
        case 5: NovaSlots = [41, 42, 43]; NovaColumns = 3; break;
        default:
            NovaSlots = [];
            for (var i = (NovaPage - 6) * 12; i < min(array_length(overflow), (NovaPage - 5) * 12); i++) array_push(NovaSlots, overflow[i]);
            NovaColumns = 6;
            break;
    }
    NovaCell = clamp(NovaCell, 0, array_length(NovaSlots) - 1);
    global.Inventory_SlotIndex_Selected = NovaSlots[NovaCell];
}
function NovaTurnPage(page_delta) {
    var index = 0;
    for (var i = 0; i < array_length(NovaPages); i++) if (NovaPages[i] == NovaPage) index = i;
    NovaPage = NovaPages[(index + page_delta + array_length(NovaPages)) mod array_length(NovaPages)];
    NovaCell = 0;
    NovaRefresh();
}
function NovaItemMenu() {
    var slot = global.Inventory_SlotIndex_Selected;
    var item = global.Inventory[slot];
    if (item.ItemClass < 0) return;
    if (item.ItemClass == 15 || item.ItemClass == 49 || item.ItemClass == 50) {
        NovaPage = item.ItemClass == 15 ? 3 : (item.ItemClass == 49 ? 4 : 5);
        NovaCell = 0;
        NovaRefresh();
        return;
    }
    ds_grid_set(MenuItemGrid, 1, 0, global.ItemData[item.ItemClass].CanEquip);
    ds_grid_set(MenuItemGrid, 1, 1, global.ItemData[item.ItemClass].CanUse && Item_CanUse(item.ItemClass, item.ItemIndex));
    ds_grid_set(MenuItemGrid, 1, 2, (slot >= 10 || (slot < 5 && (item.ItemClass != 46 || item.ItemIndex > 0))) && !oLink.InDoor_Facing);
    MenuSelectionIndex = 0;
    while (!ds_grid_get(MenuItemGrid, 1, MenuSelectionIndex)) MenuSelectionIndex++;
    MenuEnable = true;
}
NovaRefresh();
