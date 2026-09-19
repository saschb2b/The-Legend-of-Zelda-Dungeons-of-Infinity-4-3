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
// Doorway movement and closing doors keep gameplay paused after the camera stops.
NovaTransitionHUD = instance_exists(oCamera) && (oCamera.RoomTransition != 0 || (NovaTransitionHUD && global.Paused));
var _nova_ui = instance_exists(oInventory) || instance_exists(oMenu_Game) || instance_exists(oDialogueBox) || instance_exists(oMap);
var _nova_modal = global.Paused || _nova_ui;
var _nova_travel = NovaTransitionHUD || (instance_exists(oLink) && oLink.StairsAutoMove);
if (global.Users[global.UserIndex].Prefs[2] && !_nova_modal)
{
    draw_surface_part_ext(application_surface, 0, 304, 288, 592, 16, 436, 0.75, 0.75, c_white, 0.9);
    draw_surface_part_ext(application_surface, 1312, 0, 288, 896, 792, 208, 0.75, 0.75, c_white, 0.9);
}
if (instance_exists(oHUD) && ((!_nova_ui && (!global.Paused || _nova_travel)) || global.NovaInventoryHUD()) && !global.ArcadeVP_Show)
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
// Render glyphs after CRT scaling so their letters remain readable.
if (instance_exists(oInventory) && (!instance_exists(oDialogueBox) || global.NovaInventoryInfo())) global.NovaInventoryPrompts(oInventory);
if (instance_exists(oMap) && !oMap.Close) {
    var sx = _nova_w / 256;
    var sy = _nova_h / 224;
    var size = 18 * min(sx, sy);
    draw_set_font(global.HUDFont2);
    draw_set_alpha(oMap.Alpha);
    var binding = global.NovaBinding("action");
    var width = global.NovaPromptWidth(binding, "CLOSE", sx, size);
    global.NovaPromptDraw(binding, "CLOSE", 222 * sx - width, 200 * sy, sx, sy, size);
    draw_set_alpha(1);
}
if (instance_exists(oHUD) && !_nova_modal && !global.ArcadeVP_Show && !global.Users[global.UserIndex].Prefs[2]) {
    var sx = _nova_w / 256;
    var sy = _nova_h / 224;
    var size = 64 * _nova_h / 960;
    draw_set_font(global.HUDFont2);
    draw_set_alpha(oHUD.MainAlpha);
    var binding = global.NovaBinding("hud");
    var width = global.NovaPromptWidth(binding, "STATUS", sx, size, 2);
    global.NovaPromptDraw(binding, "STATUS", _nova_w - 40 * _nova_h / 960 - width, _nova_h - 64 * _nova_h / 960, sx, sy, size, 2);
    draw_set_alpha(1);
}
