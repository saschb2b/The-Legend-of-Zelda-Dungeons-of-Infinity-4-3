using System;
using System.IO;
using System.Text.RegularExpressions;
using UndertaleModLib.Compiler;
var patchDir = Directory.GetCurrentDirectory();
var group = new CodeImportGroup(Data) { AutoCreateAssets = false };
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
group.QueueAppend("gml_Object_oRender_Create_0", "NovaFrame = -1; display_set_gui_maximise();");
group.QueueAppend("gml_Object_oRender_CleanUp_0", "if (surface_exists(NovaFrame)) surface_free(NovaFrame); display_set_gui_maximise(-1, -1);");
group.QueueAppend("gml_Object_oGame_Create_0", "global.Users[global.UserIndex].Prefs[2] = false;");
var usersName = "gml_GlobalScript___Users";
var users = FlattenEnums(Read(usersName));
var defaults = "return [true, true, true, false, true, false, false, false];";
if (!users.Contains(defaults)) throw new Exception("HUD default not found");
group.QueueReplace(usersName, users.Replace(defaults, "return [true, true, false, false, true, false, false, false];"));
group.Import();
Console.WriteLine("4:3 overlay patch compiled.");
