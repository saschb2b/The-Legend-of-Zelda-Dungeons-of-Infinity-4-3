global.NovaSlotSymbols = [0,1,0,4,0,2,0,5,0,6,0,1,0,3,0,2,0,6,0,4,0,1,0,5,0,3,0,6,0,2,0,1,0,4,0,5,0,2,0,6,0,3,0,4,0,5,0,1,0,2,0,6];
global.NovaSlotMultipliers = [0,1,2,5,10,25,100];

global.NovaArcadeTemplates = function() {
    var arcade = global.Templates_Room[4][1][0];
    var pub = global.Templates_Room[4][1][3];
    var changed = 0;
    for (var i = 0; i < array_length(arcade.Objs); i++) {
        var obj = arcade.Objs[i];
        if (obj.id == 28362 && obj.gid == 182 && obj.type == "") {
            obj.type = "ClawMachine"; obj.x = 91; obj.y = 21; changed++;
        }
    }
    for (var i = 0; i < array_length(pub.Objs); i++) {
        var obj = pub.Objs[i];
        if (obj.gid == 182 && obj.type == "Poker" && (obj.id == 28875 || obj.id == 28888 || obj.id == 28889 || obj.id == 28891)) {
            obj.type = "Mothula"; changed++;
        }
    }
    if (changed != 5) throw "Village arcade template mismatch";
};
global.NovaSlotResult = function(roll) {
    if (roll <= 15) return 6;
    if (roll <= 100) return 5;
    if (roll <= 275) return 4;
    if (roll <= 625) return 3;
    if (roll <= 1125) return 2;
    if (roll <= 2725) return 1;
    return 0;
};
global.NovaSlotLosingSymbols = function() {
    var symbols = array_create(3);
    for (var i = 0; i < 3; i++) symbols[i] = choose(0,0,0,0,1,2,3,4,5,5,6,6);
    if (symbols[0] == symbols[1] && symbols[1] == symbols[2]) symbols[choose(0,1,2,2)] = 0;
    return symbols;
};
global.NovaClawPrizePool = function(food, heart, wish) {
    var pool = [];
    if (food) repeat (75) array_push(pool, 13);
    var ordinary = [48,14,23,27,33];
    for (var i = 0; i < 5; i++) repeat (food ? 4 : 19) array_push(pool, ordinary[i]);
    if (wish) array_push(pool, 47);
    if (heart) array_push(pool, 18);
    return pool;
};
global.NovaClawPrizeIndex = function(item_class) {
    switch (item_class) {
        case 13: return choose(4,5);
        case 48: return choose(0,0,0,0,0,0,0,0,1,1,1,1,3,4,5,2);
        case 23: return Kinstone_PickIndex();
        case 14: return Gem_PickIndex();
        case 33: return 2;
    }
    return 0;
};
global.NovaArcadePrompts = function() {
    if (instance_exists(oDialogueBox)) return;
    var prompts = [];
    var machine = global.Arcade_ActiveInst;
    if (instance_exists(machine) && machine.object_index == oArcade_Mothula && machine.State != 0) {
        if (!machine.Paid) {
            array_push(prompts, {binding: global.NovaBinding("nova_bag_previous"), binding2: global.NovaBinding("nova_bag_next"), label:"BET"});
            array_push(prompts, {binding: global.NovaBinding(global.NovaConfirmVerb()), label:"SPIN"});
        }
        array_push(prompts, {binding: global.NovaBinding(global.NovaCloseVerb()), label:"CLOSE"});
    } else {
        with (oClawMachine) {
            if (Paid) {
                if (State == 2 && ClawX > 6) array_push(prompts, {binding: global.NovaBinding(global.NovaConfirmVerb()), label:"GRAB"});
                array_push(prompts, {binding: global.NovaBinding(global.NovaCloseVerb()), label:"CLOSE"});
            }
        }
    }
    if (array_length(prompts) == 0) return;
    var sx = display_get_gui_width() / 256;
    var sy = display_get_gui_height() / 224;
    draw_set_font(global.HUDFont2);
    draw_set_alpha(1);
    prompts = global.NovaHintRow(prompts, 238 * sx, 209 * sy, sx, sy, 12 * min(sx,sy), 8*sx, 224*sx);
    for (var i = 0; i < array_length(prompts); i++) global.NovaHintDraw(prompts[i]);
};
