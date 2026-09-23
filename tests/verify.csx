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
// Rooms keep their 4:3 defaults; oNovaScreen widens the views to the display at runtime.
Check(Data.Rooms.ByName("Room_Title").Views[0].ViewWidth == 300, "Title must default to the 4:3 view");
Check(Data.Rooms.ByName("Room_Menu").Views[0].ViewHeight == 300, "Menus must fit vertically");
var screen = Code("gml_Object_oNovaScreen_Create_0");
Check(screen.Contains("camera_set_view_size(view_camera[0]") && screen.Contains("global.NovaMenuInset") && screen.Contains("window_get_width()"), "Start screens must follow the display shape");
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
Check(menuDraw.Contains("NovaAdventureDraw()") && menuCreate.Contains("NovaDraft") && menuCreate.Contains("global.NovaOptionsStep(NovaOptions") && Code("gml_GlobalScript___Input").Contains("Previous bag"), "Adventure, challenge and control paths must coexist");
Check(Code("gml_Object_oMenu_Game_Step_0").Contains("global.NovaOptionsStep(NovaOptions") && Code("gml_Object_oMenu_Game_Step_0").Contains("NovaPauseDialog"), "Pause must use the redesigned menu and shared Options screen");
Check(!Code("gml_Object_oMenu_Game_Draw_0").Contains("draw_text(TextPosX"), "The original pause list must not draw");
Check(Code("gml_Object_oRender_Draw_64").Contains("global.NovaPauseOverlay("), "Pause must draw after the CRT pass");
foreach (var name in new[] { "gml_Object_oInputRemap_Create_0", "gml_GlobalScript___Input" })
    Check(!Code(name).Contains("oMenu.Bindings_Remap") && Code(name).Contains("global.NovaRemapping"), "Remapping must not require the adventure menu: " + name);
Check(Code("gml_Object_oMenu_Step_0").Contains("keyboard_check_pressed(vk_escape)"), "Menu cancel missing");
Check(menuCreate.Contains("NovaUpdateOpen = false") && menuCreate.Contains("NovaUpdateDraw()"), "Updater menu initialization and drawing must coexist");
Check(Code("gml_Object_oMenuWin_Draw_0").Contains("instance_exists(oMenu)"), "Startup must suppress inactive parent windows");
Check(Code("gml_Object_oMenu_Game_Step_0").Contains("global.NovaCloseVerb()"), "Pause cancel missing");
Check(Code("gml_Object_oEnemy_Medusa_Alarm_0").Contains("Stoned"), "Medusa status guard missing");
Check(Code("gml_Object_oEnemy_Cannon_Step_0").Contains("!Stoned"), "Cannon status guard missing");
Check(Code("gml_Object_oEnemy_Pikit_Tongue_Step_0").Contains("oLink.State != 20"), "Pikit falling guard missing");
Check(Code("gml_Object_oSword_Draw_0").Contains("oLink.NovaSwordIsCharged()"), "Sword charge cue must use the attack readiness condition");
Check(Code("gml_Object_oRender_Step_2").Contains("global.NovaContextUpdate(delta_time / 1000000)"), "Context animation must advance once per End Step using elapsed time");
var compositor = Code("gml_Object_oRender_Draw_64");
Check(Data.Shaders.ByName("shd_NovaCRT").GLSL_ES_Fragment.Content.Contains("vec3 Bloom("), "CRT-Lottes shader missing");
var crtPosition = compositor.IndexOf("NovaCRT_Draw(NovaFrame");
Check(crtPosition >= 0 && crtPosition < compositor.IndexOf("NovaHUD_Draw(_nova_layout)"), "CRT must leave the HUD unfiltered");
Check(compositor.IndexOf("draw_surface_stretched(NovaFrame") < compositor.IndexOf("NovaHUD_Draw(_nova_layout)"), "HUD must be composed after world scaling");
Check(compositor.Contains("gpu_set_texfilter(false)") && compositor.Contains("gpu_set_texfilter(_nova_filter)"), "HUD must use nearest-neighbor scaling and restore filtering");
Check(!Regex.IsMatch(compositor, @"_nova_[wh] / (256|224)"), "Compositor prompts must use the HUD layout, not the world scale");
Check(compositor.Contains("NovaCRT_Draw(NovaFrame, _nova_ww, _nova_wh, _nova_wx, _nova_wy)") && compositor.Contains("draw_surface_stretched(NovaFrame, _nova_wx, _nova_wy, _nova_ww, _nova_wh)"), "The playfield must keep its shape inside the screen");
Check(compositor.Contains("global.NovaPauseOverlay(oMenu_Game, _nova_ww, _nova_wh, _nova_wx, _nova_wy)"), "Pause must stay over the playfield");
foreach (var caller in new[] { "global.NovaInventoryPrompts(oInventory, _nova_layout)", "global.NovaArcadePrompts(_nova_layout)" })
    Check(compositor.Contains(caller), "Prompt layer must receive the HUD layout: " + caller);
foreach (var name in new[] { "gml_GlobalScript___Input", "gml_GlobalScript___Arcade" })
    Check(!Code(name).Contains("display_get_gui_width() / 256"), "Prompt helpers must size from the HUD layout: " + name);
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
