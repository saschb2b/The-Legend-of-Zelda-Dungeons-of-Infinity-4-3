function ContextNPC(px, py) {
    var npc = instance_create_layer(px, py, "Objs_" + oLink.FloorLevelStr, oNPC, {Name: "Villager_Guard", sprite_index: sVillager_Guard_Down});
    npc.x = px;
    npc.y = py;
    npc.Dialogue = ["Hello."];
    npc.Response = [];
    npc.visible = true;
    return npc;
}
function ContextTests() {
    var start_x = oLink.x;
    var start_y = oLink.y;
    var px = start_x;
    var py = start_y;
    var clear = false;
    for (var yy = max(48, py - 64); yy <= start_y && !clear; yy += 8) {
        for (var xx = px - 32; xx <= start_x + 32 && !clear; xx += 8) {
            if (GetFloorLevelID(xx, yy) == oLink.FloorLevel && OnStairs(xx, yy) == 0
                && collision_rectangle(xx - 28, yy - 32, xx + 28, yy + 24, [oWall, oItem, oPickupObj, oNPC, oSign], false, true) == noone) {
                px = xx;
                py = yy;
                clear = true;
            }
        }
    }
    Record("context fixture has clear floor", clear);
    if (!clear) return;
    ContextFixtureX = px;
    ContextFixtureY = py;
    var facing = oLink.Facing;
    var profile = input_profile_get();
    var bindings = input_profile_export("gamepad");
    var saves = json_stringify(global.Users);
    var inventory = json_stringify(global.Inventory);
    var seed = random_get_seed();
    var stats = StructCopy(global.StatsToAdd);
    var save_level = global.SaveLevel;
    global.SaveLevel = false;
    input_profile_set("gamepad");
    MovementReset(px, py);
    oLink.StairsAutoMove = false;
    oLink.BounceBack = false;
    oLink.InDoor_Facing = false;
    oLink.InDoor_Aligned = true;
    Record("empty ground has no interaction hint", global.NovaContextAction() == "");
    var pot = instance_create_layer(px, py - 16, "Objs_Lower", oPot, {FloorLevel: oLink.FloorLevel});
    var positions = [[0,-16],[0,8],[-16,0],[16,0]];
    for (var dir = 1; dir <= 4; dir++) {
        pot.x = px + positions[dir - 1][0];
        pot.y = py + positions[dir - 1][1];
        oLink.Facing = dir;
        Record("Lift follows facing " + string(dir), global.NovaContextAction() == "LIFT");
        pot.Hidden = true;
        Record("hidden pot has no hint " + string(dir), global.NovaContextAction() == "");
        pot.Hidden = false;
    }
    pot.x = px;
    pot.y = py - 16;
    oLink.Facing = 2;
    Record("facing away clears Lift", global.NovaContextAction() == "");
    oLink.Facing = 1;
    pot.FloorLevel = oLink.FloorLevel == 0 ? 1 : 0;
    Record("another floor cannot be lifted", global.NovaContextAction() == "");
    pot.FloorLevel = oLink.FloorLevel;
    pot.State = 5;
    Record("destroyed pot has no Lift hint", global.NovaContextAction() == "");
    pot.State = 0;
    var link_state = oLink.State;
    var rng = random_get_seed();
    repeat (20) global.NovaContextAction();
    Record("hint queries preserve object and player state", pot.State == 0 && oLink.State == link_state && oLink.ItemHolding == noone && random_get_seed() == rng && json_stringify(global.Users) == saves && json_stringify(global.Inventory) == inventory);
    ContextMotionTests();
    oRender.NovaContext = global.NovaContextMotion();
    global.NovaContextUpdate(0.12);
    PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
    Record("the hinted interaction lifts the actual pot", oLink.State == 6 && oLink.ItemHolding == pot);
    var held_hint = true;
    var lift_frames = 0;
    repeat (120) {
        if (oLink.State != 6) break;
        held_hint = held_hint && global.NovaContextAction() == "";
        global.NovaContextUpdate(1 / 60);
        held_hint = held_hint && oRender.NovaContext.alpha == 1 && oRender.NovaContext.label == "LIFT";
        oLink.image_index = min(oLink.image_number - 1, oLink.image_index + 0.25);
        with (oLink) event_perform_object(oLink, ev_step, ev_step_normal);
        lift_frames++;
    }
    Record("pickup keeps the accepted Lift visible until carrying is ready", held_hint && lift_frames > 1 && oLink.State != 6 && oLink.ItemHolding == pot);
    Record("carrying changes Lift to Throw", global.NovaContextAction() == "THROW");
    global.NovaContextUpdate(0.06);
    Record("pickup changes the label without fading the button", oRender.NovaContext.alpha == 1 && oRender.NovaContext.shown_label == "THROW" && oRender.NovaContext.text_alpha > 0 && oRender.NovaContext.text_alpha < 1);
    global.NovaContextUpdate(0.06);
    Record("pickup completes on the available Throw action", oRender.NovaContext.shown_label == "THROW" && oRender.NovaContext.text_alpha > 0.999);
    oLink.InDoor_Facing = true;
    Record("blocked doorway does not advertise Throw", global.NovaContextAction() != "THROW");
    oLink.InDoor_Facing = false;
    PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
    Record("the hinted carrying action starts a throw", oLink.State == 10);
    MovementReset(px, py);
    with (pot) instance_destroy();
    oLink.Facing = 1;
    var npc = ContextNPC(px, py - 16);
    Record("person in front advertises Talk", global.NovaContextAction() == "TALK");
    repeat (20) global.NovaContextAction();
    Record("reading Talk cannot start dialogue", !npc.DB_Init && !npc.DB_Started && !instance_exists(oDialogueBox));
    npc.DialogueIgnore = true;
    Record("unavailable conversation hides Talk", global.NovaContextAction() == "");
    npc.DialogueIgnore = false;
    npc.DB_Delay = true;
    Record("conversation cooldown hides Talk", global.NovaContextAction() == "");
    npc.DB_Delay = false;
    oRender.NovaContext = global.NovaContextMotion();
    global.NovaContextUpdate(0.03);
    Record("Talk begins fading in before the interaction", oRender.NovaContext.alpha > 0 && oRender.NovaContext.alpha < 1);
    PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
    Record("the hinted interaction starts the conversation during its fade", npc.DB_Init);
    npc.DB_Init = false;
    with (npc) instance_destroy();
    MovementReset(px, py);
    oLink.Facing = 1;
    var chest = instance_create_layer(px, py - 16, "Objs_Lower", oItem_Treasure, {From: 2, ContentsFrom: 2});
    chest.ContentsObj = 40;
    chest.image_index = 0;
    Record("closed chest advertises Open", global.NovaContextAction() == "OPEN");
    chest.visible = false;
    Record("hidden chest has no Open hint", global.NovaContextAction() == "");
    chest.visible = true;
    chest.image_index = 1;
    Record("opened chest has no Open hint", global.NovaContextAction() == "");
    chest.image_index = 0;
    rng = random_get_seed();
    repeat (20) global.NovaContextAction();
    Record("reading Open preserves treasure and RNG", chest.image_index == 0 && json_stringify(global.StatsToAdd) == json_stringify(stats) && random_get_seed() == rng);
    var states = [0,3,5,6,8,9,10,12,19,20,22,23,24];
    for (var i = 0; i < array_length(states); i++) {
        oLink.State = states[i];
        Record("no interaction hint during state " + string(states[i]), global.NovaContextAction() == "");
    }
    oLink.State = 1;
    global.Paused = true;
    Record("paused game hides interaction hint", global.NovaContextAction() == "");
    global.NovaContextUpdate(1 / 60);
    Record("pause clears pending label transitions", oRender.NovaContext.alpha == 0 && oRender.NovaContext.shown_label == "");
    global.Paused = false;
    global.NovaContextUpdate(0.12);
    oCamera.RoomTransition = 1;
    Record("room scrolling hides interaction hint", global.NovaContextAction() == "");
    global.NovaContextUpdate(1 / 60);
    Record("room changes cannot carry a stale hint into the next room", oRender.NovaContext.alpha == 0);
    oCamera.RoomTransition = 0;
    oLink.BounceBack = true;
    Record("knockback hides interaction hint", global.NovaContextAction() == "");
    oLink.BounceBack = false;
    oLink.StairsAutoMove = true;
    Record("stairs hide interaction hint", global.NovaContextAction() == "");
    oLink.StairsAutoMove = false;
    var modal_objects = [oMenu_Game, oMap, oInventory, oDialogueBox];
    for (var i = 0; i < array_length(modal_objects); i++) {
        global.NovaContextUpdate(0.12);
        var modal = instance_create_layer(0, 0, "System", modal_objects[i]);
        Record("modal hides interaction " + object_get_name(modal_objects[i]), global.NovaContextAction() == "");
        global.NovaContextUpdate(1 / 60);
        Record("modal clears animated interaction " + object_get_name(modal_objects[i]), oRender.NovaContext.alpha == 0);
        with (modal) instance_destroy();
        global.Paused = false;
        oLink.State = 1;
    }
    draw_set_font(global.HUDFont2);
    var status_width = global.NovaPromptWidth(global.NovaBinding("hud"), "STATUS", 5, 12 * (960 / 224), 2);
    global.NovaContextUpdate(0.06);
    var motion_before_draw = json_stringify(oRender.NovaContext);
    var target = surface_create(1280, 960);
    surface_set_target(target);
    draw_set_alpha(0.7);
    var incoming_alpha = draw_get_alpha();
    repeat (3) global.NovaContextDraw(5, 960 / 224, 1190 - status_width);
    Record("drawing hints preserves animation time", json_stringify(oRender.NovaContext) == motion_before_draw);
    Record("drawing hints preserves HUD opacity", draw_get_alpha() == incoming_alpha);
    surface_reset_target();
    surface_free(target);
    draw_set_alpha(1);
    var hint = global.NovaContextHint(5, 960 / 224, 1190 - status_width);
    Record("context hint sits left of Status with a fixed gap", hint.visible && hint.label == "OPEN" && abs(hint.right + 40 + status_width - 1190) < 0.01);
    Record("context hint uses the interaction binding", global.NovaGlyph(hint.binding) == 0);
    input_binding_set("action", input_binding_gamepad_button(gp_face4), 0, 0, "gamepad");
    var remapped = global.NovaContextHint(5, 960 / 224, 1190 - status_width);
    Record("remapping changes the interaction glyph without shifting it", global.NovaGlyph(remapped.binding) == 3 && remapped.icon_x == hint.icon_x);
    input_profile_set("keyboard");
    var keyboard = global.NovaContextHint(5, 960 / 224, 1190 - status_width);
    Record("keyboard hint shows Interact rather than menu Confirm", keyboard.binding.__value == global.NovaBinding("action").__value && global.NovaGlyph(keyboard.binding) == -1 && keyboard.right < 1190 - status_width);
    input_profile_import(bindings, "gamepad");
    input_profile_set("gamepad");
    PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
    Record("the hinted interaction opens the actual chest", chest.image_index == 1 && global.StatsToAdd[5] == stats[5] + 1);
    with (chest) instance_destroy();
    with (oItem_Rupee) instance_destroy();
    MovementReset(px, py);
    ContextShopTests(px, py);
    oLink.Facing = facing;
    input_profile_set(profile);
    global.SaveLevel = save_level;
    global.StatsToAdd = stats;
    random_set_seed(seed);
    MovementReset(start_x, start_y);
    oRender.NovaContext = global.NovaContextMotion();
}

function ContextMotionTests() {
    var motion = global.NovaContextMotion();
    global.NovaContextAdvance(motion, "TALK", 0);
    Record("hint appearance starts transparent", motion.alpha == 0);
    global.NovaContextAdvance(motion, "TALK", 0.06);
    Record("hint fades in over time", abs(motion.alpha - 0.5) < 0.001);
    global.NovaContextAdvance(motion, "TALK", 0.06);
    Record("hint reaches full opacity after 120 ms", motion.alpha == 1);
    global.NovaContextAdvance(motion, "LIFT", 0.02);
    Record("label change fades the old word while keeping the glyph opaque", motion.alpha == 1 && motion.shown_label == "TALK" && abs(motion.text_alpha - 0.5) < 0.001);
    global.NovaContextAdvance(motion, "TALK", 0);
    Record("reversing a label transition preserves visible text opacity", motion.shown_label == "TALK" && abs(motion.text_alpha - 0.5) < 0.001);
    global.NovaContextAdvance(motion, "OPEN", 0.03);
    Record("rapid target changes show only the latest word after fade-out", motion.shown_label == "OPEN" && motion.text_alpha > 0 && motion.text_alpha < 0.5 && motion.alpha == 1);
    global.NovaContextAdvance(motion, "OPEN", 0.12);
    Record("latest action finishes fully readable", motion.shown_label == "OPEN" && motion.text_alpha == 1);
    global.NovaContextAdvance(motion, "", 0.05);
    Record("hint fades out over time", abs(motion.alpha - 0.5) < 0.001);
    var alpha = motion.alpha;
    global.NovaContextAdvance(motion, "OPEN", 0);
    Record("reacquiring an interaction never resets its opacity", motion.alpha == alpha);
    global.NovaContextAdvance(motion, "OPEN", 0.06);
    Record("reacquired hint returns to full opacity", motion.alpha == 1);
    global.NovaContextAdvance(motion, "", 0.10);
    Record("hidden hints discard their labels after 100 ms", motion.alpha == 0 && motion.label == "" && motion.shown_label == "");
    global.NovaContextAdvance(motion, "LIFT", 0.06);
    Record("new interaction cannot revive an unrelated old label", motion.shown_label == "LIFT" && motion.text_alpha == 1);
    for (var hz = 30; hz <= 120; hz *= 2) {
        motion = global.NovaContextMotion();
        repeat (ceil(hz * 0.12)) global.NovaContextAdvance(motion, "LIFT", 1 / hz);
        Record("hint entrance finishes at " + string(hz) + " Hz", motion.alpha > 0.999);
        repeat (ceil(hz * 0.12)) global.NovaContextAdvance(motion, "THROW", 1 / hz);
        Record("label change finishes at " + string(hz) + " Hz", motion.shown_label == "THROW" && motion.text_alpha > 0.999);
        repeat (ceil(hz * 0.10) + 1) global.NovaContextAdvance(motion, "", 1 / hz);
        Record("hint exit finishes at " + string(hz) + " Hz", motion.alpha == 0);
    }
    draw_set_font(global.HUDFont2);
    var previous_x = -1;
    var labels = ["LIFT", "THROW", "TALK", "OPEN", "INSPECT"];
    for (var i = 0; i < array_length(labels); i++) {
        var hint = global.NovaContextHint(5, 960 / 224, 980, labels[i]);
        Record("interaction glyph stays anchored for " + labels[i], previous_x == -1 || abs(hint.icon_x - previous_x) < 0.001);
        previous_x = hint.icon_x;
    }
}

function ContextShopTests(px, py) {
    var challenges = global.Challenges[5];
    global.Challenges[5] = true;
    var shop = instance_create_layer(px + 48, py, "System", oShop, {ShopType: 1, ShopW: 96, ShopH: 64, RoomIndex: oLink.RoomIndex});
    global.Challenges[5] = challenges;
    var wall = instance_create_layer(px - 8, py - 18, "Objs_Lower", oShopWall);
    wall.ShopInst = shop;
    wall.FloorLevel = oLink.FloorLevel;
    wall.image_xscale = 2;
    wall.image_yscale = 2;
    var goods = instance_create_layer(px, py - 22, "Objs_Lower", oItem_Arrows, {From: 4});
    goods.ShopItem = true;
    var look = oLink.ShopItemLook;
    var list = ds_list_write(oLink.CollidedShopItemList);
    var inventory = json_stringify(global.Inventory);
    oLink.Facing = 1;
    Record("shop advertises Inspect rather than Buy", global.NovaContextAction() == "INSPECT");
    repeat (20) global.NovaContextAction();
    Record("shop hint preserves selection and collision list", !shop.DB_Init && oLink.ShopItemLook == look && ds_list_write(oLink.CollidedShopItemList) == list);
    Record("shop hint cannot buy goods", shop.ItemsSold == 0 && instance_exists(goods) && json_stringify(global.Inventory) == inventory);
    var pot = instance_create_layer(px + 32, py, "Objs_Lower", oPot);
    oLink.ItemHolding = pot;
    oLink.State = 11;
    oLink.InDoor_Facing = false;
    oLink.InDoor_Aligned = true;
    Record("carrying takes priority over the shop hint", global.NovaContextAction() == "THROW");
    oLink.ItemHolding = noone;
    oLink.State = 1;
    with (pot) instance_destroy();
    PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
    Record("Inspect starts the shop conversation without purchasing", shop.DB_Init && shop.ItemsSold == 0 && oLink.ShopItemLook == goods);
    with (goods) instance_destroy();
    with (wall) instance_destroy();
    with (shop) instance_destroy();
    oLink.ShopItemLook = look;
    ds_list_read(oLink.CollidedShopItemList, list);
    MovementReset(px, py);
}

ContextCaptureIndex = 0;
ContextCaptureTicks = 0;
ContextCaptureObject = noone;
function ContextCaptureStart() {
    ContextCaptureIndex = 0;
    ContextCaptureTicks = 0;
    ContextCaptureBindings = input_profile_export("gamepad");
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
    if (!file_exists("nova-capture-done.txt")) return;
    file_delete("nova-capture-done.txt");
    ContextCaptureTicks = 0;
    ContextCaptureIndex++;
    Capture = "";
    if (ContextCaptureIndex == 5) { Complete = true; Flush(); game_end(); return; }
    ContextCaptureNext();
}

function ContextMotionCapture() {
    var saved = oRender.NovaContext;
    oRender.NovaContext = global.NovaContextMotion();
    var width = display_get_gui_width();
    var height = display_get_gui_height();
    var sx = width / 256;
    var sy = height / 224;
    var size = 12 * min(sx, sy);
    var preview = surface_create(width, height);
    draw_set_font(global.HUDFont2);
    var binding = global.NovaBinding("hud");
    var status_left = 238 * sx - global.NovaPromptWidth(binding, "STATUS", sx, size, 2);
    for (var frame = 0; frame < 96; frame++) {
        var label = frame < 12 || frame >= 84 ? "" : (frame < 48 ? "LIFT" : "THROW");
        global.NovaContextAdvance(oRender.NovaContext, label, 1 / 60);
        surface_set_target(preview);
        draw_clear_alpha(c_black, 1);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_surface_stretched(oRender.NovaFrame, 0, 0, width, height);
        global.NovaContextDraw(sx, sy, status_left);
        global.NovaPromptDraw(binding, "STATUS", status_left, 209 * sy, sx, sy, size, 2);
        surface_reset_target();
        var number = string(frame);
        while (string_length(number) < 3) number = "0" + number;
        surface_save_part(preview, "nova-context-motion-" + number + ".png", floor(width * 0.48), floor(height * 0.875), floor(width * 0.48), floor(height * 0.11));
    }
    surface_free(preview);
    oRender.NovaContext = saved;
}
