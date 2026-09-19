NovaSwordMode = 0;
NovaSwordCharge = 0;
NovaSwordSpinTicks = 0;
NovaSwordFacing = Facing;
function NovaSwordStep() {
    if (global.Paused || State != 12) return;
    if (NovaSwordMode == 1) {
        if (!input_check("sword")) {
            if (SwordLevel(2) && NovaSwordCharge >= 45) {
                NovaSwordMode = 2;
                NovaSwordSpinTicks = 0;
                audio_play_sound(asset_get_index("Sound_Sword" + string(global.Inventory_ItemData[44].Index + 1)), 1, false);
            } else UpdateState(1);
            return;
        }
        NovaSwordCharge++;
        Facing = NovaSwordFacing;
        var move_x = input_check("right") - input_check("left");
        var move_y = input_check("down") - input_check("up");
        var move_speed = WalkSpeed * 0.65;
        if (move_x != 0 && move_y != 0) move_speed = move_speed * 2 / 3;
        vx = move_x * move_speed;
        vy = move_y * move_speed;
        image_index = 6;
        image_speed = 0;
    } else if (NovaSwordMode == 2) {
        NovaSwordSpinTicks++;
        if (NovaSwordSpinTicks >= 16) {
            Facing = NovaSwordFacing;
            UpdateState(1);
            return;
        }
        var facings = [2, 3, 1, 4];
        Facing = facings[(NovaSwordSpinTicks div 4) mod 4];
        UpdateSprites();
        image_index = 6;
        image_speed = 0;
    }
}
function NovaSwordFinishSwing() {
    if (input_check("sword")) {
        NovaSwordMode = 1;
        NovaSwordCharge = 0;
        NovaSwordFacing = Facing;
        image_index = 6;
        image_speed = 0;
    } else UpdateState(1);
}
