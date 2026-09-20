if (State == 0 || !surface_exists(global.ArcadeVP_Surface)) exit;
surface_set_target(global.ArcadeVP_Surface);
draw_clear(make_color_rgb(6,106,181));
draw_set_color(c_white);
draw_set_alpha(1);
draw_set_font(global.ArcadeFont);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var icons = [sArcade_Mothula_Icon_Cherry,sArcade_Mothula_Icon_Plum,sArcade_Mothula_Icon_Orange,sArcade_Mothula_Icon_Bell,sArcade_Mothula_Icon_7,sArcade_Mothula_Icon_Jackpot];
var positions = [[16,7],[16,20],[75,7],[74,20],[134,7],[131,19]];
var text_x = [50,50,107,107,170,170];
for (var i = 0; i < 6; i++) {
    var icon = icons[i];
    draw_sprite_stretched(icon, 0, positions[i][0], positions[i][1], sprite_get_width(icon)*3, sprite_get_height(icon));
    draw_text(text_x[i], i mod 2 == 0 ? 8 : 21, "x" + string(global.NovaSlotMultipliers[i+1]));
}
draw_set_halign(fa_center);
draw_text(100,40,StatusText);
for (var i = 0; i < 3; i++) {
    var px = 12 + i*60;
    draw_sprite_stretched(sArcade_Mothula_Reel,0,px,56,56,72);
    var index = floor(ReelPos[i] / 16);
    var offset = ReelPos[i] mod 16;
    for (var row = -2; row <= 4; row++) {
        var symbol = global.NovaSlotSymbols[(index + row + 52) mod 52];
        if (symbol == 0) continue;
        var yy = 76 + row*16 - offset;
        var top = max(60,yy);
        var bottom = min(124,yy+32);
        if (bottom > top) draw_sprite_part(sArcade_Mothula_Symbols,symbol-1,0,top-yy,48,bottom-top,px+4,top);
    }
    draw_sprite_stretched(sArcade_Mothula_ReelShading,0,px+4,60,48,12);
    draw_sprite_stretched(sArcade_Mothula_ReelShading_Flipped,0,px+4,112,48,12);
}
draw_sprite(sArcade_Mothula_ReelLine,0,8,89);
draw_sprite_ext(sArcade_Mothula_ReelLine,0,192,89,-1,1,0,c_white,1);
draw_set_halign(fa_left);
draw_text(5,137,"BALANCE:" + string(global.Inventory_ItemData[40].Amount));
draw_set_halign(fa_right);
draw_text(195,137,"BET:" + string(Bet+1));
draw_set_halign(fa_left);
surface_reset_target();
