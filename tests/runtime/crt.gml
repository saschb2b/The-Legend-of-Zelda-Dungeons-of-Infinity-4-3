function CRTRender(source, target) {
    surface_set_target(target);
    draw_clear_alpha(c_black, 1);
    with (oRender) NovaCRT_Draw(source, surface_get_width(target), surface_get_height(target));
    surface_reset_target();
}
function CRTTests() {
    Record("gameplay CRT shader compiles on the device", oRender.NovaCRTReady);
    if (!oRender.NovaCRTReady) return;
    var filtering = gpu_get_texfilter();
    var color = draw_get_color();
    var alpha = draw_get_alpha();
    var original_shader = shader_current();
    shader_reset();
    draw_set_alpha(1);
    draw_set_color(c_white);
    var source = surface_create(256, 224);
    var enlarged = surface_create(1024, 896);
    var target = surface_create(1280, 960);
    var reference = surface_create(1280, 960);
    surface_set_target(source);
    draw_clear_alpha(c_black, 1);
    surface_reset_target();
    CRTRender(source, target);
    Record("CRT keeps black black without animated noise", surface_getpixel(target, 640, 480) == c_black);
    for (var level = 32; level <= 224; level += 96) {
        surface_set_target(source);
        draw_clear_alpha(make_color_rgb(level, level, level), 1);
        surface_reset_target();
        CRTRender(source, target);
        var red = 0;
        var green = 0;
        var blue = 0;
        var low = 255;
        var high = 0;
        for (var row = 0; row < 30; row++) {
            for (var column = 0; column < 3; column++) {
                var pixel = surface_getpixel(target, 639 + column, 465 + row);
                red += color_get_red(pixel);
                green += color_get_green(pixel);
                blue += color_get_blue(pixel);
                low = min(low, color_get_red(pixel));
                high = max(high, color_get_red(pixel));
            }
        }
        var mean = (red + green + blue) / 270;
        Record("CRT preserves gray " + string(level) + " brightness", abs(mean - level) < level * 0.12 + 2);
        Record("CRT gray " + string(level) + " has no color cast", abs(red - green) / 90 < 1 && abs(green - blue) / 90 < 1);
        Record("CRT gray " + string(level) + " has beam and phosphor detail", high - low > 8);
    }
    surface_set_target(source);
    draw_clear_alpha(make_color_rgb(128, 128, 128), 1);
    surface_reset_target();
    for (var size = 0; size < 2; size++) {
        var small = surface_create(size == 0 ? 256 : 640, size == 0 ? 224 : 480);
        CRTRender(source, small);
        var brightness = 0;
        for (var sample = 0; sample < 60; sample++) {
            var value = surface_getpixel(small, 90 + sample mod 3, 90 + sample div 3);
            brightness += (color_get_red(value) + color_get_green(value) + color_get_blue(value)) / 3;
        }
        Record("CRT preserves brightness at " + string(surface_get_width(small)) + " pixels", abs(brightness / 60 - 128) < 12);
        surface_free(small);
    }
    surface_set_target(source);
    draw_clear_alpha(c_black, 1);
    draw_set_color(c_white);
    draw_rectangle(128, 112, 128, 112, false);
    surface_reset_target();
    CRTRender(source, target);
    Record("CRT bloom spreads light beyond a source pixel", color_get_red(surface_getpixel(target, 648, 482)) > 2);
    Record("CRT bloom preserves distant blacks", surface_getpixel(target, 700, 482) == c_black);
    surface_set_target(source);
    draw_clear_alpha(c_black, 1);
    draw_set_color(c_red);
    draw_rectangle(0, 0, 31, 31, false);
    draw_set_color(c_lime);
    draw_rectangle(224, 192, 255, 223, false);
    for (var xpixel = 40; xpixel < 216; xpixel++) {
        draw_set_color(xpixel mod 2 == 0 ? c_white : c_black);
        draw_rectangle(xpixel, 32, xpixel, 191, false);
    }
    draw_set_color(c_white);
    surface_reset_target();
    gpu_set_texfilter(false);
    surface_set_target(enlarged);
    draw_surface_stretched(source, 0, 0, 1024, 896);
    surface_reset_target();
    CRTRender(source, reference);
    gpu_set_texfilter(true);
    CRTRender(enlarged, target);
    Record("CRT restores texture filtering", gpu_get_texfilter());
    Record("CRT restores the previous shader", shader_current() == -1);
    Record("CRT retains the top-left corner", color_get_red(surface_getpixel(target, 0, 0)) > 100);
    Record("CRT retains the bottom-right corner", color_get_green(surface_getpixel(target, 1279, 959)) > 100);
    var same = true;
    for (var sample = 0; sample < 60; sample++) {
        var px = 270 + sample * 11;
        var py = 420 + sample;
        same = same && surface_getpixel(target, px, py) == surface_getpixel(reference, px, py);
    }
    Record("CRT samples native pixels from the enlarged world", same);
    shader_set(shd_CRT);
    CRTRender(enlarged, reference);
    Record("CRT restores an active shader", shader_current() == shd_CRT);
    shader_reset();
    CRTRender(enlarged, reference);
    Record("CRT phosphors remain stationary between frames", surface_getpixel(target, 501, 480) == surface_getpixel(reference, 501, 480));
    oRender.NovaCRTReady = false;
    CRTRender(source, target);
    Record("CRT compilation failure falls back to the game image", surface_getpixel(target, 0, 0) == c_red);
    oRender.NovaCRTReady = true;
    surface_free(source);
    surface_free(enlarged);
    surface_free(target);
    surface_free(reference);
    gpu_set_texfilter(filtering);
    draw_set_color(color);
    draw_set_alpha(alpha);
    if (original_shader == -1) shader_reset(); else shader_set(original_shader);
}

function CRTBenchmarkStart() {
    CRTSaved = global.Users[global.UserIndex].Prefs[3];
    CRTBenchmarkFrame = 0;
    CRTTimes = [[], []];
    global.Users[global.UserIndex].Prefs[3] = false;
}
function CRTBenchmarkStep() {
    var mode = CRTBenchmarkFrame div 150;
    var frame = CRTBenchmarkFrame mod 150;
    // Warm up shader caches and GPU clocks before measuring each mode.
    if (frame >= 30) array_push(CRTTimes[mode], delta_time / 1000);
    CRTBenchmarkFrame++;
    if (CRTBenchmarkFrame == 150) global.Users[global.UserIndex].Prefs[3] = true;
    if (CRTBenchmarkFrame < 300) return false;
    global.Users[global.UserIndex].Prefs[3] = CRTSaved;
    for (var index = 0; index < 2; index++) {
        var values = CRTTimes[index];
        array_sort(values, true);
        var total = 0;
        for (var sample = 0; sample < array_length(values); sample++) total += values[sample];
        var mean = total / array_length(values);
        var timing = {mean_ms: mean, p95_ms: values[113], frames_per_second: 1000 / mean};
        if (index == 0) CRTBenchmark.off = timing; else CRTBenchmark.on = timing;
    }
    Record("CRT sustains the scene's frame rate", CRTBenchmark.on.mean_ms <= CRTBenchmark.off.mean_ms * 1.25 + 1);
    return true;
}
