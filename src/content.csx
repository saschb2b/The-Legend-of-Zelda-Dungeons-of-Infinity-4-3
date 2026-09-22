using System;
using System.IO;
using System.Collections.Generic;
using System.Text.Json;
using System.Security.Cryptography;
using UndertaleModLib.Models;
using UndertaleModLib.Util;
void ApplyContent() {
using (var art = JsonDocument.Parse(File.ReadAllText(Path.Combine(patchDir, "assets/content-art.json"))))
using (var worker = new TextureWorker()) {
    foreach (var spec in art.RootElement.EnumerateArray()) {
        var source = Data.Sprites.ByName(spec.GetProperty("source").GetString());
        var exportPath = Path.Combine(patchDir, ".build", "art-source.png");
        worker.ExportAsPNG(source.Textures[spec.GetProperty("source_frame").GetInt32()].Texture, exportPath, null, true);
        var original = File.ReadAllBytes(exportPath);
        if (Convert.ToHexString(SHA256.HashData(original)).ToLowerInvariant() != spec.GetProperty("source_sha256").GetString())
            throw new Exception("Art patch source mismatch: " + source.Name.Content);
        var png = new byte[spec.GetProperty("size").GetInt32()];
        Array.Copy(original, png, Math.Min(original.Length, png.Length));
        foreach (var range in spec.GetProperty("ranges").EnumerateArray()) {
            var bytes = Convert.FromBase64String(range[1].GetString());
            Array.Copy(bytes, 0, png, range[0].GetInt32(), bytes.Length);
        }
        if (Convert.ToHexString(SHA256.HashData(png)).ToLowerInvariant() != spec.GetProperty("sha256").GetString())
            throw new Exception("Art patch result mismatch");
        var name = spec.GetProperty("target").GetString();
        var sprite = Data.Sprites.ByName(name);
        if (sprite == null) {
            sprite = new UndertaleSprite { Name = Data.Strings.MakeString(name), Width = source.Width, Height = source.Height,
                OriginX = source.OriginX, OriginY = source.OriginY, MarginLeft = source.MarginLeft, MarginRight = source.MarginRight,
                MarginTop = source.MarginTop, MarginBottom = source.MarginBottom };
            foreach (var mask in source.CollisionMasks) sprite.CollisionMasks.Add(new UndertaleSprite.MaskEntry((byte[])mask.Data.Clone(), mask.Width, mask.Height));
            Data.Sprites.Add(sprite);
        }
        if (name == "sNovaWallmaster") {
            sprite.Width = (uint)spec.GetProperty("width").GetInt32();
            sprite.Height = (uint)spec.GetProperty("height").GetInt32();
            sprite.OriginX = (int)sprite.Width / 2;
            sprite.OriginY = (int)sprite.Height - 1;
            sprite.CollisionMasks.Clear();
        }
        var texture = new UndertaleEmbeddedTexture { Name = new UndertaleString(name) };
        texture.TextureData.Image = GMImage.FromPng(png);
        Data.EmbeddedTextures.Add(texture);
        var page = new UndertaleTexturePageItem { Name = new UndertaleString(name),
            SourceWidth = (ushort)sprite.Width, SourceHeight = (ushort)sprite.Height,
            TargetWidth = (ushort)sprite.Width, TargetHeight = (ushort)sprite.Height,
            BoundingWidth = (ushort)sprite.Width, BoundingHeight = (ushort)sprite.Height, TexturePage = texture };
        Data.TexturePageItems.Add(page);
        var frame = spec.GetProperty("frame").GetInt32();
        if (frame == sprite.Textures.Count) sprite.Textures.Add(new UndertaleSprite.TextureEntry { Texture = page });
        else sprite.Textures[frame].Texture = page;
    }
}
var content = JsonDocument.Parse(File.ReadAllText(Path.Combine(patchDir, "src/data/content_1_2_1.json"))).RootElement;
var gemIndices = new List<int>();
var gemNames = new string[10];
var gemRanks = new int[10];
for (var rank = 0; rank < 10; rank++) {
    var index = content.GetProperty("save_indices")[rank].GetInt32();
    gemIndices.Add(index);
    gemNames[index] = content.GetProperty("gem_order")[rank].GetString();
    gemRanks[index] = rank;
}
var gemCode = "global.GemNames = " + JsonSerializer.Serialize(gemNames) + ";\n";
gemCode += "global.NovaGemRanks = " + JsonSerializer.Serialize(gemRanks) + ";\n";
var choices = new List<int>();
for (var rank = 0; rank < 10; rank++)
    for (var weight = 0; weight < content.GetProperty("drop_weights")[rank].GetInt32(); weight++) choices.Add(gemIndices[rank]);
gemCode += "function Gem_PickIndex() { return choose(" + string.Join(",", choices) + "); }\n";
gemCode += "function InitGemPrizes() { global.GemPrize = array_create(10);\n";
for (var row = 0; row < 10; row++) {
    var recipes = content.GetProperty("recipes")[row];
    if (recipes.GetArrayLength() != row + 1) throw new Exception("Incomplete gem recipe row");
    for (var col = 0; col <= row; col++) {
        var hi = Math.Max(gemIndices[row], gemIndices[col]);
        var lo = Math.Min(gemIndices[row], gemIndices[col]);
        gemCode += "global.GemPrize[" + hi + "][" + lo + "] = " + recipes[col].GetRawText() + ";\n";
    }
}
gemCode += "}\n" + File.ReadAllText(Path.Combine(patchDir, "src/gml/gameplay/gems.gml"));
group.QueueReplace("gml_GlobalScript___Gems", gemCode);
Edit("gml_Object_oGemPondWater_Create_0", "GemCount = array_create(9);", "GemCount = array_create(10);");
Edit("gml_GlobalScript___Users", "    global.Challenges = StructCopy(global.Users[global.UserIndex].SaveData.Challenges);",
    "    global.NovaGemSaveInit();\n    global.Challenges = StructCopy(global.Users[global.UserIndex].SaveData.Challenges);");
Edit("gml_Object_oZora_Alarm_3", "var _Rupees = false;", "var _Rupees = GemPrize.Class == 40;");
Edit("gml_Object_oZora_Alarm_3", "(_Gem1 + 1) * (_Gem2 + 1)", "(global.NovaGemRanks[_Gem1] + 1) * (global.NovaGemRanks[_Gem2] + 1)");
Edit("gml_GlobalScript___Link", "Item_Get(39, 0, 16);", "Item_Get(39, 0, Inventory_MaxAmount(39, 0));");
var challengeData = content.GetProperty("challenges");
var challengeCode = "";
foreach (var field in new[] { "Hearts", "Defense", "Rupees", "ShopPrices", "Curses" })
    challengeCode += "global.NovaChallenge" + field + " = " + challengeData.GetProperty("ChallengeMaxArray_" + field).GetRawText() + ";\n";
group.QueueAppend("gml_GlobalScript___Menu", challengeCode + File.ReadAllText(Path.Combine(patchDir, "src/gml/gameplay/challenges.gml")));
Edit("gml_Object_oMenu_Create_0", "depth = -100;", "depth = -100;\n" + File.ReadAllText(Path.Combine(patchDir, "src/gml/menus/challenge_menu.gml")));
Edit("gml_GlobalScript___Users", "    global.Users[global.UserIndex].SaveData.Challenges = StructCopy(global.Challenges);",
    "    global.Users[global.UserIndex].SaveData.Challenges = StructCopy(global.Challenges);\n    global.Users[global.UserIndex].SaveData.NovaChallengeOptions = StructCopy(global.NovaChallengeOptions);");
Edit("gml_GlobalScript___Users", "    global.Challenges = StructCopy(global.Users[global.UserIndex].SaveData.Challenges);",
    "    global.Challenges = StructCopy(global.Users[global.UserIndex].SaveData.Challenges);\n    global.NovaLoadChallenges(global.Users[global.UserIndex].SaveData);");
Edit("gml_Object_oMenu_Create_0", "global.Challenges = array_create(7, false);", "global.NovaResetChallenges();");
void ContentReplaceAll(string name, string anchor, string replacement, int count) {
    var code = edits.ContainsKey(name) ? edits[name] : FlattenEnums(Read(name));
    if (code.Split(new[] { anchor }, StringSplitOptions.None).Length - 1 != count) throw new Exception("Content anchor count: " + name + " / " + anchor);
    edits[name] = code.Replace(anchor, replacement);
}
foreach (var entry in new[] { ("gml_Object_oZora_Alarm_3", 1), ("gml_GlobalScript___Food", 1),
    ("gml_Object_oShop_Create_0", 1), ("gml_Object_oFairy_Health_Step_0", 1), ("gml_GlobalScript___Items", 5) })
    ContentReplaceAll(entry.Item1, "global.Challenges[0] ? 5 : 16", "global.NovaMaxHearts()", entry.Item2);
Edit("gml_GlobalScript___Link", "global.Inventory_ItemData[18].Amount = 4;", "global.Inventory_ItemData[18].Amount = 4 - global.NovaOption(0);");
Edit("gml_GlobalScript___Link", "return max(DefensePoints, 0);", "return clamp(DefensePoints, 0, global.NovaChallengeDefense[global.NovaOption(2)]);");
Edit("gml_GlobalScript___Items", "    return Price;", "    return Price * global.NovaChallengeShopPrices[global.NovaOption(6)];");
Edit("gml_GlobalScript___Items", "Price = 10 + (arg1 * 3);", "Price = 10 + (global.NovaGemRanks[arg1] * 3);");
Edit("gml_GlobalScript___Items", "function Item_Allowed(arg0, arg1 = -1, arg2 = 22)\n{",
    "function Item_Allowed(arg0, arg1 = -1, arg2 = 22)\n{\n    if (global.NovaOption(10) && (arg0 == 13 || arg0 == 49)) return false;");
Edit("gml_Object_oShop_Create_0", "Slots = global.Challenges[5] ? 0 : Shop_GetSlotCount();",
    "Slots = (global.Challenges[5] || (global.NovaOption(10) && ShopType == 2)) ? 0 : Shop_GetSlotCount();");
Edit("gml_GlobalScript___Dungeon_Draw_SpecialObjs_Forced", "case 260:\n                var PizzaInst", "case 260:\n                if (global.NovaOption(10)) break;\n                var PizzaInst");
Edit("gml_Object_oZora_Alarm_3", "var _Rupees = GemPrize.Class == 40;",
    "var _Rupees = GemPrize.Class == 40 || (global.NovaOption(10) && (GemPrize.Class == 13 || GemPrize.Class == 49));");
Edit("gml_Object_oHUD_Step_2", "_InvRupees.Amount = max(_InvRupees.Amount + Increment, 0);",
    "_InvRupees.Amount = global.NovaRupeeLimit(_InvRupees.Amount + Increment);\n    if (Increment > 0 && _InvRupees.Amount == global.NovaChallengeRupees[global.NovaOption(5)]) AddRupees = 0;");
Edit("gml_GlobalScript___Chance", "if (global.Challenges[4])", "if (global.Challenges[4] || global.NovaOption(3) >= 2)");
Edit("gml_GlobalScript___Chance", "return Prob(P);", "return Prob(min(1, P + global.NovaOption(3) * 0.3));");
Edit("gml_GlobalScript___Dungeon_Draw_SpecialObjs", "PackPoints_Min = PackPoints_Min * _RoomSizeFactor;", "PackPoints_Min = PackPoints_Min * _RoomSizeFactor * (1 + global.NovaOption(7));");
Edit("gml_GlobalScript___Dungeon_Draw_SpecialObjs", "PackPoints_Max = PackPoints_Max * _RoomSizeFactor;", "PackPoints_Max = PackPoints_Max * _RoomSizeFactor * (1 + global.NovaOption(7));");
Edit("gml_GlobalScript___Dungeon_Draw_SpecialObjs", "min(irandom_range(PackPoints_Min, PackPoints_Max), 30)", "min(irandom_range(PackPoints_Min, PackPoints_Max), 30 * (1 + global.NovaOption(7)))");
Edit("gml_GlobalScript___Treasures", "Prob(0.055 + (global.Level.Index * 0.005))", "Prob((0.055 + (global.Level.Index * 0.005)) * global.NovaChallengeCurses[global.NovaOption(8)])");
Edit("gml_Object_oDeadGuy_Step_0", "(0.2 + (global.Level.Index * 0.005))", "((0.2 + (global.Level.Index * 0.005)) * global.NovaChallengeCurses[global.NovaOption(8)])");
var hand = new UndertaleGameObject { Name = Data.Strings.MakeString("oNovaWallmaster"), Sprite = Data.Sprites.ByName("sNovaWallmaster"), Visible = true };
Data.GameObjects.Add(hand);
group.QueueReplace("gml_Object_oNovaWallmaster_Create_0", File.ReadAllText(Path.Combine(patchDir, "src/gml/gameplay/wallmaster_create.gml")));
group.QueueReplace("gml_Object_oNovaWallmaster_Step_0", File.ReadAllText(Path.Combine(patchDir, "src/gml/gameplay/wallmaster_step.gml")));
group.QueueReplace("gml_Object_oNovaWallmaster_Draw_0", File.ReadAllText(Path.Combine(patchDir, "src/gml/gameplay/wallmaster_draw.gml")));
group.QueueAppend("gml_Object_oLink_Step_2", @"
if (global.NovaOption(11) && global.Level.Index > 0 && global.Level.Index < 13 && global.Level.Index != 6 && global.Level.Index != 10 && !instance_exists(oNovaWallmaster))
    instance_create_layer(x - 80, y, ""ObjsHighest"", oNovaWallmaster);");

}
