draw_set_color(c_white);
draw_set_alpha(MainAlpha);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var _nova_item_x = 28;
var _nova_item_y = 22;
draw_set_color(c_black);
draw_rectangle(_nova_item_x + 1, _nova_item_y + 1, _nova_item_x + 20, _nova_item_y + 20, false);
draw_rectangle(13, 27, 18, 59, false);
draw_set_color(c_white);
draw_sprite_part(sHUD_Items, 0, 0, 0, 22, 24, _nova_item_x, _nova_item_y);
if (global.Inventory_SlotIndex_Equiped != -1)
{
    var _ItemEquiped = global.Inventory[global.Inventory_SlotIndex_Equiped];
    if (_ItemEquiped != -1)
    {
        var _ItemClass = _ItemEquiped.ItemClass;
        switch (_ItemClass)
        {
            case 4:
                _ItemClass = 5;
                break;
        }
        var _ObjIndex = ObjIndexFromItemClass(_ItemClass);
        if (_ObjIndex != -1)
        {
            var SprInd = object_get_sprite(_ObjIndex);
            var ItemInd = _ItemEquiped.ItemIndex;
            var _nova_offset = Inventory_GetPosOffset(SprInd, ItemInd);
            var _x = _nova_item_x + _nova_offset[0] + 3;
            var _y = _nova_item_y + _nova_offset[1] + 2;
            draw_sprite(SprInd, ItemInd, _x, _y);
            var _DrawAmount, _ItemAmount;
            if (_ItemClass == 5 && global.Inventory_ItemData[4].Owns[0])
            {
                _ItemAmount = global.Inventory_ItemData[5].Amount[0];
                _DrawAmount = true;
            }
            else
            {
                _ItemAmount = _ItemEquiped.Amount;
                _DrawAmount = global.ItemData[_ItemClass].Type == 4 || global.Inventory[global.Inventory_SlotIndex_Equiped].Amount > 1;
            }
            if (_DrawAmount)
            {
                draw_set_font(global.Font_ItemValues);
                draw_set_halign(fa_right);
                draw_text(_nova_item_x + 19, _nova_item_y + 12, string(_ItemAmount));
                draw_set_halign(fa_left);
            }
        }
    }
}

draw_set_font(global.FontNumbers);
draw_sprite(sHUD_Icon_Rupees, 0, 68, 14);
draw_sprite(sHUD_Icon_Bombs, 0, 94, 14);
draw_sprite(sHUD_Icon_Arrows, 0, 115, 14);
draw_sprite(sHUD_Icon_Keys, 0, 142, 14);
draw_text(57, 26, RupeesStr);
draw_set_color(BombsColor);
draw_text(91, 26, ScoreText(global.Inventory_ItemData[5].Amount[0], 2));
draw_set_color(ArrowsColor);
draw_text(115, 26, ScoreText(global.Inventory_ItemData[1].Amount[0], 2));
draw_set_color(c_white);
if (global.Inventory_ItemData[21].Owns[0])
{
    draw_sprite(sHUD_Infinite, 0, 142, 27);
}
else
{
    draw_text(139, 26, ScoreText(global.Inventory_ItemData[20].Amount, 2));
}
// Rotating the native frame keeps its border consistent with the other HUD sprites.
draw_sprite_general(sHUD_Magic, 0, 0, 8, 68, 8, 12, 60, 0.5, 1, 90, c_white, c_white, c_white, c_white, MainAlpha);
var _nova_magic = clamp(MagicW, 0, 64) / 2;
if (_nova_magic > 0)
{
    draw_sprite_stretched(sHUD_MagicMeterLiquid, 0, 13, 59 - _nova_magic, 6, _nova_magic);
}
draw_sprite_ext(sHUD_Life, 0, 184, 14, 1, 1, 0, HealthLowPulseColor, MainAlpha);
var _nova_capacity = global.Inventory_ItemData[18].Amount;
var _nova_health = clamp(global.Inventory_ItemData[17].Amount - AddHealth, 0, _nova_capacity);
for (var _nova_heart = 0; _nova_heart < _nova_capacity; _nova_heart++)
{
    var _nova_value = clamp(_nova_health - _nova_heart, 0, 1);
    var _nova_frame = _nova_value >= 1 ? 4 : (_nova_value > 0 ? max(1, floor(_nova_value * 4)) : 0);
    draw_sprite_ext(sHUD_Heart, _nova_frame, 166 + (_nova_heart mod 10) * 8, 26 + (_nova_heart div 10) * 8, 1, 1, 0, HealthLowPulseColor, MainAlpha);
}
if (!global.Users[global.UserIndex].Prefs[2])
{
    draw_set_font(global.HUDFont2);
    draw_set_halign(fa_right);
    draw_set_alpha(MainAlpha * 0.8);
    draw_set_color(c_black);
    draw_text(249, 205, "PANELS");
    draw_set_color(c_white);
    draw_text(248, 204, "PANELS");
    draw_sprite_stretched(sNovaPanelHint, 0, 228 - string_width("PANELS"), 198, 16, 16);
    draw_set_halign(fa_left);
}
draw_set_color(c_white);
draw_set_alpha(1);
