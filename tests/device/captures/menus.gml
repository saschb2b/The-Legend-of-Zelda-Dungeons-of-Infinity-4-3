// Adventure menu screenshots: profiles, setup, players, Options and the updater.
ProfileCaptureGamepad = "";
function ProfileCaptureStart() {
    ProfileCaptureUsers = global.Users;
    ProfileCaptureUserIndex = global.UserIndex;
    global.Users = [new User_Create(), new User_Create(), new User_Create(), new User_Create(), new User_Create()];
    global.UserIndex = 0;
    input_profile_set("gamepad");
    oMenu.NovaPage = "home";
    oMenu.NovaFocus = 0;
    Capture = "profiles-empty";
    Flush();
}
function ProfileCaptureStep() {
    if (!file_exists("nova-capture-done.txt")) return false;
    file_delete("nova-capture-done.txt");
    if (Capture == "profiles-empty") {
        global.Users = [ProfileFixture("LINK", 0, 4, 3.5, 5), ProfileFixture("WWWWWWWW", 8, 20, 19.25, 99), ProfileFixture("HERO", 2, 0, 0, 0), new User_Create(), ProfileFixture("RAVIO", 3, 8, 5.25, 15)];
        Capture = "profiles-saves";
    } else if (Capture == "profiles-saves") {
        global.UserIndex = 1;
        Capture = "profiles-maximum";
    } else if (Capture == "profiles-maximum") {
        global.UserIndex = 0;
        with (oMenu) NovaNewDraft();
        oMenu.NovaDraft.bonus = 4;
        oMenu.NovaDraft.challenges = array_create(12, 0);
        array_copy(oMenu.NovaDraft.challenges, 0, oMenu.NovaPresets[1].values, 0, 12);
        oMenu.NovaFocus = 2;
        Capture = "profiles-setup";
    } else if (Capture == "profiles-setup") {
        oMenu.NovaFocus = 3;
        Capture = "profiles-begin";
    } else if (Capture == "profiles-begin") {
        oMenu.NovaPage = "challenges";
        oMenu.NovaChallengePage = 0;
        oMenu.NovaFocus = 1;
        Capture = "profiles-challenges";
    } else if (Capture == "profiles-challenges") {
        // Lifetime records, a challenge level and a play date give the cards realistic content.
        global.Users[0].SaveData.NovaChallengeOptions = oMenu.NovaPresets[1].values;
        global.Users[0].SaveData.TimePlayed = 4980000000;
        global.Users[1].SaveData.TimePlayed = 35940000000;
        global.Users[1].SaveData.BossesDefeated = 31;
        global.Users[1].Stats = [42, 3, 39, 5210, 48012, 417, 3288000000, 0];
        global.Users[0].Stats = [5, 0, 4, 190, 1210, 23, 0, 0];
        global.UserIndex = 0;
        with (oMenu) NovaPlayedMark();
        oMenu.NovaPage = "players";
        oMenu.NovaFocus = 0;
        Capture = "profiles-players";
    } else if (Capture == "profiles-players") {
        with (oMenu) { NovaSelectPlayer(1); NovaGo("player", 0); }
        Capture = "profiles-details";
    } else if (Capture == "profiles-details") {
        oMenu.NovaName = "WWWWWWWW";
        oMenu.NovaNameCell = 0;
        oMenu.NovaRenameNotice = "";
        oMenu.NovaPage = "rename";
        Capture = "profiles-rename";
    } else if (Capture == "profiles-rename") {
        oMenu.NovaPage = "player";
        oMenu.NovaFocus = 2;
        oMenu.NovaPlayerDialog = true;
        oMenu.NovaPlayerDialogFocus = 0;
        Capture = "profiles-delete";
    } else if (Capture == "profiles-delete") {
        oMenu.NovaPlayerDialog = false;
        global.UserIndex = 0;
        oMenu.NovaOptions = global.NovaOptionsState("title");
        oMenu.NovaOptions.tab = 2;
        oMenu.NovaPage = "options";
        Capture = "options-audio";
    } else if (Capture == "options-audio") {
        oMenu.NovaOptions.tab = 1;
        Capture = "options-display";
    } else if (Capture == "options-display") {
        // About shows the installed version beside Updates and the base game below the list.
        oMenu.NovaOptions.tab = 4;
        oMenu.NovaOptions.focus = 0;
        Capture = "options-about";
    } else if (Capture == "options-about") {
        oMenu.NovaOptions.tab = 2;
        oMenu.NovaOptions.page = "confirm";
        oMenu.NovaOptions.confirm = "tab";
        Capture = "options-defaults";
    } else if (Capture == "options-defaults") {
        oMenu.NovaOptions.tab = 3;
        oMenu.NovaOptions.page = "device";
        oMenu.NovaOptions.device = 1;
        input_profile_set("keyboard");
        Capture = "profiles-keyboard";
    } else if (Capture == "profiles-keyboard") {
        input_profile_set("gamepad");
        ProfileCaptureGamepad = input_profile_export("gamepad");
        // Item moved to Y swaps Map onto X, so the capture shows two changed actions.
        global.NovaRemapAssign("item", input_binding_gamepad_button(gp_face4), 0);
        oMenu.NovaOptions.device = 0;
        oMenu.NovaOptions.bind_focus = 2;
        oMenu.NovaOptions.notice = "";
        Capture = "options-gamepad";
    } else if (Capture == "options-gamepad") {
        // Show the scan highlight without starting a real binding scan.
        oMenu.NovaOptions.bind_focus = 1;
        oMenu.NovaOptions.capture = true;
        global.NovaRemapping = true;
        Capture = "options-remapping";
    } else if (Capture == "options-remapping") {
        oMenu.NovaOptions.capture = false;
        global.NovaRemapping = false;
        oMenu.NovaOptions.page = "confirm";
        oMenu.NovaOptions.confirm = "device";
        Capture = "options-gamepaddefaults";
    } else if (Capture == "options-gamepaddefaults") {
        oMenu.NovaOptions.page = "list";
        oMenu.NovaCreditPage = 0;
        oMenu.NovaPage = "credits";
        Capture = "options-credits";
    } else {
        input_profile_import(ProfileCaptureGamepad, "gamepad");
        oMenu.NovaOptions = global.NovaOptionsState("title");
        global.Users = ProfileCaptureUsers;
        global.UserIndex = ProfileCaptureUserIndex;
        oMenu.NovaPage = "home";
        Capture = "";
        return true;
    }
    Flush();
    return false;
}

function UpdateCaptureStart() {
    input_profile_set("gamepad");
    with (oMenu) NovaUpdateEnter();
    UpdateStatus("available", oMenu.NovaUpdateId, "An update is available.");
    with (oMenu) NovaUpdatePoll();
    Capture = "updates-available";
    Flush();
}
function UpdateCaptureStep() {
    if (!file_exists("nova-capture-done.txt")) return false;
    file_delete("nova-capture-done.txt");
    if (Capture == "updates-available") {
        oMenu.NovaUpdateState.state = "error";
        oMenu.NovaUpdateState.message = "Update failed. Check Wi-Fi and try again.";
        file_delete("nova-update-status.json");
        Capture = "updates-error";
        Flush();
        return false;
    }
    with (oMenu) NovaUpdateClose();
    input_profile_set("keyboard");
    return true;
}
