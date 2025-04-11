// based on the moonshine engine
// from: https://monome.org/docs/norns/engine-study-1/
Engine_Kinesis : CroneEngine {
// All norns engines follow the 'Engine_MySynthName' convention above

	var params;

	alloc { // allocate memory to the following:

		// add SynthDefs
		SynthDef("Kinesis", {
			arg out = 0,
			freq, sub_div, noise_level,
			cutoff, resonance,
			attack, release,
			amp, pan;

			var pulse = Pulse.ar(freq: freq);
			var saw = Saw.ar(freq: freq);
			var sub = Pulse.ar(freq: freq/sub_div);
			var noise = WhiteNoise.ar(mul: noise_level);
			var mix = Mix.ar([pulse,saw,sub,noise]);

			var envelope = Env.perc(attackTime: attack, releaseTime: release, level: amp).kr(doneAction: 2);
			var filter = MoogFF.ar(in: mix, freq: cutoff * envelope, gain: resonance);

			var signal = Pan2.ar(filter*envelope,pan);

			Out.ar(out,signal);

		}).add;

  // We don't need to sync with the server in this example,
  //   because were not actually doing anything that depends on the SynthDef being available,
  //   so let's leave this commented:
  // Server.default.sync;
		
  // let's create a Dictionary (an unordered associative collection)
  //   to store parameter values, initialized to defaults.
		params = Dictionary.newFrom([
			\sub_div, 2,
			\noise_level, 0.1,
			\cutoff, 8000,
			\resonance, 3,
			\attack, 0,
			\release, 0.4,
			\amp, 0.5,
			\pan, 0;
		]);

  // "Commands" are how the Lua interpreter controls the engine.
  // The format string is analogous to an OSC message format string,
  //   and the 'msg' argument contains data.

  // We'll just loop over the keys of the dictionary, 
  //   and add a command for each one, which updates corresponding value:
		params.keysDo({ arg key;
			this.addCommand(key, "f", { arg msg;
				params[key] = msg[1];
			});
		});

  // This is faster than (but similar to) individually defining each command, eg:
		// this.addCommand("amp", "f", { arg msg;
		//	  amp = msg[1];
		// });

  // The "hz" command, however, requires a new syntax!
  // ".getPairs" flattens the dictionary to alternating key,value array
  //   and "++" concatenates it:
		this.addCommand("hz", "f", { arg msg;
			Synth.new("Kinesis", [\freq, msg[1]] ++ params.getPairs)
		});

	}

}