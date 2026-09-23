// Moves the game through the contexts the suites need (oNovaTests, Step event):
// title, adventure menu, back to the title, gameplay and multi-frame travel.
// Screenshot modes run afterwards when the device runner enables them.
// Screenshot transfer time is bounded by the host's wall-clock deadline.
if (Capture == "") Ticks++;
try {
    switch (Stage) {
        case "title":
            if (!instance_exists(oTitle)) break;
            Stage = RunPhase("title") ? "menu" : "title-async";
            break;
        case "title-async":
            if (AsyncStep()) Stage = "menu";
            break;
        case "menu":
            if (!instance_exists(oMenu)) break;
            RunPhase("menu");
            Stage = CapturePlan([
                {name: "adventure menus", flags: ["nova-capture-enabled.txt", "nova-profile-capture-enabled.txt"], start: ProfileCaptureStart, step: ProfileCaptureStep},
                {name: "updates", flags: ["nova-capture-enabled.txt", "nova-update-capture-enabled.txt"], start: UpdateCaptureStart, step: UpdateCaptureStep}
            ], false) ? "menu-exit" : "menu-captures";
            break;
        case "menu-captures":
            if (CaptureModeStep()) Stage = "menu-exit";
            break;
        case "menu-exit":
            Stage = RunPhase("menu-exit") ? "start-game" : "menu-exit-async";
            break;
        case "menu-exit-async":
            if (AsyncStep()) Stage = "start-game";
            break;
        case "start-game":
            if (!instance_exists(oMenu)) break;
            global.UserIndex = 0;
            with (oMenu) Menu_StartGame();
            Stage = "gameplay";
            break;
        case "gameplay":
            if (!instance_exists(oHUD) || !instance_exists(oLink) || global.Paused || oLink.State != 1) break;
            RunPhase("gameplay");
            Stage = RunPhase("travel") ? "gameplay-captures" : "travel";
            break;
        case "travel":
            if (AsyncStep()) Stage = "gameplay-captures";
            break;
        case "gameplay-captures":
            // Each gameplay screenshot mode changes rooms or fixtures, so only one runs per launch.
            Stage = CapturePlan([
                {name: "arcade", flags: ["nova-arcade-capture-enabled.txt"], start: ArcadeCaptureStart, step: ArcadeCaptureStep},
                {name: "interaction hints", flags: ["nova-context-capture-enabled.txt"], start: ContextCaptureStart, step: ContextCaptureStep},
                {name: "gameplay", flags: ["nova-capture-enabled.txt"], start: CaptureStart, step: CaptureStep}
            ], true) ? "done" : "gameplay-capture-step";
            break;
        case "gameplay-capture-step":
            if (CaptureModeStep()) Stage = "done";
            break;
        case "done":
            Complete = true;
            Flush();
            game_end();
            break;
    }
    if (Ticks > 3600) throw "the harness timed out at stage " + string(Stage);
} catch (error) {
    if (CurrentTest == undefined) BeginTest("Harness", "sequencer");
    Fail("exception: " + string(error));
    CurrentTest.checks++;
    EndTest();
    Complete = true;
    Flush();
    game_end();
}
