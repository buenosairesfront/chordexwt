// Engine_ChordexWT.sc
// Chordex WT — mismo instrumento de acordes que Chordex2 / Chordex80 /
// ChordexFM (una tecla = un acorde de 4 tonos + bajo, arpegio, retener,
// crackle), pero con un motor WAVETABLE.
//
// Tablas: 8 bancos de 8 ondas (un ciclo cada una, 1024 puntos) armados
//   con suma de armónicos. La fórmula de cada onda es la misma que usa
//   el script de Lua para dibujarlas (ver WT.amps en chordexwt.lua).
//   0 CRISTAL: de seno a sierra, sumando armónicos
//   1 VOCAL:   formantes de vocales u-o-a-e-i
//   2 DIGITAL: pulso con ancho que se cierra (PPG)
//   3 ORGANO:  registros de órgano (drawbars)
//   4 SYNC:    sierra con hard sync (la esclava va de 1x a 5x)
//   5 METAL:   pocos armónicos altos y separados, como campana
//   6 BITS:    seno con menos bits y menos muestras (lo-fi)
//   7 RESO:    sierra con un pico resonante que sube por los armónicos
//   SYNC y BITS se definen como forma de onda y se pasan a armónicos
//   con una DFT de 256 puntos (amplitud + fase), igual que en Lua.
// Voz (\wt_voice / \wt_pluck / \wt_legato): VOsc recorre las 8 ondas del
//   banco. Posición = bus de control (E1, en vivo) + velocidad
//   + barrido (envolvente que arranca corrida y vuelve) + scan (LFO).
//   Después: filtro pasa bajos (RLPF) -> warp (wavefolder) -> drive.
//   fatness = gemelo desafinado a la derecha + chorus.
// FX (\wt_fx): crackle -> chorus estéreo -> shimmer -> hall -> compresor.

Engine_ChordexWT : CroneEngine {

  var voiceBus, posBus;
  var fxSynth, bufs;
  var noteGroup, releasingGroup, padSynth, legatoSynth, plucks;

  var atk = 0.01, rel = 0.9;
  var wobble = 0.2, drive = 0.1, fatness = 0.5, shimmer = 0.0;
  var bank = 0, barrido = 0.5, scan = 0, filtro = 0.75, warp = 0;

  alloc {
    var mk, amps, dft, vowels, bars, size = 1024, nh32 = 32;
    plucks = List.new;

    // ---- armado de las tablas (misma fórmula que en Lua) ----
    vowels = [[300, 800], [450, 850], [750, 1150], [700, 1450],
              [500, 1850], [300, 2300], [300, 1700], [320, 600]];
    bars = [
      [8, 0, 0, 0, 0, 0, 0], [8, 8, 0, 0, 0, 0, 0], [8, 6, 8, 0, 0, 0, 0],
      [8, 8, 8, 6, 0, 0, 0], [8, 4, 6, 8, 4, 0, 0], [8, 8, 8, 8, 6, 6, 0],
      [6, 8, 4, 8, 6, 8, 6], [8, 8, 8, 8, 8, 8, 8]
    ];
    // forma de onda (función de t en 0..1) -> [amplitudes, fases] de 32 armónicos
    dft = { |fn|
      var m = 256, xs = Array.fill(m, { |k| fn.(k / m) }), am, ph;
      am = Array.newClear(nh32); ph = Array.newClear(nh32);
      nh32.do({ |i| var h = i + 1, bs = 0, ac = 0;
        m.do({ |k| var th = 2pi * h * k / m;
          bs = bs + (xs[k] * sin(th)); ac = ac + (xs[k] * cos(th));
        });
        bs = bs * 2 / m; ac = ac * 2 / m;
        am[i] = hypot(bs, ac); ph[i] = atan2(ac, bs);
      });
      [am, ph]
    };
    // devuelve [amplitudes, fases]
    amps = { |b, f|
      var u = f / 7, a = Array.fill(nh32, 0), ph = Array.fill(nh32, 0), r, lv, st, p,
          nh, w, fr, harm = [1, 2, 3, 4, 6, 8, 10];
      switch (b,
        0, {
          nh = 1 + (u * u * 31);
          nh32.do({ |i| var h = i + 1; a[i] = (nh - h + 1).clip(0, 1) / h });
        },
        1, {
          fr = vowels[f];
          nh32.do({ |i| var h = i + 1, hz = h * 130;
            a[i] = exp((((hz - fr[0]) / 110) ** 2).neg)
              + (0.7 * exp((((hz - fr[1]) / 150) ** 2).neg)) + (0.12 / h);
          });
        },
        2, {
          w = 0.5 - (u * 0.44);
          nh32.do({ |i| var h = i + 1; a[i] = sin(pi * h * w) / h });
          ph = Array.fill(nh32, pi / 2);
        },
        3, {
          harm.do({ |h, j| var v = bars[f][j];
            if (v > 0) { a[h - 1] = 10 ** ((v - 8) * 3 / 20) };
          });
        },
        4, {
          r = 1 + (u * 4);
          # a, ph = dft.({ |t| ((r * t).frac * 2) - 1 });
        },
        5, {
          p = 2 + f;
          a[0] = 1; a[1] = 0.3;
          [[p, 0.8], [(2 * p) + 1, 0.6], [(3 * p) + 3, 0.45], [(5 * p) - 1, 0.35]].do({ |e|
            if (e[0] <= nh32) { a[e[0] - 1] = a[e[0] - 1] + e[1] };
          });
        },
        6, {
          lv = [16, 8, 5, 4, 3, 2, 1.5, 1][f];
          st = [64, 32, 16, 12, 10, 8, 6, 4][f];
          # a, ph = dft.({ |t| (sin(2pi * (t * st).floor / st) * lv + 0.5).floor / lv });
        },
        7, {
          r = 2 + (u * 22);
          nh32.do({ |i| var h = i + 1;
            a[i] = (0.25 + (2.5 * exp((((h - r) / 1.3) ** 2).neg)) ) / h;
          });
        }
      );
      [a, ph]
    };

    bufs = Buffer.allocConsecutive(64, context.server, size * 2, 1);
    context.server.sync;
    8.do({ |b|
      8.do({ |f|
        var ap = amps.(b, f);
        var sig = Signal.sineFill(size, ap[0], ap[1]);
        bufs[(b * 8) + f].sendCollection(sig.asWavetable);
      });
    });

    voiceBus = Bus.audio(context.server, 2);
    posBus = Bus.control(context.server, 1);
    posBus.set(0.35);

    // mode 0 = acorde (gate), 1 = pluck del arpegio (dur), 2 = legato
    mk = { |name, mode|
      SynthDef(name, {
        arg out = 0, freq = 440, gate = 1, vel = 0.8, amp = 0.2, pan = 0, dur = 0.3,
            atk = 0.01, rel = 0.9, wobble = 0.2, drive = 0.1, fat = 0.5,
            base = 0, barrido = 0.5, scan = 0, filtro = 0.75, warp = 0, posBus = 0;
        var g, relE, env, fv, vdel, vib, drift, f, swe, pos, bp, det,
            sl, sr, sig, fc, fenv, dg, sat, master, swt;

        if (mode == 1) {
          g = Trig1.kr(1, dur * 0.45);
          relE = (dur * 0.9) + 0.04;
          env = EnvGen.kr(Env([0, 1, 0.6, 0], [atk.min(dur * 0.3) + 0.002, dur * 0.45, relE], [-2, -4, -4], 2), g);
          swt = (dur * 3 + 0.2).min(2.2);
        } {
          g = gate;
          relE = rel;
          env = EnvGen.kr(Env.adsr(atk + 0.002, 1.5, 0.7, relE), g);
          swt = 2.2;
        };

        fv = if (mode == 2) { Lag.kr(freq, 0.035) } { freq };
        vdel = EnvGen.kr(Env([0, 0, 1], [0.3, 0.9]));
        vib = SinOsc.kr(5.2 + LFNoise1.kr(0.4).range(-0.2, 0.2)) * wobble * 0.006 * vdel;
        drift = LFNoise2.kr(0.3).range(-0.0015, 0.0015);
        f = fv * (1 + vib + drift);

        // posición en la tabla (0..1): E1 + velocidad + barrido + scan
        swe = EnvGen.kr(Env([1, 0.0001], [swt], \exp));
        pos = In.kr(posBus, 1) + ((vel - 0.6) * 0.15) + (barrido * swe)
          + (SinOsc.kr(0.1 + (scan * 3)) * scan * 0.35);
        bp = base + (pos.clip(0, 1) * 6.999);

        det = 1 + (fat * 0.0045);
        sl = VOsc.ar(bp, f);
        sr = VOsc.ar(bp, f * det);
        sig = [sl, (sl * (1 - fat)) + (sr * fat)];

        // filtro: cutoff del fader, sigue un poco a la nota, envolvente corta
        fenv = EnvGen.kr(Env([1, 0], [0.35], -4)) * vel;
        fc = (180 * (2 ** (filtro * 6.8)) * ((fv / 261.6) ** 0.5) * (1 + (fenv * 1.5))).clip(30, 18000);
        sig = RLPF.ar(sig, fc, 0.7);

        // warp: wavefolder
        sig = (sig * (1 + (warp * 4))).fold2(1);

        dg = 1 + (drive.pow(1.4) * 9);
        sat = (sig * dg).tanh;
        sig = (sig * (1 - drive.min(1))) + (sat * drive.min(1) / (1 + (drive * 0.8)));
        sig = HPF.ar(sig, 40);

        if (mode == 1) {
          master = EnvGen.kr(Env([1, 1, 0], [(dur * 0.45) + relE, 0.05]), doneAction: 2)
            * EnvGen.kr(Env.asr(0, 1, 0.06), gate, doneAction: 2);
        } {
          master = EnvGen.kr(Env.asr(0, 1, relE + 0.08), gate, doneAction: 2);
        };
        sig = sig * env * master * amp * (0.45 + (Lag.kr(vel, 0.03) * 0.55));
        Out.ar(out, Balance2.ar(sig[0], sig[1], if (mode == 2) { Lag.kr(pan, 0.05) } { pan }));
      }).add;
    };
    mk.(\wt_voice, 0);
    mk.(\wt_pluck, 1);
    mk.(\wt_legato, 2);

    // --- bajo: la primera onda del banco, filtrada ---
    SynthDef(\wt_bass, {
      arg out = 0, freq = 55, gate = 1, atk = 0.01, rel = 0.6,
          drive = 0.1, amp = 0.3, base = 0, posBus = 0;
      var env, sig;
      env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction: 2);
      sig = VOsc.ar(base + (In.kr(posBus, 1).clip(0, 1) * 2.5), freq);
      sig = LPF.ar(sig, 500);
      sig = (sig * (1 + (drive * 3))).tanh / (1 + (drive * 0.6));
      Out.ar(out, Pan2.ar(sig * env * amp, 0));
    }).add;

    SynthDef(\wt_fx, {
      arg in, out, fat = 0.5, shimmer = 0, crackle = 0, space = 0.22, gain = 1.0;
      var dry, sig, lfo1, lfo2, cmix, wet, sh, verb, cn, cg, comp;

      dry = In.ar(in, 2);
      sig = dry;

      cn = HPF.ar(Crackle.ar(1.85, mul: [1, 1]), 1600);
      cg = Amplitude.kr(Mix(dry), 0.01, 0.08) > 0.02;
      sig = sig + (cn * crackle * 0.3 * cg);

      lfo1 = LFTri.kr(0.47);
      lfo2 = LFTri.kr(0.79);
      cmix = LPF.ar(Mix(sig) * 0.5, 9000);
      wet = [DelayC.ar(cmix, 0.02, 0.004 + (lfo1 * 0.0016) + (lfo2 * 0.0007)),
             DelayC.ar(cmix, 0.02, 0.004 - (lfo1 * 0.0016) - (lfo2 * 0.0007))];
      sig = (sig * (1 - (fat * 0.25))) + (LPF.ar(wet, 8000) * fat * 0.55);

      sh = PitchShift.ar(sig, 0.15, 2.0, 0.008, 0.01);
      sh = FreeVerb2.ar(sh[0], sh[1], 1, 0.9, 0.3);
      sig = sig + (sh * shimmer * 0.8);

      verb = HPF.ar(sig, 200) * (space + (shimmer * 0.35));
      verb = DelayN.ar(verb, 0.05, 0.03);
      verb = FreeVerb2.ar(verb[0], verb[1], 1, 0.93 + (shimmer * 0.05), 0.4);
      sig = sig + (verb * 0.9);

      comp = Compander.ar(sig, Mix(sig) * 0.5, 0.25, 1, 0.5, 0.008, 0.18);
      sig = comp * 1.5 * gain;
      // lookahead corto: el Limiter atrasa la señal 2 x dur (antes 20 ms)
      sig = Limiter.ar(LeakDC.ar(sig), 0.92, 0.002);
      Out.ar(out, sig);
    }).add;

    context.server.sync;

    fxSynth = Synth.tail(context.xg, \wt_fx, [
      \in, voiceBus, \out, context.out_b, \fat, fatness, \shimmer, shimmer
    ]);

    this.addCommand("noteOn", "ffffff", { |msg|
      var freqs = [msg[1], msg[2], msg[3], msg[4]];
      var subf = msg[5], vel = msg[6], nv;

      if (releasingGroup.notNil) { releasingGroup.free };
      if (noteGroup.notNil) {
        noteGroup.set(\gate, 0);
        releasingGroup = noteGroup;
      };
      noteGroup = Group.head(context.xg);

      // freq 0 = voz apagada (modo acorde off: una sola nota, al centro)
      nv = freqs.count({ |f| f > 0 }).max(1);
      freqs.do({ |f, i|
        if (f > 0) {
          Synth.new(\wt_voice, this.voiceArgs ++ [
            \freq, f, \vel, vel, \amp, 0.2 * this.bankAmp * ((4 / nv) ** 0.5),
            \pan, if (nv == 1) { 0 } { ((i - 1.5) * 0.3 * (0.5 + fatness)).clip(-0.9, 0.9) }
          ], noteGroup);
        };
      });
      Synth.new(\wt_bass, this.bassArgs(subf, 0.22), noteGroup);
    });

    this.addCommand("noteOff", "", { |msg|
      var g;
      if (releasingGroup.notNil) { releasingGroup.free; releasingGroup = nil };
      if (noteGroup.notNil) {
        g = noteGroup;
        g.set(\gate, 0);
        releasingGroup = g;
        noteGroup = nil;
        SystemClock.sched(rel + 0.6, {
          if (releasingGroup === g) { g.free; releasingGroup = nil };
          nil
        });
      };
    });

    this.addCommand("padOn", "f", { |msg|
      if (padSynth.notNil) {
        padSynth.set(\freq, this.bassFreq(msg[1]));
      } {
        padSynth = Synth.new(\wt_bass, this.bassArgs(msg[1], 0.3), context.xg);
      };
    });

    this.addCommand("padOff", "", { |msg|
      if (padSynth.notNil) { padSynth.set(\gate, 0); padSynth = nil };
    });

    // freq, dur, vel, pan
    this.addCommand("arpStep", "ffff", { |msg|
      var p;
      while { plucks.size >= 8 } { plucks.removeAt(0).set(\gate, 0) };
      p = Synth.new(\wt_pluck, this.voiceArgs ++ [
        \freq, msg[1], \dur, msg[2], \vel, msg[3], \pan, msg[4], \amp, 0.3 * this.bankAmp
      ], context.xg);
      plucks.add(p);
      p.onFree { plucks.remove(p) };
    });

    // freq, vel, pan: la primera vez crea la voz, después solo la mueve
    this.addCommand("arpLegato", "fff", { |msg|
      if (legatoSynth.notNil) {
        legatoSynth.set(\freq, msg[1], \vel, msg[2], \pan, msg[3]);
      } {
        legatoSynth = Synth.new(\wt_legato, this.voiceArgs ++ [
          \freq, msg[1], \vel, msg[2], \pan, msg[3], \amp, 0.42 * this.bankAmp
        ], context.xg);
      };
    });
    this.addCommand("arpLegatoOff", "", { |msg|
      if (legatoSynth.notNil) { legatoSynth.set(\gate, 0); legatoSynth = nil };
    });

    this.addCommand("atk", "f", { |msg| atk = msg[1] });
    this.addCommand("rel", "f", { |msg|
      rel = msg[1];
      this.setLive([\rel, rel]);
    });
    this.addCommand("drive", "f", { |msg|
      drive = msg[1];
      this.setLive([\drive, drive]);
    });
    this.addCommand("wobble", "f", { |msg|
      wobble = msg[1];
      this.setLive([\wobble, wobble]);
    });
    this.addCommand("fatness", "f", { |msg|
      fatness = msg[1];
      fxSynth.set(\fat, fatness);
      this.setLive([\fat, fatness]);
    });
    this.addCommand("shimmer", "f", { |msg|
      shimmer = msg[1];
      fxSynth.set(\shimmer, shimmer);
    });
    this.addCommand("space", "f", { |msg| fxSynth.set(\space, msg[1]) });
    this.addCommand("gain", "f", { |msg| fxSynth.set(\gain, msg[1]) });
    this.addCommand("crackle", "f", { |msg| fxSynth.set(\crackle, msg[1]) });
    this.addCommand("pos", "f", { |msg| posBus.set(msg[1]) });

    // todo se oye en vivo en las notas que ya suenan
    this.addCommand("bank", "i", { |msg|
      bank = msg[1].clip(0, 7);
      this.setLive([\base, this.baseBuf]);
      if (padSynth.notNil) { padSynth.set(\base, this.baseBuf) };
    });
    this.addCommand("barrido", "f", { |msg|
      barrido = msg[1];
      this.setLive([\barrido, barrido]);
    });
    this.addCommand("scan", "f", { |msg|
      scan = msg[1];
      this.setLive([\scan, scan]);
    });
    this.addCommand("filtro", "f", { |msg|
      filtro = msg[1];
      this.setLive([\filtro, filtro]);
    });
    this.addCommand("warp", "f", { |msg|
      warp = msg[1];
      this.setLive([\warp, warp]);
    });
  }

  baseBuf { ^bufs[0].bufnum + (bank * 8) }

  // nivel por banco (los pulsos suenan más fuerte que el seno)
  bankAmp { ^[1.0, 1.45, 0.57, 1.23, 1.3, 1.1, 0.85, 1.3][bank] }

  voiceArgs {
    ^[\out, voiceBus, \posBus, posBus.index, \base, this.baseBuf,
      \atk, atk, \rel, rel, \wobble, wobble, \drive, drive, \fat, fatness,
      \barrido, barrido, \scan, scan, \filtro, filtro, \warp, warp]
  }

  bassArgs { |f, amp|
    ^[\out, voiceBus, \freq, this.bassFreq(f), \atk, atk, \rel, rel,
      \drive, drive, \base, this.baseBuf, \posBus, posBus.index, \amp, amp]
  }

  setLive { |args|
    if (noteGroup.notNil) { noteGroup.set(*args) };
    if (legatoSynth.notNil) { legatoSynth.set(*args) };
  }

  bassFreq { |f| ^if (f < 40) { f * 2 } { f } }

  free {
    if (noteGroup.notNil) { noteGroup.free };
    if (releasingGroup.notNil) { releasingGroup.free };
    if (padSynth.notNil) { padSynth.free };
    if (legatoSynth.notNil) { legatoSynth.free };
    fxSynth.free;
    voiceBus.free;
    posBus.free;
    bufs.do(_.free);
  }
}
