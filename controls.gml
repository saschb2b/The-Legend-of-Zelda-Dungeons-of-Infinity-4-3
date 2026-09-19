global.NovaBinding = function(verb, profile = undefined) {
    var binding = input_binding_get(verb, 0, 0, profile);
    if (binding.__type == undefined) binding = input_binding_get(verb, 0, 1, profile);
    return binding;
};
global.NovaGlyph = function(binding) {
    if (binding.__type != "gamepad button" && binding.__type != "gamepad axis") return -1;
    var value = binding.__value;
    if (value >= gp_face1 && value <= gp_shoulderrb) return value - gp_face1;
    if (value == gp_select) return 8;
    if (value == gp_stickl) return 9;
    if (value == gp_stickr) return 10;
    if (value >= gp_padu && value <= gp_padr) return 11 + value - gp_padu;
    if (value >= gp_axislh && value <= gp_axisrv) return 15 + (value - gp_axislh) * 2 + (binding.__axis_negative ? 0 : 1);
    return -1;
};
global.NovaKeyLabel = function(binding) {
    if (binding.__type == undefined) return "UNBOUND";
    if (binding.__type == "gamepad button" && binding.__value == gp_start) return "START";
    if (binding.__type == "key") {
        switch (binding.__value) {
            case vk_control: case 162: case 163: return "CTRL";
            case vk_alt: case 164: case 165: return "ALT";
            case vk_shift: case 160: case 161: return "SHIFT";
            case vk_enter: return "ENTER";
            case vk_escape: return "ESC";
            case vk_pageup: return "PGUP";
            case vk_pagedown: return "PGDN";
            case vk_space: return "SPACE";
            case vk_tab: return "TAB";
            case vk_backspace: return "BSPC";
            case vk_delete: return "DEL";
            case vk_insert: return "INS";
            case vk_up: return "UP";
            case vk_down: return "DOWN";
            case vk_left: return "LEFT";
            case vk_right: return "RIGHT";
        }
    }
    return string_upper(input_binding_get_name(binding));
};
global.NovaKeyWidth = function(binding) {
    var font = draw_get_font();
    draw_set_font(global.HUDFont);
    var width = ceil(string_width(global.NovaKeyLabel(binding)) / 2) + 6;
    draw_set_font(font);
    return width;
};
global.NovaPromptWidth = function(binding, label, scale_x, size) {
    var icon_width = global.NovaGlyph(binding) >= 0 ? size : global.NovaKeyWidth(binding) * scale_x;
    return icon_width + (label == "" ? 0 : (4 + string_width(label)) * scale_x);
};
global.NovaPromptDraw = function(binding, label, px, py, scale_x, scale_y, size) {
    var frame = global.NovaGlyph(binding);
    var icon_width = size;
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    if (frame >= 0) draw_sprite_stretched(sNovaButtons, frame, px, py - size / 2, size, size);
    else {
        var key_label = global.NovaKeyLabel(binding);
        icon_width = global.NovaKeyWidth(binding) * scale_x;
        draw_set_color(c_black);
        draw_rectangle(px, py - 6 * scale_y, px + icon_width, py + 6 * scale_y, false);
        draw_set_color(c_white);
        draw_rectangle(px, py - 6 * scale_y, px + icon_width, py + 6 * scale_y, true);
        // The small HUD font has no Z glyph; the dialogue font covers keyboard letters.
        var font = draw_get_font();
        draw_set_font(global.HUDFont);
        draw_text_transformed(px + 3 * scale_x, py, key_label, scale_x / 2, scale_y / 2, 0);
        draw_set_font(font);
    }
    if (label != "") {
        var text_x = px + icon_width + 4 * scale_x;
        draw_set_color(c_black);
        draw_text_transformed(text_x + scale_x, py + scale_y, label, scale_x, scale_y, 0);
        draw_set_color(c_white);
        draw_text_transformed(text_x, py, label, scale_x, scale_y, 0);
    }
    draw_set_valign(fa_top);
};
global.NovaInventoryInfo = function() {
    return instance_exists(oInventory) && oInventory.DB_Started && instance_exists(global.DB_Inst) && global.DB_Inst.Script == oInventory.DBScript_Info;
};
global.NovaInventoryHUD = function() {
    return instance_exists(oInventory) && !instance_exists(oMenu_Game) && (!instance_exists(oDialogueBox) || global.NovaInventoryInfo()) && !global.ArcadeVP_Show;
};
global.NovaInventoryAction = function(inventory) {
    if (inventory.MenuEnable) return ds_grid_get(inventory.MenuItemGrid, 0, inventory.MenuSelectionIndex);
    var item = global.Inventory[global.Inventory_SlotIndex_Selected];
    if (item.ItemClass < 0) return "";
    if (item.ItemClass == 15 || item.ItemClass == 49 || item.ItemClass == 50) return "OPEN";
    return "ACTIONS";
};
global.NovaInventoryPrompts = function(inventory) {
    with (inventory) {
    var sx = display_get_gui_width() / 256;
    var sy = display_get_gui_height() / 224;
    var size = 18 * min(sx, sy);
    var left = X - oCamera.X;
    var top = Y - oCamera.Y;
    draw_set_font(global.HUDFont2);
    draw_set_alpha(Alpha);
    var previous = global.NovaBinding("nova_bag_previous");
    var next = global.NovaBinding("nova_bag_next");
    var previous_width = global.NovaPromptWidth(previous, "", sx, size);
    var next_width = global.NovaPromptWidth(next, "", sx, size);
    global.NovaPromptDraw(previous, "", (left + 8) * sx, (top + 14) * sy, sx, sy, size);
    global.NovaPromptDraw(next, "", (left + W - 8) * sx - next_width, (top + 14) * sy, sx, sy, size);
    var verbs = [];
    var labels = [];
    var selected = global.Inventory[global.Inventory_SlotIndex_Selected];
    if (MenuEnable || selected.ItemClass >= 0) {
        array_push(verbs, "sword");
        array_push(labels, global.NovaInventoryAction(id));
    }
    if (!MenuEnable && selected.ItemClass >= 0 && global.ItemData[selected.ItemClass].CanEquip) {
        array_push(verbs, "item");
        array_push(labels, "EQUIP");
    }
    array_push(verbs, "action");
    array_push(labels, "CLOSE");
    var widths = [];
    var total = 0;
    for (var i = 0; i < array_length(verbs); i++) {
        widths[i] = global.NovaPromptWidth(global.NovaBinding(verbs[i]), labels[i], sx, size);
        total += widths[i];
    }
    var gap = 8 * sx;
    total += gap * (array_length(verbs) - 1);
    var px = (left + W / 2) * sx - total / 2;
    for (var i = 0; i < array_length(verbs); i++) {
        global.NovaPromptDraw(global.NovaBinding(verbs[i]), labels[i], px, (top + 116) * sy, sx, sy, size);
        px += widths[i] + gap;
    }
    draw_set_alpha(1);
    }
};
