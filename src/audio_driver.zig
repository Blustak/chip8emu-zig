const rl = @import("raylib").rl;
const std = @import("std");
const pi = std.math.pi;
pub var play_tone:bool = true;
const MAX_SAMPLES = 512;
const MAX_SAMPLES_PER_UPDATE=4096;

const frequency:f32 = 320.0;
var audio_freq:f32 = frequency;
var prev_freq:f32 = 1.0;
var sineIdx:f32 = 0.0;


var audio_stream:rl.AudioStream = undefined;
var data:?*anyopaque = undefined;
var writeBuf:?*anyopaque = undefined;


fn audio_callback_fn(buf:?*anyopaque, frames:c_uint) callconv(.c) void {
    audio_freq = frequency + (audio_freq - frequency) * 0.95;
    const incr = audio_freq/44100.0;

    const d: [*]i16 = @alignCast(@ptrCast(buf orelse return));

    for(0..frames) |i| {
        d[i] = @intFromFloat(32000.0*@sin(2*pi*sineIdx));
        sineIdx += incr;
        if (sineIdx > 1.0) {
            sineIdx -= 1.0;
        }
    }

}

pub fn init() !void {
    rl.InitAudioDevice();
    if (!rl.IsAudioDeviceReady()) {
        return error.AudioDeviceInitialisationError;
    }
    rl.SetAudioStreamBufferSizeDefault(MAX_SAMPLES_PER_UPDATE);
    audio_stream = rl.LoadAudioStream(44100, 16, 1);

    rl.SetAudioStreamCallback(audio_stream, &audio_callback_fn);
    data = rl.MemAlloc(@sizeOf(i16)*MAX_SAMPLES);
    writeBuf = rl.MemAlloc(@sizeOf(i16)*MAX_SAMPLES_PER_UPDATE);

}

pub fn play_sound() void {
    if (play_tone) {
        rl.PlayAudioStream(audio_stream);
    } else {
        rl.StopAudioStream(audio_stream);
    }
}

pub fn deinit() void {
    rl.CloseAudioDevice();
    rl.UnloadAudioStream(audio_stream);
    rl.MemFree(data);
    rl.MemFree(writeBuf);
}
