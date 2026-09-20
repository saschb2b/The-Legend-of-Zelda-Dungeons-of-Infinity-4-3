function ProfileRoot() {
    with (oMenu) {
        Win_Main_Activate(0);
        MenuWin_Main_Shift = false;
        Menu_Active = true;
        Win_Main_SetX(MenuWin_Main_X_Default);
    }
}

function ProfileFixture(name, character, hearts, health, level) {
    var user = new User_Create();
    user.Name = name;
    if (hearts > 0) {
        user.SaveData = new User_SaveDataStruct();
        user.SaveData.LinkCharacterIndex = character;
        user.SaveData.Level = level;
        user.SaveData.Inventory_ItemData = array_create(19);
        user.SaveData.Inventory_ItemData[17] = {Amount: health};
        user.SaveData.Inventory_ItemData[18] = {Amount: hearts};
    }
    return user;
}

function ProfileMenuTests() {
    var users = global.Users;
    var user_index = global.UserIndex;
    var profile = input_profile_get();
    global.Users = [ProfileFixture("LINK", 0, 4, 3.5, 5), ProfileFixture("WWWWWWWW", 8, 16, 16, 99), ProfileFixture("ZELDA", 2, 0, 0, 0), new User_Create(), new User_Create()];
    var before = json_stringify(global.Users);
    ProfileRoot();
    Record("Player Select retains all five profiles and both utility actions", oMenu.Menu_Count[0] == 7);
    for (var index = 0; index < 7; index++) {
        Record("Player Select reaches row " + string(index), oMenu.Selector_Index_Main == index);
        PressEvent(oMenu, "down", oMenu, ev_step, ev_step_normal);
    }
    Record("Player Select wraps after Exit", oMenu.Selector_Index_Main == 0);
    PressEvent(oMenu, "up", oMenu, ev_step, ev_step_normal);
    Record("Player Select wraps up to Exit", oMenu.Selector_Index_Main == 6);
    var saved = oMenu.NovaProfileSummary(0);
    Record("Save preview uses recorded health and floor", saved.saved && saved.hearts == 4 && saved.health == 3.5 && saved.floor == 5);
    var maximum = oMenu.NovaProfileSummary(1);
    Record("Save preview retains character and maximum hearts", maximum.character == 8 && maximum.hearts == 16 && maximum.health == 16);
    var fresh = oMenu.NovaProfileSummary(2);
    Record("Named player without a run shows no invented progress", !fresh.saved && fresh.hearts == 0);
    var empty = oMenu.NovaProfileSummary(4);
    Record("Empty player has no portrait or progress data", empty.name == "" && !empty.saved && empty.hearts == 0);
    for (var device = 0; device < 2; device++) {
        input_profile_set(device == 0 ? "gamepad" : "keyboard");
        var layout = oMenu.NovaProfileLayout();
        Record("Player Select frame fits the 4:3 view " + string(device), layout.x >= 8 && layout.x + layout.width <= 392 && layout.header_y >= -30 && layout.y + layout.height < 254);
        Record("Player Select footer clears the frame " + string(device), layout.footer_y - 6 >= layout.y + layout.height + 8 && layout.footer_y + 6 <= 258);
        Record("Player Select prompt groups have separate space " + string(device), layout.left + layout.close_width + 24 < layout.right - layout.confirm_width);
        draw_set_font(global.MenuFont);
        for (var index = 1; index <= global.MaxUsers; index++) Record("Slot number clears the name " + string(device) + ":" + string(index), layout.number_x + string_width(string(index) + ".") + 6 <= layout.name_x);
        Record("Longest player name clears heart preview " + string(device), layout.name_x + string_width("WWWWWWWW") + 8 < layout.hearts_x);
        Record("Two rows of hearts fit each save row " + string(device), layout.hearts_x + 79 <= layout.x + layout.width - 16 && layout.row_height >= 28);
        with (oMenu) NovaProfileDraw();
    }
    Record("Drawing save previews does not write to profiles", json_stringify(global.Users) == before);
    var old_save = global.Users[0].SaveData;
    global.Users[0].SaveData = {};
    var legacy = oMenu.NovaProfileSummary(0);
    Record("Legacy save preview tolerates missing optional fields", legacy.saved && legacy.character == 0 && legacy.hearts == 0);
    global.Users[0].SaveData = old_save;
    for (var index = 0; index < 5; index++) {
        ProfileRoot();
        oMenu.Selector_Index_Main = index;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Record("Player row opens its existing save flow " + string(index), oMenu.Menu_ActiveIndex == (index < 2 ? 2 : (index == 2 ? 1 : 5)) && global.UserIndex == index);
        Record("Child menus use their original windows " + string(index), !oMenu.NovaProfileVisible());
        if (index >= 3) {
            oMenu.MenuWin_Main_Shift = false;
            oMenu.Menu_Active = true;
            PressEvent(oMenu, "escape", oMenu, ev_step, ev_step_normal);
            Record("Closing name entry restores Player Select " + string(index), oMenu.NovaProfileVisible() && global.Users[index].Name == "");
        }
    }
    global.Users = users;
    global.UserIndex = user_index;
    input_profile_set(profile);
    ProfileRoot();
}

function ProfileCaptureStart() {
    ProfileCaptureUsers = global.Users;
    global.Users = [new User_Create(), new User_Create(), new User_Create(), new User_Create(), new User_Create()];
    input_profile_set("gamepad");
    ProfileRoot();
    Capture = "profiles-empty";
    Flush();
}

function ProfileCaptureStep() {
    if (!file_exists("nova-capture-done.txt")) return false;
    file_delete("nova-capture-done.txt");
    if (Capture == "profiles-empty") {
        global.Users = [ProfileFixture("LINK", 0, 4, 3.5, 5), ProfileFixture("ZELDA", 8, 16, 16, 20), ProfileFixture("HERO", 2, 0, 0, 0), new User_Create(), ProfileFixture("RAVIO", 3, 8, 5.25, 15)];
        Capture = "profiles-saves";
    } else if (Capture == "profiles-saves") {
        input_profile_set("keyboard");
        oMenu.Selector_Index_Main = global.MaxUsers;
        Capture = "profiles-keyboard";
    } else {
        global.Users = ProfileCaptureUsers;
        ProfileRoot();
        Capture = "";
        return true;
    }
    Flush();
    return false;
}
