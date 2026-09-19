draw_set_alpha(Alpha * 0.6);
draw_set_color(c_black);
draw_rectangle(oCamera.X, oCamera.Y, oCamera.X + oCamera.W, oCamera.Y + oCamera.H, false);
draw_set_alpha(Alpha);
draw_set_color(c_white);
draw_sprite_stretched(sprite_index, 0, X, Y, W, H);
draw_set_font(global.HUDFont2);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
if (DB_Started) {
    draw_text(X + W / 2, Y + 10, "ITEM INFO");
    draw_set_halign(fa_left);
    draw_set_alpha(1);
    exit;
}
var heading = global.NovaInventoryHeading(id);
draw_text(X + W / 2, Y + 10, heading);
var origin_x = X + floor((W - NovaColumns * 24) / 2);
var origin_y = Y + 28;
for (var cell = 0; cell < array_length(NovaSlots); cell++) {
    var slot = NovaSlots[cell];
    var px = origin_x + (cell mod NovaColumns) * 24;
    var py = origin_y + (cell div NovaColumns) * 24;
    draw_sprite(sInventory_Slot, 0, px, py);
    var item = global.Inventory[slot];
    if (item.ItemClass >= 0) {
        var spr = item.ItemClass == 44 ? sItem_Sword_Inventory : object_get_sprite(ObjIndexFromItemClass(item.ItemClass));
        var index = item.ItemClass == 51 ? 1 : (item.ItemClass == 31 ? global.Level.SwitchBlock_ActiveColor : item.ItemIndex);
        var offset = Inventory_GetPosOffset(spr, index);
        draw_sprite(spr, index, px + offset[0] + 2, py + offset[1] + 1);
        var amount = item.Amount;
        if (item.ItemClass == 0) amount = global.Inventory_ItemData[1].Amount[0];
        if (item.ItemClass == 4) amount = global.Inventory_ItemData[5].Amount[0];
        if (amount > 1 || global.ItemData[item.ItemClass].Type == 4) {
            draw_set_font(global.Font_ItemValues);
            draw_set_halign(fa_right);
            draw_text(px + 18, py + 11, string(amount));
            draw_set_halign(fa_center);
        }
    }
    if (cell == NovaCell) draw_sprite_stretched(sInventory_Selection, 0, px, py, 20, 20);
    if (slot == global.Inventory_SlotIndex_Equiped) {
        draw_set_color(c_yellow);
        draw_rectangle(px - 1, py - 1, px + 20, py + 20, true);
        draw_set_color(c_white);
    }
}
draw_set_font(global.HUDFont2);
var item = global.Inventory[global.Inventory_SlotIndex_Selected];
var title = item.ItemClass < 0 ? "EMPTY" : string_upper(Item_Name(item.ItemClass, item.ItemIndex, item.Amount));
draw_text(X + W / 2, Y + 78, title);
if (MenuEnable) {
    var menu_x = X + floor((W - MenuStrW) / 2);
    draw_set_halign(fa_left);
    for (var action = 0; action < MenuItems; action++) {
        draw_set_color(ds_grid_get(MenuItemGrid, 1, action) ? c_white : c_dkgray);
        draw_text(menu_x + MenuItemPos[action], Y + 93, ds_grid_get(MenuItemGrid, 0, action));
    }
    draw_set_color(c_white);
    draw_sprite_stretched(sInventory_Selection, 0, menu_x + MenuItemPos[MenuSelectionIndex] - 2, Y + 90, MenuItemW[MenuSelectionIndex] + 3, 12);
    draw_set_halign(fa_center);
} else if (global.Inventory_SlotIndex_Selected == global.Inventory_SlotIndex_Equiped) draw_text(X + W / 2, Y + 93, "EQUIPPED");
else if (NovaPage >= 6) draw_text(X + W / 2, Y + 93, "USE OR DROP TO FREE SPACE");
if (global.Cursed && !DB_Started) {
    draw_text(X + W / 2, Y + H + 5, "CURSED: " + string_upper(string_replace(global.CurseEffectStr, "\\", " ")));
    draw_text(X + W / 2, Y + H + 15, string_upper(string_replace(global.CurseTaskStr, "\\", " ")) + " (" + string(global.CurseTaskCount) + ")");
}
draw_set_halign(fa_left);
draw_set_alpha(1);
