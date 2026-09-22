if (!instance_exists(oLink) || !NovaCanHunt() || LevelIndex != global.Level.Index) {
    instance_destroy();
    exit;
}
if (global.Paused || instance_exists(oInventory) || instance_exists(oMenu_Game) || instance_exists(oDialogueBox)) exit;
if (global.TransitionRoomIndex != -1 || oLink.State == 22 || oLink.State == 24 || oLink.State == 20 || oLink.State == 21) {
    visible = false;
    AttackTicks = 0;
    Hover = 24;
    Wait = IdleFrames;
    exit;
}
if (RoomIndex != oLink.RoomIndex) {
    RoomIndex = oLink.RoomIndex;
    var facing_angle = [0, 90, 270, 180, 0];
    x = oLink.x - lengthdir_x(80, facing_angle[oLink.Facing]);
    y = oLink.y - lengthdir_y(80, facing_angle[oLink.Facing]);
    SpawnWait = 60;
    AttackTicks = 0;
    Hover = 24;
}
if (SpawnWait > 0) { SpawnWait--; visible = false; exit; }
visible = true;
Bob = (Bob + 4) mod 360;
if (AttackTicks > 0) {
    x += lengthdir_x(1.5, AttackDir);
    y += lengthdir_y(1.5, AttackDir);
    Hover = max(0, Hover - 3);
    AttackTicks--;
    if (Hover <= 3 && NovaCanAttack() && point_distance(x, y, oLink.x, oLink.y - 6) < 12) {
        var damage = Attack;
        var direction_away = point_direction(x, y, oLink.x, oLink.y);
        with (oLink) LinkHit(direction_away, 1.5, 12, damage);
        AttackTicks = 0;
    }
    if (AttackTicks == 0) Wait = IdleFrames;
} else {
    Hover = min(24, Hover + 1);
    if (Wait > 0) Wait--;
    var direction_to = point_direction(x, y, oLink.x, oLink.y - 6);
    var distance_to = point_distance(x, y, oLink.x, oLink.y - 6);
    x += lengthdir_x(min(ChaseSpeed, distance_to), direction_to);
    y += lengthdir_y(min(ChaseSpeed, distance_to), direction_to);
    if (Wait == 0 && distance_to <= 32 && NovaCanAttack()) {
        AttackDir = direction_to;
        AttackTicks = 36;
    }
}
