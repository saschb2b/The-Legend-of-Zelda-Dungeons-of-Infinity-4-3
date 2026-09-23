// The Updates page under About: checking, release notes, downloading, cancelling and restarting.
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

// The tests run in order through one visit to Updates, as a player would use it.
Suite("Updates", "menu", function() {
    BeforeAll(function() {
        UpdateInput = input_profile_get();
    });
    Test("Updates opens from About without selecting a player", function() {
        var user = global.UserIndex;
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
        Check("Updates is available in Options", oMenu.NovaPage == "options");
        UpdateMenuWidth = inst_100004.W;
        UpdateMenuHeight = inst_100004.H;
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("Updates opens without selecting or editing a profile", oMenu.NovaUpdateOpen && global.UserIndex == user);
    });
    Test("Updates shares the adventure frame and only checks", function() {
        var frame = oMenu.NovaUpdateLayout();
        var profiles = oMenu.NovaMenuLayout();
        Check("Updates shares the adventure frame and footer", frame.x == profiles.x && frame.y == profiles.y && frame.width == profiles.width && frame.height == profiles.height && frame.header_y == profiles.header_y && frame.header_width == profiles.header_width && frame.footer_y == profiles.footer_y);
        Check("Updates requests a check without installation", UpdateRequestRead().action == "check");
        Check("the update window stays within the screen", frame.x >= 8 && frame.x + frame.width <= 392 && frame.y + frame.height <= 254);
    });
    Test("only the current check's response is shown", function() {
        UpdateStatus("available", "stale");
        with (oMenu) NovaUpdatePoll();
        Check("stale update responses are ignored", oMenu.NovaUpdateState.state == "checking");
        UpdateStatus("available", oMenu.NovaUpdateId);
        with (oMenu) NovaUpdatePoll();
        Check("an available update shows installed and available versions", oMenu.NovaUpdateState.state == "available" && oMenu.NovaUpdateState.installed == "1.5.3" && oMenu.NovaUpdateState.available == "1.6.0");
    });
    Test("release notes page with the shoulders", function() {
        with (oMenu) NovaUpdateWrapNotes();
        Check("release notes wrap into readable pages", array_length(oMenu.NovaUpdateLines) > 5 && oMenu.NovaUpdatePage == 0);
        PressEvent(oMenu, "nova_bag_next", oMenu, ev_step, ev_step_normal);
        Check("right shoulder shows the next changes page", oMenu.NovaUpdatePage == 1);
        PressEvent(oMenu, "nova_bag_previous", oMenu, ev_step, ev_step_normal);
        Check("left shoulder returns to the first changes page", oMenu.NovaUpdatePage == 0);
        PressEvent(oMenu, "left", oMenu, ev_step, ev_step_normal);
        Check("changes paging stops at the first page", oMenu.NovaUpdatePage == 0);
    });
    Test("the update footer, paging and notes fit", function() {
        for (var device = 0; device < 2; device++) {
            var device_name = device == 0 ? "gamepad" : "keyboard";
            input_profile_set(device_name);
            var layout = oMenu.NovaUpdateLayout();
            var hints = oMenu.NovaFooterLayout("Install update", undefined, "Back");
            Check("update footer clears the frame with the " + device_name, hints[0].x >= layout.footer_left && hints[1].right <= layout.footer_right && layout.footer_y - 8 >= layout.y + layout.height + 8 && layout.footer_y + 8 <= 258);
            Check("update footer orders Install then Back with the " + device_name, hints[0].right < hints[1].x && hints[0].label == "Install update" && hints[1].label == "Back");
            Check("update paging stays above the footer with the " + device_name, layout.pages_y + 12 < layout.footer_y - 8);
            Check("update notes clear the paging controls with the " + device_name, layout.y + 12 + 60 + (oMenu.NovaUpdateNoteRows - 1) * 15 + 12 < layout.pages_y - 6);
        }
        input_profile_set(UpdateInput);
    });
    Test("Close cancels a download and restores the menu", function() {
        with (oMenu) NovaUpdateDraw();
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        Check("confirm starts downloading without closing the game", oMenu.NovaUpdateOpen && oMenu.NovaUpdateState.state == "downloading" && UpdateRequestRead().action == "install");
        var download_id = oMenu.NovaUpdateId;
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("Close cancels the download and restores the menu", !oMenu.NovaUpdateOpen && UpdateRequestRead().action == "cancel" && UpdateRequestRead().id != download_id && inst_100004.W == UpdateMenuWidth && inst_100004.H == UpdateMenuHeight);
        Check("closing Updates consumes the button press", __input_global().__cleared);
    });
    Test("retrying after an error or a current version checks again", function() {
        PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
        for (var index = 0; index < 2; index++) {
            var state = index == 0 ? "error" : "current";
            UpdateStatus(state, oMenu.NovaUpdateId);
            with (oMenu) NovaUpdatePoll();
            PressEvent(oMenu, "menu_input", oMenu, ev_step, ev_step_normal);
            Check("retry after " + state + " requests a fresh check", oMenu.NovaUpdateState.state == "checking" && UpdateRequestRead().action == "check");
        }
    });
    Test("a verified update restarts with its download token", function() {
        global.NovaTestUpdateRestart = false;
        oMenu.NovaUpdateState.state = "ready";
        var ready_id = oMenu.NovaUpdateId;
        PressEvent(oMenu, "", oMenu, ev_step, ev_step_normal);
        Check("the restart request carries the download token", global.NovaTestUpdateRestart && UpdateRequestRead().action == "restart" && UpdateRequestRead().id == ready_id);
    });
    Test("Close wins over a ready update and restores the Options row", function() {
        global.NovaTestUpdateRestart = false;
        input_profile_set("gamepad");
        PressEvent(oMenu, global.NovaCloseVerb(), oMenu, ev_step, ev_step_normal);
        Check("Close wins over a ready update", !global.NovaTestUpdateRestart && UpdateRequestRead().action == "cancel");
        Check("controller B closes Updates", !oMenu.NovaUpdateOpen);
        Check("closing Updates restores its Options row", oMenu.NovaPage == "options" && oMenu.NovaOptions.tab == 4 && oMenu.NovaOptions.focus == 0);
        input_profile_set(UpdateInput);
        file_delete("nova-update-request.json");
        file_delete("nova-update-status.json");
    });
});
