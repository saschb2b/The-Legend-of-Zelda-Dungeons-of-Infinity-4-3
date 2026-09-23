// Interaction hint screenshots: Talk, Open, Lift with its motion frames, a remapped button and the keyboard.
ContextCaptureIndex = 0;
ContextCaptureTicks = 0;
ContextCaptureObject = noone;
function ContextCaptureStart() {
    ContextCaptureIndex = 0;
    ContextCaptureTicks = 0;
    ContextCaptureBindings = input_profile_export("gamepad");
    // A filtered run may skip the Interaction hints suite that finds the clear floor.
    if (!variable_instance_exists(id, "ContextFixtureX")) ContextBegin();
    ContextCaptureX = ContextFixtureX;
    ContextCaptureY = ContextFixtureY;
    ContextCaptureNext();
}
function ContextCaptureNext() {
    if (instance_exists(ContextCaptureObject)) with (ContextCaptureObject) instance_destroy();
    MovementReset(ContextCaptureX, ContextCaptureY);
    oLink.Facing = 1;
    global.Paused = false;
    global.Users[global.UserIndex].Prefs[2] = false;
    input_profile_import(ContextCaptureBindings, "gamepad");
    input_profile_set(ContextCaptureIndex == 4 ? "keyboard" : "gamepad");
    with (oLink) UpdateSprites();
    if (ContextCaptureIndex == 0) ContextCaptureObject = ContextNPC(oLink.x, oLink.y - 16);
    else if (ContextCaptureIndex == 1) {
        ContextCaptureObject = instance_create_layer(oLink.x, oLink.y - 16, "Objs_" + oLink.FloorLevelStr, oItem_Treasure, {From: 2});
        ContextCaptureObject.image_index = 0;
    } else {
        ContextCaptureObject = instance_create_layer(oLink.x, oLink.y - 16, "Objs_" + oLink.FloorLevelStr, oPot, {FloorLevel: oLink.FloorLevel});
        if (ContextCaptureIndex == 3) input_binding_set("action", input_binding_gamepad_button(gp_face4), 0, 0, "gamepad");
    }
    var names = ["context-talk", "context-open", "context-lift", "context-remapped", "context-keyboard"];
    ContextCaptureName = names[ContextCaptureIndex];
}
function ContextCaptureStep() {
    ContextCaptureTicks++;
    if (ContextCaptureTicks == 240) {
        if (ContextCaptureIndex == 2) ContextMotionCapture();
        Capture = ContextCaptureName;
        Flush();
    }
    if (!file_exists("nova-capture-done.txt")) return false;
    file_delete("nova-capture-done.txt");
    ContextCaptureTicks = 0;
    ContextCaptureIndex++;
    Capture = "";
    if (ContextCaptureIndex == 5) return true;
    ContextCaptureNext();
    return false;
}

function ContextMotionCapture() {
    var saved = oRender.NovaContext;
    oRender.NovaContext = global.NovaContextMotion();
    var width = display_get_gui_width();
    var height = display_get_gui_height();
    var layout = global.NovaHUDLayout(width, height);
    var sx = layout.scale;
    var sy = sx;
    var size = 12 * min(sx, sy);
    var preview = surface_create(width, height);
    draw_set_font(global.HUDFont2);
    var binding = global.NovaBinding("hud");
    var status_left = layout.right - global.NovaPromptWidth(binding, "STATUS", sx, size, 2);
    for (var frame = 0; frame < 96; frame++) {
        var label = frame < 12 || frame >= 84 ? "" : (frame < 48 ? "LIFT" : "THROW");
        global.NovaContextAdvance(oRender.NovaContext, label, 1 / 60);
        surface_set_target(preview);
        draw_clear_alpha(c_black, 1);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_surface_stretched(oRender.NovaFrame, 0, 0, width, height);
        global.NovaContextDraw(layout, status_left);
        global.NovaPromptDraw(binding, "STATUS", status_left, layout.footer_y, sx, sy, size, 2);
        surface_reset_target();
        var number = string(frame);
        while (string_length(number) < 3) number = "0" + number;
        surface_save_part(preview, "nova-context-motion-" + number + ".png", floor(width * 0.48), floor(height * 0.875), width - floor(width * 0.48), floor(height * 0.11));
    }
    surface_free(preview);
    oRender.NovaContext = saved;
}
