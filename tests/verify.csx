using System;
using System.Linq;
using System.Text.RegularExpressions;
using UndertaleModLib.Util;
void Check(bool value, string message) {
    if (!value) throw new Exception(message);
}
string Code(string name) {
    var code = GetDecompiledText(name, null, new Underanalyzer.Decompiler.DecompileSettings());
    return Regex.Replace(code, @"UnknownEnum\.Value_(\d+)", "$1");
}
Check(Data.Rooms.ByName("Room_Title").Views[0].ViewWidth == 300, "Title must use the 4:3 view");
Check(Data.Rooms.ByName("Room_Menu").Views[0].ViewHeight == 300, "Menus must fit vertically");
var buttons = Data.Sprites.ByName("sNovaButtons");
Check(buttons.Width == 128 && buttons.Height == 128 && buttons.Textures.Count == 24, "Controller glyph frames missing or resized");
Check(Data.Sprites.ByName("sItem_Gem").Textures.Count == 10, "Topaz texture missing");
foreach (var name in new[] { "sNovaFoodBag", "sNovaPendantBag" }) {
    var bag = Data.Sprites.ByName(name);
    Check(bag.Textures.Count == 1 && bag.Width == 16 && bag.Height == 16, "Bag texture bounds changed: " + name);
    Check(bag.MarginLeft == 1 && bag.MarginRight == 14 && bag.MarginTop == 0 && bag.MarginBottom == 15, "Bag pickup bounds changed: " + name);
}
var hand = Data.Sprites.ByName("sNovaWallmaster");
Check(hand.Textures.Count == 2 && hand.Width == 24 && hand.Height == 23, "Wallmaster texture bounds changed");
Check(Code("gml_Object_oTitle_Step_0").Contains("global.CanSkipTitle"), "Title skip option missing");
var menuDraw = Code("gml_Object_oMenu_Draw_0");
var menuCreate = Code("gml_Object_oMenu_Create_0");
Check(menuDraw.Contains("NovaAdventureDraw()") && menuCreate.Contains("NovaDraft") && menuCreate.Contains("Previous bag"), "Adventure, challenge and control paths must coexist");
Check(Code("gml_Object_oMenu_Step_0").Contains("keyboard_check_pressed(vk_escape)"), "Menu cancel missing");
Check(menuCreate.Contains("NovaUpdateOpen = false") && menuCreate.Contains("NovaUpdateDraw()"), "Updater menu initialization and drawing must coexist");
Check(Code("gml_Object_oMenuWin_Draw_0").Contains("instance_exists(oMenu)"), "Startup must suppress inactive parent windows");
Check(Code("gml_Object_oMenu_Game_Step_0").Contains("global.NovaCloseVerb()"), "Pause cancel missing");
Check(Code("gml_Object_oEnemy_Medusa_Alarm_0").Contains("Stoned"), "Medusa status guard missing");
Check(Code("gml_Object_oEnemy_Cannon_Step_0").Contains("!Stoned"), "Cannon status guard missing");
Check(Code("gml_Object_oEnemy_Pikit_Tongue_Step_0").Contains("oLink.State != 20"), "Pikit falling guard missing");
Check(Code("gml_Object_oSword_Draw_0").Contains("oLink.NovaSwordIsCharged()"), "Sword charge cue must use the attack readiness condition");
Check(!Data.GameObjects.Any(obj => obj.Name.Content == "oNovaTests"), "Test object leaked into production");
Check(!Data.Code.Any(code => code.Name.Content.Contains("NovaTest")), "Test code leaked into production");
Check(!Data.GameObjects.Any(obj => obj.Name.Content == "oNovaVillageTest"), "Village preview leaked into production");
Check(Data.GameObjects.ByName("oClawMachine").ParentId == Data.GameObjects.ByName("oPopMachine"), "Claw must share interaction and room cleanup with machines");
Check(Data.GameObjects.ByName("oArcade_Mothula").ParentId == Data.GameObjects.ByName("oArcade"), "Slot must inherit arcade placement");
Check(Data.Sprites.ByName("sClawMachine_Window").Textures.Count == 6, "Claw prize frames missing");
Check(Data.Sprites.ByName("sArcade_Mothula_Symbols").Textures.Count == 6, "Slot symbols missing");
var spinButton = Data.Sprites.ByName("sPoker_Button_Spin");
Check(spinButton != null && spinButton.Width == 26 && spinButton.Height == 11, "Original slot Spin button missing");
var iconSlice = Data.Sprites.ByName("sArcade_Mothula_Icon_Cherry").V3NineSlice;
Check(iconSlice != null && iconSlice.Enabled && (int)iconSlice.TileModes[4] == 1, "Slot payout icons must repeat instead of stretching");
var clawSlice = Data.Sprites.ByName("sClawMachine_Claw").V3NineSlice;
Check(clawSlice != null && clawSlice.Enabled && clawSlice.Top == 2 && clawSlice.Bottom == 5, "Claw cable must extend without stretching its tips");
foreach (var name in new[] { "sClawMachine", "sArcade_Mothula" }) {
    Check(Data.Sprites.ByName(name).CollisionMasks.Count == 1, "Cabinet collision mask missing: " + name);
}
foreach (var sound in Data.Sounds.Where(sound => sound.Name.Content.Contains("ClawMachine") || sound.Name.Content.StartsWith("Sound_Slot"))) {
    Check(sound.AudioFile != null && sound.AudioFile.Data.Length > 44 && sound.GroupID == Data.GetBuiltinSoundGroupID(), "Arcade audio must be embedded: " + sound.Name.Content);
}
Console.WriteLine("NOVA BUILD VERIFIED");
