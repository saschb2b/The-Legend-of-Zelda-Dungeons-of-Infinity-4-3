// Contextual interaction hints: Lift, Throw, Talk, Open and Inspect, their motion, placement and bindings.
function ContextNPC(px, py) {
    var npc = instance_create_layer(px, py, "Objs_" + oLink.FloorLevelStr, oNPC, {Name: "Villager_Guard", sprite_index: sVillager_Guard_Down});
    npc.x = px;
    npc.y = py;
    npc.Dialogue = ["Hello."];
    npc.Response = [];
    npc.visible = true;
    return npc;
}
// Finds clear floor near Link for the fixtures and saves what the suite changes; the last test calls ContextEnd.
function ContextBegin() {
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
    ContextFixtureClear = clear;
    if (!clear) return;
    ContextFixtureX = px;
    ContextFixtureY = py;
    ContextSaved = {
        start_x: start_x,
        start_y: start_y,
        facing: oLink.Facing,
        profile: input_profile_get(),
        bindings: input_profile_export("gamepad"),
        saves: json_stringify(global.Users),
        inventory: json_stringify(global.Inventory),
        seed: random_get_seed(),
        stats: StructCopy(global.StatsToAdd),
        save_level: global.SaveLevel
    };
    global.SaveLevel = false;
    input_profile_set("gamepad");
}
function ContextEnd() {
    oLink.Facing = ContextSaved.facing;
    input_profile_set(ContextSaved.profile);
    global.SaveLevel = ContextSaved.save_level;
    global.StatsToAdd = ContextSaved.stats;
    random_set_seed(ContextSaved.seed);
    MovementReset(ContextSaved.start_x, ContextSaved.start_y);
    oRender.NovaContext = global.NovaContextMotion();
}
// Puts Link on the clear floor with nothing blocking an interaction. Returns false without clear floor.
function ContextPlace() {
    if (!ContextFixtureClear) return false;
    MovementReset(ContextFixtureX, ContextFixtureY);
    oLink.StairsAutoMove = false;
    oLink.BounceBack = false;
    oLink.InDoor_Facing = false;
    oLink.InDoor_Aligned = true;
    return true;
}
function ContextPot() {
    return instance_create_layer(ContextFixtureX, ContextFixtureY - 16, "Objs_Lower", oPot, {FloorLevel: oLink.FloorLevel});
}
function ContextChest() {
    var chest = instance_create_layer(ContextFixtureX, ContextFixtureY - 16, "Objs_Lower", oItem_Treasure, {From: 2, ContentsFrom: 2});
    chest.ContentsObj = 40;
    chest.image_index = 0;
    return chest;
}
// A one-item shop in front of Link; ContextShopClose restores Link's shop selection.
function ContextShopOpen() {
    var px = ContextFixtureX;
    var py = ContextFixtureY;
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
    return {shop: shop, wall: wall, goods: goods, look: oLink.ShopItemLook, list: ds_list_write(oLink.CollidedShopItemList), inventory: json_stringify(global.Inventory)};
}
function ContextShopClose(fixture) {
    with (fixture.goods) instance_destroy();
    with (fixture.wall) instance_destroy();
    with (fixture.shop) instance_destroy();
    oLink.ShopItemLook = fixture.look;
    ds_list_read(oLink.CollidedShopItemList, fixture.list);
    MovementReset(ContextFixtureX, ContextFixtureY);
}
// Returns a motion that has faded fully in on label, as the first test checks step by step.
function ContextMotionShown(label) {
    var motion = global.NovaContextMotion();
    global.NovaContextAdvance(motion, label, 0);
    global.NovaContextAdvance(motion, label, 0.06);
    global.NovaContextAdvance(motion, label, 0.06);
    return motion;
}

Suite("Interaction hints", "gameplay", function() {
    BeforeAll(ContextBegin);
    Test("empty ground offers no interaction", function() {
        Check("context fixture has clear floor", ContextFixtureClear);
        if (!ContextPlace()) return;
        Check("empty ground has no interaction hint", global.NovaContextAction() == "");
    });
    Test("Lift appears only for a liftable pot Link faces", function() {
        if (!ContextPlace()) return;
        var px = ContextFixtureX;
        var py = ContextFixtureY;
        var pot = ContextPot();
        var positions = [[0,-16],[0,8],[-16,0],[16,0]];
        for (var dir = 1; dir <= 4; dir++) {
            pot.x = px + positions[dir - 1][0];
            pot.y = py + positions[dir - 1][1];
            oLink.Facing = dir;
            Check("Lift follows facing " + string(dir), global.NovaContextAction() == "LIFT");
            pot.Hidden = true;
            Check("hidden pot has no hint " + string(dir), global.NovaContextAction() == "");
            pot.Hidden = false;
        }
        pot.x = px;
        pot.y = py - 16;
        oLink.Facing = 2;
        Check("facing away clears Lift", global.NovaContextAction() == "");
        oLink.Facing = 1;
        pot.FloorLevel = oLink.FloorLevel == 0 ? 1 : 0;
        Check("another floor cannot be lifted", global.NovaContextAction() == "");
        pot.FloorLevel = oLink.FloorLevel;
        pot.State = 5;
        Check("destroyed pot has no Lift hint", global.NovaContextAction() == "");
        with (pot) instance_destroy();
    });
    Test("reading Lift changes no object or player state", function() {
        if (!ContextPlace()) return;
        var pot = ContextPot();
        oLink.Facing = 1;
        var link_state = oLink.State;
        var rng = random_get_seed();
        repeat (20) global.NovaContextAction();
        Check("hint queries preserve object and player state", pot.State == 0 && oLink.State == link_state && oLink.ItemHolding == noone && random_get_seed() == rng && json_stringify(global.Users) == ContextSaved.saves && json_stringify(global.Inventory) == ContextSaved.inventory);
        with (pot) instance_destroy();
    });
    Test("Lift picks up the pot and becomes Throw", function() {
        if (!ContextPlace()) return;
        var pot = ContextPot();
        oLink.Facing = 1;
        oRender.NovaContext = global.NovaContextMotion();
        global.NovaContextUpdate(0.12);
        PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
        Check("the hinted interaction lifts the actual pot", oLink.State == 6 && oLink.ItemHolding == pot);
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
        Check("pickup keeps the accepted Lift visible until carrying is ready", held_hint && lift_frames > 1 && oLink.State != 6 && oLink.ItemHolding == pot);
        Check("carrying changes Lift to Throw", global.NovaContextAction() == "THROW");
        global.NovaContextUpdate(0.06);
        Check("pickup changes the label without fading the button", oRender.NovaContext.alpha == 1 && oRender.NovaContext.shown_label == "THROW" && oRender.NovaContext.text_alpha > 0 && oRender.NovaContext.text_alpha < 1);
        global.NovaContextUpdate(0.06);
        Check("pickup completes on the available Throw action", oRender.NovaContext.shown_label == "THROW" && oRender.NovaContext.text_alpha > 0.999);
        oLink.InDoor_Facing = true;
        Check("blocked doorway does not advertise Throw", global.NovaContextAction() != "THROW");
        oLink.InDoor_Facing = false;
        PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
        Check("the hinted carrying action starts a throw", oLink.State == 10);
        MovementReset(ContextFixtureX, ContextFixtureY);
        with (pot) instance_destroy();
    });
    Test("Talk appears for a person Link faces and starts only on Interact", function() {
        if (!ContextPlace()) return;
        oLink.Facing = 1;
        var npc = ContextNPC(ContextFixtureX, ContextFixtureY - 16);
        Check("person in front advertises Talk", global.NovaContextAction() == "TALK");
        repeat (20) global.NovaContextAction();
        Check("reading Talk cannot start dialogue", !npc.DB_Init && !npc.DB_Started && !instance_exists(oDialogueBox));
        npc.DialogueIgnore = true;
        Check("unavailable conversation hides Talk", global.NovaContextAction() == "");
        npc.DialogueIgnore = false;
        npc.DB_Delay = true;
        Check("conversation cooldown hides Talk", global.NovaContextAction() == "");
        npc.DB_Delay = false;
        oRender.NovaContext = global.NovaContextMotion();
        global.NovaContextUpdate(0.03);
        Check("Talk begins fading in before the interaction", oRender.NovaContext.alpha > 0 && oRender.NovaContext.alpha < 1);
        PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
        Check("the hinted interaction starts the conversation during its fade", npc.DB_Init);
        npc.DB_Init = false;
        with (npc) instance_destroy();
        MovementReset(ContextFixtureX, ContextFixtureY);
    });
    Test("Open appears only for a visible closed chest and reading it changes nothing", function() {
        if (!ContextPlace()) return;
        oLink.Facing = 1;
        var chest = ContextChest();
        Check("closed chest advertises Open", global.NovaContextAction() == "OPEN");
        chest.visible = false;
        Check("hidden chest has no Open hint", global.NovaContextAction() == "");
        chest.visible = true;
        chest.image_index = 1;
        Check("opened chest has no Open hint", global.NovaContextAction() == "");
        chest.image_index = 0;
        var rng = random_get_seed();
        repeat (20) global.NovaContextAction();
        Check("reading Open preserves treasure and RNG", chest.image_index == 0 && json_stringify(global.StatsToAdd) == json_stringify(ContextSaved.stats) && random_get_seed() == rng);
        with (chest) instance_destroy();
    });
    Test("hints hide while Link is busy, paused, travelling or in a menu", function() {
        if (!ContextPlace()) return;
        oLink.Facing = 1;
        var chest = ContextChest();
        var states = [0,3,5,6,8,9,10,12,19,20,22,23,24];
        for (var i = 0; i < array_length(states); i++) {
            oLink.State = states[i];
            Check("no interaction hint during state " + string(states[i]), global.NovaContextAction() == "");
        }
        oLink.State = 1;
        global.Paused = true;
        Check("paused game hides interaction hint", global.NovaContextAction() == "");
        global.NovaContextUpdate(1 / 60);
        Check("pause clears pending label transitions", oRender.NovaContext.alpha == 0 && oRender.NovaContext.shown_label == "");
        global.Paused = false;
        global.NovaContextUpdate(0.12);
        oCamera.RoomTransition = 1;
        Check("room scrolling hides interaction hint", global.NovaContextAction() == "");
        global.NovaContextUpdate(1 / 60);
        Check("room changes cannot carry a stale hint into the next room", oRender.NovaContext.alpha == 0);
        oCamera.RoomTransition = 0;
        oLink.BounceBack = true;
        Check("knockback hides interaction hint", global.NovaContextAction() == "");
        oLink.BounceBack = false;
        oLink.StairsAutoMove = true;
        Check("stairs hide interaction hint", global.NovaContextAction() == "");
        oLink.StairsAutoMove = false;
        var modal_objects = [oMenu_Game, oMap, oInventory, oDialogueBox];
        for (var i = 0; i < array_length(modal_objects); i++) {
            global.NovaContextUpdate(0.12);
            var modal = instance_create_layer(0, 0, "System", modal_objects[i]);
            Check("modal hides interaction " + object_get_name(modal_objects[i]), global.NovaContextAction() == "");
            global.NovaContextUpdate(1 / 60);
            Check("modal clears animated interaction " + object_get_name(modal_objects[i]), oRender.NovaContext.alpha == 0);
            with (modal) instance_destroy();
            global.Paused = false;
            oLink.State = 1;
        }
        with (chest) instance_destroy();
    });
    Test("drawing hints preserves animation time and HUD opacity", function() {
        if (!ContextPlace()) return;
        oLink.Facing = 1;
        var chest = ContextChest();
        draw_set_font(global.HUDFont2);
        var layout = global.NovaHUDLayout(1280, 960);
        var status_width = global.NovaPromptWidth(global.NovaBinding("hud"), "STATUS", layout.scale, 12 * layout.scale, 2);
        oRender.NovaContext = global.NovaContextMotion();
        global.NovaContextUpdate(0.06);
        var motion_before_draw = json_stringify(oRender.NovaContext);
        var target = surface_create(1280, 960);
        surface_set_target(target);
        draw_set_alpha(0.7);
        var incoming_alpha = draw_get_alpha();
        repeat (3) global.NovaContextDraw(layout, layout.right - status_width);
        Check("drawing hints preserves animation time", json_stringify(oRender.NovaContext) == motion_before_draw);
        Check("drawing hints preserves HUD opacity", draw_get_alpha() == incoming_alpha);
        surface_reset_target();
        surface_free(target);
        draw_set_alpha(1);
        with (chest) instance_destroy();
    });
    Test("the hint sits left of Status and shows the current Interact binding", function() {
        if (!ContextPlace()) return;
        oLink.Facing = 1;
        var chest = ContextChest();
        draw_set_font(global.HUDFont2);
        var layout = global.NovaHUDLayout(1280, 960);
        var status_width = global.NovaPromptWidth(global.NovaBinding("hud"), "STATUS", layout.scale, 12 * layout.scale, 2);
        var hint = global.NovaContextHint(layout, layout.right - status_width);
        Check("context hint sits left of Status with a fixed gap", hint.visible && hint.label == "OPEN" && abs(hint.right + 8 * layout.scale + status_width - layout.right) < 0.01);
        Check("context hint uses the interaction binding", global.NovaGlyph(hint.binding) == 0);
        input_binding_set("action", input_binding_gamepad_button(gp_face4), 0, 0, "gamepad");
        var remapped = global.NovaContextHint(layout, layout.right - status_width);
        Check("remapping changes the interaction glyph without shifting it", global.NovaGlyph(remapped.binding) == 3 && remapped.icon_x == hint.icon_x);
        input_profile_set("keyboard");
        var keyboard = global.NovaContextHint(layout, layout.right - status_width);
        Check("keyboard hint shows Interact rather than menu Confirm", keyboard.binding.__value == global.NovaBinding("action").__value && global.NovaGlyph(keyboard.binding) == -1 && keyboard.right < layout.right - status_width);
        input_profile_import(ContextSaved.bindings, "gamepad");
        input_profile_set("gamepad");
        with (chest) instance_destroy();
    });
    Test("Interact opens the hinted chest", function() {
        if (!ContextPlace()) return;
        oLink.Facing = 1;
        var chest = ContextChest();
        PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
        Check("the hinted interaction opens the actual chest", chest.image_index == 1 && global.StatsToAdd[5] == ContextSaved.stats[5] + 1);
        with (chest) instance_destroy();
        with (oItem_Rupee) instance_destroy();
        MovementReset(ContextFixtureX, ContextFixtureY);
    });
    Test("shops advertise Inspect and reading it changes nothing", function() {
        if (!ContextPlace()) return;
        var fixture = ContextShopOpen();
        oLink.Facing = 1;
        Check("shop advertises Inspect rather than Buy", global.NovaContextAction() == "INSPECT");
        repeat (20) global.NovaContextAction();
        Check("shop hint preserves selection and collision list", !fixture.shop.DB_Init && oLink.ShopItemLook == fixture.look && ds_list_write(oLink.CollidedShopItemList) == fixture.list);
        Check("shop hint cannot buy goods", fixture.shop.ItemsSold == 0 && instance_exists(fixture.goods) && json_stringify(global.Inventory) == fixture.inventory);
        var pot = instance_create_layer(ContextFixtureX + 32, ContextFixtureY, "Objs_Lower", oPot);
        oLink.ItemHolding = pot;
        oLink.State = 11;
        oLink.InDoor_Facing = false;
        oLink.InDoor_Aligned = true;
        Check("carrying takes priority over the shop hint", global.NovaContextAction() == "THROW");
        oLink.ItemHolding = noone;
        oLink.State = 1;
        with (pot) instance_destroy();
        ContextShopClose(fixture);
    });
    Test("Inspect starts the shop conversation without purchasing", function() {
        if (!ContextPlace()) return;
        var fixture = ContextShopOpen();
        oLink.Facing = 1;
        PressEvent(oLink, "action", oLink, ev_step, ev_step_normal);
        Check("Inspect starts the shop conversation without purchasing", fixture.shop.DB_Init && fixture.shop.ItemsSold == 0 && oLink.ShopItemLook == fixture.goods);
        ContextShopClose(fixture);
        ContextEnd();
    });
});

Suite("Interaction hint motion", "gameplay", function() {
    Test("a hint fades in over 120 ms", function() {
        var motion = global.NovaContextMotion();
        global.NovaContextAdvance(motion, "TALK", 0);
        Check("hint appearance starts transparent", motion.alpha == 0);
        global.NovaContextAdvance(motion, "TALK", 0.06);
        Check("hint fades in over time", abs(motion.alpha - 0.5) < 0.001);
        global.NovaContextAdvance(motion, "TALK", 0.06);
        Check("hint reaches full opacity after 120 ms", motion.alpha == 1);
    });
    Test("a label change fades through one word at a time", function() {
        var motion = ContextMotionShown("TALK");
        global.NovaContextAdvance(motion, "LIFT", 0.02);
        Check("label change fades the old word while keeping the glyph opaque", motion.alpha == 1 && motion.shown_label == "TALK" && abs(motion.text_alpha - 0.5) < 0.001);
        global.NovaContextAdvance(motion, "TALK", 0);
        Check("reversing a label transition preserves visible text opacity", motion.shown_label == "TALK" && abs(motion.text_alpha - 0.5) < 0.001);
        global.NovaContextAdvance(motion, "OPEN", 0.03);
        Check("rapid target changes show only the latest word after fade-out", motion.shown_label == "OPEN" && motion.text_alpha > 0 && motion.text_alpha < 0.5 && motion.alpha == 1);
        global.NovaContextAdvance(motion, "OPEN", 0.12);
        Check("latest action finishes fully readable", motion.shown_label == "OPEN" && motion.text_alpha == 1);
    });
    Test("a hint fades out and forgets its label", function() {
        var motion = ContextMotionShown("OPEN");
        global.NovaContextAdvance(motion, "", 0.05);
        Check("hint fades out over time", abs(motion.alpha - 0.5) < 0.001);
        var alpha = motion.alpha;
        global.NovaContextAdvance(motion, "OPEN", 0);
        Check("reacquiring an interaction never resets its opacity", motion.alpha == alpha);
        global.NovaContextAdvance(motion, "OPEN", 0.06);
        Check("reacquired hint returns to full opacity", motion.alpha == 1);
        global.NovaContextAdvance(motion, "", 0.10);
        Check("hidden hints discard their labels after 100 ms", motion.alpha == 0 && motion.label == "" && motion.shown_label == "");
        global.NovaContextAdvance(motion, "LIFT", 0.06);
        Check("new interaction cannot revive an unrelated old label", motion.shown_label == "LIFT" && motion.text_alpha == 1);
    });
    Test("transitions finish at 30, 60 and 120 Hz", function() {
        for (var hz = 30; hz <= 120; hz *= 2) {
            var motion = global.NovaContextMotion();
            repeat (ceil(hz * 0.12)) global.NovaContextAdvance(motion, "LIFT", 1 / hz);
            Check("hint entrance finishes at " + string(hz) + " Hz", motion.alpha > 0.999);
            repeat (ceil(hz * 0.12)) global.NovaContextAdvance(motion, "THROW", 1 / hz);
            Check("label change finishes at " + string(hz) + " Hz", motion.shown_label == "THROW" && motion.text_alpha > 0.999);
            repeat (ceil(hz * 0.10) + 1) global.NovaContextAdvance(motion, "", 1 / hz);
            Check("hint exit finishes at " + string(hz) + " Hz", motion.alpha == 0);
        }
    });
    Test("the glyph stays anchored for every label", function() {
        draw_set_font(global.HUDFont2);
        var previous_x = -1;
        var layout = global.NovaHUDLayout(1280, 960);
        var labels = ["LIFT", "THROW", "TALK", "OPEN", "INSPECT"];
        for (var i = 0; i < array_length(labels); i++) {
            var hint = global.NovaContextHint(layout, 980, labels[i]);
            Check("interaction glyph stays anchored for " + labels[i], previous_x == -1 || abs(hint.icon_x - previous_x) < 0.001);
            previous_x = hint.icon_x;
        }
    });
});
