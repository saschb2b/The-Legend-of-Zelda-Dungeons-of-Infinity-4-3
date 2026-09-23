// Shop dialogues: closing never buys, and confirming Buy charges exactly once.
function ShopWait(dialogue, choices = true) {
    for (var frame = 0; frame < 100 && instance_exists(dialogue); frame++) {
        if (dialogue.Status == (choices ? 4 : 1) && !dialogue.ScriptNext) return true;
        PressEvent(dialogue, "", oDialogueBox, ev_step, ev_step_end);
    }
    return false;
}
function ShopOpen(shop, wait_for_choices = true) {
    global.Paused = false;
    with (oLink) UpdateState(1);
    // A previous purchase must not survive as the next dialogue's result.
    global.DB_ExitCode = 1;
    shop.DB_Init = true;
    PressEvent(shop, "action", oShop, ev_step, ev_step_normal);
    var dialogue = global.DB_Inst;
    global.NovaTestInput = "action";
    with (dialogue) event_perform_object(oDialogueBox, ev_step, ev_step_end);
    global.NovaTestInput = "";
    Check("shop opening press cannot close or buy", instance_exists(dialogue) && shop.ItemsSold == 0 && global.DB_ExitCode == 0);
    if (wait_for_choices) Check("shop reaches its real purchase choices", ShopWait(dialogue));
    return dialogue;
}
function ShopReset(shop) {
    global.DB_ExitCode = 0;
    if (instance_exists(global.DB_Inst)) with (global.DB_Inst) instance_destroy();
    with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
    global.Paused = false;
    with (oLink) UpdateState(1);
}
function ShopCloseCase(shop, dialogue, name, verb) {
    var inventory = json_stringify(global.Inventory);
    var items = json_stringify(global.Inventory_ItemData);
    var rupees = oHUD.AddRupees;
    PressEvent(dialogue, verb, oDialogueBox, ev_step, ev_step_end);
    Check(name + " closes without submitting", !instance_exists(dialogue) && global.DB_ExitCode == 0);
    Check(name + " consumes the close press", __input_global().__cleared);
    Check(name + " returns control to Link", !global.Paused && oLink.State == 1);
    with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
    Check(name + " preserves goods, rupees, and coupons", shop.ItemsSold == 0 && instance_exists(oLink.ShopItemLook) && oHUD.AddRupees == rupees && json_stringify(global.Inventory) == inventory && json_stringify(global.Inventory_ItemData) == items);
    ShopReset(shop);
}
// A shop without its own goods, a 25-rupee couponed item beside it, two coupons and 500 rupees.
// ShopEnd removes both and restores what ShopBegin saved.
function ShopBegin() {
    var fixture = {
        profile: input_profile_get(),
        inventory: StructCopy(global.Inventory),
        items: StructCopy(global.Inventory_ItemData),
        equipped: global.Inventory_SlotIndex_Equiped,
        add_rupees: oHUD.AddRupees,
        item_look: oLink.ShopItemLook
    };
    var challenges_before = global.Challenges[5];
    Inventory_InitData();
    Inventory_Add(48, 0, 2);
    global.Inventory_SlotIndex_Equiped = Inventory_ItemIndexExists(48, 0);
    global.Inventory_ItemData[40].Amount = 500;
    oHUD.AddRupees = 0;
    global.Challenges[5] = true;
    fixture.shop = instance_create_layer(oLink.x + 48, oLink.y, "System", oShop,
        {ShopType: 1, ShopW: 96, ShopH: 64, RoomIndex: oLink.RoomIndex});
    global.Challenges[5] = challenges_before;
    var goods = instance_create_layer(oLink.x + 48, oLink.y, "Objs_Lower", oItem_Arrows, {From: 4});
    goods.Amount = 10;
    goods.Price_Modified = 25;
    goods.Price_CouponApplied = true;
    goods.ShopItem = true;
    oLink.ShopItemLook = goods;
    fixture.goods = goods;
    return fixture;
}
function ShopEnd(fixture) {
    with (fixture.goods) instance_destroy();
    with (fixture.shop) instance_destroy();
    input_profile_set(fixture.profile);
    global.Inventory = fixture.inventory;
    global.Inventory_ItemData = fixture.items;
    global.Inventory_SlotIndex_Equiped = fixture.equipped;
    oHUD.AddRupees = fixture.add_rupees;
    oLink.ShopItemLook = fixture.item_look;
    global.Paused = false;
    with (oLink) UpdateState(1);
}

Suite("Shop", "gameplay", function() {
    Test("closing during the opening animation buys nothing", function() {
        var fixture = ShopBegin();
        var shop = fixture.shop;
        for (var device = 0; device < 2; device++) {
            input_profile_set(device == 0 ? "keyboard" : "gamepad");
            var dialogue = ShopOpen(shop, false);
            ShopCloseCase(shop, dialogue, "shop opening animation " + input_profile_get(), global.NovaCloseVerb());
        }
        ShopEnd(fixture);
    });
    Test("Back, Escape and both buttons close every choice without buying", function() {
        var fixture = ShopBegin();
        var shop = fixture.shop;
        for (var device = 0; device < 2; device++) {
            input_profile_set(device == 0 ? "keyboard" : "gamepad");
            // Pressing both buttons also presses their fixed menu verbs.
            var verbs = [global.NovaCloseVerb(), "escape", ["action", "sword", "nova_confirm", "nova_back"]];
            for (var key = 0; key < array_length(verbs); key++) {
                for (var choice = 0; choice < 3; choice++) {
                    var dialogue = ShopOpen(shop);
                    dialogue.InputChoice = choice;
                    ShopCloseCase(shop, dialogue, "shop " + input_profile_get() + " choice " + string(choice) + " close " + string(key), verbs[key]);
                }
            }
        }
        ShopEnd(fixture);
    });
    Test("confirming the information choice opens item information", function() {
        var fixture = ShopBegin();
        var shop = fixture.shop;
        for (var device = 0; device < 2; device++) {
            input_profile_set(device == 0 ? "keyboard" : "gamepad");
            var dialogue = ShopOpen(shop);
            dialogue.InputChoice = 2;
            PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
            Check("shop confirm opens item information", ShopWait(dialogue, false) && dialogue.ScriptCode == 0);
            ShopCloseCase(shop, dialogue, "shop information", global.NovaCloseVerb());
        }
        ShopEnd(fixture);
    });
    Test("buying without enough rupees is refused", function() {
        var fixture = ShopBegin();
        var shop = fixture.shop;
        for (var device = 0; device < 2; device++) {
            input_profile_set(device == 0 ? "keyboard" : "gamepad");
            var dialogue = ShopOpen(shop);
            global.Inventory_ItemData[40].Amount = 0;
            dialogue.InputChoice = 0;
            PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
            Check("shop keeps its insufficient-funds check", ShopWait(dialogue, false) && dialogue.ScriptCode == 4 && shop.ItemsSold == 0);
            ShopCloseCase(shop, dialogue, "shop purchase refusal", global.NovaCloseVerb());
            global.Inventory_ItemData[40].Amount = 500;
        }
        ShopEnd(fixture);
    });
    Test("closing a pending purchase confirmation buys nothing", function() {
        var fixture = ShopBegin();
        var shop = fixture.shop;
        for (var device = 0; device < 2; device++) {
            input_profile_set(device == 0 ? "keyboard" : "gamepad");
            var dialogue = ShopOpen(shop);
            dialogue.InputChoice = 0;
            PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
            ShopCloseCase(shop, dialogue, "shop pending confirmation " + input_profile_get(), global.NovaCloseVerb());
        }
        ShopEnd(fixture);
    });
    Test("confirming Cancel declines the purchase", function() {
        var fixture = ShopBegin();
        var shop = fixture.shop;
        input_profile_set("gamepad");
        var dialogue = ShopOpen(shop);
        dialogue.InputChoice = 1;
        PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
        for (var frame = 0; frame < 4 && instance_exists(dialogue); frame++) PressEvent(dialogue, "", oDialogueBox, ev_step, ev_step_end);
        with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
        Check("confirming Cancel still declines the purchase", !instance_exists(dialogue) && !shop.DB_Started && shop.ItemsSold == 0 && oHUD.AddRupees == 0);
        ShopEnd(fixture);
    });
    Test("confirming Buy charges once and consumes one coupon", function() {
        var fixture = ShopBegin();
        var shop = fixture.shop;
        var goods = fixture.goods;
        input_profile_set("gamepad");
        var dialogue = ShopOpen(shop);
        dialogue.InputChoice = 0;
        var coupons = global.Inventory[global.Inventory_SlotIndex_Equiped].Amount;
        PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
        for (var frame = 0; frame < 4 && instance_exists(dialogue); frame++) PressEvent(dialogue, "", oDialogueBox, ev_step, ev_step_end);
        with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
        Check("confirming Buy charges once and receives the selected item", shop.ItemsSold == 1 && oHUD.AddRupees == -25 && oLink.State == 9 && oLink.ItemHolding == goods);
        Check("confirmed purchase consumes one applicable coupon", global.Inventory[global.Inventory_SlotIndex_Equiped].Amount == coupons - 1);
        with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
        Check("completed purchase cannot charge again", shop.ItemsSold == 1 && oHUD.AddRupees == -25);
        oLink.alarm[0] = -1;
        oLink.ItemHolding = noone;
        audio_stop_sound(Sound_ItemGetFanfare);
        ShopEnd(fixture);
    });
});
