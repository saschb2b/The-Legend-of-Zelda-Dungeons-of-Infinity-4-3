NovaUpdateOpen = false;
NovaUpdateId = "";
NovaUpdateState = {state: "idle", message: "Check for the latest stable patch.", installed: "", available: "", notes: ""};
NovaUpdateTicks = 0;
NovaUpdatePage = 0;
NovaUpdateNoteText = "";
NovaUpdateLines = [];
NovaUpdateNoteRows = 7;
function NovaUpdateRequest(action, keep_id = false) {
    if (!keep_id) NovaUpdateId = string(current_time) + "-" + string(irandom(1000000));
    var handle = file_text_open_write("nova-update-request.tmp");
    file_text_write_string(handle, json_stringify({id: NovaUpdateId, action: action}));
    file_text_close(handle);
    if (file_exists("nova-update-request.json")) file_delete("nova-update-request.json");
    file_rename("nova-update-request.tmp", "nova-update-request.json");
    NovaUpdateTicks = 0;
}
function NovaUpdateEnter() {
    NovaUpdateOpen = true;
    NovaUpdateState.state = "checking";
    NovaUpdateState.message = "Checking for updates...";
    NovaUpdatePage = 0;
    NovaUpdateRequest("check");
    input_clear_momentary(true);
}
function NovaUpdateClose() {
    NovaUpdateRequest("cancel");
    NovaUpdateOpen = false;
    input_clear_momentary(true);
}
function NovaUpdatePoll() {
    if (!file_exists("nova-update-status.json")) return;
    var handle = file_text_open_read("nova-update-status.json");
    var contents = file_text_read_string(handle);
    file_text_close(handle);
    try {
        var status = json_parse(contents);
        if (is_struct(status) && variable_struct_exists(status, "id") && status.id == NovaUpdateId)
            NovaUpdateState = status;
    } catch (error) {
        // An unreadable status must leave the menu usable for closing or retrying.
    }
}
function NovaUpdateStep() {
    if (input_check_pressed(global.NovaCloseVerb()) || keyboard_check_pressed(vk_escape)) {
        NovaUpdateClose();
        return;
    }
    NovaUpdateTicks++;
    if (NovaUpdateTicks mod 10 == 0) NovaUpdatePoll();
    var state = NovaUpdateState.state;
    if (state == "available") {
        NovaUpdateWrapNotes();
        var pages = max(1, ceil(array_length(NovaUpdateLines) / NovaUpdateNoteRows));
        if (input_check_pressed("nova_bag_previous") || input_check_pressed("left")) NovaUpdatePage = max(0, NovaUpdatePage - 1);
        if (input_check_pressed("nova_bag_next") || input_check_pressed("right")) NovaUpdatePage = min(pages - 1, NovaUpdatePage + 1);
    }
    if ((state == "checking" || state == "downloading") && NovaUpdateTicks > 60 * (state == "checking" ? 30 : 420)) {
        NovaUpdateRequest("cancel");
        NovaUpdateState.state = "error";
        NovaUpdateState.message = "Update timed out. Please try again.";
    }
    if (state == "ready") {
        NovaUpdateRequest("restart", true);
        game_end();
        return;
    }
    if (input_check_pressed("menu_input")) {
        if (state == "available") {
            NovaUpdateState.state = "downloading";
            NovaUpdateState.message = "Downloading update...";
            NovaUpdateRequest("install");
        } else if (state == "current" || state == "error" || state == "idle") {
            NovaUpdateState.state = "checking";
            NovaUpdateState.message = "Checking for updates...";
            NovaUpdateRequest("check");
        }
        input_clear_momentary(true);
    }
}
function NovaUpdateWrapNotes() {
    var notes = variable_struct_exists(NovaUpdateState, "notes") ? NovaUpdateState.notes : "No release notes were provided.";
    if (notes == NovaUpdateNoteText) return;
    NovaUpdateNoteText = notes;
    NovaUpdateLines = [];
    NovaUpdatePage = 0;
    var font = draw_get_font();
    draw_set_font(global.MenuFont);
    var layout = NovaMenuLayout();
    var max_width = layout.right - layout.left;
    var paragraphs = string_split(notes, "\n");
    for (var paragraph = 0; paragraph < array_length(paragraphs); paragraph++) {
        var words = string_split(paragraphs[paragraph], " ");
        var line = "";
        for (var word = 0; word < array_length(words); word++) {
            var text = line == "" ? words[word] : line + " " + words[word];
            if (string_width(text) * 0.75 > max_width && line != "") {
                array_push(NovaUpdateLines, line);
                line = words[word];
            } else line = text;
        }
        array_push(NovaUpdateLines, line);
    }
    var bounded = [];
    for (var index = 0; index < array_length(NovaUpdateLines); index++) {
        var remaining = NovaUpdateLines[index];
        while (string_width(remaining) * 0.75 > max_width) {
            var length = string_length(remaining) - 1;
            while (length > 1 && string_width(string_copy(remaining, 1, length)) * 0.75 > max_width) length--;
            array_push(bounded, string_copy(remaining, 1, length));
            remaining = string_delete(remaining, 1, length);
        }
        array_push(bounded, remaining);
    }
    NovaUpdateLines = bounded;
    draw_set_font(font);
}
function NovaUpdateDraw() {
    NovaMenuFrame(["Options", "About", "Updates"]);
    var layout = NovaUpdateLayout();
    var left = layout.left;
    var top = layout.y + 12;
    var state = NovaUpdateState.state;
    draw_text_transformed(left, top, "Installed: " + NovaUpdateState.installed, 0.75, 0.75, 0);
    if (NovaUpdateState.available != "") draw_text_transformed(left, top + 16, "Available: " + NovaUpdateState.available, 0.75, 0.75, 0);
    if (state == "available") {
        NovaUpdateWrapNotes();
        draw_text(left, top + 38, "What's changed");
        for (var row = 0; row < NovaUpdateNoteRows; row++) {
            var index = NovaUpdatePage * NovaUpdateNoteRows + row;
            if (index < array_length(NovaUpdateLines)) draw_text_transformed(left, top + 60 + row * 15, NovaUpdateLines[index], 0.75, 0.75, 0);
        }
        var pages = max(1, ceil(array_length(NovaUpdateLines) / NovaUpdateNoteRows));
        if (pages > 1) {
            global.NovaPromptDraw(global.NovaBinding("nova_bag_previous"), "", 148, layout.pages_y, 0.75, 0.75, 16);
            global.NovaPromptDraw(global.NovaBinding("nova_bag_next"), "", 236, layout.pages_y, 0.75, 0.75, 16);
            draw_set_valign(fa_middle);
            draw_set_halign(fa_center);
            draw_text_transformed(200, layout.pages_y, string(NovaUpdatePage + 1) + " / " + string(pages), 0.75, 0.75, 0);
        }
    } else {
        draw_text_ext_transformed(left, top + 48, NovaUpdateState.message, 20, (layout.right - left) / 0.75, 0.75, 0.75, 0);
        if (state == "downloading" && variable_struct_exists(NovaUpdateState, "percent"))
            draw_text(left, top + 84, string(NovaUpdateState.percent) + "%");
    }
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    if (state == "available") {
        draw_set_halign(fa_right);
        draw_text_transformed(layout.right, top, "Restarts to install.", 0.6, 0.6, 0);
        draw_text_transformed(layout.right, top + 16, "Your saves stay.", 0.6, 0.6, 0);
    }
    var label = state == "available" ? "Install update" : "Check again";
    NovaFooter(state == "available" || state == "current" || state == "error" || state == "idle" ? label : "", undefined, "Back");
}

function NovaMenuConfirmBinding() {
    var binding = input_binding_get("menu_input", 0, 1);
    return binding.__type == undefined ? global.NovaBinding("menu_input") : binding;
}

function NovaUpdateLayout() {
    var layout = NovaMenuLayout();
    layout.pages_y = layout.y + layout.height - 30;
    return layout;
}
