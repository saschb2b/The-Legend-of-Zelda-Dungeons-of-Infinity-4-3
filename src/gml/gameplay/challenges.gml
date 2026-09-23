global.NovaChallengeOptions = array_create(12, 0);
global.NovaOption = function(index) {
    return global.NovaChallengeOptions[index];
};
global.NovaResetChallenges = function() {
    global.NovaChallengeOptions = array_create(12, 0);
    global.Challenges = array_create(7, false);
};
global.NovaLoadChallenges = function(save) {
    global.NovaChallengeOptions = array_create(12, 0);
    if (variable_struct_exists(save, "NovaChallengeOptions")) {
        for (var i = 0; i < min(12, array_length(save.NovaChallengeOptions)); i++)
            global.NovaChallengeOptions[i] = clamp(floor(save.NovaChallengeOptions[i]), 0, i < 9 ? 3 : 1);
    }
    global.Inventory_ItemData[2].Index_Max = 5 + global.NovaOption(4);
};
global.NovaMaxHearts = function() {
    return global.Challenges[0] ? 5 : global.NovaChallengeHearts[global.NovaOption(1)];
};
global.NovaRupeeLimit = function(amount) {
    var cap = global.NovaChallengeRupees[global.NovaOption(5)];
    return cap < 0 ? max(0, amount) : clamp(amount, 0, cap);
};
global.NovaChallengeActive = function() {
    for (var i = 0; i < 12; i++) if (global.NovaOption(i) > 0) return true;
    for (var i = 0; i < 7; i++) if (global.Challenges[i]) return true;
    return false;
};

// Shared by New adventure, player Details and the pause menu.
global.NovaBonusNames = ["None", "100 Rupees", "+1 Inventory slot", "+1 Heart", "Wooden Shield", "Rod of Stone", "10 Fire Orbs", "Antidote"];
// Presets borrow Zelda's harder replays; each keeps a plain description.
global.NovaPresets = [
    {name: "Hero's Path", help: "The standard adventure, with no extra challenges.", values: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]},
    {name: "Second Quest", help: "A tougher run: fewer hearts, more enemies and curses, darker rooms and higher prices.", values: [1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0]},
    {name: "Master Quest", help: "For veterans: scarce hearts, dark dungeons, crowds of enemies and the Wall Master.", values: [2, 2, 1, 2, 1, 1, 2, 2, 2, 0, 0, 1]}
];
global.NovaChallengeLevel = function(values) {
    var level = 0;
    for (var i = 0; i < array_length(values); i++) level += values[i];
    return level;
};
// Returns the matching preset index, or -1 for a custom mix.
global.NovaPresetIndex = function(values) {
    for (var p = 0; p < array_length(global.NovaPresets); p++) {
        if (json_stringify(global.NovaPresets[p].values) == json_stringify(values)) return p;
    }
    return -1;
};
