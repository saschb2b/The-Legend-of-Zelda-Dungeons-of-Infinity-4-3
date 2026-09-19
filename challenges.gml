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
