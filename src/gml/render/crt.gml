NovaCRTReady = shader_is_compiled(shd_NovaCRT);
NovaCRTSource = NovaCRTReady ? shader_get_uniform(shd_NovaCRT, "SourceSize") : -1;
NovaCRTBeam = NovaCRTReady ? shader_get_uniform(shd_NovaCRT, "hardScan") : -1;
function NovaCRT_Draw(source, width, height, left = 0, top = 0) {
    if (!NovaCRTReady) {
        draw_surface_stretched(source, left, top, width, height);
        return;
    }
    var filtering = gpu_get_texfilter();
    var previous = shader_current();
    gpu_set_texfilter(false);
    shader_set(shd_NovaCRT);
    // NovaFrame is already enlarged 4x; reconstruct from native game pixels.
    shader_set_uniform_f(NovaCRTSource, 256, 224);
    // Broader beams reduce scanline aliasing on displays below 3x vertical scale.
    shader_set_uniform_f(NovaCRTBeam, -clamp(height / 224 * 2, 2, 6));
    draw_surface_stretched(source, left, top, width, height);
    if (previous == -1) shader_reset(); else shader_set(previous);
    gpu_set_texfilter(filtering);
}
