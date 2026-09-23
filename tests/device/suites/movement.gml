// Link's movement speeds, facing, input cancellation and wall sliding.
function MovementReset(px, py) {
    with (oLink) {
        ItemHolding = noone;
        UpdateState(1);
        x = px;
        y = py;
        MoveAssist = false;
        MoveAssistDir = 0;
        InDoorPassage = 0;
        Facing = 4;
        FacingLock = 4;
    }
    global.NovaTestHeld = [];
    global.NovaTestInput = "";
}
function MovementTick() {
    with (oLink) event_perform_object(oLink, ev_step, ev_step_normal);
}
function MovementAt(px, py) {
    // Runner coordinates accumulate float error over eight steps; allow 1/256 pixel.
    var matched = abs(oLink.x - px) < 1 / 256 && abs(oLink.y - py) < 1 / 256;
    if (!matched) show_debug_message("Movement: expected " + string_format(px, 0, 6) + "," + string_format(py, 0, 6)
        + "; actual " + string_format(oLink.x, 0, 6) + "," + string_format(oLink.y, 0, 6));
    return matched;
}
// A pot Link can carry without it colliding with anything.
function MovementCarried() {
    var carried = instance_create_layer(MovementX, MovementY, "Objs_Lower", oPot, {FloorLevel: oLink.FloorLevel});
    carried.mask_index = sEmptyMask;
    return carried;
}

// The tests share one patch of clear floor; the last one returns Link to where he stood.
Suite("Movement and facing", "gameplay", function() {
    BeforeAll(function() {
        MovementStartX = oLink.x;
        MovementStartY = oLink.y;
        MovementFacing = oLink.Facing;
        MovementSwordLevel = global.Inventory_ItemData[44].Index;
        MovementHeldItem = oLink.ItemHolding;
        MovementX = MovementStartX;
        MovementY = MovementStartY;
        MovementClear = false;
        for (var yy = max(48, MovementStartY - 64); yy <= min(1999, MovementStartY + 64) && !MovementClear; yy += 16) {
            for (var xx = max(48, MovementStartX - 64); xx <= min(1999, MovementStartX + 64) && !MovementClear; xx += 16) {
                if (collision_rectangle(xx - 40, yy - 40, xx + 40, yy + 40, oWall, false, true) == noone
                    && collision_rectangle(xx - 40, yy - 40, xx + 40, yy + 40, oDoor, false, true) == noone
                    && OnStairs(xx, yy) == 0 && GetFloorLevelID(xx, yy) == oLink.FloorLevel) {
                    MovementX = xx;
                    MovementY = yy;
                    MovementClear = true;
                }
            }
        }
        global.Inventory_ItemData[44].Index = 0;
    });
    Test("the fixture stands on clear floor", function() {
        Check("movement fixture has clear floor", MovementClear);
    });
    Test("each mode covers its SNES distance in eight directions", function() {
        var px = MovementX;
        var py = MovementY;
        var directions = [["right"], ["left"], ["down"], ["up"], ["right", "down"], ["left", "down"], ["right", "up"], ["left", "up"]];
        var axes = [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, 1], [1, -1], [-1, -1]];
        var modes = ["walking", "running", "carrying", "sword ready"];
        // NTSC SNES uses 24/16 for walking and 20/13 for carrying and sword-ready, in sixteenths of a pixel.
        var straight = [1.5, 2, 1.25, 1.25];
        var diagonal = [1, 4 / 3, 13 / 16, 13 / 16];
        var carried = MovementCarried();
        for (var mode = 0; mode < array_length(modes); mode++) {
            for (var dir = 0; dir < array_length(directions); dir++) {
                MovementReset(px, py);
                for (var button = 0; button < array_length(directions[dir]); button++) array_push(global.NovaTestHeld, directions[dir][button]);
                if (mode == 1) array_push(global.NovaTestHeld, "action");
                if (mode == 2) oLink.ItemHolding = carried;
                if (mode == 3) {
                    array_push(global.NovaTestHeld, "sword");
                    with (oLink) { UpdateState(12); NovaSwordFinishSwing(); }
                }
                var expected_speed = dir < 4 ? straight[mode] : diagonal[mode];
                repeat (8) MovementTick();
                Check(modes[mode] + " displacement direction " + string(dir), MovementAt(px + axes[dir][0] * expected_speed * 8, py + axes[dir][1] * expected_speed * 8));
                if (mode == 2) Check("carried item follows direction " + string(dir), carried.x == oLink.x && abs(carried.y - oLink.y) <= 18);
                if (mode == 3) Check("sword facing stays locked direction " + string(dir), oLink.Facing == 4);
            }
        }
        with (carried) instance_destroy();
    });
    Test("each mode turns to the expected facing", function() {
        var px = MovementX;
        var py = MovementY;
        var carried = MovementCarried();
        var seed = random_get_seed();
        var sword_sound = asset_get_index("Sound_Sword" + string(global.Inventory_ItemData[44].Index + 1));
        var directions = [["right"], ["left"], ["down"], ["up"], ["right", "down"], ["left", "down"], ["right", "up"], ["left", "up"], []];
        // Rows start facing up, down, left, right. Columns follow the input cases above.
        var expected = [
            [4, 3, 2, 1, 2, 2, 1, 1, 1],
            [4, 3, 2, 1, 2, 2, 1, 1, 2],
            [4, 3, 2, 1, 2, 3, 1, 3, 3],
            [4, 3, 2, 1, 4, 2, 4, 1, 4]
        ];
        var modes = ["walking", "running", "carrying", "strafe", "sword ready"];
        for (var mode = 0; mode < array_length(modes); mode++) {
            for (var start = 1; start <= 4; start++) {
                for (var dir = 0; dir < array_length(directions); dir++) {
                    var matched = true;
                    // Multiple seeds expose random turns without depending on the current dungeon RNG.
                    for (var trial = 0; trial < 8; trial++) {
                        MovementReset(px, py);
                        random_set_seed(100 + trial);
                        oLink.Facing = start;
                        for (var button = 0; button < array_length(directions[dir]); button++) array_push(global.NovaTestHeld, directions[dir][button]);
                        if (mode == 1) array_push(global.NovaTestHeld, "action");
                        if (mode == 2) oLink.ItemHolding = carried;
                        if (mode == 3) array_push(global.NovaTestHeld, "strafe");
                        if (mode == 4) {
                            array_push(global.NovaTestHeld, "sword");
                            with (oLink) { UpdateState(12); NovaSwordFinishSwing(); }
                            // Repeated sword setup shares one frame and can exhaust audio channels.
                            audio_stop_sound(sword_sound);
                        }
                        var wanted = mode >= 3 ? start : expected[start - 1][dir];
                        repeat (3) {
                            MovementTick();
                            if (oLink.Facing != wanted) matched = false;
                        }
                    }
                    Check(modes[mode] + " facing from " + string(start) + " with input " + string(dir), matched);
                }
            }
        }
        random_set_seed(seed);
        with (carried) instance_destroy();
    });
    Test("corner assistance preserves facing", function() {
        // A fixed seed keeps any random turn reproducible.
        var seed = random_get_seed();
        random_set_seed(107);
        for (var start = 1; start <= 4; start++) {
            MovementReset(round(MovementX / 2) * 2, round(MovementY / 2) * 2);
            oLink.Facing = start;
            oLink.MoveAssistDir = 4;
            global.NovaTestHeld = ["up"];
            MovementTick();
            Check("corner assistance preserves facing " + string(start), oLink.Facing == start);
        }
        random_set_seed(seed);
    });
    Test("knockback preserves facing", function() {
        // A fixed seed keeps any random turn reproducible.
        var seed = random_get_seed();
        random_set_seed(107);
        for (var start = 1; start <= 4; start++) {
            MovementReset(MovementX, MovementY);
            oLink.Facing = start;
            oLink.BounceBack = true;
            oLink.vx = 1;
            oLink.vy = -1;
            global.NovaTestHeld = ["down", "left"];
            MovementTick();
            Check("knockback preserves facing " + string(start), oLink.Facing == start);
        }
        random_set_seed(seed);
    });
    Test("releasing half a diagonal faces the direction still held", function() {
        // A fixed seed keeps any random turn reproducible.
        var seed = random_get_seed();
        random_set_seed(107);
        var directions = [["right"], ["left"], ["down"], ["up"], ["right", "down"], ["left", "down"], ["right", "up"], ["left", "up"]];
        for (var dir = 4; dir < 8; dir++) {
            for (var retained = 0; retained < 2; retained++) {
                MovementReset(MovementX, MovementY);
                global.NovaTestHeld = directions[dir];
                MovementTick();
                var key = directions[dir][retained];
                global.NovaTestHeld = [key];
                MovementTick();
                var wanted = key == "right" ? 4 : (key == "left" ? 3 : (key == "down" ? 2 : 1));
                Check("diagonal release faces remaining direction " + string(dir) + "/" + string(retained), oLink.Facing == wanted);
                global.NovaTestHeld = [];
                MovementTick();
                Check("stopping retains facing " + string(dir) + "/" + string(retained), oLink.Facing == wanted);
            }
        }
        random_set_seed(seed);
    });
    Test("opposing directions cancel before scaling", function() {
        var cancellation = [[[], 0, 0], [["up", "down"], 0, 0], [["left", "right"], 0, 0], [["up", "down", "right"], 1.5, 0], [["left", "right", "up"], 0, -1.5], [["up", "down", "left", "right"], 0, 0]];
        for (var i = 0; i < array_length(cancellation); i++) {
            MovementReset(MovementX, MovementY);
            global.NovaTestHeld = cancellation[i][0];
            MovementTick();
            Check("opposing directions cancel before scaling " + string(i), MovementAt(MovementX + cancellation[i][1], MovementY + cancellation[i][2]));
        }
    });
    Test("releasing directions restores straight speed and then stops", function() {
        MovementReset(MovementX, MovementY);
        global.NovaTestHeld = ["up", "right"];
        MovementTick();
        var diagonal_x = oLink.x;
        var diagonal_y = oLink.y;
        global.NovaTestHeld = ["right"];
        MovementTick();
        Check("releasing one diagonal direction restores straight speed", MovementAt(diagonal_x + 1.5, diagonal_y));
        var stopped_x = oLink.x;
        var stopped_y = oLink.y;
        global.NovaTestHeld = [];
        MovementTick();
        Check("releasing all directions stops movement", MovementAt(stopped_x, stopped_y));
    });
    Test("running while carrying keeps the carrying speed", function() {
        var carried = MovementCarried();
        MovementReset(MovementX, MovementY);
        oLink.ItemHolding = carried;
        global.NovaTestHeld = ["up", "right", "action"];
        MovementTick();
        Check("run input retains carrying's SNES diagonal ratio", MovementAt(MovementX + 13 / 16, MovementY - 13 / 16));
        oLink.ItemHolding = noone;
        with (carried) instance_destroy();
    });
    Test("strafing moves at the SNES diagonal speed without turning", function() {
        MovementReset(MovementX, MovementY);
        global.NovaTestHeld = ["up", "right", "strafe"];
        MovementTick();
        Check("strafe uses SNES diagonal speed and retains facing", MovementAt(MovementX + 1, MovementY - 1) && oLink.Facing == 4);
    });
    Test("doorways limit running to walking speed", function() {
        MovementReset(MovementX, MovementY);
        oLink.InDoorPassage = 1;
        global.NovaTestHeld = ["right", "action"];
        MovementTick();
        Check("doorway still limits running to walking speed", MovementAt(MovementX + 1.5, MovementY));
    });
    Test("corner assistance keeps its own speed", function() {
        var assist_x = round(MovementX / 2) * 2;
        var assist_y = round(MovementY / 2) * 2;
        MovementReset(assist_x, assist_y);
        global.NovaTestHeld = ["up"];
        oLink.MoveAssistDir = 4;
        MovementTick();
        Check("corner assistance retains its own movement speed", MovementAt(assist_x + 1, assist_y - 1));
    });
    Test("scripted movement keeps its velocity and duration", function() {
        MovementReset(MovementX, MovementY);
        with (oLink) Link_SetAutoMove(1, -1, 0.5, 20);
        MovementTick();
        Check("scripted movement retains its velocity and duration", MovementAt(MovementX + 0.5, MovementY - 0.5) && oLink.AutoMoveFrames == 19);
    });
    Test("knockback ignores held directions", function() {
        MovementReset(MovementX, MovementY);
        oLink.BounceBack = true;
        oLink.vx = -2;
        oLink.vy = 2;
        global.NovaTestHeld = ["up", "right"];
        MovementTick();
        Check("knockback ignores held movement directions", MovementAt(MovementX - 2, MovementY + 2));
    });
    Test("airborne movement keeps its velocity", function() {
        MovementReset(MovementX, MovementY);
        oLink.State = 3;
        oLink.vx = 2;
        oLink.vy = -2;
        MovementTick();
        Check("airborne movement retains its velocity", MovementAt(MovementX + 2, MovementY - 2));
    });
    Test("falling over an edge keeps its velocity", function() {
        MovementReset(MovementX, MovementY);
        oLink.State = 21;
        oLink.FallOverEdgeDelay = 20;
        oLink.vx = 0.5;
        oLink.vy = 0.5;
        MovementTick();
        Check("falling over an edge retains its velocity", MovementAt(MovementX + 0.5, MovementY + 0.5));
    });
    Test("walking, carrying and sword-ready movement slide along walls", function() {
        var px = MovementX;
        var py = MovementY;
        var modes = ["walking", "running", "carrying", "sword ready"];
        var carried = MovementCarried();
        var wall_modes = [0, 2, 3];
        for (var m = 0; m < array_length(wall_modes); m++) {
            var wall_mode = wall_modes[m];
            for (var axis = 0; axis < 2; axis++) {
                for (var wall_dir = -1; wall_dir <= 1; wall_dir += 2) {
                    MovementReset(px, py);
                    if (wall_mode == 2) oLink.ItemHolding = carried;
                    if (wall_mode == 3) {
                        global.NovaTestHeld = ["sword"];
                        with (oLink) { UpdateState(12); NovaSwordFinishSwing(); }
                    }
                    var wall = instance_create_layer(px, py, "Objs_Lower", oWall);
                    wall.FloorLevel = oLink.FloorLevel;
                    wall.mask_index = sWallMask;
                    wall.image_xscale = axis == 0 ? 1 : 8;
                    wall.image_yscale = axis == 0 ? 8 : 1;
                    if (axis == 0) {
                        wall.x += wall_dir > 0 ? oLink.bbox_right - wall.bbox_left : oLink.bbox_left - wall.bbox_right;
                        wall.y += py - (wall.bbox_top + wall.bbox_bottom) / 2;
                        global.NovaTestHeld = [wall_dir > 0 ? "right" : "left", "up"];
                    } else {
                        wall.y += wall_dir > 0 ? oLink.bbox_bottom - wall.bbox_top : oLink.bbox_top - wall.bbox_bottom;
                        wall.x += px - (wall.bbox_left + wall.bbox_right) / 2;
                        global.NovaTestHeld = ["right", wall_dir > 0 ? "down" : "up"];
                    }
                    if (wall_mode == 3) array_push(global.NovaTestHeld, "sword");
                    repeat (4) MovementTick();
                    var distance = wall_mode == 0 ? 4 : 3.25;
                    Check(modes[wall_mode] + " slides along wall " + string(axis) + "/" + string(wall_dir), axis == 0 ? MovementAt(px, py - distance) : MovementAt(px + distance, py));
                    with (wall) instance_destroy();
                }
            }
        }
        with (carried) instance_destroy();
        MovementReset(MovementStartX, MovementStartY);
        global.Inventory_ItemData[44].Index = MovementSwordLevel;
        oLink.ItemHolding = MovementHeldItem;
        oLink.Facing = MovementFacing;
        oLink.FacingLock = MovementFacing;
        oLink.HitBox.x = MovementStartX;
        oLink.HitBox.y = MovementStartY;
    });
});
