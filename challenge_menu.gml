NovaChallengePage = 0;
NovaChallengePages = [[0, 1, 2, 4, 5], [3, 6, 7, 8], [9, 10, 11]];
NovaChallengeLabels = ["Start hearts", "Max hearts", "Max defense", "Darkness", "Start slots", "Max rupees", "Shop prices", "Enemies", "Curses", "No map", "No food", "Wall Master"];
NovaChallengeValues = [["4", "3", "2", "1"], ["16", "8", "6", "5"], ["Normal", "4", "3", "2"], ["Normal", "More", "All dark", "No lights"], ["5", "4", "3", "2"], ["No limit", "400", "300", "200"], ["Normal", "1.5x", "2x", "2.5x"], ["Normal", "More", "Many", "Most"], ["Normal", "2x", "4x", "6x"], ["Off", "On"], ["Off", "On"], ["Off", "On"]];
function NovaChallengeMenu() {
    Menu[11] = [];
    Menu_Create(11, "Challenges", 28, undefined, 16, "Back");
    var page = NovaChallengePages[NovaChallengePage];
    for (var i = 0; i < array_length(page); i++) Menu[11][i + 1] = NovaChallengeLabels[page[i]];
    array_push(Menu[11], "Next page");
    array_push(Menu[11], "Reset all");
    Menu_Count[11] = array_length(Menu[11]);
    for (var i = 0; i < Menu_Count[11]; i++) Menu_Y[11][i] = 70 + 16 * i;
}
function NovaChallengeChange(delta) {
    var page = NovaChallengePages[NovaChallengePage];
    var row = Selector_Index_Options - 1;
    if (row >= 0 && row < array_length(page)) {
        var index = page[row];
        var count = array_length(NovaChallengeValues[index]);
        global.NovaChallengeOptions[index] = (global.NovaOption(index) + delta + count) mod count;
        global.Challenges[3] = global.NovaOption(9) == 1;
        global.Challenges[4] = global.NovaOption(3) == 3;
    } else if (row == array_length(page)) {
        NovaChallengePage = (NovaChallengePage + delta + 3) mod 3;
        NovaChallengeMenu();
        Selector_Index_Options = 0;
    } else if (row == array_length(page) + 1) {
        global.NovaResetChallenges();
    }
    audio_play_sound(Sound_TextDone, 1, false);
}
function NovaChallengeDraw() {
    var page = NovaChallengePages[NovaChallengePage];
    draw_set_halign(fa_right);
    for (var i = 0; i < array_length(page); i++) {
        var index = page[i];
        draw_text(inst_100005.x + inst_100005.W - 12, Menu_Y[11][i + 1], NovaChallengeValues[index][global.NovaOption(index)]);
    }
    draw_set_halign(fa_left);
}
NovaChallengeMenu();
