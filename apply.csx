using System;
using System.IO;
using System.Collections.Generic;
using System.Text.Json;
using System.Text.RegularExpressions;
using UndertaleModLib.Compiler;
using UndertaleModLib.Models;
using UndertaleModLib.Util;
// The bundled runner expects a FUNC locals table. The upstream empty table is
// mistaken for 2024.8 alignment padding by the tool's version detection.
Data.SetGMS2Version(2024, 6);
Data.FORM.FUNC.CodeLocals ??= new UndertaleModLib.UndertaleSimpleList<UndertaleCodeLocals>();
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
group.QueueAppend("gml_Object_oLink_Create_0", File.ReadAllText(Path.Combine(patchDir, "sword.gml")));
group.QueueAppend("gml_Object_oLink_Create_0", "NovaCrystalHold = false; NovaCrystalTicks = 0;");
using (var backports = JsonDocument.Parse(File.ReadAllText(Path.Combine(patchDir, "backports.json")))) {
    foreach (var fix in backports.RootElement.EnumerateArray()) {
        Edit(fix.GetProperty("code").GetString(), fix.GetProperty("anchor").GetString(), fix.GetProperty("replacement").GetString());
    }
}
using (var corrections = JsonDocument.Parse(File.ReadAllText(Path.Combine(patchDir, "dungeon_fixes.json")))) {
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
var additions = File.ReadAllText(Path.Combine(patchDir, "inventory.gml"));
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
foreach (var spec in new[] { ("oNovaFoodBag", "sItem_GemBag"), ("oNovaPendantBag", "sItem_BombBag"), ("oNovaCandle", "sNovaCandle") }) {
    var bag = new UndertaleGameObject {
        Name = Data.Strings.MakeString(spec.Item1),
        Sprite = Data.Sprites.ByName(spec.Item2),
        ParentId = Data.GameObjects.ByName("oItem"),
        Visible = true
    };
    Data.GameObjects.Add(bag);
    group.QueueReplace("gml_Object_" + spec.Item1 + "_Create_0", "event_inherited(); ShadowOffsetY = -1; if (Class == 51) { image_index = 1; mask_index = sItem_Lamp; }");
}
group.QueueAppend("gml_Object_oInventory_Create_0", File.ReadAllText(Path.Combine(patchDir, "inventory_ui.gml")));
group.QueueReplace("gml_Object_oInventory_Step_0", File.ReadAllText(Path.Combine(patchDir, "inventory_step.gml")));
group.QueueReplace("gml_Object_oInventory_Draw_0", File.ReadAllText(Path.Combine(patchDir, "inventory_draw.gml")));
group.QueueReplace("gml_Object_oInventory_Step_2", "if (Close) { Alpha -= AlphaSpeed; if (Alpha <= 0) instance_destroy(); }");
string GlobalInventoryCalls(string source) => Regex.Replace(source, @"(?<![.\w])Nova(GearSlot|BagRange|EmptyRange|EmptySlot|InventoryInit|InventoryMigrate|CandleInit)\(", "global.Nova$1(");
foreach (var edit in edits) group.QueueReplace(edit.Key, GlobalInventoryCalls(edit.Value));
group.Import();
Console.WriteLine("4:3 overlay patch compiled.");
