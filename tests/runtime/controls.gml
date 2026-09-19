function ControlTests() {
    if (!variable_global_exists("NovaBinding")) { Record("binding-aware controls are available", false); return; }
    var profile_before = input_profile_get();
    var gamepad_before = input_profile_export("gamepad");
    var keyboard_before = input_profile_export("keyboard");
    var buttons = [gp_face1, gp_face2, gp_face3, gp_face4, gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb, gp_select, gp_stickl, gp_stickr, gp_padu, gp_padd, gp_padl, gp_padr];
    input_profile_set("gamepad");
    for (var i = 0; i < array_length(buttons); i++) {
        input_binding_set("hud", input_binding_gamepad_button(buttons[i]), 0, 0, "gamepad");
        Record("status glyph follows remapped button " + string(buttons[i]), global.NovaGlyph(global.NovaBinding("hud")) == i);
    }
    for (var axis = gp_axislh; axis <= gp_axisrv; axis++) {
        for (var negative = 0; negative < 2; negative++) {
            var binding = input_binding_gamepad_axis(axis, negative == 1);
            Record("stick direction glyph " + string(axis) + "/" + string(negative), global.NovaGlyph(binding) == 15 + (axis - gp_axislh) * 2 + (negative == 1 ? 0 : 1));
        }
    }
    input_binding_set("hud", input_binding_empty(), 0, 0, "gamepad");
    input_binding_set("hud", input_binding_gamepad_button(gp_face4), 0, 1, "gamepad");
    Record("status falls back to the populated alternate binding", global.NovaGlyph(global.NovaBinding("hud")) == 3);
    input_binding_set("hud", input_binding_empty(), 0, 1, "gamepad");
    Record("unbound status never claims R3", global.NovaGlyph(global.NovaBinding("hud")) == -1 && global.NovaKeyLabel(global.NovaBinding("hud")) == "UNBOUND");
    input_profile_set("keyboard");
    input_binding_set("hud", input_binding_key(ord("K")), 0, 0, "keyboard");
    Record("keyboard status uses the remapped key", global.NovaGlyph(global.NovaBinding("hud")) == -1 && global.NovaKeyLabel(global.NovaBinding("hud")) == "K");
    input_profile_import(gamepad_before, "gamepad");
    input_profile_import(keyboard_before, "keyboard");
    input_profile_set("gamepad");
    Record("shoulders default to previous and next bag", global.NovaGlyph(global.NovaBinding("nova_bag_previous")) == 4 && global.NovaGlyph(global.NovaBinding("nova_bag_next")) == 5);
    var legacy = json_parse(gamepad_before);
    variable_struct_remove(legacy, "nova_bag_previous");
    variable_struct_remove(legacy, "nova_bag_next");
    input_profile_import(legacy, "gamepad");
    Record("old controller profiles gain shoulders without losing bindings", input_profile_export("gamepad") == gamepad_before);
    input_binding_set("nova_bag_previous", input_binding_empty(), 0, 0, "gamepad");
    var unbound = input_profile_export("gamepad");
    input_profile_import(unbound, "gamepad");
    Record("explicitly unbound shoulders remain unbound on reload", global.NovaBinding("nova_bag_previous").__type == undefined);
    input_profile_import(gamepad_before, "gamepad");
    legacy = json_parse(keyboard_before);
    variable_struct_remove(legacy, "nova_bag_previous");
    variable_struct_remove(legacy, "nova_bag_next");
    input_profile_import(legacy, "keyboard");
    Record("old keyboard profiles gain page keys without losing bindings", input_profile_export("keyboard") == keyboard_before);

    var inventory_before = StructCopy(global.Inventory);
    var items_before = StructCopy(global.Inventory_ItemData);
    var equipped_before = global.Inventory_SlotIndex_Equiped;
    Inventory_InitData();
    var ui = instance_create_layer(0, 0, "System", oInventory);
    ui.Open = false;
    ui.Alpha = 1;
    global.InventoryInst = ui;
    Record("inventory leaves room for the full HUD", global.NovaInventoryHUD() && ui.Y - oCamera.Y >= 64 && ui.X - oCamera.X >= 24 && ui.X + ui.W <= oCamera.X + 232 && ui.Y + ui.H + 23 <= oCamera.Y + 224);
    PressEvent(ui, "nova_bag_previous", oInventory, ev_step, ev_step_normal);
    Record("left shoulder opens gear from items", ui.NovaPage == 0);
    PressEvent(ui, "nova_bag_previous", oInventory, ev_step, ev_step_normal);
    Record("left shoulder wraps to the last owned bag page", ui.NovaPage == 2);
    PressEvent(ui, "nova_bag_next", oInventory, ev_step, ev_step_normal);
    Record("right shoulder wraps to gear", ui.NovaPage == 0);
    Record("empty slots have no confirm prompt", global.NovaInventoryAction(ui) == "");
    ui.NovaCell = 4;
    with (ui) { NovaRefresh(); NovaItemMenu(); }
    Record("confirm opens actions for the highlighted item", ui.MenuEnable);
    Record("active gear has no redundant equip action", !ds_grid_get(ui.MenuItemGrid, 1, 0) && !ds_grid_get(ui.MenuItemGrid, 1, 1));
    var action_labels = ["EQUIP", "USE", "DROP", "INFO"];
    for (var action = 0; action < 4; action++) {
        ui.MenuSelectionIndex = action;
        Record("confirm prompt names action " + string(action), global.NovaInventoryAction(ui) == action_labels[action]);
    }
    PressEvent(ui, "sword", oInventory, ev_step, ev_step_normal);
    Record("item information keeps the HUD visible", global.NovaInventoryInfo() && global.NovaInventoryHUD());
    PressEvent(global.DB_Inst, "action", oDialogueBox, ev_step, ev_step_end);
    Record("close dismisses information without closing inventory", !instance_exists(global.DB_Inst) && instance_exists(ui) && !ui.Close && __input_global().__cleared);
    PressEvent(ui, "", oInventory, ev_step, ev_step_normal);
    Record("gear prompt opens actions without claiming to equip", global.NovaInventoryAction(ui) == "ACTIONS");
    with (ui) NovaItemMenu();
    var before_close = json_stringify(global.Inventory);
    PressEvent(ui, ["action", "sword"], oInventory, ev_step, ev_step_normal);
    Record("close dismisses item actions without executing them", !ui.MenuEnable && !ui.Close && json_stringify(global.Inventory) == before_close);
    with (ui) NovaItemMenu();
    PressEvent(ui, ["nova_bag_next", "sword"], oInventory, ev_step, ev_step_normal);
    Record("paging dismisses actions without selecting an item", ui.NovaPage == 1 && !ui.MenuEnable && !ui.Close);
    var page_before = ui.NovaPage;
    PressEvent(ui, ["nova_bag_previous", "nova_bag_next"], oInventory, ev_step, ev_step_normal);
    Record("opposed shoulders leave the selected page unchanged", ui.NovaPage == page_before);
    var status_before = global.Users[global.UserIndex].Prefs[2];
    PressEvent(oGame, "hud", oGame, ev_step, ev_step_begin);
    Record("status toggle cannot change behind inventory", global.Users[global.UserIndex].Prefs[2] == status_before);

    for (var slot = 10; slot <= 31; slot++) global.Inventory[slot] = {ItemClass: 36, ItemIndex: slot mod 5, Amount: 1, Enabled: true};
    ui.NovaPage = 6;
    with (ui) NovaRefresh();
    var first_page = array_length(ui.NovaSlots);
    PressEvent(ui, "nova_bag_next", oInventory, ev_step, ev_step_normal);
    Record("large overflow stays accessible in two-row pages", first_page == 12 && ui.NovaPage == 7 && array_length(ui.NovaSlots) == 5);
    for (var slot = 15; slot <= 31; slot++) global.Inventory[slot] = {ItemClass: -1, ItemIndex: -1, Amount: 0, Enabled: true};
    with (ui) NovaRefresh();
    Record("empty overflow returns to a valid bag", ui.NovaPage == 1 && global.Inventory_SlotIndex_Selected >= 10 && global.Inventory_SlotIndex_Selected < 15);
    PressEvent(ui, "action", oInventory, ev_step, ev_step_normal);
    Record("close dismisses inventory and consumes the input", ui.Close && __input_global().__cleared);
    global.NovaTestInput = "action";
    Record("closing suppresses a second press query in the same frame", !input_check_pressed("action"));
    global.NovaTestInput = "";
    with (ui) instance_destroy();
    input_clear_momentary(false);
    Record("inventory closure does not leave the HUD in menu mode", !global.NovaInventoryHUD());
    for (var i = 0; i < 3; i++) {
        var map = instance_create_layer(0, 0, "System", oMap);
        map.Open = false;
        global.MapInst = map;
        var verb = i == 0 ? "action" : (i == 1 ? "menu_access" : "escape");
        PressEvent(map, verb, oMap, ev_step, ev_step_normal);
        Record("map closes via " + verb, map.Close && __input_global().__cleared);
        with (map) instance_destroy();
        input_clear_momentary(false);
    }
    global.Inventory = inventory_before;
    global.Inventory_ItemData = items_before;
    global.Inventory_SlotIndex_Equiped = equipped_before;
    input_profile_set(profile_before);
}
