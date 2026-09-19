using System;
using System.IO;
using System.Text.RegularExpressions;
using UndertaleModLib.Compiler;
var patchDir = Directory.GetCurrentDirectory();
var group = new CodeImportGroup(Data) { AutoCreateAssets = true };
string Read(string name) => GetDecompiledText(name, null, new Underanalyzer.Decompiler.DecompileSettings());
string FlattenEnums(string code) {
    var matches = Regex.Matches(code, @"UnknownEnum\.Value_(\d+)");
    foreach (Match match in matches) code = code.Replace(match.Value, match.Groups[1].Value);
    return Regex.Replace(code, @"\s*enum UnknownEnum\s*\{[^}]*\}\s*", "");
}
var renderName = "gml_Object_oRender_Draw_64";
var render = FlattenEnums(Read(renderName));
var marker = "if (global.Users[global.UserIndex].Prefs[3])";
var position = render.IndexOf(marker);
if (position < 0) throw new Exception("Final compositor not found");
group.QueueReplace(renderName, render.Substring(0, position) + File.ReadAllText(Path.Combine(patchDir, "composite.gml")));
group.QueueAppend("gml_Object_oRender_Create_0", "NovaFrame = -1; surface_resize(application_surface, 1600, 900); display_set_gui_maximise();");
group.QueueAppend("gml_Object_oRender_CleanUp_0", "if (surface_exists(NovaFrame)) surface_free(NovaFrame); display_set_gui_maximise(-1, -1);");
group.QueueAppend("gml_Object_oGame_Create_0", "global.Users[global.UserIndex].Prefs[2] = false;");
var usersName = "gml_GlobalScript___Users";
var users = FlattenEnums(Read(usersName));
var defaults = "return [true, true, true, false, true, false, false, false];";
if (!users.Contains(defaults)) throw new Exception("HUD default not found");
group.QueueReplace(usersName, users.Replace(defaults, "return [true, true, false, false, true, false, false, false];"));
var title = Data.Rooms.ByName("Room_Title");
title.Views[0].ViewX = 50;
title.Views[0].ViewWidth = 300;
title.Views[0].PortWidth = 1200;
var menu = Data.Rooms.ByName("Room_Menu");
menu.Height = 300;
menu.Views[0].ViewY = -38;
menu.Views[0].ViewHeight = 300;
menu.Views[0].PortHeight = 1200;
group.QueueReplace("gml_Object_oTitle_Draw_0", Read("gml_Object_oTitle_Draw_0").Replace("draw_text(8, 212,", "draw_text(58, 212,"));
var credits = Read("gml_Object_oCredits_Create_0");
credits = credits.Replace("x = (camera_get_view_width(view_camera[0]) - BoxW) / 2;", "x = camera_get_view_x(view_camera[0]) + (camera_get_view_width(view_camera[0]) - BoxW) / 2;");
credits = credits.Replace("TextSurfaceX = (x * 4) + 20;", "TextSurfaceX = ((x - camera_get_view_x(view_camera[0])) * 4) + 20;");
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
