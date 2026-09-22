// Menu Confirm and Back use fixed verbs, so remapping Interact or Sword cannot strand the player in a menu.
global.NovaConfirmVerb = function() { return "nova_confirm"; };
global.NovaCloseVerb = function() { return "nova_back"; };
global.NovaBinding = function(verb, profile = undefined) {
    var binding = input_binding_get(verb, 0, 0, profile);
    if (binding.__type == undefined) binding = input_binding_get(verb, 0, 1, profile);
    return binding;
};
global.NovaGlyph = function(binding) {
    if (binding.__type != "gamepad button" && binding.__type != "gamepad axis") return -1;
    var value = binding.__value;
    if (value == gp_face1) return 1;
    if (value == gp_face2) return 0;
    if (value >= gp_face3 && value <= gp_shoulderrb) return value - gp_face1;
    if (value == gp_select) return 8;
    if (value == gp_start) return 23;
    if (value == gp_stickl) return 9;
    if (value == gp_stickr) return 10;
    if (value >= gp_padu && value <= gp_padr) return 11 + value - gp_padu;
    if (value >= gp_axislh && value <= gp_axisrv) return 15 + (value - gp_axislh) * 2 + (binding.__axis_negative ? 0 : 1);
    return -1;
};
global.NovaKeyLabel = function(binding) {
    if (binding.__type == undefined) return "UNBOUND";
    if (binding.__type == "gamepad button" && binding.__value == gp_face1) return "B";
    if (binding.__type == "gamepad button" && binding.__value == gp_face2) return "A";
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
    // The compact HUD font has no Z glyph; keycaps need the complete font.
    draw_set_font(global.HUDFont);
    var width = ceil(string_width(global.NovaKeyLabel(binding)) / 2) + 6;
    draw_set_font(font);
    return width;
};
global.NovaPromptParts = function(binding, label, px, scale_x, size, gap = undefined) {
    var spacing = gap == undefined ? size / 4 : gap * scale_x;
    var text_width = string_width(label) * scale_x;
    var icon_width = global.NovaGlyph(binding) >= 0 ? size : global.NovaKeyWidth(binding) * scale_x;
    return {text_x: px, icon_x: px + (label == "" ? 0 : text_width + spacing), icon_width: icon_width,
        width: icon_width + (label == "" ? 0 : text_width + spacing)};
};
global.NovaPromptWidth = function(binding, label, scale_x, size, gap = undefined) {
    return global.NovaPromptParts(binding, label, 0, scale_x, size, gap).width;
};
global.NovaPromptLabelDraw = function(label, px, py, scale_x, scale_y) {
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    if (label != "") {
        draw_set_color(c_black);
        draw_text_transformed(px + scale_x, py + scale_y, label, scale_x, scale_y, 0);
        draw_set_color(c_white);
        draw_text_transformed(px, py, label, scale_x, scale_y, 0);
    }
};
global.NovaPromptDraw = function(binding, label, px, py, scale_x, scale_y, size, gap = undefined) {
    var parts = global.NovaPromptParts(binding, label, px, scale_x, size, gap);
    global.NovaPromptLabelDraw(label, parts.text_x, py, scale_x, scale_y);
    var frame = global.NovaGlyph(binding);
    var icon_x = parts.icon_x;
    draw_set_color(c_white);
    if (frame >= 0) draw_sprite_stretched(sNovaButtons, frame, icon_x, py - size / 2, size, size);
    else {
        var key_label = global.NovaKeyLabel(binding);
        draw_set_color(c_black);
        draw_rectangle(icon_x, py - 6 * scale_y, icon_x + parts.icon_width, py + 6 * scale_y, false);
        draw_set_color(c_white);
        draw_rectangle(icon_x, py - 6 * scale_y, icon_x + parts.icon_width, py + 6 * scale_y, true);
        var font = draw_get_font();
        draw_set_font(global.HUDFont);
        draw_text_transformed(icon_x + 3 * scale_x, py, key_label, scale_x / 2, scale_y / 2, 0);
        draw_set_font(font);
    }
    draw_set_valign(fa_top);
};
global.NovaHintWidth = function(prompt, label, sx, size) {
    var width = global.NovaPromptWidth(prompt.binding, label, sx, size);
    if (variable_struct_exists(prompt, "binding2")) width += size / 6 + global.NovaPromptWidth(prompt.binding2, "", sx, size);
    return width;
};
global.NovaHintRow = function(prompts, right, py, sx, sy, size, gap, available) {
    var total = max(0, array_length(prompts) - 1) * gap;
    for (var i = 0; i < array_length(prompts); i++) {
        var prompt = prompts[i];
        var reserve = variable_struct_exists(prompt, "reserve") ? prompt.reserve : prompt.label;
        total += global.NovaHintWidth(prompt, reserve, sx, size);
    }
    var fit = min(1, available / max(1, total));
    var cursor = right;
    for (var i = array_length(prompts) - 1; i >= 0; i--) {
        var prompt = prompts[i];
        var reserve = variable_struct_exists(prompt, "reserve") ? prompt.reserve : prompt.label;
        var width = global.NovaHintWidth(prompt, prompt.label, sx * fit, size * fit);
        var reserved_width = global.NovaHintWidth(prompt, reserve, sx * fit, size * fit);
        prompt.x = cursor - width;
        prompt.y = py;
        prompt.width = width;
        prompt.right = cursor;
        prompt.scale_x = sx * fit;
        prompt.scale_y = sy * fit;
        prompt.size = size * fit;
        prompt.icon_x = global.NovaPromptParts(prompt.binding, prompt.label, prompt.x, prompt.scale_x, prompt.size).icon_x;
        cursor -= reserved_width + gap * fit;
    }
    return prompts;
};
global.NovaHintDraw = function(prompt) {
    if (variable_struct_exists(prompt, "visible") && !prompt.visible) return;
    global.NovaPromptDraw(prompt.binding, prompt.label, prompt.x, prompt.y, prompt.scale_x, prompt.scale_y, prompt.size);
    if (variable_struct_exists(prompt, "binding2")) {
        var width = global.NovaPromptWidth(prompt.binding, prompt.label, prompt.scale_x, prompt.size);
        global.NovaPromptDraw(prompt.binding2, "", prompt.x + width + prompt.size / 6, prompt.y, prompt.scale_x, prompt.scale_y, prompt.size);
    }
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
global.NovaInventoryPager = function(inventory, layout) {
    var font = draw_get_font();
    draw_set_font(global.HUDFont2);
    // Reserve the full title set, including both possible legacy overflow pages.
    var heading_width = string_width(inventory.NovaTitles[6] + " 2");
    for (var i = 0; i < array_length(inventory.NovaTitles); i++) heading_width = max(heading_width, string_width(inventory.NovaTitles[i]));
    var bindings = [global.NovaBinding("nova_bag_previous"), global.NovaBinding("nova_bag_next")];
    // Page headings use world coordinates, but glyphs use square screen pixels.
    var scale = layout.scale;
    var size = 12 * scale;
    var widths = [global.NovaPromptWidth(bindings[0], "", scale, size), global.NovaPromptWidth(bindings[1], "", scale, size)];
    var center = round((inventory.X - oCamera.X + inventory.W / 2) * layout.world_x);
    var offset = ceil((heading_width / 2 + 8) * layout.world_x);
    var py = round((inventory.Y - oCamera.Y + 14) * layout.world_y);
    draw_set_font(font);
    return [
        {binding: bindings[0], x: center - offset - widths[0], y: py, width: widths[0], size: size, scale: scale},
        {binding: bindings[1], x: center + offset, y: py, width: widths[1], size: size, scale: scale}
    ];
};
global.NovaInventoryFooter = function(inventory, layout) {
    var info = global.NovaInventoryInfo();
    var selected = global.Inventory[global.Inventory_SlotIndex_Selected];
    var primary = info ? "MORE" : global.NovaInventoryAction(inventory);
    var prompts = [
        {binding: global.NovaBinding("item"), label: "EQUIP", visible: !info && !inventory.MenuEnable && selected.ItemClass >= 0 && global.ItemData[selected.ItemClass].CanEquip},
        {binding: global.NovaBinding(global.NovaConfirmVerb()), label: primary, reserve: "ACTIONS", visible: info ? global.DB_Inst.LinesLeft > 3 : primary != ""},
        {binding: global.NovaBinding(global.NovaCloseVerb()), label: "CLOSE", visible: true}
    ];
    var font = draw_get_font();
    draw_set_font(global.HUDFont2);
    var scale = layout.scale;
    prompts = global.NovaHintRow(prompts, layout.right, layout.footer_y, scale, scale, 12 * scale, 8 * scale, layout.footer_width);
    draw_set_font(font);
    return prompts;
};
global.NovaInventoryPrompts = function(inventory, layout) {
    with (inventory) {
    draw_set_font(global.HUDFont2);
    draw_set_alpha(Alpha);
    if (!global.NovaInventoryInfo()) {
        var pager = global.NovaInventoryPager(id, layout);
        for (var i = 0; i < array_length(pager); i++) {
            var prompt = pager[i];
            global.NovaPromptDraw(prompt.binding, "", prompt.x, prompt.y, prompt.scale, prompt.scale, prompt.size);
        }
    }
    var prompts = global.NovaInventoryFooter(id, layout);
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
    draw_set_alpha(1);
    }
};

global.NovaHUDLayout = function(width, height) {
    var fit = min(width / 256, height / 224);
    var scale = max(1, min(floor(fit), round(fit * 0.75)));
    var columns = floor(width / scale);
    var rows = floor(height / scale);
    var left = floor((width - columns * scale) / 2);
    var top = floor((height - rows * scale) / 2);
    return {scale: scale, width: columns, height: rows, x: left, y: top,
        world_x: width / 256, world_y: height / 224,
        right: left + (columns - 16) * scale, footer_y: top + (rows - 15) * scale,
        footer_left: left + 16 * scale, footer_width: (columns - 32) * scale};
};
global.NovaContextBlocked = function() {
    return !instance_exists(oLink) || !instance_exists(oCamera) || global.Paused || global.AltTab || global.ArcadeVP_Show
        || instance_exists(oInventory) || instance_exists(oMap) || instance_exists(oMenu_Game) || instance_exists(oDialogueBox)
        || oCamera.RoomTransition != 0 || oLink.StairsAutoMove || oLink.BounceBack;
};
global.NovaContextAction = function() {
    if (global.NovaContextBlocked() || (oLink.State != 1 && oLink.State != 2 && oLink.State != 11)) return "";
    return oLink.NovaInteractionProbe();
};
global.NovaContextHint = function(layout, status_left, label = undefined) {
    if (label == undefined) label = global.NovaContextAction();
    var scale = layout.scale;
    var prompt = {binding: global.NovaBinding("action"), label: label, visible: label != ""};
    var hints = global.NovaHintRow([prompt], status_left - 8 * scale, layout.footer_y, scale, scale, 12 * scale, 0, layout.footer_width);
    return hints[0];
};

global.NovaContextMotion = function() {
    return {visibility: 0, alpha: 0, label: "", shown_label: "", text_visibility: 1, text_alpha: 1};
};
global.NovaContextAdvance = function(motion, label, seconds) {
    seconds = max(0, seconds);
    if (label != "") {
        if (motion.visibility == 0) {
            motion.shown_label = label;
            motion.text_visibility = 1;
        }
        motion.label = label;
    }
    // Fade through keeps pixel lettering legible without overlapping two words.
    var remaining = seconds;
    if (motion.shown_label != motion.label) {
        var fade_out = min(remaining, motion.text_visibility * 0.04);
        motion.text_visibility = max(0, motion.text_visibility - fade_out / 0.04);
        remaining -= fade_out;
        if (motion.text_visibility <= 0) {
            motion.text_visibility = 0;
            motion.shown_label = motion.label;
        }
    }
    if (motion.shown_label == motion.label) motion.text_visibility = min(1, motion.text_visibility + remaining / 0.08);
    motion.text_alpha = motion.text_visibility * motion.text_visibility * (3 - 2 * motion.text_visibility);
    motion.visibility = clamp(motion.visibility + seconds * (label == "" ? -1 / 0.10 : 1 / 0.12), 0, 1);
    motion.alpha = motion.visibility * motion.visibility * (3 - 2 * motion.visibility);
    if (motion.visibility == 0) {
        motion.label = "";
        motion.shown_label = "";
        motion.text_visibility = 1;
        motion.text_alpha = 1;
    }
};
global.NovaContextUpdate = function(seconds) {
    if (global.NovaContextBlocked() || !instance_exists(oHUD) || global.Users[global.UserIndex].Prefs[2]) {
        oRender.NovaContext = global.NovaContextMotion();
        return;
    }
    var motion = oRender.NovaContext;
    var label = global.NovaContextAction();
    // State 6 finishes the accepted lift before Interact can become Throw.
    if (label == "" && oLink.State == 6 && instance_exists(oLink.ItemHolding) && motion.label == "LIFT") label = "LIFT";
    global.NovaContextAdvance(motion, label, seconds);
};
global.NovaContextDraw = function(layout, status_left) {
    var motion = oRender.NovaContext;
    if (motion.alpha <= 0 || global.NovaContextBlocked()) return;
    var prompt = global.NovaContextHint(layout, status_left, motion.label);
    var alpha = draw_get_alpha();
    draw_set_alpha(alpha * motion.alpha * motion.text_alpha);
    var text_x = prompt.icon_x - prompt.size / 4 - string_width(motion.shown_label) * prompt.scale_x;
    global.NovaPromptLabelDraw(motion.shown_label, text_x, prompt.y, prompt.scale_x, prompt.scale_y);
    draw_set_alpha(alpha * motion.alpha);
    global.NovaPromptDraw(prompt.binding, "", prompt.icon_x, prompt.y, prompt.scale_x, prompt.scale_y, prompt.size);
    draw_set_alpha(alpha);
};
