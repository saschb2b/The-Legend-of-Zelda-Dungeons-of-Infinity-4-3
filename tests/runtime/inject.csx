using System;
using System.IO;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;
// The bundled runner expects a FUNC locals table. The upstream empty table is
// mistaken for 2024.8 alignment padding by the tool's version detection.
Data.SetGMS2Version(2024, 6);
Data.FORM.FUNC.CodeLocals ??= new UndertaleModLib.UndertaleSimpleList<UndertaleCodeLocals>();
var root = Directory.GetCurrentDirectory();
var group = new CodeImportGroup(Data) { AutoCreateAssets = true };
group.QueueReplace("gml_Object_oNovaTests_Create_0", File.ReadAllText(Path.Combine(root, "tests/runtime/create.gml")) + "\n" + File.ReadAllText(Path.Combine(root, "tests/runtime/backports.gml")) + "\n" + File.ReadAllText(Path.Combine(root, "tests/runtime/inventory.gml")) + "\n" + File.ReadAllText(Path.Combine(root, "tests/runtime/capture.gml")) + "\n" + File.ReadAllText(Path.Combine(root, "tests/runtime/content.gml")) + "\n" + File.ReadAllText(Path.Combine(root, "tests/runtime/controls.gml")));
group.QueueAppend("gml_Object_oNovaTests_Create_0", File.ReadAllText(Path.Combine(root, "tests/runtime/movement.gml")));
group.QueueAppend("gml_Object_oNovaTests_Create_0", File.ReadAllText(Path.Combine(root, "tests/runtime/hud.gml")));
group.QueueAppend("gml_Object_oNovaTests_Create_0", File.ReadAllText(Path.Combine(root, "tests/runtime/shop.gml")));
group.QueueAppend("gml_Object_oNovaTests_Create_0", File.ReadAllText(Path.Combine(root, "tests/runtime/updates.gml")));
group.QueueAppend("gml_Object_oNovaTests_Create_0", File.ReadAllText(Path.Combine(root, "tests/runtime/profiles.gml")));
group.QueueReplace("gml_Object_oNovaTests_Step_0", File.ReadAllText(Path.Combine(root, "tests/runtime/step.gml")));
group.QueueAppend("gml_Object_oTitle_Create_0", "if (!instance_exists(oNovaTests)) instance_create_depth(0, 0, -100000, oNovaTests);");
group.QueueAppend("gml_Object_oNovaTests_Create_0", File.ReadAllText(Path.Combine(root, "tests/runtime/context.gml")));
var settings = new Underanalyzer.Decompiler.DecompileSettings();
var updateMenu = GetDecompiledText("gml_Object_oMenu_Create_0", null, settings);
if (updateMenu.Contains("NovaUpdateStep")) {
    if (!updateMenu.Contains("game_end();")) throw new Exception("Updater restart boundary missing");
    group.QueueReplace("gml_Object_oMenu_Create_0", updateMenu.Replace("game_end();", "global.NovaTestUpdateRestart = true;").Replace("Menu_StartGame();", "global.NovaTestStart = true;").Replace("Menu_ContinueGame();", "global.NovaTestContinue = true;"));
}
var renderName = "gml_Object_oRender_Draw_64";
var render = GetDecompiledText(renderName, null, settings);
if (render.Contains("NovaHUD_Draw();")) {
    render = render.Replace("NovaHUD_Draw();", "NovaHUD_Draw(); global.NovaTestHUDDraws++;");
    var statusCall = "global.NovaPromptDraw(binding, \"STATUS\",";
    if (!render.Contains(statusCall)) throw new Exception("Status drawing boundary missing");
    render = render.Replace(statusCall, "global.NovaTestStatusDraws++; " + statusCall);
    group.QueueReplace(renderName, render);
}
var inputName = "gml_GlobalScript_input_check_pressed";
var input = GetDecompiledText(inputName, null, settings);
var pressedBoundary = "return _global.__cleared ? false : _verb_struct.__press;";
if (!input.Contains(pressedBoundary)) throw new Exception("Input press boundary missing");
group.QueueReplace(inputName, input.Replace(pressedBoundary, @"
if (variable_global_exists(""NovaTestInput"")) {
    var pressed = false;
    if (is_array(global.NovaTestInput)) {
        for (var i = 0; i < array_length(global.NovaTestInput); i++) if (global.NovaTestInput[i] == arg0) pressed = true;
    } else pressed = arg0 == global.NovaTestInput;
    return _global.__cleared ? false : pressed;
}
" + pressedBoundary));
var heldName = "gml_GlobalScript_input_check";
var held = GetDecompiledText(heldName, null, settings);
group.QueueReplace(heldName, held.Insert(held.IndexOf('{') + 1, "\nif (variable_global_exists(\"NovaTestHeld\")) { for (var i = 0; i < array_length(global.NovaTestHeld); i++) if (global.NovaTestHeld[i] == arg0) return true; return false; }\n"));
// Only the instrumented build substitutes the keyboard boundary; the event bodies stay intact.
foreach (var name in new[] { "gml_Object_oMenu_Step_0", "gml_Object_oMenu_Game_Step_0", "gml_Object_oInventory_Step_0", "gml_Object_oMap_Step_0", "gml_Object_oDialogueBox_Step_2" }) {
    var code = GetDecompiledText(name, null, settings);
    code = System.Text.RegularExpressions.Regex.Replace(code, @"UnknownEnum\.Value_(\d+)", "$1");
    code = System.Text.RegularExpressions.Regex.Replace(code, @"\s*enum UnknownEnum\s*\{[^}]*\}\s*", "");
    group.QueueReplace(name, code.Replace("keyboard_check_pressed(vk_escape)", "(global.NovaTestInput == \"escape\")"));
}
group.Import();
Console.WriteLine("NOVA TEST HARNESS COMPILED");
