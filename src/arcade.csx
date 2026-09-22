using System;
using System.IO;
using System.IO.Compression;
using System.Text.Json;
using System.Security.Cryptography;
using UndertaleModLib;
using UndertaleModLib.Models;
using UndertaleModLib.Util;

void ApplyArcade() {
    // GLES requires global initializers to be constant; aspect depends on a uniform.
    var crt = Data.Shaders.ByName("shd_CRT");
    var fragment = crt.GLSL_ES_Fragment.Content;
    var aspect = "vec2 aspect = uni_crt_sizes.xy / uni_crt_sizes.x;";
    if (!fragment.Contains(aspect) || !fragment.Contains("float border_corners(vec2 UV) {"))
        throw new Exception("CRT aspect boundary missing");
    crt.GLSL_ES_Fragment = Data.Strings.MakeString(fragment.Replace(aspect, "")
        .Replace("float border_corners(vec2 UV) {", "float border_corners(vec2 UV) {\n  " + aspect));
    var crtCode = Read("gml_GlobalScript___CRT");
    foreach (var uniform in new[] { "radial_distortion", "border", "RGB_separation", "scanlines", "noise" }) {
        var call = "shader_set_uniform_f(global.uni_use_" + uniform + ",";
        if (crtCode.Split(call).Length != 3) throw new Exception("CRT boolean uniform boundary missing: " + uniform);
        crtCode = crtCode.Replace(call, "shader_set_uniform_i(global.uni_use_" + uniform + ",");
    }
    edits["gml_GlobalScript___CRT"] = crtCode;
    using var file = File.OpenRead(Path.Combine(patchDir, "assets/arcade-resources.zip"));
    using var archive = new ZipArchive(file, ZipArchiveMode.Read);
    JsonDocument ReadSpec(string name) {
        using var stream = archive.GetEntry(name).Open();
        return JsonDocument.Parse(stream);
    }
    string Hash(byte[] bytes) => Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
    using var manifest = ReadSpec("manifest.json");
    var spec = manifest.RootElement;
    byte[] Patch(byte[] original, string name) {
        using var document = ReadSpec(name);
        var delta = document.RootElement;
        var bytes = new byte[delta.GetProperty("size").GetInt32()];
        Array.Copy(original, bytes, Math.Min(original.Length, bytes.Length));
        foreach (var range in delta.GetProperty("ranges").EnumerateArray()) {
            var changed = Convert.FromBase64String(range[1].GetString());
            Array.Copy(changed, 0, bytes, range[0].GetInt32(), changed.Length);
        }
        if (Hash(bytes) != delta.GetProperty("sha256").GetString()) throw new Exception("Arcade resource checksum: " + name);
        return bytes;
    }
    using var worker = new TextureWorker();
    var source = Data.Sprites.ByName(spec.GetProperty("source_sprite").GetString());
    var export = Path.Combine(patchDir, ".build/arcade-base.png");
    worker.ExportAsPNG(source.Textures[spec.GetProperty("source_frame").GetInt32()].Texture, export, null, true);
    var originalSprite = File.ReadAllBytes(export);
    if (Hash(originalSprite) != spec.GetProperty("sprite_sha256").GetString()) throw new Exception("Arcade sprite source mismatch");
    foreach (var item in spec.GetProperty("sprites").EnumerateArray()) {
        var name = item.GetProperty("name").GetString();
        var sprite = new UndertaleSprite {
            Name = Data.Strings.MakeString(name), Width = item.GetProperty("width").GetUInt32(), Height = item.GetProperty("height").GetUInt32(),
            OriginX = item.GetProperty("origin_x").GetInt32(), OriginY = item.GetProperty("origin_y").GetInt32(),
            MarginLeft = item.GetProperty("left").GetInt32(), MarginRight = item.GetProperty("right").GetInt32(),
            MarginTop = item.GetProperty("top").GetInt32(), MarginBottom = item.GetProperty("bottom").GetInt32()
        };
        var nineSlice = item.GetProperty("nine_slice");
        if (nineSlice.ValueKind != JsonValueKind.Null) {
            sprite.IsSpecialType = true;
            sprite.SVersion = 3;
            sprite.V3NineSlice = JsonSerializer.Deserialize<UndertaleSprite.NineSlice>(nineSlice.GetRawText());
        }
        for (var frame = 0; frame < item.GetProperty("frames").GetInt32(); frame++) {
            var texture = new UndertaleEmbeddedTexture { Name = new UndertaleString(name) };
            texture.TextureData.Image = GMImage.FromPng(Patch(originalSprite, name + "_" + frame + ".json"));
            Data.EmbeddedTextures.Add(texture);
            var page = new UndertaleTexturePageItem {
                SourceWidth = (ushort)sprite.Width, SourceHeight = (ushort)sprite.Height,
                TargetWidth = (ushort)sprite.Width, TargetHeight = (ushort)sprite.Height,
                BoundingWidth = (ushort)sprite.Width, BoundingHeight = (ushort)sprite.Height, TexturePage = texture
            };
            Data.TexturePageItems.Add(page);
            sprite.Textures.Add(new UndertaleSprite.TextureEntry { Texture = page });
        }
        if (name == "sClawMachine" || name == "sArcade_Mothula") {
            var mask = sprite.NewMaskEntry(Data);
            Array.Fill(mask.Data, (byte)255);
            sprite.CollisionMasks.Add(mask);
        }
        Data.Sprites.Add(sprite);
    }
    var soundSource = Data.Sounds.ByName(spec.GetProperty("source_sound").GetString());
    byte[] originalSound;
    if (soundSource.AudioFile != null) originalSound = soundSource.AudioFile.Data;
    else {
        using var portStream = File.OpenRead(Path.Combine(patchDir, ".build/original.port"));
        using var port = new ZipArchive(portStream, ZipArchiveMode.Read);
        using var stream = port.GetEntry("assets/audiogroup" + soundSource.GroupID + ".dat").Open();
        using var memory = new MemoryStream();
        stream.CopyTo(memory);
        memory.Position = 0;
        // The upstream audio group has alignment padding that UTMT reports as warnings.
        var audio = UndertaleIO.Read(memory, (warning, _) => Console.WriteLine(warning));
        originalSound = audio.EmbeddedAudio[soundSource.AudioID].Data;
    }
    if (Hash(originalSound) != spec.GetProperty("sound_sha256").GetString()) throw new Exception("Arcade audio source mismatch");
    foreach (var item in spec.GetProperty("sounds").EnumerateArray()) {
        var name = item.GetProperty("name").GetString();
        var audio = new UndertaleEmbeddedAudio { Name = new UndertaleString(name), Data = Patch(originalSound, name + ".json") };
        Data.EmbeddedAudio.Add(audio);
        Data.Sounds.Add(new UndertaleSound {
            Name = Data.Strings.MakeString(name), Type = Data.Strings.MakeString(".wav"), File = Data.Strings.MakeString(name + ".wav"),
            Flags = UndertaleSound.AudioEntryFlags.Regular | UndertaleSound.AudioEntryFlags.IsEmbedded,
            Volume = item.GetProperty("volume").GetSingle(), Pitch = 1,
            AudioFile = audio, AudioID = Data.EmbeddedAudio.Count - 1,
            GroupID = Data.GetBuiltinSoundGroupID(), AudioGroup = Data.AudioGroups[Data.GetBuiltinSoundGroupID()]
        });
    }
    foreach (var name in new[] { "oArcade_Mothula", "oClawMachine" }) {
        Data.GameObjects.Add(new UndertaleGameObject {
            Name = Data.Strings.MakeString(name), Visible = true,
            Sprite = Data.Sprites.ByName(name == "oClawMachine" ? "sClawMachine" : "sArcade_Mothula"),
            ParentId = Data.GameObjects.ByName(name == "oClawMachine" ? "oPopMachine" : "oArcade")
        });
    }
    group.QueueAppend("gml_GlobalScript___Arcade", File.ReadAllText(Path.Combine(patchDir, "src/gml/arcade/arcade.gml")));
    foreach (var entry in new[] { ("oArcade_Mothula", "slot"), ("oClawMachine", "claw") }) {
        foreach (var ev in new[] { "Create_0", "Step_0", "Draw_0", "CleanUp_0" }) {
            var path = Path.Combine(patchDir, "src/gml/arcade", entry.Item2 + "_" + ev.ToLowerInvariant() + ".gml");
            group.QueueReplace("gml_Object_" + entry.Item1 + "_" + ev, File.ReadAllText(path));
        }
    }
    // Parent end-step state changes belong to the older arcade games.
    group.QueueReplace("gml_Object_oArcade_Mothula_Step_2", "");
    group.QueueReplace("gml_Object_oArcade_Mothula_Alarm_1", "");
    group.QueueReplace("gml_Object_oArcade_Mothula_Draw_73", File.ReadAllText(Path.Combine(patchDir, "src/gml/arcade/slot_draw_73.gml")));
    Edit("gml_GlobalScript___RoomTemplates", "global.Templates_Room = json_parse(buffer_read(ParsedTemplates_Buffer, buffer_string));",
        "global.Templates_Room = json_parse(buffer_read(ParsedTemplates_Buffer, buffer_string));\n    global.NovaArcadeTemplates();");
    Edit("gml_GlobalScript___Dungeon_Draw_SpecialObjs_Forced", "case \"Poker\":", "case \"ClawMachine\":\n                        ArcadeType = oClawMachine;\n                        PosX = ObjX; PosY = ObjY;\n                        break;\n                    case \"Mothula\":\n                        ArcadeType = oArcade_Mothula;\n                        break;\n                    case \"Poker\":");
}
