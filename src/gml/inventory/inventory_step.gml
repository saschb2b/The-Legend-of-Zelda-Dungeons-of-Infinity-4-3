Link_PauseHitFlashingTimer();
if (Open) {
    Alpha = min(1, Alpha + AlphaSpeed);
    Open = Alpha < 1;
    exit;
}
if (Close) exit;
if (DB_Started) {
    if (!instance_exists(global.DB_Inst)) DB_Started = false;
    exit;
}
if (instance_exists(global.DB_Inst)) exit;
if (input_check_pressed("menu_access") || input_check_pressed("inventory") || keyboard_check_pressed(vk_escape)) { Close = true; input_clear_momentary(true); exit; }
var left = input_check_pressed("left");
var right = input_check_pressed("right");
var up = input_check_pressed("up");
var down = input_check_pressed("down");
var confirm = input_check_pressed(global.NovaConfirmVerb());
var close_input = input_check_pressed(global.NovaCloseVerb());
if (close_input) {
    if (MenuEnable) MenuEnable = false;
    else Close = true;
    input_clear_momentary(true);
    exit;
}
var previous = input_check_pressed("nova_bag_previous");
var next = input_check_pressed("nova_bag_next");
if (previous || next) {
    if (previous != next) { MenuEnable = false; NovaTurnPage(next ? 1 : -1); }
    input_clear_momentary(true);
    exit;
}
if (MenuEnable) {
    if (left || right) {
        var page_delta = right ? 1 : -1;
        repeat (MenuItems) {
            MenuSelectionIndex = (MenuSelectionIndex + page_delta + MenuItems) mod MenuItems;
            if (ds_grid_get(MenuItemGrid, 1, MenuSelectionIndex)) break;
        }
    }
    if (confirm && ds_grid_get(MenuItemGrid, 1, MenuSelectionIndex)) {
        var slot = global.Inventory_SlotIndex_Selected;
        var item = global.Inventory[slot];
        switch (MenuSelectionIndex) {
            case 0: global.Inventory_SlotIndex_Equiped = slot; break;
            case 1: Inventory_UseItem(slot, true); break;
            case 2:
                var pos = Item_DropPos();
                var dropped = ItemDrop(pos[0], pos[1], item.ItemClass, item.ItemIndex, item.Amount, 19);
                dropped.Get_ShowDialogue = false;
                Inventory_DeleteSlot(slot);
                Inventory_CountStackItems();
                break;
            case 3:
                global.DB_Inst = instance_create_layer(0, 0, "System", oDialogueBox);
                global.DB_Inst.depth = depth - 1;
                global.DB_Inst.Y = Y_DialogueBox - oCamera.Y;
                global.DB_Inst.ShowBox = false;
                global.DB_Inst.Script = DBScript_Info;
                DB_Started = true;
                break;
        }
        MenuEnable = false;
        NovaRefresh();
    }
    exit;
}
{
    if (up) NovaCell = max(0, NovaCell - NovaColumns);
    if (down) NovaCell = min(NovaCell + NovaColumns, array_length(NovaSlots) - 1);
    if (left) NovaCell = max(0, NovaCell - 1);
    if (right) NovaCell = min(array_length(NovaSlots) - 1, NovaCell + 1);
    NovaRefresh();
    if (confirm) NovaItemMenu();
    if (input_check_pressed("item")) {
        var item = global.Inventory[global.Inventory_SlotIndex_Selected];
        if (item.ItemClass >= 0 && global.ItemData[item.ItemClass].CanEquip) global.Inventory_SlotIndex_Equiped = global.Inventory_SlotIndex_Selected;
    }
}
