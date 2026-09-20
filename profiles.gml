function NovaProfileVisible() {
    return !NovaUpdateOpen && MenuWin_Main_MenuIndex == 0 && Menu_ActiveIndex == 0 && !instance_exists(ErrorMsgInst);
}

function NovaMenuLayout() {
    return {
        x: 24, y: 12, width: 352, height: 222,
        header_y: -28, header_width: 232, header_height: 32,
        left: 42, right: 358, footer_y: 250
    };
}

function NovaMenuFrame(title) {
    var layout = NovaMenuLayout();
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_sprite_stretched(sMenuWin, 0, layout.x, layout.header_y, layout.header_width, layout.header_height);
    draw_sprite_stretched(sMenuWin, 0, layout.x, layout.y, layout.width, layout.height);
    draw_set_font(global.MenuFont);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(layout.x + layout.header_width / 2, layout.header_y + 8, title);
    draw_set_halign(fa_left);
}

function NovaProfileLayout() {
    var font = draw_get_font();
    draw_set_font(global.MenuFont);
    var layout = NovaMenuLayout();
    layout.row_y = 24;
    layout.row_height = 32;
    layout.cursor_x = 44;
    layout.portrait_x = 76;
    layout.number_x = 104;
    var number_width = 0;
    for (var index = 1; index <= global.MaxUsers; index++) number_width = max(number_width, string_width(string(index) + "."));
    layout.name_x = layout.number_x + number_width + 6;
    layout.hearts_x = 256;
    layout.utility_y = 190;
    layout.utility_height = 18;
    layout.confirm_width = global.NovaPromptWidth(NovaMenuConfirmBinding(), "Select", 0.75, 12);
    layout.close_width = global.NovaPromptWidth(global.NovaBinding(global.NovaCloseVerb()), "Close", 0.75, 12);
    draw_set_font(font);
    return layout;
}

function NovaProfileSummary(index) {
    var user = global.Users[index];
    var summary = {name: user.Name, saved: false, character: 0, hearts: 0, health: 0, floor: 0};
    if (user.Name == "" || !is_struct(user.SaveData)) return summary;
    var save = user.SaveData;
    summary.saved = true;
    if (variable_struct_exists(save, "LinkCharacterIndex")) summary.character = clamp(floor(save.LinkCharacterIndex), 0, 8);
    if (variable_struct_exists(save, "Level")) summary.floor = max(0, floor(save.Level));
    if (variable_struct_exists(save, "Inventory_ItemData") && is_array(save.Inventory_ItemData)) {
        var items = save.Inventory_ItemData;
        if (array_length(items) > 18 && is_struct(items[17]) && is_struct(items[18])) {
            if (variable_struct_exists(items[18], "Amount")) summary.hearts = clamp(floor(items[18].Amount), 0, 20);
            if (variable_struct_exists(items[17], "Amount")) summary.health = clamp(items[17].Amount, 0, summary.hearts);
        }
    }
    return summary;
}

function NovaProfileDraw() {
    var layout = NovaProfileLayout();
    NovaMenuFrame("Player Select");
    for (var index = 0; index < global.MaxUsers; index++) {
        var row = layout.row_y + index * layout.row_height;
        var summary = NovaProfileSummary(index);
        var name = summary.name == "" ? "New player" : summary.name;
        draw_set_font(global.MenuFont);
        draw_text(layout.number_x, row + 2, string(index + 1) + ".");
        draw_text(layout.name_x, row + 2, name);
        if (summary.name != "") {
            draw_sprite(global.CharacterSprites, summary.character, layout.portrait_x, row + 2);
            draw_set_font(global.HUDFont);
            draw_text_transformed(layout.name_x, row + 19, summary.saved ? ("Floor " + string(summary.floor)) : "No saved run", 0.625, 0.625, 0);
        }
        for (var heart = 0; heart < summary.hearts; heart++) {
            var value = clamp(summary.health - heart, 0, 1);
            var frame = value >= 1 ? 4 : (value > 0 ? max(1, floor(value * 4)) : 0);
            draw_sprite(sHUD_Heart, frame, layout.hearts_x + (heart mod 10) * 8, row + 5 + (heart div 10) * 8);
        }
        if (Selector_Index_Main == index) draw_sprite(sMenu_Selector_Active, Selector_Frame, layout.cursor_x, row + 4);
    }
    draw_set_font(global.MenuFont);
    for (var index = 0; index < 2; index++) {
        var row = layout.utility_y + index * layout.utility_height;
        draw_text(layout.number_x, row, Menu[0][global.MaxUsers + index]);
        if (Selector_Index_Main == global.MaxUsers + index) draw_sprite(sMenu_Selector_Active, Selector_Frame, layout.cursor_x, row);
    }
    global.NovaPromptDraw(global.NovaBinding(global.NovaCloseVerb()), "Close", layout.left, layout.footer_y, 0.75, 0.75, 12);
    global.NovaPromptDraw(NovaMenuConfirmBinding(), "Select", layout.right - layout.confirm_width, layout.footer_y, 0.75, 0.75, 12);
}
