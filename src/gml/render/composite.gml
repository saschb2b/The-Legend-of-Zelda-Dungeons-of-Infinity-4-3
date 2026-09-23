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
if (global.Users[global.UserIndex].Prefs[3] && !global.ArcadeVP_Show)
{
    NovaCRT_Draw(NovaFrame, _nova_w, _nova_h);
}
else
{
    draw_surface_stretched(NovaFrame, 0, 0, _nova_w, _nova_h);
}
var _nova_layout = global.NovaHUDLayout(_nova_w, _nova_h);
// Compose native HUD pixels after world scaling and CRT distortion.
if (instance_exists(oHUD) && ((!_nova_ui && (!global.Paused || _nova_travel)) || global.NovaInventoryHUD()) && !global.ArcadeVP_Show)
{
    var _nova_filter = gpu_get_texfilter();
    gpu_set_texfilter(false);
    if (surface_exists(NovaHUD) && surface_get_width(NovaHUD) != _nova_layout.width) surface_free(NovaHUD);
    if (!surface_exists(NovaHUD)) NovaHUD = surface_create(_nova_layout.width, 64);
    surface_set_target(NovaHUD);
    draw_clear_alpha(c_black, 0);
    NovaHUD_Draw(_nova_layout);
    surface_reset_target();
    draw_surface_ext(NovaHUD, _nova_layout.x, _nova_layout.y, _nova_layout.scale, _nova_layout.scale, 0, c_white, 1);
    gpu_set_texfilter(_nova_filter);
}
// Render glyphs after CRT scaling so their letters remain readable.
if (instance_exists(oInventory) && (!instance_exists(oDialogueBox) || global.NovaInventoryInfo())) global.NovaInventoryPrompts(oInventory, _nova_layout);
if (instance_exists(oMap) && !oMap.Close) {
    var sx = _nova_layout.scale;
    var sy = sx;
    var size = 12 * sx;
    draw_set_font(global.HUDFont2);
    draw_set_alpha(oMap.Alpha);
    var binding = global.NovaBinding(global.NovaCloseVerb());
    var width = global.NovaPromptWidth(binding, "CLOSE", sx, size);
    global.NovaPromptDraw(binding, "CLOSE", _nova_layout.right - width, _nova_layout.footer_y, sx, sy, size);
    draw_set_alpha(1);
}
if (instance_exists(oHUD) && !_nova_modal && !global.ArcadeVP_Show && !global.Users[global.UserIndex].Prefs[2]) {
    var sx = _nova_layout.scale;
    var sy = sx;
    var size = 12 * sx;
    draw_set_font(global.HUDFont2);
    draw_set_alpha(oHUD.MainAlpha);
    var binding = global.NovaBinding("hud");
    var width = global.NovaPromptWidth(binding, "STATUS", sx, size, 2);
    global.NovaContextDraw(_nova_layout, _nova_layout.right - width);
    global.NovaPromptDraw(binding, "STATUS", _nova_layout.right - width, _nova_layout.footer_y, sx, sy, size, 2);
    draw_set_alpha(1);
}

global.NovaArcadePrompts(_nova_layout);
// Options draw over the finished frame, so CRT changes show behind them immediately.
if (instance_exists(oMenu_Game)) global.NovaPauseOverlay(oMenu_Game, _nova_w, _nova_h);
