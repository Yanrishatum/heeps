package cherry;

import hxd.snd.SoundGroup;
import hxd.snd.Channel;
import hxd.snd.ChannelGroup;
import hxd.res.Sound;

class Music {
  
  public static var current(default, null):Sound;
  public static var channelGroup:ChannelGroup;
  static var channel:Channel;
  public static var FADE_TIME:Float = 0.4;
  
  public static var soundGroups: Map<String, SoundGroup> = [];
  
  public static function play(res:Sound, fade:Bool = true) {
    if (res == null) {
      stop(fade);
      return;
    }
    if (channel != null) {
      if (fade) {
        var old = channel;
        old.fadeTo(0, FADE_TIME, () -> old.stop());
      } else {
        channel.stop();
      }
    }
    current = res;
    channel = current.play(true, fade ? 0 : 1, channelGroup);
    if (fade) channel.fadeTo(1, FADE_TIME);
  }
  
  public static function crossfade(res: Sound) {
    if (res == current) return;
    if (res == null) {
      stop();
      return;
    }
    var pos: Float = 0;
    if (channel != null) {
      var old = channel;
      pos = old.position;
      old.fadeTo(0, FADE_TIME, () -> old.stop());
    }
    current = res;
    channel = res.play(true, 0, channelGroup);
    channel.position = pos;
    channel.fadeTo(1, FADE_TIME);
  }
  
  public static function pause(fade:Bool = true) {
    if (channel != null && !channel.pause) {
      if (fade) {
        channel.fadeTo(0, FADE_TIME, () -> channel.pause = true);
      } else {
        channel.pause = false;
      }
    }
  }
  
  public static function unpause(fade:Bool = true) {
    if (channel != null && channel.pause) {
      if (fade) {
        channel.position -= FADE_TIME * 2;
        channel.pause = false;
        channel.fadeTo(1, FADE_TIME);
      } else {
        channel.pause = false;
      }
    }
  }
  
  public static function unpauseAt(time:Float, fade:Bool = true) {
    if (channel != null && channel.pause) {
      if (fade) {
        channel.position = time - FADE_TIME;
        channel.pause = false;
        channel.fadeTo(1, FADE_TIME);
      } else {
        channel.position = time;
        channel.pause = false;
      }
    }
  }
  
  public static function transit(res:Sound, jingle:Sound, fadeCurrent:Bool = true, fadeNew:Bool = false) {
    if (res == null) {
      stop(fadeCurrent||fadeNew);
      if (jingle != null) {
        var chn = jingle.play(false, fadeCurrent ? 0 : 1, channelGroup);
        if (fadeCurrent) chn.fadeTo(1, FADE_TIME);
      }
      return;
    }
    else if (jingle == null) {
      play(res, fadeNew);
      return;
    }
    if (channel != null) {
      if (fadeCurrent) {
        var old = channel;
        old.fadeTo(0, FADE_TIME, () -> old.stop());
      } else {
        channel.stop();
      }
    }
    current = res;
    channel = jingle.play(false, fadeCurrent ? 0 : 1, channelGroup);
    var chn = channel;
    if (fadeCurrent) channel.fadeTo(1, FADE_TIME);
    channel.onEnd = () -> {
      if (current == res && channel == chn) {
        channel = res.play(true, fadeNew ? 0 : 1, channelGroup);
        if (fadeNew) channel.fadeTo(1, FADE_TIME);
      }
    }
  }
  
  public static function jingle(jingle:Sound, fade:Bool = true) {
    if (jingle == null) return;
    var oldSong = current;
    var old = channel;
    if (old != null) {
      if (fade) {
        old.fadeTo(0, FADE_TIME, () -> old.pause = true);
      } else {
        old.pause = true;
      }
    }
    channel = jingle.play(false, fade ? 0 : 1, channelGroup);
    var chn = channel;
    if (fade) channel.fadeTo(1, FADE_TIME);
    channel.onEnd = function() {
      if (current == oldSong && channel == chn) {
        if (old != null) {
          old.pause = false;
          if (fade) old.fadeTo(1, FADE_TIME);
        }
        channel = old;
      }
    }
  }
  
  public static function stop(fade:Bool = true) {
    if (channel != null) {
      if (fade) {
        var chn = channel;
        chn.fadeTo(0, FADE_TIME, () -> chn.stop());
      } else {
        channel.stop();
      }
      channel = null;
      current = null;
    }
  }
  
  public static inline function soundGroup(name: String) {
    return soundGroups[name] ?? (soundGroups[name] = new SoundGroup(name));
  }
  
}