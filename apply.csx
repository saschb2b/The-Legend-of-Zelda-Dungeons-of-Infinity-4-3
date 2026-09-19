using System;
using System.IO;
using System.Text.RegularExpressions;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;
using UndertaleModLib.Util;
var patchDir = Directory.GetCurrentDirectory();
var hintTexture = new UndertaleEmbeddedTexture();
hintTexture.Name = new UndertaleString("Nova panel hint");
hintTexture.TextureData.Image = GMImage.FromPng(File.ReadAllBytes(Path.Combine(patchDir, "assets", "right-stick-click.png")));
Data.EmbeddedTextures.Add(hintTexture);
var hintPage = new UndertaleTexturePageItem {
    Name = new UndertaleString("Nova panel hint"),
    SourceWidth = 128, SourceHeight = 128,
    TargetWidth = 128, TargetHeight = 128,
    BoundingWidth = 128, BoundingHeight = 128,
    TexturePage = hintTexture
};
Data.TexturePageItems.Add(hintPage);
var hintSprite = new UndertaleSprite {
    Name = Data.Strings.MakeString("sNovaPanelHint"),
    Width = 128, Height = 128,
    MarginRight = 127, MarginBottom = 127
};
hintSprite.Textures.Add(new UndertaleSprite.TextureEntry { Texture = hintPage });
hintSprite.CollisionMasks.Add(hintSprite.NewMaskEntry(Data));
Data.Sprites.Add(hintSprite);
var group = new CodeImportGroup(Data) { AutoCreateAssets = true };
string Read(string name) => GetDecompiledText(name, null, new Underanalyzer.Decompiler.DecompileSettings());
string FlattenEnums(string code) {
    var matches = Regex.Matches(code, @"UnknownEnum\.Value_(\d+)");
    foreach (Match match in matches) code = code.Replace(match.Value, match.Groups[1].Value);
    return Regex.Replace(code, @"\s*enum UnknownEnum\s*\{[^}]*\}\s*", "");
}
string ReplaceOnce(string code, string anchor, string replacement) {
    var first = code.IndexOf(anchor, StringComparison.Ordinal);
    if (first < 0 || code.IndexOf(anchor, first + anchor.Length, StringComparison.Ordinal) >= 0)
        throw new Exception("Expected one patch anchor: " + anchor);
    return code.Substring(0, first) + replacement + code.Substring(first + anchor.Length);
}
void Edit(string name, string anchor, string replacement) {
    group.QueueReplace(name, ReplaceOnce(FlattenEnums(Read(name)), anchor, replacement));
}
Edit("gml_Object_oInit_Create_0", "ini_close();",
    "global.CanSkipTitle = ini_read_real(\"Preferences\", \"CanSkipTitle\", 1) == 1;\nini_close();");
Edit("gml_Object_oTitle_Step_0", "AllowStart || false", "AllowStart || global.CanSkipTitle");
Edit("gml_Object_oMenu_Step_0", "if (Menu_Active)",
    File.ReadAllText(Path.Combine(patchDir, "menu_cancel.gml")) + "\nif (Menu_Active)");
Edit("gml_Object_oMenu_Game_Step_0", "if (input_check_pressed(\"menu_access\"))",
    File.ReadAllText(Path.Combine(patchDir, "pause_cancel.gml")) + "\nif (input_check_pressed(\"menu_access\"))");
// A blocked alarm must stay armed so the Medusa can fire after the status ends.
Edit("gml_Object_oEnemy_Medusa_Alarm_0", "if (StopWatch)\n{\n    exit;\n}",
    "if (global.Paused || StopWatch || Stoned || State == 15 || State == 17)\n{\n    alarm[0] = 1;\n    exit;\n}");
Edit("gml_Object_oEnemy_Cannon_Step_0", "if (ShootReady && oLink.State == 12 && !StopWatch)",
    "if (ShootReady && oLink.State == 12 && !global.Paused && !StopWatch && !Stoned && State != 15 && State != 17)");
// Link states 20 and 21 cover falling into a pit and falling over its edge.
Edit("gml_Object_oEnemy_Pikit_Tongue_Step_0",
    "if (!ItemGrabbed && !oLink.Invincible && !oLink.Cape && Dist >= GrabDist)",
    "if (!ItemGrabbed && !oLink.Invincible && !oLink.Cape && oLink.State != 20 && oLink.State != 21 && Dist >= GrabDist)");
var renderName = "gml_Object_oRender_Draw_64";
var render = FlattenEnums(Read(renderName));
var marker = "if (global.Users[global.UserIndex].Prefs[3])";
var position = render.IndexOf(marker);
if (position < 0) throw new Exception("Final compositor not found");
group.QueueReplace(renderName, render.Substring(0, position) + File.ReadAllText(Path.Combine(patchDir, "composite.gml")));
group.QueueAppend("gml_Object_oRender_Create_0", "NovaFrame = -1; NovaHUD = -1; surface_resize(application_surface, 1600, 900); display_set_gui_maximise();");
group.QueueAppend("gml_Object_oRender_CleanUp_0", "if (surface_exists(NovaFrame)) surface_free(NovaFrame); if (surface_exists(NovaHUD)) surface_free(NovaHUD); display_set_gui_maximise(-1, -1);");
group.QueueAppend("gml_Object_oRender_Create_0", "function NovaHUD_Draw() { with (oHUD) {\n" + File.ReadAllText(Path.Combine(patchDir, "hud.gml")) + "\n} }");
var hudName = "gml_Object_oHUD_Draw_0";
var hud = FlattenEnums(Read(hudName));
var metricsStart = hud.IndexOf("draw_sprite_ext(sHUD_Life,");
var metricsEnd = hud.IndexOf("draw_sprite(sHUD_Side1,");
if (metricsStart < 0 || metricsEnd <= metricsStart) throw new Exception("HUD metrics not found");
var equipmentStats = @"
draw_sprite(sHUD_Icon_Attack, 0, MainSide + 7, 80);
draw_sprite(sHUD_Icon_Defense, 0, MainSide + 38, 80);
draw_set_color(AttackColor);
draw_text(MainSide + 20, 82, string(oLink.AttackPoints));
draw_set_color(DefenseColor);
draw_text(MainSide + 51, 82, string(oLink.DefensePoints));
draw_set_color(c_white);
";
group.QueueReplace(hudName, hud.Substring(0, metricsStart) + equipmentStats + hud.Substring(metricsEnd));
group.QueueAppend("gml_Object_oGame_Create_0", "global.Users[global.UserIndex].Prefs[2] = false;");
var usersName = "gml_GlobalScript___Users";
var users = FlattenEnums(Read(usersName));
var defaults = "return [true, true, true, false, true, false, false, false];";
if (!users.Contains(defaults)) throw new Exception("HUD default not found");
group.QueueReplace(usersName, ReplaceOnce(users, defaults, "return [true, true, false, false, true, false, false, false];"));
var title = Data.Rooms.ByName("Room_Title");
title.Views[0].ViewX = 50;
title.Views[0].ViewWidth = 300;
title.Views[0].PortWidth = 1200;
var menu = Data.Rooms.ByName("Room_Menu");
menu.Height = 300;
menu.Views[0].ViewY = -38;
menu.Views[0].ViewHeight = 300;
menu.Views[0].PortHeight = 1200;
group.QueueReplace("gml_Object_oTitle_Draw_0", ReplaceOnce(Read("gml_Object_oTitle_Draw_0"), "draw_text(8, 212,", "draw_text(58, 212,"));
var credits = Read("gml_Object_oCredits_Create_0");
credits = ReplaceOnce(credits, "x = (camera_get_view_width(view_camera[0]) - BoxW) / 2;", "x = camera_get_view_x(view_camera[0]) + (camera_get_view_width(view_camera[0]) - BoxW) / 2;");
credits = ReplaceOnce(credits, "TextSurfaceX = (x * 4) + 20;", "TextSurfaceX = ((x - camera_get_view_x(view_camera[0])) * 4) + 20;");
group.QueueReplace("gml_Object_oCredits_Create_0", credits);
group.QueueReplace("gml_Object_oNovaScreen_Create_0", @"
depth = 1000000;
NovaWidth = room == Room_Title ? 1200 : 1600;
NovaHeight = room == Room_Title ? 900 : 1200;
application_surface_draw_enable(false);
display_set_gui_maximise(window_get_width() / NovaWidth, window_get_height() / NovaHeight);
surface_resize(application_surface, NovaWidth, NovaHeight);");
group.QueueReplace("gml_Object_oNovaScreen_Draw_64", "draw_surface_stretched(application_surface, 0, 0, NovaWidth, NovaHeight);");
group.QueueReplace("gml_Object_oNovaScreen_CleanUp_0", "display_set_gui_maximise(-1, -1); application_surface_draw_enable(true);");
foreach (var screen in new[] { "oTitle", "oMenu" }) {
    group.QueueAppend($"gml_Object_{screen}_Create_0", "instance_create_layer(0, 0, \"System\", oNovaScreen);");
}
group.Import();
Console.WriteLine("4:3 overlay patch compiled.");
