if (!surface_exists(NovaFrame))
{
    NovaFrame = surface_create(1024, 896);
}
surface_set_target(NovaFrame);
draw_clear_alpha(c_black, 1);
draw_set_alpha(1);
draw_set_color(c_white);
// Effects and cameras use the 1600x900 canvas, with the playfield at (288, 0).
draw_surface_part(application_surface, 288, 0, 1024, 896, 0, 0);
// Modal screens need the full playfield width for their text and controls.
if (global.Users[global.UserIndex].Prefs[2] && !global.Paused)
{
    draw_surface_part_ext(application_surface, 0, 304, 288, 592, 16, 436, 0.75, 0.75, c_white, 0.9);
    draw_surface_part_ext(application_surface, 1312, 0, 288, 896, 792, 208, 0.75, 0.75, c_white, 0.9);
}
if (instance_exists(oHUD) && !global.Paused && !global.ArcadeVP_Show)
{
    if (!surface_exists(NovaHUD)) NovaHUD = surface_create(256, 224);
    surface_set_target(NovaHUD);
    draw_clear_alpha(c_black, 0);
    NovaHUD_Draw();
    surface_reset_target();
    draw_surface_ext(NovaHUD, 0, 0, 4, 4, 0, c_white, 1);
}
if (global.ArcadeVP_Show)
{
    draw_set_color(c_black);
    draw_set_alpha(0.5);
    draw_rectangle(0, 0, 1023, 895, false);
    draw_set_color(c_white);
    draw_set_alpha(1);
    CRT_Do_Stretch(global.ArcadeVP_Surface, global.ArcadeVP_RenderX - 288, global.ArcadeVP_RenderY, global.ArcadeVP_RenderW, global.ArcadeVP_RenderH, global.ArcadeVP_Sizes, true, 0.2, true, 0.025, 80, true, true, true, 0.04);
}
surface_reset_target();
var _nova_w = display_get_gui_width();
var _nova_h = display_get_gui_height();
if (global.Users[global.UserIndex].Prefs[3])
{
    CRT_Do_Stretch(NovaFrame, 0, 0, _nova_w, _nova_h, [256, 224, _nova_w, _nova_h], false, 0.04, false, 0.03, 80, true, false, true, 0.04);
}
else
{
    draw_surface_stretched(NovaFrame, 0, 0, _nova_w, _nova_h);
}
