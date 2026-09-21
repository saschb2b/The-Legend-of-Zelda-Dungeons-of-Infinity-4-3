# CRT-Lottes for the Nova

The gameplay CRT option ports Timothy Lottes' public-domain CRT shader from RetroArch's shader collection. It reconstructs horizontal detail with Gaussian filters, draws shaped scanline beams, and adds bloom. A phosphor mask modulates linear light before conversion back to sRGB.

Source: [libretro/glsl-shaders, crt-lottes.glsl](https://github.com/libretro/glsl-shaders/blob/e808ca09c699db7a843154cf7dc4dfd766d18a8a/crt/shaders/crt-lottes.glsl). The upstream file's SHA-256 is `699a947fc2744eb7e2dc4adb2c08a8b74e31685baa77cbc1face9593106b57ef`. `crt-lottes.fsh` retains its public-domain notice.

The GameMaker adaptation replaces RetroArch's shader inputs with the runner's vertex attributes, texture and matrix. It samples native 256×224 pixel centers from the enlarged world surface. The fixed Gaussian exponent of two uses multiplication. The filtering and bloom equations come from Lottes.

The Nova preset uses a flat aperture grille with mask weights 0.8/1.4, horizontal sharpness -3, beam sharpness -6 and bloom strength 0.08. Broader beams reduce aliasing below 3× vertical scale, with energy compensation to maintain brightness. Flat geometry keeps the entire playfield visible. The shader has no animated noise, chromatic displacement or added input frames. The HUD and button hints render afterward.

The existing CRT preference enables this shader. A compile failure displays the unfiltered world. Arcade machines retain their original game's shader.

## Research

[Russ's handheld shader guide](https://retrogamecorps.com/2024/09/01/guide-shaders-and-overlays-on-retro-handhelds/) discusses CRT Consumer, zfast CRT and glow combinations. His recommendations distinguish lightweight effects from more demanding CRT simulation.

[CRT Royale](https://github.com/libretro/glsl-shaders/blob/master/crt/shaders/crt-royale/README.TXT) models more features, including mask resampling, configurable beam profiles, diffusion and geometry. Its RetroArch pipeline uses multiple passes, mipmapping and sRGB framebuffers. This patch ports CRT-Lottes, not Royale. It fits the GameMaker compositor without importing RetroArch's preset pipeline.
