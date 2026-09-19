using System;
using System.IO;
using UndertaleModLib.Compiler;
var root = Directory.GetCurrentDirectory();
var group = new CodeImportGroup(Data) { AutoCreateAssets = true };
group.QueueReplace("gml_Object_oNovaTests_Create_0", File.ReadAllText(Path.Combine(root, "tests/runtime/create.gml")));
group.QueueReplace("gml_Object_oNovaTests_Step_0", File.ReadAllText(Path.Combine(root, "tests/runtime/step.gml")));
group.QueueAppend("gml_Object_oTitle_Create_0", "if (!instance_exists(oNovaTests)) instance_create_depth(0, 0, -100000, oNovaTests);");
var settings = new Underanalyzer.Decompiler.DecompileSettings();
var inputName = "gml_GlobalScript_input_check_pressed";
var input = GetDecompiledText(inputName, null, settings);
var brace = input.IndexOf('{');
group.QueueReplace(inputName, input.Insert(brace + 1, "\nif (variable_global_exists(\"NovaTestInput\")) return arg0 == global.NovaTestInput;\n"));
// Only the instrumented build substitutes the keyboard boundary; the event bodies stay intact.
foreach (var name in new[] { "gml_Object_oMenu_Step_0", "gml_Object_oMenu_Game_Step_0" }) {
    var code = GetDecompiledText(name, null, settings);
    code = System.Text.RegularExpressions.Regex.Replace(code, @"UnknownEnum\.Value_(\d+)", "$1");
    code = System.Text.RegularExpressions.Regex.Replace(code, @"\s*enum UnknownEnum\s*\{[^}]*\}\s*", "");
    group.QueueReplace(name, code.Replace("keyboard_check_pressed(vk_escape)", "(global.NovaTestInput == \"escape\")"));
}
group.Import();
Console.WriteLine("NOVA TEST HARNESS COMPILED");
