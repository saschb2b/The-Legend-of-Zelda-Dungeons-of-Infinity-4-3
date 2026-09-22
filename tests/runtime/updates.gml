function UpdateStatus(state, id, message = "Update test") {
    var file = file_text_open_write("nova-update-status.json");
    file_text_write_string(file, json_stringify({id: id, state: state, message: message, installed: "1.5.3", available: "1.6.0", notes: "1.6.0\nAdded\n- Check for stable patch updates from the start menu.\n- Read the changes before installing.\n- Keep saves and recover interrupted installations.\n1.5.3\nFixed\n- SNES movement and controller fixes."}));
    file_text_close(file);
}
function UpdateRequestRead() {
    var file = file_text_open_read("nova-update-request.json");
    var request = json_parse(file_text_read_string(file));
    file_text_close(file);
    return request;
}
function UpdateMenuTests() {
    var user = global.UserIndex;
    var profile = input_profile_get();
    with (oMenu) {
        MenuWin_Main_Shift = false;
        Menu_Active = true;
        Menu_ActiveIndex = 0;
        NovaPage = "options";
        NovaOptions = global.NovaOptionsState("title");
        NovaOptions.tab = 4;
        NovaOptions.focus = 0;
        Selector_Index_Main = global.MaxUsers;
    }
    Record("Updates is available in Options", oMenu.NovaPage == "options");
    var width = inst_100004.W;
    var height = inst_100004.H;
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Updates opens without selecting or editing a profile", oMenu.NovaUpdateOpen && global.UserIndex == user);
    var frame = oMenu.NovaUpdateLayout();
    var profiles = oMenu.NovaMenuLayout();
    Record("Updates shares the adventure frame and footer", frame.x == profiles.x && frame.y == profiles.y && frame.width == profiles.width && frame.height == profiles.height && frame.header_y == profiles.header_y && frame.header_width == profiles.header_width && frame.footer_y == profiles.footer_y);
    Record("Updates requests a check without installation", UpdateRequestRead().action == "check");
    Record("Update window stays within the screen", frame.x >= 8 && frame.x + frame.width <= 392 && frame.y + frame.height <= 254);
    UpdateStatus("available", "stale");
    with (oMenu) NovaUpdatePoll();
    Record("Stale update responses are ignored", oMenu.NovaUpdateState.state == "checking");
    UpdateStatus("available", oMenu.NovaUpdateId);
    with (oMenu) NovaUpdatePoll();
    Record("Available update shows installed and available versions", oMenu.NovaUpdateState.state == "available" && oMenu.NovaUpdateState.installed == "1.5.3" && oMenu.NovaUpdateState.available == "1.6.0");
    with (oMenu) NovaUpdateWrapNotes();
    Record("Release notes wrap into readable pages", array_length(oMenu.NovaUpdateLines) > 5 && oMenu.NovaUpdatePage == 0);
    PressEvent(oMenu, "nova_bag_next", oMenu, ev_step, ev_step_normal);
    Record("Right shoulder shows the next changes page", oMenu.NovaUpdatePage == 1);
    PressEvent(oMenu, "nova_bag_previous", oMenu, ev_step, ev_step_normal);
    Record("Left shoulder returns to the first changes page", oMenu.NovaUpdatePage == 0);
    PressEvent(oMenu, "left", oMenu, ev_step, ev_step_normal);
    Record("Changes paging stops at the first page", oMenu.NovaUpdatePage == 0);
    for (var device = 0; device < 2; device++) {
        input_profile_set(device == 0 ? "gamepad" : "keyboard");
        var layout = oMenu.NovaUpdateLayout();
        var hints = oMenu.NovaFooterLayout("Install update");
        Record("Update footer clears the frame " + string(device), hints[0].x >= layout.footer_left && hints[1].right <= layout.footer_right && layout.footer_y - 8 >= layout.y + layout.height + 8 && layout.footer_y + 8 <= 258);
        Record("Update footer orders Install then Close " + string(device), hints[0].right < hints[1].x && hints[0].label == "Install update" && hints[1].label == "Close");
        Record("Update paging stays above the footer " + string(device), layout.pages_y + 12 < layout.footer_y - 8);
        Record("Update notes clear the paging controls " + string(device), layout.y + 12 + 60 + (oMenu.NovaUpdateNoteRows - 1) * 15 + 12 < layout.pages_y - 6);
    }
    input_profile_set(profile);
    with (oMenu) NovaUpdateDraw();
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    Record("Confirm starts downloading without closing the game", oMenu.NovaUpdateOpen && oMenu.NovaUpdateState.state == "downloading" && UpdateRequestRead().action == "install");
    var download_id = oMenu.NovaUpdateId;
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Close cancels the download and restores the menu", !oMenu.NovaUpdateOpen && UpdateRequestRead().action == "cancel" && UpdateRequestRead().id != download_id && inst_100004.W == width && inst_100004.H == height);
    Record("Closing Updates consumes the button press", __input_global().__cleared);
    PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
    for (var index = 0; index < 2; index++) {
        UpdateStatus(index == 0 ? "error" : "current", oMenu.NovaUpdateId);
        with (oMenu) NovaUpdatePoll();
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Record("Update retry requests a fresh check " + string(index), oMenu.NovaUpdateState.state == "checking" && UpdateRequestRead().action == "check");
    }
    global.NovaTestUpdateRestart = false;
    oMenu.NovaUpdateState.state = "ready";
    var ready_id = oMenu.NovaUpdateId;
    PressEvent(oMenu, "", oMenu, ev_step, ev_step_normal);
    Record("Verified update requests a restart with the download token", global.NovaTestUpdateRestart && UpdateRequestRead().action == "restart" && UpdateRequestRead().id == ready_id);
    global.NovaTestUpdateRestart = false;
    input_profile_set("gamepad");
    PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
    Record("Close wins over a ready update", !global.NovaTestUpdateRestart && UpdateRequestRead().action == "cancel");
    Record("Controller B closes Updates", !oMenu.NovaUpdateOpen);
    Record("Closing Updates restores its Options row", oMenu.NovaPage == "options" && oMenu.NovaOptions.tab == 4 && oMenu.NovaOptions.focus == 0);
    input_profile_set(profile);
    file_delete("nova-update-request.json");
    file_delete("nova-update-status.json");
}
