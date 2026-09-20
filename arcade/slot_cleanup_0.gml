if (Paid) SettleRound();
if (global.Arcade_ActiveInst == id) CloseMachine();
if (surface_exists(GameSurface)) surface_free(GameSurface);
if (surface_exists(ReelSurface)) surface_free(ReelSurface);
