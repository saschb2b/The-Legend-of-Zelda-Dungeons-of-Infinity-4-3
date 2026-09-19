LevelIndex = global.Level.Index;
RoomIndex = oLink.RoomIndex;
SpawnWait = 200;
Attack = (LevelIndex + 1) * 0.25;
ChaseSpeed = min(0.475 + LevelIndex * 0.025, 0.75);
IdleFrames = max(1, 41 - LevelIndex);
Wait = IdleFrames;
AttackTicks = 0;
AttackDir = 0;
Hover = 24;
Bob = 0;
visible = false;
depth = -10000;
function NovaCanHunt() {
    return global.NovaOption(11) && global.Level.Index > 0 && global.Level.Index < 13 && global.Level.Index != 6 && global.Level.Index != 10;
}
function NovaCanAttack() {
    return !oLink.Invincible && !oLink.Cape && !oLink.InDoor_Full && (oLink.State == 1 || oLink.State == 12 || oLink.State == 6);
}
