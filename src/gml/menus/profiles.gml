function NovaMenuLayout() {
    return global.NovaMenuLayout();
}
function NovaMenuFrame(title) {
    var layout = NovaMenuLayout();
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_sprite_stretched(sMenuWin, 0, layout.x, layout.y, layout.width, layout.height);
    global.NovaMenuTitle(title);
    draw_set_font(global.MenuFont_Innactive);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

function NovaProfileSummary(index) {
    var user = global.Users[index];
    var summary = {name: user.Name, saved: false, character: 0, hearts: 0, health: 0, floor: 0, level: 0};
    if (user.Name == "" || !is_struct(user.SaveData)) return summary;
    var save = user.SaveData;
    summary.saved = true;
    if (variable_struct_exists(save, "LinkCharacterIndex")) summary.character = clamp(floor(save.LinkCharacterIndex), 0, 8);
    if (variable_struct_exists(save, "Level")) summary.floor = max(0, floor(save.Level));
    if (variable_struct_exists(save, "NovaChallengeOptions") && is_array(save.NovaChallengeOptions))
        for (var i = 0; i < min(12, array_length(save.NovaChallengeOptions)); i++) summary.level += clamp(floor(save.NovaChallengeOptions[i]), 0, i < 9 ? 3 : 1);
    if (variable_struct_exists(save, "Inventory_ItemData") && is_array(save.Inventory_ItemData)) {
        var items = save.Inventory_ItemData;
        if (array_length(items) > 18 && is_struct(items[17]) && is_struct(items[18])) {
            if (variable_struct_exists(items[18], "Amount")) summary.hearts = clamp(floor(items[18].Amount), 0, 20);
            if (variable_struct_exists(items[17], "Amount")) summary.health = clamp(items[17].Amount, 0, summary.hearts);
        }
    }
    return summary;
}
