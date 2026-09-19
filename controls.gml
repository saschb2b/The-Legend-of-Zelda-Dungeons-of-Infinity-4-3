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
global.NovaPromptWidth = function(binding, label, scale_x, size, gap = 4) {
    var icon_width = global.NovaGlyph(binding) >= 0 ? size : global.NovaKeyWidth(binding) * scale_x;
    return icon_width + (label == "" ? 0 : (gap + string_width(label)) * scale_x);
};
global.NovaPromptDraw = function(binding, label, px, py, scale_x, scale_y, size, gap = 4) {
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
        var text_x = px + icon_width + gap * scale_x;
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
global.NovaInventoryHeading = function(inventory) {
    var heading = inventory.NovaTitles[min(inventory.NovaPage, 6)];
    if (inventory.NovaPage >= 6 && inventory.NovaOverflowPages > 1) heading += " " + string(inventory.NovaPage - 5);
    return heading;
};
global.NovaInventoryPager = function(inventory, sx, sy) {
    var font = draw_get_font();
    draw_set_font(global.HUDFont2);
    // Reserve the full title set, including both possible legacy overflow pages.
    var heading_width = string_width(inventory.NovaTitles[6] + " 2");
    for (var i = 0; i < array_length(inventory.NovaTitles); i++) heading_width = max(heading_width, string_width(inventory.NovaTitles[i]));
    var bindings = [global.NovaBinding("nova_bag_previous"), global.NovaBinding("nova_bag_next")];
    var size = 18 * min(sx, sy);
    var widths = [global.NovaPromptWidth(bindings[0], "", sx, size), global.NovaPromptWidth(bindings[1], "", sx, size)];
    var center = (inventory.X - oCamera.X + inventory.W / 2) * sx;
    var offset = (heading_width / 2 + 8) * sx;
    var py = (inventory.Y - oCamera.Y + 14) * sy;
    draw_set_font(font);
    return [
        {binding: bindings[0], x: center - offset - widths[0], y: py, width: widths[0], size: size},
        {binding: bindings[1], x: center + offset, y: py, width: widths[1], size: size}
    ];
};
global.NovaInventoryFooter = function(inventory, sx, sy) {
    var info = global.NovaInventoryInfo();
    var selected = global.Inventory[global.Inventory_SlotIndex_Selected];
    var primary = info ? "MORE" : global.NovaInventoryAction(inventory);
    var prompts = [
        {binding: global.NovaBinding("item"), label: "EQUIP", visible: !info && !inventory.MenuEnable && selected.ItemClass >= 0 && global.ItemData[selected.ItemClass].CanEquip},
        {binding: global.NovaBinding("action"), label: "CLOSE", visible: true},
        {binding: global.NovaBinding("sword"), label: primary, visible: info ? global.DB_Inst.LinesLeft > 3 : primary != ""}
    ];
    var font = draw_get_font();
    draw_set_font(global.HUDFont2);
    var reserves = ["EQUIP", "CLOSE", "ACTIONS"];
    var size = 18 * min(sx, sy);
    var available = (inventory.W - 16) * sx;
    var total = 16 * sx;
    for (var i = 0; i < 3; i++) total += global.NovaPromptWidth(prompts[i].binding, reserves[i], sx, size);
    var fit = min(1, available / total);
    var widths = [];
    total = 0;
    for (var i = 0; i < 3; i++) {
        widths[i] = global.NovaPromptWidth(prompts[i].binding, reserves[i], sx * fit, size * fit);
        total += widths[i];
    }
    // Hidden actions retain their space so changing selection cannot move Close.
    var gap = (available - total) / 2;
    var px = (inventory.X - oCamera.X + 8) * sx;
    for (var i = 0; i < 3; i++) {
        prompts[i].x = px;
        prompts[i].y = (inventory.Y - oCamera.Y + 116) * sy;
        prompts[i].width = widths[i];
        prompts[i].scale_x = sx * fit;
        prompts[i].scale_y = sy * fit;
        prompts[i].size = size * fit;
        px += widths[i] + gap;
    }
    draw_set_font(font);
    return prompts;
};
global.NovaInventoryPrompts = function(inventory) {
    with (inventory) {
    var sx = display_get_gui_width() / 256;
    var sy = display_get_gui_height() / 224;
    draw_set_font(global.HUDFont2);
    draw_set_alpha(Alpha);
    if (!global.NovaInventoryInfo()) {
        var pager = global.NovaInventoryPager(id, sx, sy);
        for (var i = 0; i < array_length(pager); i++) {
            var prompt = pager[i];
            global.NovaPromptDraw(prompt.binding, "", prompt.x, prompt.y, sx, sy, prompt.size);
        }
    }
    var prompts = global.NovaInventoryFooter(id, sx, sy);
    for (var i = 0; i < array_length(prompts); i++) {
        var prompt = prompts[i];
        if (prompt.visible) global.NovaPromptDraw(prompt.binding, prompt.label, prompt.x, prompt.y, prompt.scale_x, prompt.scale_y, prompt.size);
    }
    draw_set_alpha(1);
    }
};
