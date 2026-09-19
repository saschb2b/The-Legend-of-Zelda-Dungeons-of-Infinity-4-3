function HUDRender(name, visible, status_visible) {
    global.NovaTestHUDDraws = 0;
    global.NovaTestStatusDraws = 0;
    surface_set_target(HUDTestSurface);
    with (oRender) event_perform_object(oRender, ev_draw, 64);
    surface_reset_target();
    Record(name + " HUD visibility", global.NovaTestHUDDraws == (visible ? 1 : 0));
    Record(name + " Status hint visibility", global.NovaTestStatusDraws == (status_visible ? 1 : 0));
    if (visible && global.NovaTestHUDDraws == 1) {
        // Sample the magic meter's fixed white cap in the composed playfield.
        var cap = surface_getpixel(oRender.NovaFrame, 81, 73);
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
