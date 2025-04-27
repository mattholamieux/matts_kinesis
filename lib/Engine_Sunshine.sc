// based on the moonshine and eglut (latkes) engines
//    moonshine: https://monome.org/docs/norns/engine-study-1/
//    latkes: https://github.com/jaseknighter/latkes
Engine_Sunshine : CroneEngine {
// All norns engines follow the 'Engine_MySynthName' convention above

  classvar numVoices = 2;
  var pg;
	var liveRecordingParams;
	var voiceParams;
  var fileBuffers;
  var voice = 0;
  var voiceModes;
  var maxBufferLength = 10;
  var liveBuffers;
  var recorders, grainPlayers, phases, grainPlayerPositions;
  var grainEnvBuffers; 
  var updatingBuffers = false;
  var grainSizes;

	*new { arg context,doneCallback;
		^super.new(context,doneCallback);
	}


  readDisk { | voice, path, sampleStart, sampleLength |
    if (path.notNil, {
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
        grainPlayers[voice].set(
          \buf, fileBuffers[voice],
          \buf_win_start, (sampleStart/maxBufferLength),
          \buf_win_start, ((sampleStart + sampleLength)/maxBufferLength)
        );
      });
    },{
      //if path is nil, assume the file_buffers array already has the buffer
      //and it just needs to be set to the grainPlayers
      grainPlayers[voice].set(\buf, fileBuffers[voice]);
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
    // create buffers to hold grain envelopes
    grainEnvBuffers = Array.fill(numVoices, { arg i; 
      var winenv = Env([0, 1, 0], [0.5, 0.5], [\wel, \wel]);
      Buffer.sendCollection(context.server, winenv.discretize, 1);
    });

    voiceModes = Array.fill(numVoices, { arg i; 0 });
    grainPlayerPositions = Array.fill(numVoices, { arg i; 0 });
    phases = Array.fill(numVoices, { | i | Bus.control(context.server); });
    grainSizes = Array.fill(numVoices, { | i | 0.1; });

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
        pitch  = 1, grain_env_buf = -1
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
              envbufnum:grain_env_buf,
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
              envbufnum:grain_env_buf,
              maxGrains:200,
              mul:0.5
      );     
      env = EnvGen.kr(Env.asr(0.5, 0.5, 0), gate: gate);
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
        grainPlayers[voice].set(\reset_pos,0);
      },{
        grainPlayers[voice].set(\reset_pos,1);
      });
      grainPlayerPositions[voice] = position;
    }, "/save_last_position");

    OSCdef(\osc_def_2, {|msg| 
      var voice = msg[3].asInteger;
      // (["grain phase completed",voice]).postln;
      // if (density_phase == 1, { /*do something here*/ });
    }, "/density_phase_completed");

    // create arrays to hold recorder and grain players synthdefs
    recorders  = Array.newClear(numVoices);
    grainPlayers     = Array.newClear(numVoices);
    
    // create a group to hold the synthdef arrays
    pg = ParGroup.head(context.xg);

    //instantiate the live recorder(s) and grain voice(s)
    numVoices.do({ | i |
      recorders.put(i,
          Synth.tail(pg,\live_recorder, [
              \buf,liveBuffers[i],
              \in,0,
          ])
      );
      grainPlayers.put(i,
        Synth.after(recorders[i], \grain_player, [
          \voice, i,
          \out, context.out_b.index,
          \phase_out, phases[i].index,
          \buf, liveBuffers[i],
          \grain_env_buf, grainEnvBuffers[i]
        ])
      );
      (["add grain synth voice",liveBuffers[0]]).postln;
    });

    context.server.sync;
    this.addCommand("live", "i", { arg msg;
      var voice = msg[1] - 1;
      var buf_array_ix;
      voiceModes[voice] = 0; // set mode to 1: live mode
      grainPlayers[voice].set(
        \buf, liveBuffers[voice],
      );
    });

    this.addCommand("sample", "is", { arg msg;
        var voice = msg[1]-1;
        var path = msg[2];
        var sample_start = 0;
        var sample_length = maxBufferLength*60;
        var bpath = fileBuffers[voice].path;
        voiceModes[voice] = 1; // set mode to 1: sample mode
        if((bpath.notNil).and(bpath == path),{
            (["file already loaded",path]).postln;
            this.readDisk(voice,nil,sample_start,sample_length);
        },{
            (["new file to load",path,bpath]).postln;
            this.readDisk(voice,path,sample_start,sample_length);
        });
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
      \gate, 1,
      // \buf_win_end, 1,
      // \pitch, 1,
    ]);

    // "Commands" are how the Lua interpreter controls the engine.
    // The format string is analogous to an OSC message format string,
    //   and the 'msg' argument contains data.
    // We'll just loop over the keys of the dictionary, 
    //   and add a command for each one, which updates corresponding value:
		liveRecordingParams.keysDo({ | key |
			this.addCommand(key, "if", { arg msg;
        var voice = msg[1]-1;
        liveRecordingParams[key] = msg[2];
        recorders[voice].set(key,liveRecordingParams[key]);
        // (["set recorder param", voice, key, liveRecordingParams[key]]).postln;
			});
		});

		voiceParams.keysDo({ arg key;
			this.addCommand(key, "if", { | msg |
        var voice = msg[1]-1;
        voiceParams[key] = msg[2];
        grainPlayers[voice].set(key,voiceParams[key]);
        // (["set voice param", key, voiceParams[key]]).postln;
        if(key == \size,{
          // (["set size", key, voiceParams[key]]).postln;
          grainSizes[voice] = voiceParams[key]
        })
			});
		});

    this.addCommand("grain_env", "ii", { arg msg;
          var voice = msg[1] - 1;
          var shape = (msg[2]-1).asInteger;
          var attack_level = 1;
          var attack_time = 0.5;
          var decay_time = 0.5;
          var size = grainSizes[voice];

          var oldbuf;
          var curve_types=["exp","squared","lin","sin","cubed","wel"];
          var winenv = Env(
              [0.001, attack_level, 0.001], 
              [attack_time*size, decay_time*size], 
              [curve_types[shape].asSymbol,curve_types[shape].asSymbol]
          );

          if (updatingBuffers == false,{
              updatingBuffers = true;
              Buffer.sendCollection(context.server, winenv.discretize(n:(1024*size).softRound(resolution:0.00390625,margin:0)), action:{
                  arg buf;
                  var oldbuf = grainEnvBuffers[voice];
                  Routine({
                      grainPlayers[voice].set(\grain_env_buf, buf);
                      grainEnvBuffers[voice] = buf;
                      updatingBuffers = false;
                      (["new env",curve_types[shape]]).postln;
                      10.wait; //wait 10 seconds to free the old buf in case it is in use.
                      oldbuf.free;
                  }).play;
              });
          })
      });
      
    this.addCommand("reload_grain_player", "ifffffi", { | msg |
      var voice = msg[1]-1; 
      var speed = msg[2]; 
      var density = msg[3]; 
      var pos = msg[4]; 
      var size = msg[5]; 
      var jitter = msg[6]; 
      var grain_env = msg[7]-1;
      var old_voice = grainPlayers[voice];
      var buffer;
      if (voiceModes[voice] == 0,{
        buffer = liveBuffers[voice];
      },{
        buffer = fileBuffers[voice];
      });
      grainPlayers.put(voice,Synth.after(recorders[voice], 
        \grain_player, [
          \voice, voice,
          \out, context.out_b.index,
          \phase_out, phases[voice].index,
          \buf, buffer,
          \speed, speed,
          \density, density,
          \pos, pos,
          \size, size,
          \jitter, jitter,
          \grain_env, grain_env,
        ])
      );
      old_voice.free;
    })

	}

  free {
    "free sunshine!".postln;  
    grainPlayers.do({ arg player; player.free; });
    recorders.do({ arg recorder; recorder.free; });
		phases.do({ arg bus; bus.free; });
		liveBuffers.do({ arg buf; buf.free; });
		fileBuffers.do({ arg buf; buf.free; });
  }
}