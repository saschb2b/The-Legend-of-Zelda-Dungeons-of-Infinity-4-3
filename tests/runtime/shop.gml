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
    Record("shop opening press cannot close or buy", instance_exists(dialogue) && shop.ItemsSold == 0 && global.DB_ExitCode == 0);
    if (wait_for_choices) Record("shop reaches its real purchase choices", ShopWait(dialogue));
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
    Record(name + " closes without submitting", !instance_exists(dialogue) && global.DB_ExitCode == 0);
    Record(name + " consumes the close press", __input_global().__cleared);
    Record(name + " returns control to Link", !global.Paused && oLink.State == 1);
    with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
    Record(name + " preserves goods, rupees, and coupons", shop.ItemsSold == 0 && instance_exists(oLink.ShopItemLook) && oHUD.AddRupees == rupees && json_stringify(global.Inventory) == inventory && json_stringify(global.Inventory_ItemData) == items);
    ShopReset(shop);
}
function ShopTests() {
    var profile_before = input_profile_get();
    var inventory_before = StructCopy(global.Inventory);
    var items_before = StructCopy(global.Inventory_ItemData);
    var equipped_before = global.Inventory_SlotIndex_Equiped;
    var add_rupees_before = oHUD.AddRupees;
    var item_look_before = oLink.ShopItemLook;
    var challenges_before = global.Challenges[5];
    Inventory_InitData();
    Inventory_Add(48, 0, 2);
    global.Inventory_SlotIndex_Equiped = Inventory_ItemIndexExists(48, 0);
    global.Inventory_ItemData[40].Amount = 500;
    oHUD.AddRupees = 0;
    global.Challenges[5] = true;
    var shop = instance_create_layer(oLink.x + 48, oLink.y, "System", oShop,
        {ShopType: 1, ShopW: 96, ShopH: 64, RoomIndex: oLink.RoomIndex});
    global.Challenges[5] = challenges_before;
    var goods = instance_create_layer(oLink.x + 48, oLink.y, "Objs_Lower", oItem_Arrows, {From: 4});
    goods.Amount = 10;
    goods.Price_Modified = 25;
    goods.Price_CouponApplied = true;
    goods.ShopItem = true;
    oLink.ShopItemLook = goods;
    for (var device = 0; device < 2; device++) {
        input_profile_set(device == 0 ? "keyboard" : "gamepad");
        var dialogue = ShopOpen(shop, false);
        ShopCloseCase(shop, dialogue, "shop opening animation " + input_profile_get(), global.NovaCloseVerb());
        var verbs = [global.NovaCloseVerb(), "escape", ["action", "sword"]];
        for (var key = 0; key < array_length(verbs); key++) {
            for (var choice = 0; choice < 3; choice++) {
                var dialogue = ShopOpen(shop);
                dialogue.InputChoice = choice;
                ShopCloseCase(shop, dialogue, "shop " + input_profile_get() + " choice " + string(choice) + " close " + string(key), verbs[key]);
            }
        }
        var dialogue = ShopOpen(shop);
        dialogue.InputChoice = 2;
        PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
        Record("shop confirm opens item information", ShopWait(dialogue, false) && dialogue.ScriptCode == 0);
        ShopCloseCase(shop, dialogue, "shop information", global.NovaCloseVerb());
    
        dialogue = ShopOpen(shop);
        global.Inventory_ItemData[40].Amount = 0;
        dialogue.InputChoice = 0;
        PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
        Record("shop keeps its insufficient-funds check", ShopWait(dialogue, false) && dialogue.ScriptCode == 4 && shop.ItemsSold == 0);
        ShopCloseCase(shop, dialogue, "shop purchase refusal", global.NovaCloseVerb());
        global.Inventory_ItemData[40].Amount = 500;
        dialogue = ShopOpen(shop);
        dialogue.InputChoice = 0;
        PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
        ShopCloseCase(shop, dialogue, "shop pending confirmation " + input_profile_get(), global.NovaCloseVerb());
    }

    dialogue = ShopOpen(shop);
    dialogue.InputChoice = 1;
    PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
    for (var frame = 0; frame < 4 && instance_exists(dialogue); frame++) PressEvent(dialogue, "", oDialogueBox, ev_step, ev_step_end);
    with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
    Record("confirming Cancel still declines the purchase", !instance_exists(dialogue) && !shop.DB_Started && shop.ItemsSold == 0 && oHUD.AddRupees == 0);

    dialogue = ShopOpen(shop);
    dialogue.InputChoice = 0;
    var coupons = global.Inventory[global.Inventory_SlotIndex_Equiped].Amount;
    PressEvent(dialogue, global.NovaConfirmVerb(), oDialogueBox, ev_step, ev_step_end);
    for (var frame = 0; frame < 4 && instance_exists(dialogue); frame++) PressEvent(dialogue, "", oDialogueBox, ev_step, ev_step_end);
    with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
    Record("confirming Buy charges once and receives the selected item", shop.ItemsSold == 1 && oHUD.AddRupees == -25 && oLink.State == 9 && oLink.ItemHolding == goods);
    Record("confirmed purchase consumes one applicable coupon", global.Inventory[global.Inventory_SlotIndex_Equiped].Amount == coupons - 1);
    with (shop) event_perform_object(oShop, ev_step, ev_step_normal);
    Record("completed purchase cannot charge again", shop.ItemsSold == 1 && oHUD.AddRupees == -25);
    oLink.alarm[0] = -1;
    oLink.ItemHolding = noone;
    with (goods) instance_destroy();
    with (shop) instance_destroy();
    audio_stop_sound(Sound_ItemGetFanfare);
    input_profile_set(profile_before);
    global.Inventory = inventory_before;
    global.Inventory_ItemData = items_before;
    global.Inventory_SlotIndex_Equiped = equipped_before;
    oHUD.AddRupees = add_rupees_before;
    oLink.ShopItemLook = item_look_before;
    global.Paused = false;
    with (oLink) UpdateState(1);
}
