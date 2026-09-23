// Binding-aware prompts and glyphs, profile migration, and inventory and map controls.
Suite("Controller bindings", "gameplay", function() {
    Test("binding-aware controls are available", function() {
        Check("binding-aware controls are available", variable_global_exists("NovaBinding"));
    });
    Test("A confirms and B closes on the Nova", function() {
        var profile_before = input_profile_get();
        input_profile_set("gamepad");
        Check("Nova A confirms and B closes through fixed menu verbs", global.NovaConfirmVerb() == "nova_confirm" && global.NovaCloseVerb() == "nova_back" && global.NovaGlyph(global.NovaBinding("nova_confirm")) == 0 && global.NovaGlyph(global.NovaBinding("nova_back")) == 1);
        Check("gameplay Sword and Interact default to the same B and A buttons", global.NovaGlyph(global.NovaBinding("sword")) == 1 && global.NovaGlyph(global.NovaBinding("action")) == 0);
        Check("Controls names the same A and B buttons as the glyphs", global.NovaKeyLabel(global.NovaBinding("sword")) == "B" && global.NovaKeyLabel(global.NovaBinding("action")) == "A");
        input_profile_set(profile_before);
    });
    Test("legacy menu confirmation moves to A", function() {
        var profile_before = input_profile_get();
        var gamepad_before = input_profile_export("gamepad");
        input_profile_set("gamepad");
        var old_confirm = json_parse(gamepad_before);
        old_confirm.menu_input[1].__value = gp_face1;
        input_profile_import(old_confirm, "gamepad");
        Check("legacy menu confirmation moves to A without changing gameplay bindings", input_binding_get("menu_input", 0, 1, "gamepad").__value == gp_face2 && input_profile_export("gamepad") == gamepad_before);
        old_confirm.menu_input[1].__value = gp_face4;
        input_profile_import(old_confirm, "gamepad");
        Check("custom menu confirmation is preserved", input_binding_get("menu_input", 0, 1, "gamepad").__value == gp_face4);
        old_confirm.menu_input = [{}, {}];
        input_profile_import(old_confirm, "gamepad");
        Check("unbound menu confirmation stays unbound", input_binding_get("menu_input", 0, 0, "gamepad").__type == undefined && input_binding_get("menu_input", 0, 1, "gamepad").__type == undefined);
        input_profile_import(gamepad_before, "gamepad");
        input_profile_set(profile_before);
    });
    Test("status glyphs follow remapped buttons and sticks", function() {
        var profile_before = input_profile_get();
        var gamepad_before = input_profile_export("gamepad");
        input_profile_set("gamepad");
        var buttons = [gp_face1, gp_face2, gp_face3, gp_face4, gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb, gp_select, gp_stickl, gp_stickr, gp_padu, gp_padd, gp_padl, gp_padr];
        for (var i = 0; i < array_length(buttons); i++) {
            input_binding_set("hud", input_binding_gamepad_button(buttons[i]), 0, 0, "gamepad");
            Check("status glyph follows remapped button " + string(buttons[i]), global.NovaGlyph(global.NovaBinding("hud")) == (i < 2 ? 1 - i : i));
        }
        Check("Start uses the Switch Plus glyph", global.NovaGlyph(input_binding_gamepad_button(gp_start)) == 23);
        for (var axis = gp_axislh; axis <= gp_axisrv; axis++) {
            for (var negative = 0; negative < 2; negative++) {
                var binding = input_binding_gamepad_axis(axis, negative == 1);
                Check("stick direction glyph " + string(axis) + "/" + string(negative), global.NovaGlyph(binding) == 15 + (axis - gp_axislh) * 2 + (negative == 1 ? 0 : 1));
            }
        }
        input_profile_import(gamepad_before, "gamepad");
        input_profile_set(profile_before);
    });
    Test("status falls back to its alternate binding and never claims R3 when unbound", function() {
        var profile_before = input_profile_get();
        var gamepad_before = input_profile_export("gamepad");
        input_profile_set("gamepad");
        input_binding_set("hud", input_binding_empty(), 0, 0, "gamepad");
        input_binding_set("hud", input_binding_gamepad_button(gp_face4), 0, 1, "gamepad");
        Check("status falls back to the populated alternate binding", global.NovaGlyph(global.NovaBinding("hud")) == 3);
        input_binding_set("hud", input_binding_empty(), 0, 1, "gamepad");
        Check("unbound status never claims R3", global.NovaGlyph(global.NovaBinding("hud")) == -1 && global.NovaKeyLabel(global.NovaBinding("hud")) == "UNBOUND");
        input_profile_import(gamepad_before, "gamepad");
        input_profile_set(profile_before);
    });
    Test("keyboard prompts keep Ctrl and Alt and follow remapped keys", function() {
        var profile_before = input_profile_get();
        var keyboard_before = input_profile_export("keyboard");
        input_profile_set("keyboard");
        Check("keyboard confirm and close keep Ctrl and Alt", global.NovaBinding("nova_confirm").__value == vk_control && global.NovaBinding("nova_back").__value == vk_alt);
        input_binding_set("hud", input_binding_key(ord("K")), 0, 0, "keyboard");
        Check("keyboard status uses the remapped key", global.NovaGlyph(global.NovaBinding("hud")) == -1 && global.NovaKeyLabel(global.NovaBinding("hud")) == "K");
        input_profile_import(keyboard_before, "keyboard");
        input_profile_set(profile_before);
    });
    Test("old profiles gain the shoulder page bindings", function() {
        var profile_before = input_profile_get();
        var gamepad_before = input_profile_export("gamepad");
        var keyboard_before = input_profile_export("keyboard");
        input_profile_set("gamepad");
        Check("shoulders default to previous and next bag", global.NovaGlyph(global.NovaBinding("nova_bag_previous")) == 4 && global.NovaGlyph(global.NovaBinding("nova_bag_next")) == 5);
        var legacy = json_parse(gamepad_before);
        variable_struct_remove(legacy, "nova_bag_previous");
        variable_struct_remove(legacy, "nova_bag_next");
        input_profile_import(legacy, "gamepad");
        Check("old controller profiles gain shoulders without losing bindings", input_profile_export("gamepad") == gamepad_before);
        input_binding_set("nova_bag_previous", input_binding_empty(), 0, 0, "gamepad");
        var unbound = input_profile_export("gamepad");
        input_profile_import(unbound, "gamepad");
        Check("explicitly unbound shoulders remain unbound on reload", global.NovaBinding("nova_bag_previous").__type == undefined);
        input_profile_import(gamepad_before, "gamepad");
        legacy = json_parse(keyboard_before);
        variable_struct_remove(legacy, "nova_bag_previous");
        variable_struct_remove(legacy, "nova_bag_next");
        input_profile_import(legacy, "keyboard");
        Check("old keyboard profiles gain page keys without losing bindings", input_profile_export("keyboard") == keyboard_before);
        input_profile_import(keyboard_before, "keyboard");
        input_profile_set(profile_before);
    });
    Test("old profiles gain fixed menu Confirm and Back", function() {
        var profile_before = input_profile_get();
        var gamepad_before = input_profile_export("gamepad");
        var keyboard_before = input_profile_export("keyboard");
        input_profile_set("gamepad");
        for (var device = 0; device < 2; device++) {
            var name = device == 0 ? "gamepad" : "keyboard";
            var legacy = json_parse(device == 0 ? gamepad_before : keyboard_before);
            variable_struct_remove(legacy, "nova_confirm");
            variable_struct_remove(legacy, "nova_back");
            input_profile_import(legacy, name);
            Check("old " + name + " profiles gain fixed menu Confirm and Back", input_profile_export(name) == (device == 0 ? gamepad_before : keyboard_before));
        }
        input_profile_import(gamepad_before, "gamepad");
        input_profile_import(keyboard_before, "keyboard");
        input_profile_set(profile_before);
    });
});

// The tests share one empty inventory screen, ControlsUI, in the order a player would use it.
// The last test closes it and restores the inventory and both input profiles.
Suite("Inventory controls", "gameplay", function() {
    BeforeAll(function() {
        ControlsProfile = input_profile_get();
        ControlsGamepad = input_profile_export("gamepad");
        ControlsKeyboard = input_profile_export("keyboard");
        ControlsInventory = StructCopy(global.Inventory);
        ControlsItems = StructCopy(global.Inventory_ItemData);
        ControlsEquipped = global.Inventory_SlotIndex_Equiped;
        input_profile_set("gamepad");
        Inventory_InitData();
        ControlsUI = instance_create_layer(0, 0, "System", oInventory);
        ControlsUI.Open = false;
        ControlsUI.Alpha = 1;
        global.InventoryInst = ControlsUI;
    });
    Test("the empty inventory leaves room for the full HUD and offers only Close", function() {
        var ui = ControlsUI;
        Check("inventory leaves room for the full HUD", global.NovaInventoryHUD() && ui.Y - oCamera.Y >= 64 && ui.X - oCamera.X >= 24 && ui.X + ui.W <= oCamera.X + 232 && ui.Y + ui.H + 23 <= oCamera.Y + 224);
        var layout = global.NovaHUDLayout(1280, 960);
        ControlsFooterEmpty = global.NovaInventoryFooter(ui, layout);
        var footer_empty = ControlsFooterEmpty;
        Check("empty inventory retains only the Close hint", !footer_empty[0].visible && footer_empty[2].visible && !footer_empty[1].visible);
    });
    Test("page titles fit between fixed shoulder hints", function() {
        var ui = ControlsUI;
        var layout = global.NovaHUDLayout(1280, 960);
        var page_before = ui.NovaPage;
        var overflow_before = ui.NovaOverflowPages;
        var pager_before = global.NovaInventoryPager(ui, layout);
        ui.NovaOverflowPages = 2;
        var font_before = draw_get_font();
        draw_set_font(global.HUDFont2);
        for (var page = 0; page <= 7; page++) {
            ui.NovaPage = page;
            var pager = global.NovaInventoryPager(ui, layout);
            var half_title = string_width(global.NovaInventoryHeading(ui)) * layout.world_x / 2;
            var center = layout.world_left + (ui.X - oCamera.X + ui.W / 2) * layout.world_x;
            var clearance = 8 * layout.world_x;
            Check("page " + string(page) + " keeps both shoulder hints fixed", pager[0].x == pager_before[0].x && pager[1].x == pager_before[1].x && pager[0].y == pager_before[0].y && pager[1].y == pager_before[1].y);
            Check("page " + string(page) + " title fits between shoulder hints", pager[0].x + pager[0].width + clearance <= center - half_title && center + half_title + clearance <= pager[1].x);
            Check("page " + string(page) + " shoulder glyphs use the HUD scale", pager[0].size == 12 * layout.scale && pager[1].size == 12 * layout.scale && pager[0].scale == layout.scale);
            Check("page " + string(page) + " shoulder glyphs use whole screen pixels", pager[0].x == floor(pager[0].x) && pager[1].x == floor(pager[1].x) && pager[0].y == floor(pager[0].y));
        }
        draw_set_font(font_before);
        ui.NovaPage = page_before;
        ui.NovaOverflowPages = overflow_before;
    });
    Test("shoulders page through the owned bags and wrap", function() {
        var ui = ControlsUI;
        PressEvent(ui, "nova_bag_previous", oInventory, ev_step, ev_step_normal);
        Check("left shoulder opens gear from items", ui.NovaPage == 0);
        PressEvent(ui, "nova_bag_previous", oInventory, ev_step, ev_step_normal);
        Check("left shoulder wraps to the last owned bag page", ui.NovaPage == 2);
        PressEvent(ui, "nova_bag_next", oInventory, ev_step, ev_step_normal);
        Check("right shoulder wraps to gear", ui.NovaPage == 0);
    });
    Test("confirm opens actions for the highlighted item and names each one", function() {
        var ui = ControlsUI;
        var layout = global.NovaHUDLayout(1280, 960);
        var footer_empty = ControlsFooterEmpty;
        Check("empty slots have no confirm prompt", global.NovaInventoryAction(ui) == "");
        ui.NovaCell = 4;
        with (ui) { NovaRefresh(); NovaItemMenu(); }
        Check("confirm opens actions for the highlighted item", ui.MenuEnable);
        Check("active gear has no redundant equip action", !ds_grid_get(ui.MenuItemGrid, 1, 0) && !ds_grid_get(ui.MenuItemGrid, 1, 1));
        ControlsFooterGear = global.NovaInventoryFooter(ui, layout);
        var footer_gear = ControlsFooterGear;
        Check("item actions keep Close in its empty-inventory position", footer_gear[2].x == footer_empty[2].x && footer_gear[2].y == footer_empty[2].y && !footer_gear[0].visible);
        var action_labels = ["EQUIP", "USE", "DROP", "INFO"];
        for (var action = 0; action < 4; action++) {
            ui.MenuSelectionIndex = action;
            Check("confirm prompt names action " + string(action), global.NovaInventoryAction(ui) == action_labels[action]);
        }
    });
    Test("item information keeps the HUD and closes without closing the inventory", function() {
        var ui = ControlsUI;
        var layout = global.NovaHUDLayout(1280, 960);
        var footer_empty = ControlsFooterEmpty;
        var footer_gear = ControlsFooterGear;
        PressEvent(ui, global.NovaConfirmVerb(), oInventory, ev_step, ev_step_normal);
        Check("item information keeps the HUD visible", global.NovaInventoryInfo() && global.NovaInventoryHUD());
        var footer_info = global.NovaInventoryFooter(ui, layout);
        Check("item information preserves the footer positions", footer_info[2].x == footer_empty[2].x && footer_info[1].icon_x == footer_gear[1].icon_x && !footer_info[0].visible);
        PressEvent(global.DB_Inst, global.NovaCloseVerb(), oDialogueBox, ev_step, ev_step_end);
        Check("close dismisses information without closing inventory", !instance_exists(global.DB_Inst) && instance_exists(ui) && !ui.Close && __input_global().__cleared);
    });
    Test("Close and paging dismiss item actions without acting", function() {
        var ui = ControlsUI;
        PressEvent(ui, "", oInventory, ev_step, ev_step_normal);
        Check("gear prompt opens actions without claiming to equip", global.NovaInventoryAction(ui) == "ACTIONS");
        with (ui) NovaItemMenu();
        var before_close = json_stringify(global.Inventory);
        PressEvent(ui, ["action", "sword", "nova_confirm", "nova_back"], oInventory, ev_step, ev_step_normal);
        Check("close dismisses item actions without executing them", !ui.MenuEnable && !ui.Close && json_stringify(global.Inventory) == before_close);
        with (ui) NovaItemMenu();
        PressEvent(ui, ["nova_bag_next", global.NovaConfirmVerb()], oInventory, ev_step, ev_step_normal);
        Check("paging dismisses actions without selecting an item", ui.NovaPage == 1 && !ui.MenuEnable && !ui.Close);
        var page_before = ui.NovaPage;
        PressEvent(ui, ["nova_bag_previous", "nova_bag_next"], oInventory, ev_step, ev_step_normal);
        Check("opposed shoulders leave the selected page unchanged", ui.NovaPage == page_before);
    });
    Test("Status cannot toggle behind the inventory", function() {
        var status_before = global.Users[global.UserIndex].Prefs[2];
        PressEvent(oGame, "hud", oGame, ev_step, ev_step_begin);
        Check("status toggle cannot change behind inventory", global.Users[global.UserIndex].Prefs[2] == status_before);
    });
    Test("large overflow stays accessible in two-row pages", function() {
        var ui = ControlsUI;
        for (var slot = 10; slot <= 31; slot++) global.Inventory[slot] = {ItemClass: 36, ItemIndex: slot mod 5, Amount: 1, Enabled: true};
        ui.NovaPage = 6;
        with (ui) NovaRefresh();
        var first_page = array_length(ui.NovaSlots);
        PressEvent(ui, "nova_bag_next", oInventory, ev_step, ev_step_normal);
        Check("large overflow stays accessible in two-row pages", first_page == 12 && ui.NovaPage == 7 && array_length(ui.NovaSlots) == 5);
        for (var slot = 15; slot <= 31; slot++) global.Inventory[slot] = {ItemClass: -1, ItemIndex: -1, Amount: 0, Enabled: true};
        with (ui) NovaRefresh();
        Check("empty overflow returns to a valid bag", ui.NovaPage == 1 && global.Inventory_SlotIndex_Selected >= 10 && global.Inventory_SlotIndex_Selected < 15);
    });
    Test("item footers keep Close fixed and share the gameplay footer row", function() {
        var ui = ControlsUI;
        var layout = global.NovaHUDLayout(1280, 960);
        var footer_empty = ControlsFooterEmpty;
        var footer_gear = ControlsFooterGear;
        var footer_item = global.NovaInventoryFooter(ui, layout);
        Check("equippable items keep Close fixed while exposing Equip", footer_item[0].visible && footer_item[2].x == footer_empty[2].x && footer_item[1].icon_x == footer_gear[1].icon_x);
        Check("Equip precedes the primary action and Close", footer_item[0].right < footer_item[1].x && footer_item[1].right < footer_item[2].x);
        Check("Nova controller prompts match the HUD scale", footer_item[0].size == 12 * layout.scale && footer_item[1].scale_x == layout.scale);
        draw_set_font(global.HUDFont2);
        var status = global.NovaBinding("hud");
        var status_left = layout.right - global.NovaPromptWidth(status, "STATUS", layout.scale, 12 * layout.scale, 2);
        var gameplay = global.NovaContextHint(layout, status_left, "INSPECT");
        Check("inventory hints share the gameplay footer row", footer_item[2].right == layout.right && footer_item[2].y == gameplay.y && footer_item[2].scale_x == gameplay.scale_x && footer_item[2].size == gameplay.size);
        input_binding_set("action", input_binding_gamepad_button(gp_face4), 0, 0, "gamepad");
        input_binding_set("sword", input_binding_gamepad_button(gp_face3), 0, 0, "gamepad");
        var footer_remapped = global.NovaInventoryFooter(ui, layout);
        Check("menu Confirm and Back stay fixed when gameplay actions move", global.NovaGlyph(footer_remapped[2].binding) == 1 && global.NovaGlyph(footer_remapped[1].binding) == 0 && footer_remapped[2].x == footer_item[2].x && footer_remapped[1].x == footer_item[1].x);
        input_profile_import(ControlsGamepad, "gamepad");
    });
    Test("keyboard footers fit on every screen size", function() {
        var ui = ControlsUI;
        input_profile_set("keyboard");
        var footer_sizes = [[256, 224], [640, 480], [1280, 960], [1920, 1440]];
        for (var index = 0; index < array_length(footer_sizes); index++) {
            var fit_layout = global.NovaHUDLayout(footer_sizes[index][0], footer_sizes[index][1]);
            var footer_keyboard = global.NovaInventoryFooter(ui, fit_layout);
            Check("keyboard footer fits at " + string(footer_sizes[index][0]) + "x" + string(footer_sizes[index][1]), footer_keyboard[0].x >= fit_layout.footer_left - 0.01 && footer_keyboard[2].right <= fit_layout.right + 0.01 && footer_keyboard[0].right < footer_keyboard[1].x && footer_keyboard[1].right < footer_keyboard[2].x);
        }
        input_profile_set("gamepad");
    });
    Test("unbound key labels fit without colliding", function() {
        var ui = ControlsUI;
        var layout = global.NovaHUDLayout(1280, 960);
        input_profile_set("keyboard");
        var footer_verbs = ["item", "action", "sword"];
        for (var i = 0; i < 3; i++) {
            var verb = footer_verbs[i];
            input_binding_set(verb, input_binding_empty(), 0, 0, "keyboard");
            input_binding_set(verb, input_binding_empty(), 0, 1, "keyboard");
        }
        var footer_unbound = global.NovaInventoryFooter(ui, layout);
        Check("unbound key labels fit without colliding", footer_unbound[0].x >= layout.footer_left - 0.01 && footer_unbound[2].right <= layout.right + 0.01);
        draw_set_font(global.HUDFont2);
        for (var i = 0; i < 3; i++) {
            var prompt = footer_unbound[i];
            Check("hint label precedes glyph " + string(i), prompt.icon_x >= prompt.x + string_width(prompt.label) * prompt.scale_x);
            Check("footer clears inventory and curse text " + string(i), prompt.y - prompt.size / 2 > layout.world_top + (ui.Y - oCamera.Y + ui.H + 23) * layout.world_y);
            if (i < 2) Check("unbound prompt spacing " + string(i), prompt.right < footer_unbound[i + 1].x);
        }
        input_profile_import(ControlsKeyboard, "keyboard");
        input_profile_set("gamepad");
    });
    Test("Close dismisses the inventory and consumes the input", function() {
        var ui = ControlsUI;
        PressEvent(ui, global.NovaCloseVerb(), oInventory, ev_step, ev_step_normal);
        Check("close dismisses inventory and consumes the input", ui.Close && __input_global().__cleared);
        global.NovaTestInput = global.NovaCloseVerb();
        Check("closing suppresses a second press query in the same frame", !input_check_pressed(global.NovaCloseVerb()));
        global.NovaTestInput = "";
        with (ui) instance_destroy();
        input_clear_momentary(false);
        Check("inventory closure does not leave the HUD in menu mode", !global.NovaInventoryHUD());
        global.Inventory = ControlsInventory;
        global.Inventory_ItemData = ControlsItems;
        global.Inventory_SlotIndex_Equiped = ControlsEquipped;
        input_profile_import(ControlsGamepad, "gamepad");
        input_profile_import(ControlsKeyboard, "keyboard");
        input_profile_set(ControlsProfile);
    });
});

Suite("Map controls", "gameplay", function() {
    Test("the map fits above the footer and closes with Back, Pause or Escape", function() {
        var profile_before = input_profile_get();
        input_profile_set("gamepad");
        for (var i = 0; i < 3; i++) {
            var map = instance_create_layer(0, 0, "System", oMap);
            Check("Map frame leaves room for the footer " + string(i), map.FrameY - oCamera.Y + map.NovaFrameSize + 8 <= 203);
            Check("Map and player marker share the full fitted area " + string(i), map.MapX - map.FrameX == 6 && map.MapY - map.FrameY == 6 && map.NovaMapScale * 256 == map.NovaFrameSize - 12);
            map.Open = false;
            global.MapInst = map;
            var verb = i == 0 ? global.NovaCloseVerb() : (i == 1 ? "menu_access" : "escape");
            PressEvent(map, verb, oMap, ev_step, ev_step_normal);
            Check("map closes via " + verb, map.Close && __input_global().__cleared);
            with (map) instance_destroy();
            input_clear_momentary(false);
        }
        input_profile_set(profile_before);
    });
});
