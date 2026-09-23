// Enemies that must hold their attacks while frozen, stoned, paused or facing protection.
function EnemyFixture(object) {
    return instance_create_layer(oLink.x + 48, oLink.y, "Objs_Lower", object, {FloorLevel: 0, RoomIndex: oLink.RoomIndex});
}
function EnemyShots(enemy, medusa) {
    var count = instance_number(oRedBall);
    if (medusa) {
        enemy.alarm[0] = -1;
        with (enemy) event_perform_object(oEnemy_Medusa, ev_alarm, 0);
    }
    else with (enemy) event_perform_object(oEnemy_Cannon, ev_step, ev_step_normal);
    return instance_number(oRedBall) - count;
}

Suite("Enemy status guards", "gameplay", function() {
    Test("Medusa and cannons fire only while active", function() {
        global.Paused = false;
        oLink.Cape = false;
        var medusa = EnemyFixture(oEnemy_Medusa);
        var cannon = EnemyFixture(oEnemy_Cannon);
        cannon.WallInit = false;
        // state, stopwatch, stoned, paused, expected shot, description
        var statuses = [[3, false, false, false, true, "active"], [15, true, false, false, false, "frozen"], [17, false, true, false, false, "stoned"], [3, true, false, false, false, "stopwatch flag"], [3, false, true, false, false, "stone flag"], [15, false, false, false, false, "frozen state"], [17, false, false, false, false, "stone state"], [3, false, false, true, false, "paused"], [3, false, false, false, true, "recovered"]];
        for (var i = 0; i < array_length(statuses); i++) {
            var status = statuses[i];
            for (var e = 0; e < 2; e++) {
                var enemy = e == 0 ? medusa : cannon;
                enemy.State = status[0];
                enemy.StopWatch = status[1];
                enemy.Stoned = status[2];
                enemy.ShootReady = true;
                global.Paused = status[3];
                oLink.State = 12;
                Check((e == 0 ? "Medusa " : "cannon ") + status[5], EnemyShots(enemy, e == 0) == (status[4] ? 1 : 0));
                if (e == 0) Check("Medusa alarm remains armed " + status[5], enemy.alarm[0] > 0);
            }
        }
        global.Paused = false;
        with (medusa) instance_destroy();
        with (cannon) instance_destroy();
        with (oRedBall) instance_destroy();
    });
    Test("a cannon fires once per sword swing", function() {
        global.Paused = false;
        var cannon = EnemyFixture(oEnemy_Cannon);
        cannon.WallInit = false;
        cannon.State = 3;
        cannon.StopWatch = false;
        cannon.Stoned = false;
        cannon.ShootReady = true;
        oLink.State = 12;
        EnemyShots(cannon, false);
        Check("a held swing fires no second shot", EnemyShots(cannon, false) == 0);
        oLink.State = 1;
        EnemyShots(cannon, false);
        oLink.State = 12;
        Check("the next swing fires again", EnemyShots(cannon, false) == 1);
        oLink.State = 1;
        with (cannon) instance_destroy();
        with (oRedBall) instance_destroy();
    });
    Test("Medusa respects the magic cape", function() {
        global.Paused = false;
        var medusa = EnemyFixture(oEnemy_Medusa);
        medusa.State = 3;
        medusa.StopWatch = false;
        medusa.Stoned = false;
        oLink.State = 12;
        oLink.Cape = true;
        var count = instance_number(oRedBall);
        with (medusa) event_perform_object(oEnemy_Medusa, ev_alarm, 0);
        Check("no shot while the cape is active", instance_number(oRedBall) == count);
        oLink.Cape = false;
        oLink.State = 1;
        with (medusa) instance_destroy();
        with (oRedBall) instance_destroy();
    });
    Test("a Pikit steals only from a landed, unprotected Link", function() {
        var parent = EnemyFixture(oEnemy_Pikit);
        parent.State = 7;
        // Link state, invincible, cape, description
        var scenarios = [[20, false, false, "falling into a pit"], [21, false, false, "falling over an edge"], [1, true, false, "invincibility"], [1, false, true, "magic cape"], [1, false, false, "landed"]];
        for (var i = 0; i < array_length(scenarios); i++) {
            var scenario = scenarios[i];
            var tongue = instance_create_layer(oLink.x, oLink.y - 6, "Objs_Lower", oEnemy_Pikit_Tongue);
            tongue.ParentInst = parent;
            tongue.Dist = 24;
            oLink.State = scenario[0];
            oLink.Invincible = scenario[1];
            oLink.Cape = scenario[2];
            global.Inventory_ItemData[40].Amount = 100;
            var before = json_stringify(global.Inventory);
            with (tongue) event_perform_object(oEnemy_Pikit_Tongue, ev_step, ev_step_normal);
            if (i < 4) Check("no theft while " + scenario[3], !tongue.ItemGrabbed && global.Inventory_ItemData[40].Amount == 100 && json_stringify(global.Inventory) == before);
            else Check("theft once landed", tongue.ItemGrabbed);
            with (tongue) {
                if (instance_exists(ItemInst)) instance_destroy(ItemInst);
                instance_destroy();
            }
        }
        oLink.Invincible = false;
        oLink.Cape = false;
        oLink.State = 1;
        with (parent) instance_destroy();
    });
});
