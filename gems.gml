function GemsInPond(pond) {
    var count = 0;
    for (var i = 0; i < array_length(pond.GemCount); i++) count += pond.GemCount[i];
    return count;
}
function GetGemCombo(pond) {
    if (GemsInPond(pond) < 2) return -1;
    var combo = [];
    for (var i = 0; i < array_length(pond.GemCount); i++) {
        while (pond.GemCount[i] > 0 && array_length(combo) < 2) {
            array_push(combo, i);
            pond.GemCount[i]--;
        }
        if (array_length(combo) == 2) return [max(combo[0], combo[1]), min(combo[0], combo[1])];
    }
    return -1;
}
global.NovaGemSaveInit = function() {
    var gems = global.Inventory_ItemData[14];
    if (array_length(gems.Amount) < 10) gems.Amount[9] = 0;
};
