// based on the moonshine and eglut (latkes) engines
//    moonshine: https://monome.org/docs/norns/engine-study-1/
//    latkes: https://github.com/jaseknighter/latkes
Engine_Sunshine : CroneEngine {
// All norns engines follow the 'Engine_MySynthName' convention above

  classvar numVoices = 1;
  var pg;
	var liveRecordingParams;
	var voiceParams;
  var fileBuffers;
  var voice = 0;
  var voiceModes;
  var maxBufferLength = 10;
  var liveBuffers;
  var recorders, voices, phases, grainPlayerPositions;

	*new { arg context,doneCallback;
		^super.new(context,doneCallback);
	}


  readDisk { | voice, path, sampleStart, sampleLength |
    var startFrame = 0;
    var soundFile, duration, newBuf;
    soundFile = SoundFile.new;
    soundFile.openRead(path.asString.standardizePath);
    duration = soundFile.duration;
    soundFile.close;
    ["file read into buffer...soundfile duration,sampleStart, sampleLength",duration,sampleStart,sampleLength].postln;
    newBuf = Buffer.readChannel(context.server, path, channels:[0], action: {
      arg buf;
      fileBuffers[voice].zero; // clear the file buffer
      buf.copyData(fileBuffers[voice]); //copy the audio into the fileBuffer 
      voices[voice].set(
        \buf, fileBuffers[voice],
        \buf_win_start, (sampleStart/maxBufferLength),
        \buf_win_start, ((sampleStart + sampleLength)/maxBufferLength)
      );
    });
  }

	alloc { // allocate memory to the following:
    // server=context.server;

    // define functions used to setup audio sent to the Sunshine SynthDef
  
    // function to read recorded audio into a buffer
    // note: the pipes (|) are used to define arguments
    //       "argements" in sc are variables that can be set
    //         by calling the function (or UGen).
    
    // create the buffer(s) for recorded audio
    // note: by default, only one buffer will be created
    //       because by default, the engine only uses one mono voice
    fileBuffers = Array.fill(numVoices, { arg i;
      Buffer.alloc(context.server,context.server.sampleRate * maxBufferLength);
    });
    // create the live buffer(s) for live audio
    liveBuffers = Array.fill(numVoices, { arg i;
      Buffer.alloc(context.server,context.server.sampleRate * maxBufferLength,1);
    });
    voiceModes = Array.fill(numVoices, { arg i; 0 });
    grainPlayerPositions = Array.fill(numVoices, { arg i; 0 });
    phases = Array.fill(numVoices, { | i | Bus.control(context.server); });

    //pause the code at this point to wait for the buffers to be allocated
    context.server.sync;

		// add SynthDefs
		SynthDef(\live_recorder, { 
      | in = 0, //define the args
        buf = 0, 
        rate = 1, 
        pos = 0, 
        reset_pos = 1,
        buf_win_start = 0, 
        buf_win_end = 1,
        rec_level = 1,
        pre_level = 0
      | 
      var buf_dur = BufDur.ir(buf);
      var buf_pos = Phasor.kr(trig: reset_pos,
                rate: buf_dur.reciprocal / ControlRate.ir * rate,
                start:buf_win_start, end:buf_win_end, resetPos: buf_win_start);
      var sig = SoundIn.ar(in);
      var recording_offset = buf_win_start*maxBufferLength*SampleRate.ir;
      var rec_buf_reset = Impulse.kr(
        freq:((buf_win_end-buf_win_start)*maxBufferLength).reciprocal,
        phase:buf_win_start
      );
      var testsnd;

      RecordBuf.ar(sig, buf, offset: recording_offset, 
        recLevel: rec_level, preLevel: pre_level, run: 1.0, loop: 1.0, 
        trigger: rec_buf_reset, doneAction: 0);

      // --[[ 0_0 ]]
      // -- uncomment to confirm the live buffer is recording
      // testsnd = PlayBuf.ar(1, bufnum: buf, rate: 1.0, trigger: 1.0, startPos: 0.0, loop: 1.0, doneAction: 0);
      // Out.ar(0,testsnd);
    }).add;

		SynthDef(\grain_player, { 
      | voice, buf, out, phase_out //define the args
        gate = 1, 
        pos = 0, reset_pos = 0,
        buf_win_start = 0, buf_win_end = 1,
        sample_length = 10,
        density = 1, speed = 1, size = 0.1, jitter = 0,
        pitch  = 1
      |
      var sig;
      var buf_pos;
      var win_size;
      var env, grain_env;
      var jitter_sig;
      var sig_pos;
      var localin = LocalIn.kr(2);
      var grain_trig = 1;
      var reset_grain_trig = localin[0];
      var buf_dur = BufDur.ir(buf);
      // var out_of_window_trig = localin[1];

      pos = pos.linlin(0,1,buf_win_start,buf_win_end);

      //note: see the save_last_position OSCdef below
      //      which moves the player to a new position 
      //      if the engine receives a new engine.pos command 
      //      from the lua script
      SendReply.kr(Impulse.kr(10), "/save_last_position", [voice,pos]);

      win_size = buf_win_end - buf_win_start - (size / maxBufferLength);
      density = Lag.kr(density);

      grain_trig = Impulse.kr(density);

      // SendReply.kr(grain_trig, "/density_phase_completed", [voice]);

      size = Lag.kr(size);
      pitch = Lag.kr(pitch);
      jitter_sig = TRand.kr(trig: grain_trig,
        lo: (speed < 0) * buf_dur.reciprocal.neg * jitter,
        hi: (speed >= 0) * buf_dur.reciprocal * jitter);
      
      buf_pos = Phasor.kr(trig: reset_pos,
        rate: buf_dur.reciprocal / ControlRate.ir * speed,
        start:buf_win_start, end:buf_win_end, resetPos: pos);

      sig_pos = buf_pos;
      
      // add jitter to each signal position
      sig_pos = (sig_pos+jitter_sig).wrap(buf_win_start,buf_win_end);
      
      sig = GrainBuf.ar(
              numChannels: 1, 
              trigger:grain_trig, 
              dur:size, 
              sndbuf:buf, 
              pos: sig_pos,
              interp: 2, 
              rate:pitch,
              envbufnum:-1,
              maxGrains:200,
              mul:0.5,
          ) +
          GrainBuf.ar(
              numChannels: 1, 
              trigger:grain_trig, 
              dur:size, 
              sndbuf:buf, 
              pos: sig_pos,
              interp: 2, 
              rate:pitch,
              envbufnum:-1,
              maxGrains:200,
              mul:0.5
      );     
      env = EnvGen.kr(Env.asr(1, 1, 1), gate: gate);
      LocalOut.kr([grain_trig]);
      Out.kr(phase_out, sig_pos);
      Out.ar(out, [sig * env,sig * env]); 
		}).add;

    context.server.sync;

    // add OSC functions called by the grain_player
    OSCdef(\osc_def_1, {|msg| 
      var voice = msg[3].asInteger;
      var position = msg[4].asFloat;
      var prev_position = grainPlayerPositions[voice];
      if (position == prev_position,{
        voices[voice].set(\reset_pos,0);
      },{
        voices[voice].set(\reset_pos,1);
      });
      grainPlayerPositions[voice] = position;
    }, "/save_last_position");

    OSCdef(\osc_def_2, {|msg| 
      var voice = msg[3].asInteger;
      // (["grain phase completed",voice]).postln;
      // if (density_phase == 1, { /*do something here*/ });
    }, "/density_phase_completed");

    //instantiate the live recorder(s) and grain voice(s)
    recorders = Array.newClear(numVoices);
    voices = Array.newClear(numVoices);
    pg = ParGroup.head(context.xg);

    numVoices.do({ | i |
      recorders.put(i,
          Synth.tail(pg,\live_recorder, [
              \buf,liveBuffers[i],
              \in,0,
          ])
      );
      voices.put(i,
        Synth.after(recorders[i], \grain_player, [
          \voice, i,
          \out, context.out_b.index,
          \phase_out, phases[i].index,
          \buf, liveBuffers[i]
        ])
      );
      (["add grain synth voice",liveBuffers[0]]).postln;
    });

    context.server.sync;
    //note: not yet fully implemented
    this.addCommand("set_mode", "ii", { arg msg;
      var voice = msg[1] - 1;
      var mode = msg[2] - 1; // 0: live, 1: recorded
      var buf_array_ix;
      voiceModes[voice] = mode;
      voices[voice].set(\mode, mode);
    });

    // let's create a Dictionary (an unordered associative collection)
    //   to store parameter values, initialized to defaults.
		liveRecordingParams = Dictionary.newFrom([
			\rec_level, 1,
			\pre_level, 0,
    ]);
    
		voiceParams = Dictionary.newFrom([
      \speed, 1,
      \density, 1,
      \pos, 0,
      \size, 0.1,
      \jitter, 0,
      \buf_win_end, 1,
      \reset_pos, 0,
      // \pitch, 1,
    ]);

    // "Commands" are how the Lua interpreter controls the engine.
    // The format string is analogous to an OSC message format string,
    //   and the 'msg' argument contains data.
    // We'll just loop over the keys of the dictionary, 
    //   and add a command for each one, which updates corresponding value:
		liveRecordingParams.keysDo({ arg key;
			this.addCommand(key, "if", { arg msg;
        var voice = msg[1]-1;
        liveRecordingParams[key] = msg[2];
        recorders[voice].set(key,liveRecordingParams[key]);
        // (["set recorder param", voice, key, liveRecordingParams[key]]).postln;
			});
		});

		voiceParams.keysDo({ arg key;
			this.addCommand(key, "if", { arg msg;
        var voice = msg[1]-1;
        voiceParams[key] = msg[2];
        voices[voice].set(key,voiceParams[key]);
        // (["set voice param", key, voiceParams[key]]).postln;
			});
		});
	}

  free {
    "free sunshine!".postln;  
    voices.do({ arg voice; voice.free; });
    recorders.do({ arg recorder; recorder.free; });
		phases.do({ arg bus; bus.free; });
		liveBuffers.do({ arg buf; buf.free; });
		fileBuffers.do({ arg buf; buf.free; });
  }
}