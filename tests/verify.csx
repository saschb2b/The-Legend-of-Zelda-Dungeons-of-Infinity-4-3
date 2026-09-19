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
Check(buttons.Width == 128 && buttons.Height == 128 && buttons.Textures.Count == 23, "Controller glyph frames missing or resized");
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
Check(menuDraw.Contains("NovaChallengeDraw()") && menuDraw.Contains("Previous bag") && menuDraw.Contains("Next bag"), "Challenge and control menu patches must coexist");
Check(Code("gml_Object_oMenu_Step_0").Contains("keyboard_check_pressed(vk_escape)"), "Menu cancel missing");
Check(Code("gml_Object_oMenu_Game_Step_0").Contains("global.NovaCloseVerb()"), "Pause cancel missing");
Check(Code("gml_Object_oEnemy_Medusa_Alarm_0").Contains("Stoned"), "Medusa status guard missing");
Check(Code("gml_Object_oEnemy_Cannon_Step_0").Contains("!Stoned"), "Cannon status guard missing");
Check(Code("gml_Object_oEnemy_Pikit_Tongue_Step_0").Contains("oLink.State != 20"), "Pikit falling guard missing");
Check(Code("gml_Object_oSword_Draw_0").Contains("oLink.NovaSwordIsCharged()"), "Sword charge cue must use the attack readiness condition");
Check(!Data.GameObjects.Any(obj => obj.Name.Content == "oNovaTests"), "Test object leaked into production");
Check(!Data.Code.Any(code => code.Name.Content.Contains("NovaTest")), "Test code leaked into production");
Console.WriteLine("NOVA BUILD VERIFIED");
