// The HUD: integer scaling on every screen shape and its visibility through room travel and menus.
function HUDRender(name, visible, status_visible) {
    global.NovaTestHUDDraws = 0;
    global.NovaTestStatusDraws = 0;
    surface_set_target(HUDTestSurface);
    with (oRender) event_perform_object(oRender, ev_draw, 64);
    surface_reset_target();
    Check(name + " HUD visibility", global.NovaTestHUDDraws == (visible ? 1 : 0));
    Check(name + " Status hint visibility", global.NovaTestStatusDraws == (status_visible ? 1 : 0));
    if (visible && global.NovaTestHUDDraws == 1) {
        var layout = global.NovaHUDLayout(display_get_gui_width(), display_get_gui_height());
        var cap = surface_getpixel(HUDTestSurface, layout.x + 20 * layout.scale, layout.y + 18 * layout.scale);
        Check(name + " HUD stays anchored", cap == make_color_rgb(248, 248, 248));
    }
}
// Saves the state the HUD tests change, then shows the HUD without Status panels or an arcade screen.
function HUDBegin() {
    HUDSaved = {
        paused: global.Paused,
        state: oLink.State,
        stairs: oLink.StairsAutoMove,
        closing: oLink.GoingThruClosedDoor,
        transition_dir: oCamera.RoomTransition,
        camera_x: oCamera.X,
        camera_y: oCamera.Y,
        alpha: oHUD.MainAlpha,
        panels: global.Users[global.UserIndex].Prefs[2],
        crt: global.Users[global.UserIndex].Prefs[3],
        arcade: global.ArcadeVP_Show
    };
    HUDTestSurface = surface_create(1600, 1200);
    oHUD.MainAlpha = 1;
    global.ArcadeVP_Show = false;
    global.Users[global.UserIndex].Prefs[2] = false;
}
function HUDEnd() {
    global.Paused = HUDSaved.paused;
    oLink.State = HUDSaved.state;
    oLink.StairsAutoMove = HUDSaved.stairs;
    oLink.GoingThruClosedDoor = HUDSaved.closing;
    oCamera.RoomTransition = HUDSaved.transition_dir;
    oCamera.X = HUDSaved.camera_x;
    oCamera.Y = HUDSaved.camera_y;
    oHUD.MainAlpha = HUDSaved.alpha;
    global.Users[global.UserIndex].Prefs[2] = HUDSaved.panels;
    global.Users[global.UserIndex].Prefs[3] = HUDSaved.crt;
    global.ArcadeVP_Show = HUDSaved.arcade;
    surface_free(HUDTestSurface);
}
// Saves and restores the screen shape options around one test.
function ScreenShapeBegin() {
    ScreenShapeSaved = {square: global.NovaSquarePixels, integer: global.NovaIntegerScale};
}
function ScreenShapeEnd() {
    global.NovaSquarePixels = ScreenShapeSaved.square;
    global.NovaIntegerScale = ScreenShapeSaved.integer;
}

Suite("HUD scaling", "gameplay", function() {
    Test("the HUD keeps whole square pixels and margins on every screen size", function() {
        HUDBegin();
        var sizes = [[256,224], [320,240], [640,480], [1024,768], [1280,960], [1280,720], [1920,1080], [1920,1440]];
        var magic = oHUD.MagicW;
        var saved_health = global.Inventory_ItemData[17].Amount;
        var capacity = global.Inventory_ItemData[18].Amount;
        var rupees = oHUD.RupeesStr;
        var pulse = oHUD.HealthLowPulseColor;
        var add_health = oHUD.AddHealth;
        var filtering = gpu_get_texfilter();
        oHUD.MagicW = 64;
        oHUD.RupeesStr = "9999";
        oHUD.HealthLowPulseColor = c_white;
        oHUD.AddHealth = 0;
        global.Inventory_ItemData[17].Amount = 19.5;
        global.Inventory_ItemData[18].Amount = 20;
        for (var index = 0; index < array_length(sizes); index++) {
            var width = sizes[index][0];
            var height = sizes[index][1];
            var layout = global.NovaHUDLayout(width, height);
            var scale = layout.scale;
            var name = "HUD at " + string(width) + "x" + string(height);
            Check(name + " uses an integer scale and position", scale >= 1 && scale == floor(scale) && layout.x == floor(layout.x) && layout.y == floor(layout.y));
            Check(name + " keeps equal side margins", abs(layout.x + 16 * scale - (width - layout.right)) <= 1);
            Check(name + " spans the footer between its margins", layout.footer_left == layout.x + 16 * scale && layout.footer_width == (layout.width - 32) * scale && layout.footer_left + layout.footer_width == layout.right);
            Check(name + " reports the world scale beside the HUD scale", layout.world_x == layout.world_width / 256 && layout.world_y == layout.world_height / 224 && scale <= max(1, min(layout.world_x, layout.world_y)));
            Check(name + " keeps a centered 4:3 playfield", abs(layout.world_width - layout.world_height * 4 / 3) <= 1
                && layout.world_left == floor((width - layout.world_width) / 2) && layout.world_top == floor((height - layout.world_height) / 2)
                && (layout.world_width == width || layout.world_height == height));
            Check(name + " keeps the HUD on the playfield", layout.x >= layout.world_left && layout.x + layout.width * scale <= layout.world_left + layout.world_width);
            Check(name + " separates counters from twenty hearts", layout.width - 95 >= 160);
            Check(name + " fits the screen", layout.x + layout.width * scale <= width && layout.y + layout.height * scale <= height);
            Check(name + " keeps the footer below the playfield center", layout.footer_y > height * 0.75 && layout.footer_y + 6 * scale < height);
            if (width == 1280 && height == 960) Check("Nova uses a compact 3x HUD", scale == 3);
            if (width == 640) Check("small screens retain readable 2x HUD pixels", scale == 2);
            var native = surface_create(layout.width, 64);
            var scaled = surface_create(width, height);
            gpu_set_texfilter(false);
            surface_set_target(native);
            draw_clear_alpha(c_black, 1);
            with (oRender) NovaHUD_Draw(layout);
            surface_reset_target();
            surface_set_target(scaled);
            draw_clear_alpha(c_black, 1);
            draw_surface_ext(native, layout.x, layout.y, scale, scale, 0, c_white, 1);
            surface_reset_target();
            var samples = [[16,21], [20,18], [20,26], [32,24], [34,21], [64,26], [layout.width - 92,26], [layout.width - 20,34]];
            var exact = true;
            for (var sample = 0; sample < array_length(samples); sample++) {
                var px = samples[sample][0];
                var py = samples[sample][1];
                var color = surface_getpixel(native, px, py);
                for (var yy = 0; yy < scale; yy++) {
                    for (var xx = 0; xx < scale; xx++) {
                        exact = exact && surface_getpixel(scaled, layout.x + px * scale + xx, layout.y + py * scale + yy) == color;
                    }
                }
            }
            Check(name + " preserves square pixel blocks", exact);
            draw_set_font(global.HUDFont2);
            var hint = global.NovaContextHint(layout, layout.right - 60 * scale, "INSPECT");
            Check(name + " keeps gameplay labels square and icons aligned", hint.scale_x == scale && hint.scale_y == scale && hint.icon_x == floor(hint.icon_x) && hint.y == layout.footer_y);
            surface_free(native);
            surface_free(scaled);
        }
        oHUD.MagicW = magic;
        oHUD.RupeesStr = rupees;
        oHUD.HealthLowPulseColor = pulse;
        oHUD.AddHealth = add_health;
        global.Inventory_ItemData[17].Amount = saved_health;
        global.Inventory_ItemData[18].Amount = capacity;
        gpu_set_texfilter(filtering);
        HUDEnd();
    });
});

Suite("Screen shapes", "gameplay", function() {
    Test("stretched pixels fit a 4:3 playfield and dock panels in wide borders", function() {
        ScreenShapeBegin();
        global.NovaSquarePixels = false;
        global.NovaIntegerScale = false;
        var wide = global.NovaHUDLayout(1920, 1080);
        Check("16:9 pillarboxes a 1440x1080 playfield", wide.world_left == 240 && wide.world_top == 0 && wide.world_width == 1440 && wide.world_height == 1080);
        Check("16:9 docks the side panels at 3x", wide.docked && wide.panel_scale == 3 && 72 * wide.panel_scale + 8 <= wide.world_left);
        Check("720p docks the side panels at 2x", global.NovaHUDLayout(1280, 720).docked && global.NovaHUDLayout(1280, 720).panel_scale == 2);
        Check("4:3 keeps panels over the playfield", !global.NovaHUDLayout(1280, 960).docked && global.NovaHUDLayout(1280, 960).world_width == 1280);
        Check("3:2 borders stay too narrow for panels", !global.NovaHUDLayout(1620, 1080).docked);
        var tall = global.NovaHUDLayout(720, 720);
        var mini = global.NovaHUDLayout(1240, 1080);
        Check("31:27 screens letterbox the playfield", mini.world_width == 1240 && mini.world_height == 930 && mini.world_top == 75 && !mini.docked);
        var ace = global.NovaHUDLayout(1620, 1080);
        Check("3:2 1080p keeps panels over the playfield", ace.world_width == 1440 && ace.world_left == 90 && !ace.docked && ace.scale == 4);
        var rg552 = global.NovaHUDLayout(1920, 1152);
        Check("5:3 docks the side panels at 2x", rg552.world_width == 1536 && rg552.docked && rg552.panel_scale == 2);
        var qhd = global.NovaHUDLayout(2560, 1440);
        Check("1440p docks the side panels at 4x beside a 5x HUD", qhd.world_width == 1920 && qhd.docked && qhd.panel_scale == 4 && qhd.scale == 5);
        Check("square screens letterbox the playfield", tall.world_width == 720 && tall.world_height == 540 && tall.world_top == 90 && !tall.docked);
        ScreenShapeEnd();
    });
    Test("square pixels narrow the playfield to 8:7", function() {
        ScreenShapeBegin();
        global.NovaSquarePixels = true;
        global.NovaIntegerScale = false;
        var pixels = global.NovaHUDLayout(1920, 1080);
        Check("square pixels narrow the playfield to 8:7", pixels.world_height == 1080 && pixels.world_width == round(1080 * 8 / 7) && pixels.docked && pixels.panel_scale == 4);
        ScreenShapeEnd();
    });
    Test("integer scaling draws whole game pixels", function() {
        ScreenShapeBegin();
        global.NovaSquarePixels = true;
        global.NovaIntegerScale = true;
        var exact = global.NovaHUDLayout(1920, 1080);
        Check("integer square pixels draw each game pixel as a 4x4 block", exact.world_width == 1024 && exact.world_height == 896 && exact.world_left == 448 && exact.world_top == 92);
        global.NovaSquarePixels = false;
        var rows = global.NovaHUDLayout(1920, 1080);
        Check("integer scaling keeps whole pixel rows in 4:3", rows.world_height == 896 && abs(rows.world_width - 896 * 4 / 3) <= 1);
        Check("integer scaling falls back below one whole multiple", global.NovaHUDLayout(256, 200).world_height == 192);
        ScreenShapeEnd();
    });
});

Suite("HUD visibility", "gameplay", function() {
    Test("the HUD compositor is available", function() {
        Check("HUD compositor is available", variable_instance_exists(oRender, "NovaFrame"));
    });
    Test("room transitions keep the HUD and hide only the Status hint", function() {
        HUDBegin();
        var camera_x = oCamera.X;
        var camera_y = oCamera.Y;
        for (var effect = 0; effect < 2; effect++) {
            global.Users[global.UserIndex].Prefs[3] = effect == 1;
            for (var dir = 1; dir <= 4; dir++) {
                var label = "transition " + string(dir) + " CRT " + string(effect);
                global.Paused = false;
                oCamera.RoomTransition = 0;
                oLink.State = 1;
                oLink.StairsAutoMove = false;
                HUDRender(label + " before", true, true);
                global.Paused = true;
                oCamera.RoomTransition = dir;
                oLink.State = 5;
                oCamera.X = camera_x + (dir == 3 ? -64 : (dir == 4 ? 64 : 0));
                oCamera.Y = camera_y + (dir == 1 ? -64 : (dir == 2 ? 64 : 0));
                HUDRender(label + " scrolling", true, false);
                oCamera.RoomTransition = 0;
                HUDRender(label + " doorway exit", true, false);
                oLink.State = 0;
                oLink.GoingThruClosedDoor = false;
                HUDRender(label + " door closing", true, false);
                global.Users[global.UserIndex].Prefs[2] = true;
                HUDRender(label + " Status enabled", true, false);
                global.Users[global.UserIndex].Prefs[2] = false;
                global.Paused = false;
                oLink.State = 1;
                HUDRender(label + " control restored", true, true);
                global.Paused = true;
                HUDRender(label + " unrelated pause", false, false);
            }
        }
        HUDEnd();
    });
    Test("stairs keep the HUD and hide only the Status hint", function() {
        HUDBegin();
        oCamera.RoomTransition = 0;
        oLink.State = 1;
        oLink.StairsAutoMove = false;
        oLink.GoingThruClosedDoor = false;
        for (var effect = 0; effect < 2; effect++) {
            global.Users[global.UserIndex].Prefs[3] = effect == 1;
            global.Paused = false;
            HUDRender("stairs reset CRT " + string(effect), true, true);
            global.Paused = true;
            oLink.StairsAutoMove = true;
            oLink.State = 5;
            HUDRender("stairs CRT " + string(effect), true, false);
            oLink.StairsAutoMove = false;
            global.Paused = false;
            oLink.State = 1;
            HUDRender("stairs exit CRT " + string(effect), true, true);
        }
        HUDEnd();
    });
    Test("menus and dialogue hide the HUD during a room handoff while the inventory keeps it", function() {
        HUDBegin();
        oLink.State = 1;
        oLink.StairsAutoMove = false;
        oLink.GoingThruClosedDoor = false;
        global.Users[global.UserIndex].Prefs[3] = false;
        global.Paused = true;
        oCamera.RoomTransition = 1;
        HUDRender("transition before modal", true, false);
        oCamera.RoomTransition = 0;
        var modal = instance_create_layer(0, 0, "System", oMenu_Game);
        HUDRender("pause menu during handoff", false, false);
        with (modal) instance_destroy();
        modal = instance_create_layer(0, 0, "System", oMap);
        global.MapInst = modal;
        HUDRender("map during handoff", false, false);
        with (modal) instance_destroy();
        global.Paused = true;
        oCamera.RoomTransition = 1;
        modal = instance_create_layer(0, 0, "System", oDialogueBox);
        global.DB_Inst = modal;
        HUDRender("dialogue during scrolling", false, false);
        oCamera.RoomTransition = 0;
        HUDRender("dialogue during handoff", false, false);
        with (modal) instance_destroy();
        global.DB_Inst = noone;
        global.Paused = true;
        modal = instance_create_layer(0, 0, "System", oInventory);
        global.InventoryInst = modal;
        modal.Open = false;
        modal.Alpha = 1;
        HUDRender("inventory retains HUD", true, false);
        with (modal) instance_destroy();
        global.Paused = false;
        HUDRender("handoff cleared", true, true);
        global.Paused = true;
        HUDRender("later pause stays hidden", false, false);
        HUDEnd();
    });
});
