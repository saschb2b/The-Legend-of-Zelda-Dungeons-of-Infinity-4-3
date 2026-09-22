using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

void ApplyContextHints() {
    var name = "gml_GlobalScript___Link";
    var source = edits[name];
    string Function(string function) {
        var match = Regex.Match(source, @"(?ms)^function " + function + @"\(.*?(?=^function |\z)");
        if (!match.Success) throw new Exception("Interaction function missing: " + function);
        return match.Value.TrimEnd();
    }
    var probe = Function("Interact").Replace("function Interact()", "function NovaInteractionProbe()");
    void Replace(string anchor, string replacement) { probe = ReplaceOnce(probe, anchor, replacement); }
    void Range(string first, string last, string replacement) {
        var start = probe.IndexOf(first, StringComparison.Ordinal);
        if (start < 0) throw new Exception("Interaction branch missing: " + first);
        var end = probe.IndexOf(last, start, StringComparison.Ordinal);
        if (end < 0) throw new Exception("Interaction branch end missing: " + last);
        Replace(probe.Substring(start, end + last.Length - start), replacement);
    }
    // Build the hint query from the patched interaction predicates and their priority.
    // Only local query state survives; the gameplay interaction function is untouched.
    Replace("MsgBox(\"Take a break? Save and quit?\", true);\n                SaveTentInst.DB_Started = true;", "return \"SAVE\";");
    Replace("UpdateState(10);", "return \"THROW\";");
    Replace("UpdateState(8);\n        Treasure_Open(TreasureInst);", "return \"OPEN\";");
    Replace("UpdateState(8);\n        TreasureLarge_Open(TreasureInst);", "return \"OPEN\";");
    Range("ds_list_clear(CollidedShopItemList);", "\n                    }\n                }", "if (NovaShopCandidate() != noone) return \"INSPECT\";\n                }");
    Replace("KinstoneInst.DB_Init = true;", "return \"FUSE\";");
    Replace("SignInst.DB_Init = true;", "return \"READ\";");
    Replace("InventoryFullInst != -4", "instance_exists(InventoryFullInst)");
    Range("var _ItemInst = InventoryFullInst.ItemInst;", "            exit;", "return \"USE\";");
    Replace("CanPickupInst = CheckPickupItem(InventoryFullInst.ItemInst);", "CanPickupInst = NovaPickupCandidate(InventoryFullInst.ItemInst);");
    Replace("if (CanPickupInst != -4)\n            {\n                exit;", "if (CanPickupInst != -4)\n            {\n                return CanPickupInst.ShopItem ? \"\" : \"LIFT\";");
    foreach (var obj in new[] { "oItem_Orb", "oItem_Bombs", "oItem_Gem", "oItem_WishStone" })
        Replace("if (CheckPickupItem(" + obj + ") != -4)\n        {\n            exit;\n        }", "var candidate = NovaPickupCandidate(" + obj + ");\n        if (candidate != noone) return candidate.ShopItem ? \"\" : \"LIFT\";");
    Range("UpdateState(6, Inst);", "            exit;", "return \"LIFT\";");
    Replace("Inst.Lighting = true;", "return \"LIGHT\";");
    Range("Curtain_Reveal(Inst);", "                exit;", "return \"BURN\";");
    Replace("DeadGuyInst.DB_Init = true;", "return \"TALK\";");
    Replace("HeartGuyInst.DB_Init = true;", "return \"TALK\";");
    Replace("NPCInst.DB_Init = true;", "return NPCInst.DialogueIgnore || NPCInst.DB_Delay ? \"\" : \"TALK\";");
    Replace("OldLadyInst.Wake_Init = true;\n                    global.Paused = true;\n                    UpdateState(0);", "return \"TALK\";");
    Replace("UpdateState(6, Inst);", "return \"LIFT\";");
    Replace("PopMachineInst.DB_Init = true;", "return \"INSPECT\";");
    Replace("Inst.Index = floor((x - Inst.x) / 18);\n                    Inst.PlayNoteInit = true;", "return \"PLAY\";");
    Replace("PrisonerInst.DB_Init = true;", "return \"TALK\";");
    probe = probe.Replace("exit;", "return \"\";");
    probe = probe.Insert(probe.LastIndexOf('}'), "    return \"\";\n");
    var pickup = Function("CheckPickupItem").Replace("function CheckPickupItem(", "function NovaPickupCandidate(");
    pickup = ReplaceOnce(pickup, "            UpdateState(6, arg1);", "            return arg1;");
    var shop = @"
function NovaShopCandidate() {
    var items = ds_list_create();
    var count = collision_rectangle_list(x - 4, y - 30, x + 4, y - 16, oItem, false, true, items, false);
    var found = noone;
    for (var i = 0; i < count; i++) {
        var item = ds_list_find_value(items, i);
        if (item != noone && item.ShopItem && FromAnyStore(item.From)) { found = item; break; }
    }
    ds_list_destroy(items);
    return found;
}
";
    var queries = probe + "\n" + pickup + "\n" + shop;
    var allowed = new HashSet<string> { "NovaInteractionProbe", "NovaPickupCandidate", "NovaShopCandidate", "if", "for", "switch", "with", "instance_exists", "instance_position", "instance_place", "collision_rectangle", "collision_rectangle_list", "Collision_CheckFloorLevel", "FromAnyStore", "Door_LocationToDir", "ds_list_create", "ds_list_destroy", "ds_list_find_value" };
    foreach (Match call in Regex.Matches(queries, @"\b(\w+)\s*\("))
        if (!allowed.Contains(call.Groups[1].Value)) throw new Exception("Unreviewed interaction query call: " + call.Value);
    if (Regex.IsMatch(queries, @"\b\w+\.\w+\s*(?:=(?!=)|\+=|-=|\+\+|--)"))
        throw new Exception("Interaction query writes instance state");
    group.QueueAppend("gml_Object_oLink_Create_0", queries);
}
