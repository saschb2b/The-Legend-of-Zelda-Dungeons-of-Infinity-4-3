#load "content.csx"
#load "context.csx"
#load "arcade.csx"
using System;
using System.IO;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Security.Cryptography;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;
using UndertaleModLib.Util;
// The bundled runner expects a FUNC locals table. The upstream empty table is
// mistaken for 2024.8 alignment padding by the tool's version detection.
Data.SetGMS2Version(2024, 6);
Data.FORM.FUNC.CodeLocals ??= new UndertaleModLib.UndertaleSimpleList<UndertaleCodeLocals>();
// build.py runs the compiler from the repository root; patch paths are relative to it.
var patchDir = Directory.GetCurrentDirectory();
var novaCRT = new UndertaleShader {
    Name = Data.Strings.MakeString("shd_NovaCRT"),
    Type = UndertaleShader.ShaderType.GLSL_ES,
    GLSL_ES_Vertex = Data.Strings.MakeString(File.ReadAllText(Path.Combine(patchDir, "src/shaders/crt-lottes.vsh"))),
    GLSL_ES_Fragment = Data.Strings.MakeString(File.ReadAllText(Path.Combine(patchDir, "src/shaders/crt-lottes.fsh"))),
    GLSL_Vertex = Data.Strings.MakeString(""), GLSL_Fragment = Data.Strings.MakeString(""),
    HLSL9_Vertex = Data.Strings.MakeString(""), HLSL9_Fragment = Data.Strings.MakeString("")
};
foreach (var attribute in new[] { "in_Position", "in_Colour", "in_TextureCoord" })
    novaCRT.VertexShaderAttributes.Add(new UndertaleShader.VertexShaderAttribute { Name = Data.Strings.MakeString(attribute) });
Data.Shaders.Add(novaCRT);
var buttons = new UndertaleSprite {
    Name = Data.Strings.MakeString("sNovaButtons"), Width = 128, Height = 128,
    MarginRight = 127, MarginBottom = 127
};
using (var icons = JsonDocument.Parse(File.ReadAllText(Path.Combine(patchDir, "assets/buttons/manifest.json")))) {
    foreach (var icon in icons.RootElement.EnumerateArray()) {
        var bytes = File.ReadAllBytes(Path.Combine(patchDir, "assets/buttons", icon.GetProperty("file").GetString()));
        if (Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant() != icon.GetProperty("sha256").GetString())
            throw new Exception("Controller glyph checksum mismatch");
        var texture = new UndertaleEmbeddedTexture { Name = new UndertaleString("Nova controller glyph") };
        texture.TextureData.Image = GMImage.FromPng(bytes);
        Data.EmbeddedTextures.Add(texture);
        var page = new UndertaleTexturePageItem {
            SourceWidth = 128, SourceHeight = 128, TargetWidth = 128, TargetHeight = 128,
            BoundingWidth = 128, BoundingHeight = 128, TexturePage = texture
        };
        Data.TexturePageItems.Add(page);
        buttons.Textures.Add(new UndertaleSprite.TextureEntry { Texture = page });
    }
}
Data.Sprites.Add(buttons);
var group = new CodeImportGroup(Data) { AutoCreateAssets = true };
string Read(string name) => GetDecompiledText(name, null, new Underanalyzer.Decompiler.DecompileSettings());
string FlattenEnums(string code) {
    var matches = Regex.Matches(code, @"UnknownEnum\.Value_(m?\d+)");
    foreach (Match match in matches) code = code.Replace(match.Value, match.Groups[1].Value.Replace("m", "-"));
    return Regex.Replace(code, @"\s*enum UnknownEnum\s*\{[^}]*\}\s*", "");
}
string ReplaceOnce(string code, string anchor, string replacement) {
    var first = code.IndexOf(anchor, StringComparison.Ordinal);
    if (first < 0 || code.IndexOf(anchor, first + anchor.Length, StringComparison.Ordinal) >= 0)
        throw new Exception("Expected one patch anchor: " + anchor);
    return code.Substring(0, first) + replacement + code.Substring(first + anchor.Length);
}
var edits = new Dictionary<string, string>();
void Edit(string name, string anchor, string replacement) {
    var code = edits.ContainsKey(name) ? edits[name] : FlattenEnums(Read(name));
    edits[name] = ReplaceOnce(code, anchor, replacement);
}
Edit("gml_Object_oInit_Create_0", "ini_close();",
    "global.CanSkipTitle = ini_read_real(\"Preferences\", \"CanSkipTitle\", 1) == 1;\nini_close();");
Edit("gml_Object_oTitle_Step_0", "AllowStart || false", "AllowStart || global.CanSkipTitle");
edits["gml_Object_oMenu_Create_0"] = FlattenEnums(Read("gml_Object_oMenu_Create_0"));
edits["gml_Object_oMenu_Create_0"] += "\n" + File.ReadAllText(Path.Combine(patchDir, "src/gml/menus/updates.gml"));
edits["gml_Object_oMenu_Create_0"] += "\n" + File.ReadAllText(Path.Combine(patchDir, "src/gml/menus/profiles.gml"));
group.QueueAppend("gml_Object_oMenu_Game_Create_0", "NovaOptionsOpen = false; NovaOptions = undefined;");
Edit("gml_Object_oMenu_Game_Step_0", "Index = 1;", "NovaOptionsOpen = true; NovaOptions = global.NovaOptionsState(\"pause\");");
Edit("gml_Object_oMenu_Game_Draw_0", "draw_sprite_stretched(sprite_index, 0, FrameX, FrameY, FrameW, FrameH);",
    "if (NovaOptionsOpen) { draw_set_alpha(1); exit; }\ndraw_sprite_stretched(sprite_index, 0, FrameX, FrameY, FrameW, FrameH);");
// Remapping also runs from the pause menu, where the adventure menu does not exist.
Edit("gml_Object_oInputRemap_Create_0", "oMenu.Bindings_Remap = true;\noMenu.Menu_Active = false;",
    "global.NovaRemapping = true;\nwith (oMenu) { Bindings_Remap = true; Menu_Active = false; }");
Edit("gml_GlobalScript___Input", "oMenu.Bindings_Remap = false;\n    oMenu.Menu_Active = true;",
    "global.NovaRemapping = false;\n    with (oMenu) { Bindings_Remap = false; Menu_Active = true; }");
Edit("gml_Object_oMenu_Game_Step_0", "if (input_check_pressed(\"menu_access\"))",
    File.ReadAllText(Path.Combine(patchDir, "src/gml/menus/pause_cancel.gml")) + "\nif (input_check_pressed(\"menu_access\"))");
Edit("gml_Object_oGame_Step_1", "if (input_check_pressed(\"hud\"))",
    "if (input_check_pressed(\"hud\") && !global.Paused && !instance_exists(oInventory) && !instance_exists(oMap) && !instance_exists(oMenu_Game) && !instance_exists(oDialogueBox))");
Edit("gml_Object_oMap_Create_0", "FrameX = oCamera.X + 26;\nFrameY = oCamera.Y + 10;",
    "NovaFrameSize = 188;\nNovaMapScale = (NovaFrameSize - 12) / 256;\nFrameX = oCamera.X + (256 - NovaFrameSize) / 2;\nFrameY = oCamera.Y + 6;");
Edit("gml_Object_oMap_Draw_0", "FrameX, FrameY, 204, 204", "FrameX, FrameY, NovaFrameSize, NovaFrameSize");
Edit("gml_Object_oMap_Draw_0", "MapX, MapY, 0.75, 0.75, 0, c_white, Alpha", "MapX, MapY, NovaMapScale, NovaMapScale, 0, c_white, Alpha");
Edit("gml_Object_oMap_Draw_0", "MapX, MapY, 0.75, 0.75, 0, c_white, abs(dsin(LinkAlpha)) * Alpha", "MapX, MapY, NovaMapScale, NovaMapScale, 0, c_white, abs(dsin(LinkAlpha)) * Alpha");
group.QueueAppend("gml_Object_oMap_Step_0", "if (!Open && !Close && (input_check_pressed(global.NovaCloseVerb()) || input_check_pressed(\"menu_access\") || keyboard_check_pressed(vk_escape))) { Close = true; input_clear_momentary(true); }");
group.QueueAppend("gml_Object_oDialogueBox_Create_0", "NovaShopDialogue = false;");
Edit("gml_Object_oShop_Step_0", "global.DB_Inst.Script = DB_Script;", @"
global.DB_Inst.Script = DB_Script;
global.DB_Inst.NovaShopDialogue = true;
global.DB_ExitCode = 0;
// The interaction press belongs to opening the shop, not its first choice.
input_clear_momentary(true);");
Edit("gml_Object_oDialogueBox_Step_2", "if (CameraExists)", @"
if (NovaShopDialogue && (input_check_pressed(global.NovaCloseVerb()) || keyboard_check_pressed(vk_escape))) {
    global.DB_ExitCode = 0;
    ScriptNext = false;
    Status = 5;
    input_clear_momentary(true);
}
if (global.NovaInventoryInfo() && (input_check_pressed(global.NovaCloseVerb()) || keyboard_check_pressed(vk_escape))) {
    ScriptNext = false;
    Status = 5;
    input_clear_momentary(true);
}
if (CameraExists)");
Edit("gml_Object_oDialogueBox_Step_2", "var Key = input_check_pressed(\"sword\") || input_check_pressed(\"action\");", "var Key = (NovaShopDialogue || global.NovaInventoryInfo()) ? input_check_pressed(global.NovaConfirmVerb()) : (input_check_pressed(\"sword\") || input_check_pressed(\"action\"));");
Edit("gml_Object_oDialogueBox_Step_2", "if (input_check_pressed(\"sword\") || input_check_pressed(\"action\"))", "if (NovaShopDialogue ? input_check_pressed(global.NovaConfirmVerb()) : (input_check_pressed(\"sword\") || input_check_pressed(\"action\")))");
foreach (var modal in new[] { "oInventory", "oMap", "oMenu_Game" })
    group.QueueAppend("gml_Object_" + modal + "_Destroy_0", "input_clear_momentary(true);");
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
group.QueueReplace(renderName, render.Substring(0, position) + File.ReadAllText(Path.Combine(patchDir, "src/gml/render/composite.gml")));
group.QueueAppend("gml_Object_oRender_Create_0", "NovaFrame = -1; NovaHUD = -1; NovaTransitionHUD = false; surface_resize(application_surface, 1600, 900); display_set_gui_maximise();");
group.QueueAppend("gml_Object_oRender_Create_0", "NovaContext = global.NovaContextMotion();");
group.QueueAppend("gml_Object_oRender_Create_0", File.ReadAllText(Path.Combine(patchDir, "src/gml/render/crt.gml")));
group.QueueAppend("gml_Object_oRender_Step_2", "global.NovaContextUpdate(delta_time / 1000000);");
group.QueueAppend("gml_Object_oRender_CleanUp_0", "if (surface_exists(NovaFrame)) surface_free(NovaFrame); if (surface_exists(NovaHUD)) surface_free(NovaHUD); display_set_gui_maximise(-1, -1);");
group.QueueAppend("gml_Object_oRender_Create_0", "function NovaHUD_Draw(layout) { with (oHUD) {\n" + File.ReadAllText(Path.Combine(patchDir, "src/gml/render/hud.gml")) + "\n} }");
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
var panelHUD = hud.Substring(0, metricsStart) + equipmentStats + hud.Substring(metricsEnd);
panelHUD = ReplaceOnce(panelHUD, "if (ShowLamp)", "if (ShowLamp && (global.Inventory_ItemData[24].Owns[0] || global.Inventory_ItemData[51].Owns[0]))");
group.QueueReplace(hudName, panelHUD);
group.QueueAppend("gml_Object_oGame_Create_0", "global.Users[global.UserIndex].Prefs[2] = false;");
Edit("gml_GlobalScript___Users", "return [true, true, true, false, true, false, false, false];", "return [true, true, false, false, true, false, false, false];");
var title = Data.Rooms.ByName("Room_Title");
title.Views[0].ViewX = 50;
title.Views[0].ViewWidth = 300;
title.Views[0].PortWidth = 1200;
var menu = Data.Rooms.ByName("Room_Menu");
menu.Height = 300;
menu.Views[0].ViewY = -38;
menu.Views[0].ViewHeight = 300;
menu.Views[0].PortHeight = 1200;
group.QueueReplace("gml_Object_oTitle_Draw_0", ReplaceOnce(Read("gml_Object_oTitle_Draw_0"), "draw_text(8, 212,", "draw_text(58, 212,") + @"
if (AllowStart) {
    draw_set_font(global.MenuFont_Innactive);
    var binding = input_binding_get(""menu_input"", 0, 1);
    if (binding.__type == undefined) binding = global.NovaBinding(""menu_input"");
    var width = global.NovaPromptWidth(binding, ""Begin"", 0.75, 12);
    global.NovaPromptDraw(binding, ""Begin"", 329 - width, 210, 0.75, 0.75, 12);
}");
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
group.QueueAppend("gml_Object_oLink_Create_0", File.ReadAllText(Path.Combine(patchDir, "src/gml/gameplay/sword.gml")));
group.QueueAppend("gml_Object_oLink_Create_0", "NovaCrystalHold = false; NovaCrystalTicks = 0;");
Edit("gml_Object_oLink_Step_0",
    "S = (ItemHolding == -4) ? ((Action[6] && !InDoorPassage) ? RunSpeed : WalkSpeed) : CarryingSpeed;",
    @"S = (ItemHolding == -4) ? ((Action[6] && !InDoorPassage) ? RunSpeed : WalkSpeed) : CarryingSpeed;
        // ALttP NTSC uses 16/24 for walking and 13/20 for carrying before collision resolution.
        if ((Action[0] || Action[1]) && (Action[2] || Action[3])) S = ItemHolding == -4 ? S * 2 / 3 : S * 13 / 20;");
var linkCode = FlattenEnums(Read("gml_GlobalScript___Link"));
var facingStart = linkCode.IndexOf("function Facing_Check()\n{");
if (facingStart < 0) throw new Exception("Link facing function missing");
var facingEnd = linkCode.IndexOf("\nfunction CheckMoveAssist()", facingStart);
if (facingEnd < 0) throw new Exception("Link facing function boundary missing");
Edit("gml_GlobalScript___Link", linkCode.Substring(facingStart, facingEnd - facingStart), @"
function Facing_Check()
{
    if (MoveAssistDir != 0 || BounceBack || Action[9]) exit;
    // SNES keeps a facing included in the diagonal; otherwise the vertical direction wins.
    if ((Facing == 1 && vy < 0) || (Facing == 2 && vy > 0)
        || (Facing == 3 && vx < 0) || (Facing == 4 && vx > 0)) exit;
    if (vy < 0) Facing = 1;
    else if (vy > 0) Facing = 2;
    else if (vx < 0) Facing = 3;
    else if (vx > 0) Facing = 4;
}
");
using (var backports = JsonDocument.Parse(File.ReadAllText(Path.Combine(patchDir, "src/data/backports.json")))) {
    foreach (var fix in backports.RootElement.EnumerateArray()) {
        Edit(fix.GetProperty("code").GetString(), fix.GetProperty("anchor").GetString(), fix.GetProperty("replacement").GetString());
    }
}
Edit("gml_GlobalScript___input_config_verbs", "hud: input_binding_key(112)",
    "hud: input_binding_key(112), nova_bag_previous: input_binding_key(vk_pageup), nova_bag_next: input_binding_key(vk_pagedown), nova_confirm: input_binding_key(vk_control), nova_back: input_binding_key(vk_alt)");
Edit("gml_GlobalScript___input_config_verbs", "menu_input: [input_binding_gamepad_button(32778), input_binding_gamepad_button(32769)]", "menu_input: [input_binding_gamepad_button(gp_start), input_binding_gamepad_button(gp_face2)]");
Edit("gml_GlobalScript___input_config_verbs", "hud: input_binding_gamepad_button(32780)",
    "hud: input_binding_gamepad_button(32780), nova_bag_previous: input_binding_gamepad_button(gp_shoulderl), nova_bag_next: input_binding_gamepad_button(gp_shoulderr), nova_confirm: input_binding_gamepad_button(gp_face2), nova_back: input_binding_gamepad_button(gp_face1)");
Edit("gml_GlobalScript_input_profile_import", "    return _global.__players[arg2].__profile_import(arg0, arg1);", @"
    var profile = is_string(arg0) ? json_parse(arg0) : arg0;
    if (is_struct(profile) && (arg1 == ""gamepad"" || arg1 == ""keyboard"")) {
        var pad = arg1 == ""gamepad"";
        if (pad && variable_struct_exists(profile, ""menu_input"")) {
            var confirm = profile.menu_input;
            if (is_array(confirm) && array_length(confirm) == 2
                && is_struct(confirm[0]) && is_struct(confirm[1])
                && variable_struct_exists(confirm[0], ""__type"") && variable_struct_exists(confirm[0], ""__value"")
                && variable_struct_exists(confirm[1], ""__type"") && variable_struct_exists(confirm[1], ""__value"")
                && confirm[0].__type == ""gamepad button"" && confirm[0].__value == gp_start
                && confirm[1].__type == ""gamepad button"" && confirm[1].__value == gp_face1)
                confirm[1].__value = gp_face2;
        }
        // Menu Confirm and Back are fixed; profiles saved before them gain the defaults.
        var verbs = [""nova_bag_previous"", ""nova_bag_next"", ""nova_confirm"", ""nova_back""];
        var values = pad ? [gp_shoulderl, gp_shoulderr, gp_face2, gp_face1] : [vk_pageup, vk_pagedown, vk_control, vk_alt];
        for (var i = 0; i < 4; i++) {
            if (!variable_struct_exists(profile, verbs[i]))
                variable_struct_set(profile, verbs[i], [{__type: pad ? ""gamepad button"" : ""key"", __value: values[i]}, {}]);
        }
    }
    return _global.__players[arg2].__profile_import(profile, arg1);");
Edit("gml_GlobalScript___Input", "global.BindingVerbs[0] = [0, 1, 2, 3, 4, 5, 6, 7];",
    "global.BindingVerbs[0] = [0, 1, 2, 3, 4, 5, 6, 7, 12, 13];");
Edit("gml_GlobalScript___Input", "global.BindingVerbs[1] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];",
    "global.BindingVerbs[1] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];");
Edit("gml_GlobalScript___Input", "function GetInputVerbStr(arg0)\n{",
    "function GetInputVerbStr(arg0)\n{\n    if (arg0 == 12) return \"nova_bag_previous\";\n    if (arg0 == 13) return \"nova_bag_next\";");
edits["gml_GlobalScript___Input"] += "\n" + File.ReadAllText(Path.Combine(patchDir, "src/gml/input/controls.gml"));
edits["gml_GlobalScript___Input"] += "\n" + File.ReadAllText(Path.Combine(patchDir, "src/gml/menus/options.gml"));
ApplyContent();
ApplyArcade();
ApplyContextHints();
using (var corrections = JsonDocument.Parse(File.ReadAllText(Path.Combine(patchDir, "src/data/dungeon_fixes.json")))) {
    var statements = "";
    foreach (var fix in corrections.RootElement.EnumerateArray()) {
        var path = "Templates_Dungeon_Temp";
        foreach (var part in fix[0].EnumerateArray()) {
            if (part.ValueKind == JsonValueKind.Number) path += "[" + part.GetInt32() + "]";
            else {
                var member = part.GetString();
                if (!Regex.IsMatch(member, @"^[A-Za-z_][A-Za-z_0-9]*$")) throw new Exception("Invalid dungeon field");
                path += "." + member;
            }
        }
        statements += "    if (" + path + " != " + fix[1].GetInt32() + ") throw \"Dungeon patch source mismatch.\";\n";
        statements += "    " + path + " = " + fix[2].GetInt32() + ";\n";
    }
    var anchor = "    global.Templates_Dungeon = array_create(7);";
    Edit("gml_GlobalScript___Dungeon", anchor, statements + anchor);
}
var inventoryName = "gml_GlobalScript___Inventory";
var inventory = edits.ContainsKey(inventoryName) ? edits[inventoryName] : FlattenEnums(Read(inventoryName));
var additions = File.ReadAllText(Path.Combine(patchDir, "src/gml/inventory/inventory.gml"));
var functions = Regex.Matches(additions, @"(?m)^function (\w+)\(");
for (var i = 0; i < functions.Count; i++) {
    var name = functions[i].Groups[1].Value;
    var start = functions[i].Index;
    var end = i + 1 < functions.Count ? functions[i + 1].Index : additions.Length;
    var body = additions.Substring(start, end - start);
    var original = Regex.Match(inventory, @"(?ms)^function " + name + @"\(.*?(?=^function |\z)");
    if (original.Success) inventory = inventory.Substring(0, original.Index) + body + inventory.Substring(original.Index + original.Length);
    else inventory += "\n" + body.Replace("function " + name + "(", "global." + name + " = function(").TrimEnd() + ";\n";
}
edits[inventoryName] = inventory;
var candleArt = Data.Sprites.ByName("sHUD_Candle");
var candleSprite = new UndertaleSprite {
    Name = Data.Strings.MakeString("sNovaCandle"),
    Width = candleArt.Width, Height = candleArt.Height,
    OriginX = (int)candleArt.Width / 2, OriginY = (int)candleArt.Height - 1,
    MarginLeft = candleArt.MarginLeft, MarginRight = candleArt.MarginRight,
    MarginTop = candleArt.MarginTop, MarginBottom = candleArt.MarginBottom
};
foreach (var texture in candleArt.Textures) candleSprite.Textures.Add(new UndertaleSprite.TextureEntry { Texture = texture.Texture });
Data.Sprites.Add(candleSprite);
foreach (var spec in new[] { ("oNovaFoodBag", "sNovaFoodBag"), ("oNovaPendantBag", "sNovaPendantBag"), ("oNovaCandle", "sNovaCandle") }) {
    var bag = new UndertaleGameObject {
        Name = Data.Strings.MakeString(spec.Item1),
        Sprite = Data.Sprites.ByName(spec.Item2),
        ParentId = Data.GameObjects.ByName("oItem"),
        Visible = true
    };
    Data.GameObjects.Add(bag);
    group.QueueReplace("gml_Object_" + spec.Item1 + "_Create_0", "event_inherited(); ShadowOffsetY = -1; if (Class == 51) { image_index = 1; mask_index = sItem_Lamp; }");
}
group.QueueAppend("gml_Object_oInventory_Create_0", File.ReadAllText(Path.Combine(patchDir, "src/gml/inventory/inventory_ui.gml")));
group.QueueReplace("gml_Object_oInventory_Step_0", File.ReadAllText(Path.Combine(patchDir, "src/gml/inventory/inventory_step.gml")));
group.QueueReplace("gml_Object_oInventory_Draw_0", File.ReadAllText(Path.Combine(patchDir, "src/gml/inventory/inventory_draw.gml")));
group.QueueReplace("gml_Object_oInventory_Step_2", "if (Close) { Alpha -= AlphaSpeed; if (Alpha <= 0) instance_destroy(); }");
string GlobalInventoryCalls(string source) => Regex.Replace(source, @"(?<![.\w])Nova(GearSlot|BagRange|EmptyRange|EmptySlot|InventoryInit|InventoryMigrate|CandleInit)\(", "global.Nova$1(");
// The startup controller owns the scene; upstream windows remain only as bootstrap data.
edits["gml_Object_oMenu_Create_0"] += "\n" + File.ReadAllText(Path.Combine(patchDir, "src/gml/menus/adventure.gml"));
Edit("gml_Object_oMenu_Create_0", "audio_sound_gain(MenuMusic, 0.5, 0);", "audio_sound_gain(MenuMusic, 0, 0); audio_sound_gain(MenuMusic, 0.5, 350);");
var creditSource = Read("gml_Object_oCredits_Create_0");
var creditStart = creditSource.IndexOf("TextArray = [];");
var creditEnd = creditSource.IndexOf("TextArrayLen =", creditStart);
if (creditStart < 0 || creditEnd < 0) throw new Exception("Original credits boundary missing");
edits["gml_Object_oMenu_Create_0"] += "\n" + creditSource.Substring(creditStart, creditEnd - creditStart).Replace("TextArray", "NovaCredits");
edits["gml_Object_oMenu_Step_0"] = "AltTabCheck(); NovaAdventureStep(input_check_pressed(global.NovaCloseVerb()) || keyboard_check_pressed(vk_escape));";
edits["gml_Object_oMenu_Draw_0"] = "NovaAdventureDraw();";
edits["gml_Object_oMenuWin_Draw_0"] = "if (instance_exists(oMenu)) exit; draw_sprite_stretched(sprite_index, 0, x, y, W, H);";
Edit("gml_Object_oTitle_Step_0", "audio_stop_all();", @"
if (variable_global_exists(""NovaTitleFrame"") && surface_exists(global.NovaTitleFrame)) surface_free(global.NovaTitleFrame);
global.NovaTitleFrame = -1;
if (surface_exists(application_surface)) {
    global.NovaTitleFrame = surface_create(surface_get_width(application_surface), surface_get_height(application_surface));
    if (surface_exists(global.NovaTitleFrame)) surface_copy(global.NovaTitleFrame, 0, 0, application_surface);
}
if (audio_is_playing(Music)) audio_sound_gain(Music, 0, 350);
input_clear_momentary(true);");
group.QueueReplace("gml_Object_oTitle_Alarm_6", "alarm[6] = -1;");
group.QueueAppend("gml_Object_oMenu_CleanUp_0", "if (variable_global_exists(\"NovaTitleFrame\") && surface_exists(global.NovaTitleFrame)) surface_free(global.NovaTitleFrame);");
foreach (var edit in edits) group.QueueReplace(edit.Key, GlobalInventoryCalls(edit.Value));
group.Import();
Console.WriteLine("4:3 overlay patch compiled.");
