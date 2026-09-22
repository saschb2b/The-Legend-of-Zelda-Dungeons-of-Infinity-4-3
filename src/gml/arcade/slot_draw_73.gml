if (State == 0 || !surface_exists(global.ArcadeVP_Surface)) exit;
if (!surface_exists(ReelSurface)) {
    ReelSurface = surface_create(48,832);
    surface_set_target(ReelSurface);
    draw_clear_alpha(c_black,0);
    draw_set_alpha(1);
    draw_set_color(c_white);
    // Native CreateReel places symbol i at ((i + 1) mod 26) * 32.
    for (var i = 0; i < 26; i++) {
        draw_sprite(sArcade_Mothula_Symbols,global.NovaSlotSymbols[i*2+1]-1,0,((i+1) mod 26)*32);
    }
    surface_reset_target();
}
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
    draw_text(text_x[i], i mod 2 == 0 ? 8 : 21, string(global.NovaSlotMultipliers[i+1]) + "x");
}
draw_sprite(sArcade_Mothula_ReelLine,0,68,88);
draw_sprite(sArcade_Mothula_ReelLine,0,128,88);
draw_text(5,137,"BALANCE:" + string(global.Inventory_ItemData[40].Amount));
draw_sprite(sPoker_Button_Bet,0,132,135);
draw_set_font(global.HUDFont2);
draw_set_color(c_black);
draw_text(151,138,string(Bet+1));
draw_set_color(c_white);
draw_sprite(sPoker_Button_Spin,0,162,135);
draw_set_halign(fa_center);
if (StatusText == "MOTHULA'S MONEY") {
    draw_set_font(global.ArcadeFont2);
    draw_text(100,36,StatusText);
} else {
    draw_set_font(global.ArcadeFont);
    draw_text(100,40,StatusText);
}
for (var i = 0; i < 3; i++) {
    var px = 12 + i*60;
    draw_sprite_stretched(sArcade_Mothula_Reel,0,px,56,56,72);
    var height = min(64,832-ReelPos[i]);
    draw_surface_part(ReelSurface,0,ReelPos[i],48,height,px+4,60);
    if (height < 64) draw_surface_part(ReelSurface,0,0,48,64-height,px+4,60+height);
    draw_sprite_stretched(sArcade_Mothula_ReelShading,0,px+4,60,48,12);
    draw_sprite_stretched(sArcade_Mothula_ReelShading_Flipped,0,px+4,112,48,12);
}
draw_set_halign(fa_left);
surface_reset_target();
