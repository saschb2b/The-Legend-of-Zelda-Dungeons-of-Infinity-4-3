draw_set_color(c_white);
draw_set_alpha(MainAlpha);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var _nova_meter_x = 16;
var _nova_item_x = _nova_meter_x + 17;
var _nova_item_y = 20;
var _nova_heart_x = layout.width - 95;
draw_set_color(c_black);
draw_rectangle(_nova_item_x + 1, _nova_item_y + 1, _nova_item_x + 20, _nova_item_y + 20, false);
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
draw_sprite(sHUD_Icon_Rupees, 0, 72, 14);
draw_sprite(sHUD_Icon_Bombs, 0, 100, 14);
draw_sprite(sHUD_Icon_Arrows, 0, 121, 14);
draw_sprite(sHUD_Icon_Keys, 0, 144, 14);
var _nova_values = [RupeesStr, ScoreText(global.Inventory_ItemData[5].Amount[0], 2), ScoreText(global.Inventory_ItemData[1].Amount[0], 2), ScoreText(global.Inventory_ItemData[20].Amount, 2)];
var _nova_centers = [76, 104, 128, 148];
var _nova_colors = [c_white, BombsColor, ArrowsColor, c_white];
for (var _nova_counter = 0; _nova_counter < 4; _nova_counter++)
{
    draw_set_color(_nova_colors[_nova_counter]);
    if (_nova_counter == 3 && global.Inventory_ItemData[21].Owns[0])
    {
        draw_sprite(sHUD_Infinite, 0, 148 - sprite_get_width(sHUD_Infinite) / 2, 25);
    }
    else
    {
        var _nova_digits = string_length(_nova_values[_nova_counter]);
        var _nova_number_x = _nova_centers[_nova_counter] - _nova_digits * 4 + 1;
        for (var _nova_digit = 0; _nova_digit < _nova_digits; _nova_digit++)
        {
            draw_text(_nova_number_x + _nova_digit * 8, 24, string_char_at(_nova_values[_nova_counter], _nova_digit + 1));
        }
    }
}
// The original vertical meter has stepped caps and an inset 8x32 fill.
draw_set_color(c_black);
draw_rectangle(_nova_meter_x + 4, 17, _nova_meter_x + 11, 59, false);
draw_rectangle(_nova_meter_x + 2, 18, _nova_meter_x + 13, 58, false);
draw_rectangle(_nova_meter_x + 1, 20, _nova_meter_x + 14, 57, false);
draw_rectangle(_nova_meter_x, 21, _nova_meter_x + 15, 54, false);
draw_set_color(make_color_rgb(248, 248, 248));
draw_rectangle(_nova_meter_x + 4, 18, _nova_meter_x + 11, 58, false);
draw_rectangle(_nova_meter_x + 2, 19, _nova_meter_x + 13, 57, false);
draw_rectangle(_nova_meter_x + 1, 21, _nova_meter_x + 14, 54, false);
draw_set_color(c_black);
draw_rectangle(_nova_meter_x + 4, 21, _nova_meter_x + 11, 54, false);
draw_rectangle(_nova_meter_x + 3, 22, _nova_meter_x + 12, 53, false);
draw_set_color(c_white);
var _nova_magic = ceil(clamp(MagicW, 0, 64) / 2);
if (_nova_magic > 0)
{
    draw_set_color(make_color_rgb(32, 192, 40));
    draw_rectangle(_nova_meter_x + 4, 55 - _nova_magic, _nova_meter_x + 11, 54, false);
    draw_set_color(make_color_rgb(248, 248, 248));
    draw_line(_nova_meter_x + 5, 55 - _nova_magic, _nova_meter_x + 10, 55 - _nova_magic);
}
draw_sprite_ext(sHUD_Life, 0, _nova_heart_x + 18, 14, 1, 1, 0, HealthLowPulseColor, MainAlpha);
var _nova_capacity = global.Inventory_ItemData[18].Amount;
var _nova_health = clamp(global.Inventory_ItemData[17].Amount - AddHealth, 0, _nova_capacity);
for (var _nova_heart = 0; _nova_heart < _nova_capacity; _nova_heart++)
{
    var _nova_value = clamp(_nova_health - _nova_heart, 0, 1);
    var _nova_frame = _nova_value >= 1 ? 4 : (_nova_value > 0 ? max(1, floor(_nova_value * 4)) : 0);
    draw_sprite_ext(sHUD_Heart, _nova_frame, _nova_heart_x + (_nova_heart mod 10) * 8, 24 + (_nova_heart div 10) * 8, 1, 1, 0, HealthLowPulseColor, MainAlpha);
}
draw_set_color(c_white);
draw_set_alpha(1);
