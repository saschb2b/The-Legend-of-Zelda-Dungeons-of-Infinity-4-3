function HUDRender(name, visible, status_visible) {
    global.NovaTestHUDDraws = 0;
    global.NovaTestStatusDraws = 0;
    surface_set_target(HUDTestSurface);
    with (oRender) event_perform_object(oRender, ev_draw, 64);
    surface_reset_target();
    Record(name + " HUD visibility", global.NovaTestHUDDraws == (visible ? 1 : 0));
    Record(name + " Status hint visibility", global.NovaTestStatusDraws == (status_visible ? 1 : 0));
    if (visible && global.NovaTestHUDDraws == 1) {
        var layout = global.NovaHUDLayout(display_get_gui_width(), display_get_gui_height());
        var cap = surface_getpixel(HUDTestSurface, layout.x + 20 * layout.scale, layout.y + 18 * layout.scale);
        Record(name + " HUD stays anchored", cap == make_color_rgb(248, 248, 248));
    }
}
function HUDTests() {
    if (!variable_instance_exists(oRender, "NovaFrame")) { Record("HUD compositor is available", false); return; }
    var paused = global.Paused;
    var state = oLink.State;
    var stairs = oLink.StairsAutoMove;
    var closing = oLink.GoingThruClosedDoor;
    var transition_dir = oCamera.RoomTransition;
    var camera_x = oCamera.X;
    var camera_y = oCamera.Y;
    var alpha = oHUD.MainAlpha;
    var panels = global.Users[global.UserIndex].Prefs[2];
    var crt = global.Users[global.UserIndex].Prefs[3];
    var arcade = global.ArcadeVP_Show;
    HUDTestSurface = surface_create(1600, 1200);
    oHUD.MainAlpha = 1;
    global.ArcadeVP_Show = false;
    global.Users[global.UserIndex].Prefs[2] = false;
    HUDScaleTests();
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
    oCamera.X = camera_x;
    oCamera.Y = camera_y;
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
    global.Paused = paused;
    oLink.State = state;
    oLink.StairsAutoMove = stairs;
    oLink.GoingThruClosedDoor = closing;
    oCamera.RoomTransition = transition_dir;
    oHUD.MainAlpha = alpha;
    global.Users[global.UserIndex].Prefs[2] = panels;
    global.Users[global.UserIndex].Prefs[3] = crt;
    global.ArcadeVP_Show = arcade;
    surface_free(HUDTestSurface);
}

function HUDScaleTests() {
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
        Record(name + " uses an integer scale and position", scale >= 1 && scale == floor(scale) && layout.x == floor(layout.x) && layout.y == floor(layout.y));
        Record(name + " keeps equal side margins", abs(layout.x + 16 * scale - (width - layout.right)) <= 1);
        Record(name + " separates counters from twenty hearts", layout.width - 95 >= 160);
        Record(name + " fits the screen", layout.x + layout.width * scale <= width && layout.y + layout.height * scale <= height);
        Record(name + " keeps the footer below the playfield center", layout.footer_y > height * 0.75 && layout.footer_y + 6 * scale < height);
        if (width == 1280 && height == 960) Record("Nova uses a compact 3x HUD", scale == 3);
        if (width == 640) Record("small screens retain readable 2x HUD pixels", scale == 2);
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
        Record(name + " preserves square pixel blocks", exact);
        draw_set_font(global.HUDFont2);
        var hint = global.NovaContextHint(layout, layout.right - 60 * scale, "INSPECT");
        Record(name + " keeps gameplay labels square and icons aligned", hint.scale_x == scale && hint.scale_y == scale && hint.icon_x == floor(hint.icon_x) && hint.y == layout.footer_y);
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
}
