// The pause menu: rows, Options and Controls, quit dialogs, run summary and resuming.
function PauseOpen() {
    var pause = instance_create_layer(0, 0, "System", oMenu_Game);
    pause.Open = false;
    return pause;
}
function PausePress(pause, verb) {
    PressEvent(pause, verb, oMenu_Game, ev_step, ev_step_normal);
}
function PauseClose(pause) {
    with (pause) instance_destroy();
}

Suite("Pause menu", "gameplay", function() {
    Test("opens on Resume and wraps its rows", function() {
        var pause = PauseOpen();
        Check("pause opens on Resume", pause.NovaPauseFocus == 0 && !pause.NovaPauseDialog && !pause.NovaOptionsOpen);
        PausePress(pause, "up");
        Check("rows wrap to Quit to desktop", pause.NovaPauseFocus == 5);
        PausePress(pause, "down");
        PausePress(pause, "down");
        Check("rows wrap back to Resume and on to Options", pause.NovaPauseFocus == 1);
        PauseClose(pause);
    });
    Test("Options opens the shared screen under Paused", function() {
        var pause = PauseOpen();
        pause.NovaPauseFocus = 1;
        PausePress(pause, "menu_input");
        var trail = global.NovaOptionsTrail(pause.NovaOptions);
        Check("Options opens with the Paused breadcrumb", pause.NovaOptionsOpen && pause.NovaOptions.context == "pause" && trail[0] == "Paused" && trail[1] == "Options");
        var footer = global.NovaOptionsFooter(pause.NovaOptions);
        Check("B is labelled Back", footer[array_length(footer) - 1].label == "Back");
        Check("the title-only About tab is absent", array_length(pause.NovaOptions.tabs) == 4 && array_get_index(pause.NovaOptions.tabs, "About") == -1);
        PausePress(pause, "escape");
        Check("Escape backs out to the pause list", !pause.NovaOptionsOpen && !pause.Close && pause.NovaPauseFocus == 1);
        PauseClose(pause);
    });
    Test("Controls remaps one action without leaving pause", function() {
        var pause = PauseOpen();
        pause.NovaPauseFocus = 2;
        PausePress(pause, "menu_input");
        var trail = global.NovaOptionsTrail(pause.NovaOptions);
        Check("Controls opens the current device's mapping", pause.NovaOptionsOpen && pause.NovaOptions.page == "device" && pause.NovaOptions.device == (input_profile_get() == "keyboard" ? 1 : 0) && trail[0] == "Paused" && trail[1] == "Controls");
        var keyboard_before = input_profile_export("keyboard");
        pause.NovaOptions.device = 1;
        pause.NovaOptions.bind_focus = 1;
        PausePress(pause, "menu_input");
        Check("a remap starts without the adventure menu", global.NovaRemapping && pause.NovaOptions.capture && !instance_exists(oMenu));
        PausePress(pause, global.NovaCloseVerb());
        Check("Back during a remap keeps Options open", pause.NovaOptionsOpen && pause.NovaOptions.capture && !pause.Close);
        PausePress(pause, "menu_access");
        Check("Select cancels the remap without leaving pause", pause.NovaOptionsOpen && !pause.NovaOptions.capture && !global.NovaRemapping && !pause.Close && input_profile_export("keyboard") == keyboard_before);
        PausePress(pause, global.NovaCloseVerb());
        Check("Back returns to the Controls row", !pause.NovaOptionsOpen && pause.NovaPauseFocus == 2 && !pause.Close);
        PauseClose(pause);
    });
    Test("Start over and both quits ask first with Cancel selected", function() {
        var pause = PauseOpen();
        for (var row = 3; row <= 5; row++) {
            var name = global.NovaPauseRows[row];
            pause.NovaPauseFocus = row;
            PausePress(pause, "menu_input");
            var text = global.NovaPauseDialogText(row);
            Check(name + " opens a dialog on Cancel", pause.NovaPauseDialog && pause.NovaPauseDialogFocus == 0 && text.confirm != "OK");
            PausePress(pause, "menu_input");
            Check(name + " Cancel keeps the run", !pause.NovaPauseDialog && !pause.Quitting && !pause.Close);
            PausePress(pause, "menu_input");
            PausePress(pause, global.NovaCloseVerb());
            Check(name + " Back closes the dialog, not the pause", !pause.NovaPauseDialog && !pause.Quitting && !pause.Close);
        }
        Check("quitting explains that progress since the Save Tent is lost", string_pos("Save Tent", global.NovaPauseHelp(4)) > 0 && string_pos("Save Tent", global.NovaPauseDialogText(5).detail) > 0 && string_pos("floor 1", global.NovaPauseHelp(3)) > 0);
        pause.NovaPauseFocus = 5;
        PausePress(pause, "menu_input");
        PausePress(pause, "down");
        PausePress(pause, "menu_input");
        Check("confirming a quit starts it with the right destination", pause.Quitting && pause.QuitTo == 2);
        PauseClose(pause);
    });
    Test("the run summary, rows, help and footer fit", function() {
        var pause = PauseOpen();
        var summary = global.NovaPauseSummary(pause);
        Check("the summary reads the live run", summary.floor == global.Level.Index && summary.hearts == global.Inventory_ItemData[18].Amount && summary.character == global.LinkCharacterIndex);
        draw_set_font(global.MenuFont_Innactive);
        var layout = global.NovaPauseLayout();
        var widest = 0;
        for (var i = 0; i < array_length(global.NovaPauseRows); i++) widest = max(widest, string_width(global.NovaPauseRows[i]) * 0.9);
        Check("rows clear the run summary", layout.rows_x + widest + 8 < layout.panel_x && layout.rows_y[5] + 14 < layout.rule_y && layout.panel_y + layout.panel_h < layout.rule_y);
        var line = string_height("A") + 4;
        for (var i = 0; i < 6; i++) Check("help for row " + string(i) + " fits in two lines", string_height_ext(global.NovaPauseHelp(i), line, global.NovaOptionsLayout().help_width / 0.6) / line <= 2.01);
        var footer = global.NovaPauseFooter(pause);
        Check("the footer offers Select and Resume", footer[0].label == "Select" && footer[1].label == "Resume");
        PauseClose(pause);
    });
    Test("every close input resumes", function() {
        var inputs = [["escape", "Escape"], [global.NovaCloseVerb(), "Back"], ["menu_access", "Select"], ["menu_input", "confirming Resume"]];
        for (var i = 0; i < array_length(inputs); i++) {
            var pause = PauseOpen();
            PausePress(pause, inputs[i][0]);
            Check(inputs[i][1] + " resumes from the pause list", pause.Close && !pause.Quitting);
            PauseClose(pause);
        }
        var pause = PauseOpen();
        PausePress(pause, "down");
        PausePress(pause, "menu_input");
        PausePress(pause, "menu_access");
        Check("Select leaves pause from Options", !pause.NovaOptionsOpen && pause.Close && !pause.Quitting);
        PauseClose(pause);
    });
});
