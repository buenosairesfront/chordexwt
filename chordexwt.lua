-- Chordex WT
-- hermano wavetable de Chordex80 / ChordexFM: mismo instrumento de acordes
-- (una tecla = un acorde de 4 tonos + bajo, suena la nota más grave
-- apretada, arpegio, retener, crackle con más de 2 teclas) con un motor
-- wavetable: 8 bancos de 8 ondas que la voz recorre en vivo.
--
-- La pantalla ES la tabla, calculada con la misma fórmula que suena:
--   centro: la tabla de ondas en 3D, de adelante (posición 0) hacia
--     atrás (posición 1). La onda brillante es la que está sonando: se
--     mueve por la tabla con E1, el barrido y el scan, y ya pasó por el
--     filtro, el warp y el drive. Fantasma = fatness, chispas = shimmer /
--     crackle, cada nota del arpegio corre por la onda como un cometa.
--     Al costado, el riel de posición (tick = E1, punto = donde está).
--   izquierda: el acorde en la rueda de 12 notas, la envolvente y los
--     9 faders.
--   derecha: osciloscopio (un ciclo), espectro con la curva del filtro
--     encima, abajo el patrón del arpegio.
--
-- Controles (los mismos de Chordex80 / ChordexFM):
--   E1: posición en la tabla     K3 + E1: banco CRISTAL/VOCAL/DIGITAL/ORGANO/
--                                         SYNC/METAL/BITS/RESO
--   E2: elige fader              K3 + E2: warp (wavefolder)
--   E3: ajusta fader             K3 + E3: tipo de acorde
--   faders: ataque, decay, barrido (la nota arranca corrida en la tabla
--           y vuelve), scan (LFO de posición), filtro, distorsión,
--           wobble, fatness, shimmer
--   K2: tap = arpegiador on/off
--   K2 + E1: gate del arpegio (al máximo = legato real)
--   K2 + E2: patrón              K2 + E3: velocidad
--   K3 mantenido (sin girar nada): modo acorde on/off (off = una sola nota)
--   K1 mantenido: retener on/off (puntito arriba a la derecha)
--   clock MIDI entrante: solo marca el tempo del arpegio

engine.name = 'ChordexWT'

local musicutil = require 'musicutil'

local midi_in
local current_note = nil
local current_vel = 0.8
local last_note = nil
local held_stack = {}
-- teclas que arpegia el modo simple (quedan con HOLD hasta la próxima tecla)
local arp_keys = {}
local function update_arp_keys()
  if #held_stack == 0 then return end
  arp_keys = {}
  for i, n in ipairs(held_stack) do arp_keys[i] = n end
  table.sort(arp_keys)
end
-- modo simple: qué teclas están sonando, para no redisparar si no cambió nada
local voiced_sig = nil
local function keys_sig() return table.concat(arp_keys, ",") end
local last_midi_clock = nil
local CLOCK_TIMEOUT = 0.5
local tick_sec = nil
local ext_ticks = 0
local hold_on = false
local loading = false

local chord_types = {"maj", "min", "dim", "aug", "7", "maj7", "min7", "m7b5", "sus2", "sus4"}
local chord_suffix = {maj = "", min = "m", dim = "dim", aug = "+", ["7"] = "7",
  maj7 = "maj7", min7 = "m7", m7b5 = "m7b5", sus2 = "sus2", sus4 = "sus4"}
local chord_intervals = {
  maj = {0, 4, 7}, min = {0, 3, 7}, dim = {0, 3, 6}, aug = {0, 4, 8},
  ["7"] = {0, 4, 7, 10}, maj7 = {0, 4, 7, 11}, min7 = {0, 3, 7, 10},
  m7b5 = {0, 3, 6, 10}, sus2 = {0, 2, 7}, sus4 = {0, 5, 7},
}
local note_names = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local arp_pattern_names = {"up", "down", "up-down", "up x2", "down x2", "random", "arpa"}
local arp_rate_mult = {4, 2, 1, 0.5}
local arp_rate_names = {"x1/4", "x1/2", "x1", "x2"}

-- ============================================================
-- tablas de ondas (la misma fórmula que el engine)
-- ============================================================

local WT = {}
do
  WT.H = 32            -- armónicos por onda
  WT.F = 8             -- ondas por banco
  WT.banks = {
    {name = "CRISTAL", pos = 0.35, barrido = 0.45, scan = 0,    filtro = 0.75, warp = 0},
    {name = "VOCAL",   pos = 0.3,  barrido = 0,    scan = 0.3,  filtro = 0.8,  warp = 0},
    {name = "DIGITAL", pos = 0.15, barrido = 0.6,  scan = 0.08, filtro = 0.7,  warp = 0.1},
    {name = "ORGANO",  pos = 0.5,  barrido = 0,    scan = 0.15, filtro = 0.85, warp = 0},
    {name = "SYNC",    pos = 0.2,  barrido = 0.7,  scan = 0,    filtro = 0.8,  warp = 0},
    {name = "METAL",   pos = 0.4,  barrido = -0.3, scan = 0.1,  filtro = 0.85, warp = 0},
    {name = "BITS",    pos = 0.3,  barrido = 0,    scan = 0.2,  filtro = 0.9,  warp = 0},
    {name = "RESO",    pos = 0.25, barrido = 0.8,  scan = 0,    filtro = 0.8,  warp = 0},
  }
  WT.names = {}
  for i, b in ipairs(WT.banks) do WT.names[i] = b.name end

  local vowels = {{300, 800}, {450, 850}, {750, 1150}, {700, 1450},
                  {500, 1850}, {300, 2300}, {300, 1700}, {320, 600}}
  local bars = {
    {8, 0, 0, 0, 0, 0, 0}, {8, 8, 0, 0, 0, 0, 0}, {8, 6, 8, 0, 0, 0, 0},
    {8, 8, 8, 6, 0, 0, 0}, {8, 4, 6, 8, 4, 0, 0}, {8, 8, 8, 8, 6, 6, 0},
    {6, 8, 4, 8, 6, 8, 6}, {8, 8, 8, 8, 8, 8, 8},
  }
  local harm = {1, 2, 3, 4, 6, 8, 10}

  -- forma de onda fn(t), t en 0..1 -> amplitudes y fases (DFT de 256 puntos)
  local function dft(fn)
    local m, xs, a, ph = 256, {}, {}, {}
    for k = 0, m - 1 do xs[k] = fn(k / m) end
    for h = 1, WT.H do
      local bs, ac = 0, 0
      for k = 0, m - 1 do
        local th = 2 * math.pi * h * k / m
        bs = bs + xs[k] * math.sin(th); ac = ac + xs[k] * math.cos(th)
      end
      bs, ac = bs * 2 / m, ac * 2 / m
      a[h] = math.sqrt(bs * bs + ac * ac)
      ph[h] = math.atan(ac, bs)
    end
    return a, ph
  end

  -- amplitudes y fases de los armónicos de la onda f (0..7) del banco b (1..8)
  local function amps(b, f)
    local u, H, a, ph = f / 7, WT.H, {}, {}
    for h = 1, H do a[h] = 0; ph[h] = (b == 3) and math.pi / 2 or 0 end
    if b == 1 then
      local nh = 1 + u * u * 31
      for h = 1, H do a[h] = util.clamp(nh - h + 1, 0, 1) / h end
    elseif b == 2 then
      local fr = vowels[f + 1]
      for h = 1, H do
        local hz = h * 130
        a[h] = math.exp(-((hz - fr[1]) / 110) ^ 2) + 0.7 * math.exp(-((hz - fr[2]) / 150) ^ 2) + 0.12 / h
      end
    elseif b == 3 then
      local w = 0.5 - u * 0.44
      for h = 1, H do a[h] = math.sin(math.pi * h * w) / h end
    elseif b == 4 then
      for j, h in ipairs(harm) do
        local v = bars[f + 1][j]
        if v > 0 then a[h] = 10 ^ ((v - 8) * 3 / 20) end
      end
    elseif b == 5 then
      -- SYNC: sierra esclava a r veces la frecuencia, reseteada cada ciclo
      local r = 1 + u * 4
      a, ph = dft(function(t) local x = r * t; return (x - math.floor(x)) * 2 - 1 end)
    elseif b == 6 then
      -- METAL: fundamental + 4 parciales altos y separados
      local p = 2 + f
      a[1], a[2] = 1, 0.3
      for _, e in ipairs({{p, 0.8}, {2 * p + 1, 0.6}, {3 * p + 3, 0.45}, {5 * p - 1, 0.35}}) do
        if e[1] <= H then a[e[1]] = a[e[1]] + e[2] end
      end
    elseif b == 7 then
      -- BITS: seno con menos niveles y menos muestras por ciclo
      local lv = ({16, 8, 5, 4, 3, 2, 1.5, 1})[f + 1]
      local st = ({64, 32, 16, 12, 10, 8, 6, 4})[f + 1]
      a, ph = dft(function(t)
        return math.floor(math.sin(2 * math.pi * math.floor(t * st) / st) * lv + 0.5) / lv
      end)
    else
      -- RESO: sierra con un pico resonante que sube
      local r = 2 + u * 22
      for h = 1, H do a[h] = (0.25 + 2.5 * math.exp(-((h - r) / 1.3) ^ 2)) / h end
    end
    return a, ph
  end

  -- tabla de senos para sintetizar ciclos de N puntos
  WT.N = 64             -- puntos por ciclo (alcanza para 46 px y es la mitad de cálculo)
  WT.S, WT.C = {}, {}
  for k = 0, WT.N - 1 do
    WT.S[k] = math.sin(2 * math.pi * k / WT.N)
    WT.C[k] = math.cos(2 * math.pi * k / WT.N)
  end

  -- y[k] = sum a[h] sin(h th + ph[h])  (k = 1..N)
  function WT.synth(a, ph, y, thr)
    local N, S, C = WT.N, WT.S, WT.C
    for k = 1, N do y[k] = 0 end
    for h = 1, WT.H do
      local ah = a[h]
      if ah > (thr or 0) or ah < -(thr or 0) then
        local p = ph[h] or 0
        local cp, sp = math.cos(p) * ah, math.sin(p) * ah
        local idx = 0
        for k = 1, N do
          y[k] = y[k] + S[idx] * cp + C[idx] * sp
          idx = (idx + h) % N
        end
      end
    end
    return y
  end

  -- normalizadas como Signal.sineFill (pico = 1)
  -- se guardan como parte real / imaginaria para poder cruzar ondas
  -- con fases distintas (VOsc mezcla las muestras, o sea los complejos)
  WT.RE, WT.IM = {}, {}   -- WT.RE[b][f+1][h]
  local y = {}
  for b = 1, #WT.banks do
    WT.RE[b], WT.IM[b] = {}, {}
    for f = 0, WT.F - 1 do
      local a, ph = amps(b, f)
      WT.synth(a, ph, y)
      local pk = 0
      for k = 1, WT.N do pk = math.max(pk, math.abs(y[k])) end
      pk = math.max(pk, 1e-6)
      local re, im = {}, {}
      for h = 1, WT.H do
        re[h] = a[h] / pk * math.cos(ph[h]); im[h] = a[h] / pk * math.sin(ph[h])
      end
      WT.RE[b][f + 1], WT.IM[b][f + 1] = re, im
    end
  end

  -- amplitudes y fases en una posición continua 0..1 (VOsc cruza ondas vecinas)
  function WT.at(b, pos, out, oph)
    local bp = util.clamp(pos, 0, 1) * 6.999
    local i0 = math.floor(bp)
    local fr = bp - i0
    local R0, R1 = WT.RE[b][i0 + 1], WT.RE[b][i0 + 2]
    local I0, I1 = WT.IM[b][i0 + 1], WT.IM[b][i0 + 2]
    for h = 1, WT.H do
      local re = R0[h] * (1 - fr) + R1[h] * fr
      local im = I0[h] * (1 - fr) + I1[h] * fr
      out[h] = math.sqrt(re * re + im * im)
      oph[h] = math.atan(im, re)
    end
    return out, oph
  end

  -- filas de la vista 3D (sin filtro), cacheadas por banco
  WT.ROWS, WT.RW = 12, 47
  WT.rows = {}
  function WT.rows_for(b)
    if WT.rows[b] then return WT.rows[b] end
    local rows, a, yy, ph = {}, {}, {}, {}
    for r = 0, WT.ROWS - 1 do
      WT.at(b, r / (WT.ROWS - 1), a, ph)
      WT.synth(a, ph, yy)
      local row = {}
      for q = 0, WT.RW - 1 do
        row[q + 1] = yy[math.floor(q / (WT.RW - 1) * (WT.N - 1)) + 1]
      end
      rows[r + 1] = row
    end
    WT.rows[b] = rows
    return rows
  end
end

-- faders (E2 elige, E3 ajusta)
local P = {
  {id = "atk",     min = 0.001, max = 2,   step = 0.01},
  {id = "rel",     min = 0.02,  max = 4,   step = 0.03},
  {id = "barrido", min = -1,    max = 1,   step = 0.04},
  {id = "scan",    min = 0,     max = 1,   step = 0.02},
  {id = "filtro",  min = 0,     max = 1,   step = 0.02},
  {id = "drive",   min = 0,     max = 1,   step = 0.02},
  {id = "wobble",  min = 0,     max = 1,   step = 0.02},
  {id = "fatness", min = 0,     max = 1,   step = 0.02},
  {id = "shimmer", min = 0,     max = 1,   step = 0.02},
}
local focus_index = 1

local arp_on = false
local arp_clock_id = nil
local arp_step_lit = 0
local k2_held, k2_turned, k3_held = false, false, false
local k3_turned = false
local k3_press = nil
local K3_LONG = 0.5   -- segundos manteniendo K3 para alternar el modo acorde

-- animación
local PULSE = 24
local pulse = {}          -- pulso por nombre de control
local flash = 0
local chord_flash = 0
local model_flash = 0
local hold_flash = 0
local last_t = nil

-- voces "simuladas" para que la pantalla respire igual que el sonido
local VS = {chord = nil, arp = nil}


local function pv(id) return params:get(id) end
local function note_to_hz(n) return musicutil.note_num_to_freq(n) end
local function bump(name) pulse[name] = PULSE end

local function four_tone_intervals(name)
  -- modo acorde apagado: suena solo la nota tocada
  if params:get("chord_on") == 1 then return {0} end
  local iv = chord_intervals[name]
  if #iv >= 4 then return iv end
  return {iv[1], iv[2], iv[3], iv[1] + 12}
end

local function chord_name() return chord_types[pv("chord")] end

local function chord_tone_hz(note)
  local f = {}
  for _, iv in ipairs(four_tone_intervals(chord_name())) do
    f[#f + 1] = note_to_hz(note + iv)
  end
  for i = #f + 1, 4 do f[i] = 0 end   -- 0 = esa voz no suena
  return f
end

local comets = {}
local riders = {}    -- notas del arpegio corriendo por la onda
local function spawn_comet(note, lv)
  if #comets > 20 then table.remove(comets, 1) end
  comets[#comets + 1] = {pc = note % 12, oct = note, r = 0, lv = lv}
  if #riders > 6 then table.remove(riders, 1) end
  riders[#riders + 1] = {u = 0, lv = lv}
end

-- ============================================================
-- sonido
-- ============================================================

local function sound_chord(note)
  local f = chord_tone_hz(note)
  -- modo simple con varias teclas: suenan todas juntas (hasta 4, las más agudas)
  if pv("chord_on") == 1 and #arp_keys > 1 then
    f = {}
    for i = math.max(1, #arp_keys - 3), #arp_keys do f[#f + 1] = note_to_hz(arp_keys[i]) end
    for i = #f + 1, 4 do f[i] = 0 end
  end
  voiced_sig = keys_sig()
  engine.noteOn(f[1], f[2], f[3], f[4], note_to_hz(note - 24), current_vel)
  VS.chord = {t0 = util.time(), note = note, vel = current_vel}
  flash = 1
end

local function release_chord_vs()
  if VS.chord and not VS.chord.t1 then VS.chord.t1 = util.time() end
end

local function step_order(pat, n)
  local t = {}
  if pat == 1 or pat == 7 then for i = 1, n do t[#t + 1] = i end
  elseif pat == 2 then for i = n, 1, -1 do t[#t + 1] = i end
  elseif pat == 3 then
    for i = 1, n do t[#t + 1] = i end
    for i = n - 1, 2, -1 do t[#t + 1] = i end
  elseif pat == 4 then for i = 1, n do t[#t + 1] = i; t[#t + 1] = i end
  elseif pat == 5 then for i = n, 1, -1 do t[#t + 1] = i; t[#t + 1] = i end
  end
  return t
end

-- notas del arpegio (en número MIDI); "arpa" recorre dos octavas
local function arp_notes()
  local t = {}
  for _, iv in ipairs(four_tone_intervals(chord_name())) do t[#t + 1] = current_note + iv end
  if pv("chord_on") == 1 and #arp_keys > 0 then
    t = {}
    for i, n in ipairs(arp_keys) do t[i] = n end
  end
  if pv("arp_pattern") == 7 then
    local n = #t
    for i = 1, n do t[#t + 1] = t[i] + 12 end
  end
  return t
end

local function ext_clock_on()
  return last_midi_clock ~= nil and (util.time() - last_midi_clock) < CLOCK_TIMEOUT
end

local function ticks_per_step()
  local div = ({1, 2, 4, 8})[params:get("midi_clock_div")]
  return math.max(1, 24 * (1 / 16) * div * arp_rate_mult[pv("arp_rate")])
end

local function step_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * ticks_per_step() end
  return clock.get_beat_sec() * (1 / 16) * arp_rate_mult[pv("arp_rate")]
end

local function beat_seconds()
  if ext_clock_on() and tick_sec then return tick_sec * 24 end
  return clock.get_beat_sec()
end

local function arp_note_dur(step_sec)
  local g = params:get("arp_gate")
  return util.clamp(step_sec * 0.25 * (32 ^ g), 0.03, 4)
end

local step_i = 1
local function arp_step()
  if current_note == nil then return end
  local notes = arp_notes()
  local pat = pv("arp_pattern")
  local idx, pos
  if pat == 6 then
    idx = math.random(1, #notes); pos = 1
  else
    local order = step_order(pat, #notes)
    pos = ((step_i - 1) % #order) + 1
    idx = order[pos]
  end
  step_i = step_i + 1
  local step_sec = step_seconds()
  local n = notes[idx]
  local vel = (pos == 1 and 1 or 0.72) * (0.55 + current_vel * 0.45)
  local pan = ((idx - 1) % 4 - 1.5) * 0.22
  local dur = arp_note_dur(step_sec)
  if params:get("arp_gate") >= 0.995 then
    engine.arpLegato(note_to_hz(n), vel, pan)
    if not (VS.arp and VS.arp.legato and not VS.arp.t1) then
      VS.arp = {t0 = util.time(), note = n, vel = vel, legato = true}
    else
      VS.arp.note = n; VS.arp.vel = vel
    end
  else
    engine.arpLegatoOff()
    engine.arpStep(note_to_hz(n), dur, vel, pan)
    VS.arp = {t0 = util.time(), note = n, vel = vel, pluck = true, dur = dur}
  end
  arp_step_lit = idx
  spawn_comet(n, 6 + vel * 9)
  flash = math.max(flash, 0.35 * vel)
end

local function arp_legato_off()
  engine.arpLegatoOff()
  if VS.arp and VS.arp.legato and not VS.arp.t1 then VS.arp.t1 = util.time() end
end

-- el loop termina solo (generación) en vez de clock.cancel: cancelar un
-- coroutine que ya estaba por despertarse tira "resume (thread expected)"
local arp_gen = 0
local function arp_loop(gen)
  while arp_on and current_note and gen == arp_gen do
    if ext_clock_on() then
      clock.sleep(0.05)
    else
      local quantum = (1 / 16) * arp_rate_mult[pv("arp_rate")]
      if params:get("clock_source") == 1 then clock.sync(quantum)
      else clock.sleep(clock.get_beat_sec() * quantum) end
      if arp_on and current_note and gen == arp_gen and not ext_clock_on() then arp_step() end
    end
  end
  if gen == arp_gen then
    arp_step_lit = 0
    arp_legato_off()
    arp_clock_id = nil
  end
end

local function start_arp_if_needed()
  if arp_clock_id == nil and current_note then
    engine.padOn(note_to_hz(current_note - 24))
    step_i = 1
    ext_ticks = 0
    arp_step()
    arp_gen = arp_gen + 1
    arp_clock_id = clock.run(arp_loop, arp_gen)
  end
end

local function stop_arp()
  if arp_clock_id ~= nil then
    arp_gen = arp_gen + 1
    arp_clock_id = nil
  end
  arp_step_lit = 0
  engine.padOff()
  arp_legato_off()
end

local function lowest_held()
  local m = nil
  for _, n in ipairs(held_stack) do
    if m == nil or n < m then m = n end
  end
  return m
end

local crackle_amt = 0
local function update_crackle()
  crackle_amt = util.clamp((#held_stack - 2) * 0.35, 0, 1)
  engine.crackle(crackle_amt)
end

-- con clock MIDI, algunos equipos repiten la nota apretada a tempo: el
-- soltar espera un poco y si vuelve la misma nota no se redispara
local release_id = nil

local function cancel_release()
  if release_id then clock.cancel(release_id); release_id = nil end
end

local function release_now()
  release_id = nil
  if #held_stack == 0 and not hold_on and current_note ~= nil then
    if arp_on then stop_arp() else engine.noteOff(); release_chord_vs() end
    current_note = nil
  end
end

local function release_grace()
  return util.clamp((tick_sec or 0.02) * 13, 0.05, 0.8)
end

local function on_note_on(note, vel)
  cancel_release()
  local prev = current_note
  local fresh = hold_on and #held_stack == 0 and prev ~= nil
  local added = hold_on and #held_stack > 0
  table.insert(held_stack, note)
  if added then
    -- con HOLD, una tecla más mientras hay otras apretadas se suma a lo
    -- retenido (aunque alguna ya se haya soltado)
    local dup = false
    for _, n in ipairs(arp_keys) do if n == note then dup = true end end
    if not dup then table.insert(arp_keys, note); table.sort(arp_keys) end
  else
    update_arp_keys()
  end
  -- modo acorde: manda la última tecla apretada (también si es más aguda);
  -- modo simple: suenan todas las apretadas y la más grave da el bajo
  local simple = pv("chord_on") == 1
  local low = simple and arp_keys[1] or note
  if low ~= prev or fresh or (simple and not arp_on and keys_sig() ~= voiced_sig) then
    current_note = low
    last_note = low
    current_vel = vel / 127
    if arp_on then
      if arp_clock_id == nil then start_arp_if_needed()
      else engine.padOn(note_to_hz(current_note - 24)) end
    else
      sound_chord(current_note)
    end
  end
  update_crackle()
end

local function on_note_off(note)
  for i = #held_stack, 1, -1 do
    if held_stack[i] == note then table.remove(held_stack, i); break end
  end
  -- con HOLD, soltar teclas no cambia nada: queda el acorde / las notas
  -- del arpegio tal como se apretaron
  if hold_on then update_crackle(); return end
  update_arp_keys()
  -- modo acorde: al soltar la que suena vuelve la última que sigue apretada;
  -- modo simple: soltar una de varias no redispara (cambia con la próxima tecla)
  local low = held_stack[#held_stack]
  if pv("chord_on") == 1 then low = (low ~= nil) and current_note or nil end
  if low == nil then
    if not hold_on and current_note ~= nil then
      if ext_clock_on() then
        cancel_release()
        local wait = release_grace()
        release_id = clock.run(function() clock.sleep(wait); release_now() end)
      else
        release_now()
      end
    end
  elseif low ~= current_note then
    current_note = low
    last_note = low
    if arp_on then engine.padOn(note_to_hz(current_note - 24))
    else sound_chord(current_note) end
  end
  update_crackle()
end

local function set_hold(on)
  hold_on = on
  hold_flash = PULSE
  if not on then cancel_release(); release_now() end
end

-- teclas soltadas con clock corriendo que esperan por si el equipo las repite
local repeat_off = {}
local function midi_event(data)
  local msg = midi.to_msg(data)
  if msg.type == "clock" then
    local now = util.time()
    if last_midi_clock then
      local d = now - last_midi_clock
      if d > 0.002 and d < 0.25 then
        tick_sec = tick_sec and (tick_sec * 0.9 + d * 0.1) or d
      end
    end
    last_midi_clock = now
    if arp_on and arp_clock_id and current_note then
      local tps = ticks_per_step()
      ext_ticks = ext_ticks + 1
      if ext_ticks >= tps then
        ext_ticks = math.min(ext_ticks - tps, tps - 1)
        arp_step()
      end
    end
    return
  elseif msg.type == "start" then
    ext_ticks = 0
    step_i = 1
    return
  elseif msg.type == "stop" or msg.type == "continue" then
    return
  end
  local ch = params:get("midi_channel")
  if ch ~= 0 and msg.ch ~= ch then return end
  if msg.type == "note_on" and msg.vel > 0 then
    -- con clock MIDI el equipo repite las teclas apretadas a cada pulso:
    -- si la tecla se soltó hace poco, sigue apretada y no se redispara
    if repeat_off[msg.note] then repeat_off[msg.note] = nil; return end
    on_note_on(msg.note, msg.vel)
  elseif msg.type == "note_off" or (msg.type == "note_on" and msg.vel == 0) then
    if ext_clock_on() then
      local note = msg.note
      local tok = {}
      repeat_off[note] = tok
      local wait = util.clamp((tick_sec or 0.02) * 30, 0.05, 1)
      clock.run(function()
        clock.sleep(wait)
        if repeat_off[note] == tok then repeat_off[note] = nil; on_note_off(note) end
      end)
    else
      on_note_off(msg.note)
    end
  end
end

-- ============================================================
-- parámetros (se guardan solos en data/chordexwt/estado.pset)
-- ============================================================

local STATE_FILE

local function add_params()
  params:add_separator("chordex_wt", "CHORDEX WT")
  params:add_number("midi_channel", "canal MIDI (0=todos)", 0, 16, 0)
  params:add_option("midi_clock_div", "divisor reloj MIDI", {"1x", "2x", "4x", "8x"}, 3)
  params:add_option("model", "banco", WT.names, 1)
  params:set_action("model", function(v)
    engine.bank(v - 1)
    -- elegir un banco carga su posición / barrido / scan / filtro / warp
    -- (como un preset); al cargar el estado guardado se respeta lo guardado
    if not loading then
      local b = WT.banks[v]
      params:set("pos", b.pos)
      params:set("barrido", b.barrido)
      params:set("scan", b.scan)
      params:set("filtro", b.filtro)
      params:set("warp", b.warp)
    end
  end)
  params:add_option("chord", "acorde", chord_types, 1)
  params:set_action("chord", function()
    if current_note and not arp_on then sound_chord(current_note) end
  end)
  params:add_option("chord_on", "modo acorde", {"no", "sí"}, 2)
  params:set_action("chord_on", function()
    if current_note and not arp_on and not loading then sound_chord(current_note) end
  end)
  params:add_option("arp_pattern", "patrón arp", arp_pattern_names, 1)
  params:add_option("arp_rate", "velocidad arp", arp_rate_names, 3)
  params:add_control("arp_gate", "gate arp (1=legato)", controlspec.new(0, 1, "lin", 0, 0.6, ""))

  params:add_separator("chordex_wt_tabla", "TABLA")
  params:add_control("pos", "posición", controlspec.new(0, 1, "lin", 0, 0.35, ""))
  params:set_action("pos", function(v) engine.pos(v) end)
  params:add_control("barrido", "barrido", controlspec.new(-1, 1, "lin", 0, 0.45, ""))
  params:set_action("barrido", function(v) engine.barrido(v) end)
  params:add_control("scan", "scan", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("scan", function(v) engine.scan(v) end)
  params:add_control("filtro", "filtro", controlspec.new(0, 1, "lin", 0, 0.75, ""))
  params:set_action("filtro", function(v) engine.filtro(v) end)
  params:add_control("warp", "warp", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("warp", function(v) engine.warp(v) end)

  params:add_separator("chordex_wt_tono", "TONO")
  params:add_control("atk", "ataque", controlspec.new(0.001, 2, "lin", 0, 0.01, "s"))
  params:set_action("atk", function(v) engine.atk(v) end)
  params:add_control("rel", "decay", controlspec.new(0.02, 4, "lin", 0, 0.9, "s"))
  params:set_action("rel", function(v) engine.rel(v) end)
  params:add_control("drive", "distorsión", controlspec.new(0, 1, "lin", 0, 0.1, ""))
  params:set_action("drive", function(v) engine.drive(v) end)
  params:add_control("wobble", "wobble", controlspec.new(0, 1, "lin", 0, 0.2, ""))
  params:set_action("wobble", function(v) engine.wobble(v) end)
  params:add_control("fatness", "fatness", controlspec.new(0, 1, "lin", 0, 0.5, ""))
  params:set_action("fatness", function(v) engine.fatness(v) end)
  params:add_control("shimmer", "shimmer", controlspec.new(0, 1, "lin", 0, 0, ""))
  params:set_action("shimmer", function(v) engine.shimmer(v ^ 3) end)
  params:add_control("space", "hall", controlspec.new(0, 0.6, "lin", 0, 0.22, ""))
  params:set_action("space", function(v) engine.space(v) end)
  params:add_control("gain", "volumen", controlspec.new(0, 1.5, "lin", 0, 1.0, ""))
  params:set_action("gain", function(v) engine.gain(v) end)
end

-- ============================================================
-- init / controles
-- ============================================================

local screen_metro
local splash_start = nil
-- primero la intro U-MA de particulas (la de uma_splash/splash), despues CHORDEX
local SPLASH_IN, SPLASH_HOLD, SPLASH_FADE = 0.5, 1.6, 0.7
local uma_intro = include("lib/uma_splash_particles")
local uma_sound = include("lib/uma_splash") -- base de la intro, maneja el sonido

local function skip_splash()
  if splash_start and util.time() - splash_start < uma_intro.DUR then uma_sound.sound_off() end
  splash_start = nil
end

function init()
  midi_in = {}
  for i = 1, #midi.vports do
    midi_in[i] = midi.connect(i)
    midi_in[i].event = midi_event
  end

  add_params()
  STATE_FILE = norns.state.data .. "estado.pset"
  loading = true
  if util.file_exists(STATE_FILE) then params:read(STATE_FILE) end
  params:bang()
  loading = false

  for b = 1, #WT.banks do WT.rows_for(b) end

  uma_sound.sound_on(norns.state.path .. "lib/uma_particles.wav")
  splash_start = util.time()
  screen_metro = metro.init(function() redraw() end, 1 / 24, -1)
  screen_metro:start()
end

function cleanup()
  if STATE_FILE then params:write(STATE_FILE, "chordexwt") end
end

local function nudge(p, d)
  if p.opt then
    local n = #params:lookup_param(p.id).options
    params:set(p.id, util.clamp(pv(p.id) + (d > 0 and 1 or -1), 1, n))
  else
    params:set(p.id, util.clamp(pv(p.id) + d * p.step, p.min, p.max))
  end
end

function enc(n, d)
  if splash_start then return end
  if n == 1 then
    if k2_held then
      params:set("arp_gate", util.clamp(params:get("arp_gate") + d * 0.02, 0, 1))
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("model", util.clamp(pv("model") + (d > 0 and 1 or -1), 1, #WT.banks))
      model_flash = PULSE * 2
    else
      params:set("pos", util.clamp(pv("pos") + d * 0.01, 0, 1))
      bump("pos")
    end
  elseif n == 2 then
    local dir = d > 0 and 1 or -1
    if k2_held then
      params:set("arp_pattern", ((pv("arp_pattern") - 1 + dir) % #arp_pattern_names) + 1)
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("warp", util.clamp(pv("warp") + d * 0.02, 0, 1))
      bump("warp")
    else
      focus_index = ((focus_index - 1 + dir) % #P) + 1
      bump(P[focus_index].id)
    end
  elseif n == 3 then
    if k2_held then
      params:set("arp_rate", util.clamp(pv("arp_rate") + (d > 0 and 1 or -1), 1, #arp_rate_names))
      k2_turned = true
      bump("arp")
    elseif k3_held then
      k3_turned = true
      params:set("chord", util.clamp(pv("chord") + (d > 0 and 1 or -1), 1, #chord_types))
      chord_flash = PULSE * 2
    else
      nudge(P[focus_index], d)
      bump(P[focus_index].id)
    end
  end
end

function key(n, z)
  -- K1 llega acá solo si se mantiene (el toque corto abre el menú de norns)
  if n == 1 then
    if z == 1 then
      if splash_start then skip_splash() end
      set_hold(not hold_on)
    end
  elseif n == 2 then
    if z == 1 then
      k2_held = true; k2_turned = false
    else
      if splash_start then skip_splash()
      elseif k2_held and not k2_turned then
        arp_on = not arp_on
        bump("arp")
        if arp_on then
          engine.noteOff(); release_chord_vs()
          if current_note then start_arp_if_needed() end
        else
          stop_arp()
          if current_note then sound_chord(current_note) end
        end
      end
      k2_held = false
    end
  elseif n == 3 then
    k3_held = (z == 1)
    if z == 1 and splash_start then skip_splash() end
    if z == 1 then
      -- mantener K3 sin girar ningún encoder alterna el modo acorde
      k3_turned = false
      local press = util.time()
      k3_press = press
      clock.run(function()
        clock.sleep(K3_LONG)
        if k3_held and not k3_turned and k3_press == press then
          params:set("chord_on", 3 - params:get("chord_on"))
          chord_flash = PULSE * 2
        end
      end)
    end
  end
end

-- ============================================================
-- GRÁFICOS — acumulador por nivel (mismo esquema que Chordex80)
-- ============================================================

local G = {}
do
local bt, b1, b2, b3, b4, bn = {}, {}, {}, {}, {}, {}
for lv = 1, 15 do bt[lv] = {}; b1[lv] = {}; b2[lv] = {}; b3[lv] = {}; b4[lv] = {}; bn[lv] = 0 end

local function add(lv, ty, a, b, c, d)
  lv = math.floor(lv + 0.5)
  if lv < 1 then return end
  if lv > 15 then lv = 15 end
  local n = bn[lv] + 1
  bn[lv] = n
  bt[lv][n] = ty; b1[lv][n] = a; b2[lv][n] = b; b3[lv][n] = c; b4[lv][n] = d
end

function G.px(lv, x, y) add(lv, 0, x, y) end
function G.line(lv, x1, y1, x2, y2) add(lv, 3, x1, y1, x2, y2) end
function G.rect(lv, x, y, w, h) add(lv, 4, x, y, w, h) end
function G.circle(lv, x, y, r) add(lv, 5, x, y, r) end

function G.flush()
  local floor = math.floor
  for lv = 1, 15 do
    local n = bn[lv]
    if n > 0 then
      local T, A, B, C, D = bt[lv], b1[lv], b2[lv], b3[lv], b4[lv]
      screen.level(lv)
      local fills, strokes = false, false
      for k = 1, n do
        local ty = T[k]
        if ty == 0 then
          screen.rect(floor(A[k]), floor(B[k]), 1, 1); fills = true
        elseif ty == 4 then
          screen.rect(floor(A[k]), floor(B[k]), C[k], D[k]); fills = true
        else
          strokes = true
        end
      end
      if fills then screen.fill() end
      if strokes then
        for k = 1, n do
          local ty = T[k]
          if ty == 3 then
            screen.move(floor(A[k]) + 0.5, floor(B[k]) + 0.5)
            screen.line(floor(C[k]) + 0.5, floor(D[k]) + 0.5)
          elseif ty == 5 then
            screen.move(floor(A[k]) + 0.5 + C[k], floor(B[k]) + 0.5)
            screen.circle(floor(A[k]) + 0.5, floor(B[k]) + 0.5, C[k])
          end
        end
        screen.stroke()
      end
      bn[lv] = 0
    end
  end
end
end

-- ============================================================
-- la onda calculada en Lua (misma fórmula que el engine) para dibujar
-- ============================================================

local V = {}          -- estado del cálculo visual
do
  V.N = WT.N
  V.y = {}
  V.a = {}             -- armónicos en la posición actual
  V.w = {}             -- armónicos después del filtro
  V.ph = {}
  V.p = {}             -- fases de la tabla en la posición actual
  V.filt = {}          -- curva del filtro por armónico (para dibujarla)
  V.env = 0
  V.amp = 0
  V.pos = 0
  V.spec = {}
  for k = 1, V.N do V.y[k] = 0 end
  for h = 1, WT.H do V.a[h] = 0; V.w[h] = 0; V.ph[h] = 0; V.p[h] = 0; V.filt[h] = 1 end
  for h = 1, 14 do V.spec[h] = 0 end
  V.tw = {}
end

-- envolvente de amplitud de la voz en el instante t (la del engine)
local function amp_env(vs, t)
  if not vs then return 0 end
  local a, d, s, rel, toff
  if vs.pluck then
    a = math.min(pv("atk"), vs.dur * 0.3) + 0.002
    d, s = vs.dur * 0.45, 0.6
    rel = vs.dur * 0.9 + 0.04
    toff = vs.t0 + vs.dur * 0.45
  else
    a, d, s = pv("atk") + 0.002, 1.5, 0.7
    rel = pv("rel")
    toff = vs.t1
  end
  local function held(tt)
    local x = tt - vs.t0
    if x < a then return x / a end
    return s + (1 - s) * math.exp(-3.5 * (x - a) / d)
  end
  if toff and t > toff then
    local x = (t - toff) / rel
    if x >= 1 then return 0 end
    return held(toff) * (1 - x) * (1 - x)
  end
  return held(t)
end

-- posición en la tabla: E1 + velocidad + barrido + scan
local function pos_now(vs, t)
  local x = vs and (t - vs.t0) or 99
  local vel = vs and vs.vel or 0.6
  local swt = (vs and vs.pluck) and math.min(2.2, vs.dur * 3 + 0.2) or 2.2
  local sc = pv("scan")
  local p = pv("pos") + (vel - 0.6) * 0.15
    + pv("barrido") * (1e-4 ^ math.min(1, x / swt))
    + math.sin(2 * math.pi * (0.1 + sc * 3) * (vs and x or t)) * sc * 0.35
  return util.clamp(p, 0, 1)
end

local function fold(x)
  if x >= -1 and x <= 1 then return x end
  local r = (x + 1) % 4
  if r > 2 then r = 4 - r end
  return r - 1
end

local atan2 = math.atan2 or math.atan
local function tanh(x) local e2 = math.exp(2 * x); return (e2 - 1) / (e2 + 1) end

local function compute_wt(t)
  local vs = arp_on and VS.arp or VS.chord
  if arp_on and not vs then vs = VS.chord end
  local b = pv("model")
  V.env = amp_env(vs, t)
  V.pos = pos_now(vs, t)
  WT.at(b, V.pos, V.a, V.p)

  -- filtro RLPF (rq 0.7): módulo y fase en cada armónico
  local note = vs and vs.note or (last_note or 60)
  local fhz = note_to_hz(note)
  local vel = vs and vs.vel or 0.6
  local fenv = (vs and t - vs.t0 < 0.35) and math.exp(-3 * (t - vs.t0) / 0.35) * vel or 0
  local fc = util.clamp(180 * 2 ^ (pv("filtro") * 6.8) * (fhz / 261.6) ^ 0.5 * (1 + fenv * 1.5), 30, 18000)
  for h = 1, WT.H do
    local x = h * fhz / fc
    local re, im = 1 - x * x, x * 0.7
    local mag = 1 / math.sqrt(re * re + im * im)
    V.filt[h] = mag
    V.w[h] = V.a[h] * mag
    V.ph[h] = V.p[h] - atan2(im, re)
  end
  WT.synth(V.w, V.ph, V.y, 0.003)

  -- warp (fold) y drive, igual que el engine
  local wg = 1 + pv("warp") * 4
  local dr = pv("drive")
  local dg = 1 + (dr ^ 1.4) * 9
  local peak = 0
  for k = 1, V.N do
    local y = fold(V.y[k] * wg)
    if dr > 0 then y = y * (1 - dr) + tanh(y * dg) * dr / (1 + dr * 0.8) end
    V.y[k] = y
    if math.abs(y) > peak then peak = math.abs(y) end
  end
  V.amp = peak * V.env

  -- espectro: 14 armónicos del ciclo final
  local N = V.N
  for h = 1, 14 do
    local tw = V.tw[h]
    if not tw then
      tw = {c = {}, s = {}}
      for k = 1, N do
        local a = 2 * math.pi * h * (k - 1) / N
        tw.c[k] = math.cos(a); tw.s[k] = math.sin(a)
      end
      V.tw[h] = tw
    end
    local re, im = 0, 0
    local cc, ss, y = tw.c, tw.s, V.y
    for k = 1, N do re = re + y[k] * cc[k]; im = im + y[k] * ss[k] end
    local mag = 2 * math.sqrt(re * re + im * im) / N * V.env
    V.spec[h] = V.spec[h] * 0.5 + mag * 0.5
  end
end

-- ============================================================
-- dibujo
-- ============================================================

local CX, CY = 64, 32
local sparks = {}

local function pl(name) return (pulse[name] or 0) / PULSE end

-- geometría de la vista 3D: fila 0 adelante abajo, fila 1 atrás arriba
local TX, TY = 33, 53        -- origen de la fila de adelante
local TDX, TDY = 14, -31     -- corrimiento hasta la fila de atrás
local TW, TA = 46, 8         -- ancho y amplitud de cada onda

local function row_origin(d) return TX + TDX * d, TY + TDY * d end

-- la tabla: filas de atrás hacia adelante, cada una tapa a las de atrás
local function draw_table(t)
  local rows = WT.rows_for(pv("model"))
  local R, RW = WT.ROWS, WT.RW
  local floor = math.floor
  local mp = model_flash > 0 and 1 or 0
  for r = R, 1, -1 do
    local d = (r - 1) / (R - 1)
    local ox, oy = row_origin(d)
    local row = rows[r]
    -- relleno negro debajo de la onda (oculta lo que queda atrás)
    screen.level(0)
    -- (cada 2 puntos: el borde lo tapa la línea de la onda y son la mitad de llamadas)
    screen.move(ox, oy - row[1] * TA)
    for q = 3, RW, 2 do
      screen.line(ox + (q - 1) / (RW - 1) * TW, oy - row[q] * TA)
    end
    if RW % 2 == 0 then screen.line(ox + TW, oy - row[RW] * TA) end
    screen.line(ox + TW, oy + TA + 1)
    screen.line(ox, oy + TA + 1)
    screen.close()
    screen.fill()
    -- la onda: más brillante cuanto más cerca de donde está sonando
    local near = math.max(0, 1 - math.abs(d - V.pos) * 5)
    local lv = floor(2 + (1 - d) * 2 + near * (2 + 4 * V.env) + mp * 2 + 0.5)
    screen.level(math.min(15, lv))
    screen.move(floor(ox) + 0.5, floor(oy - row[1] * TA) + 0.5)
    for q = 2, RW do
      screen.line(floor(ox + (q - 1) / (RW - 1) * TW) + 0.5, floor(oy - row[q] * TA) + 0.5)
    end
    screen.stroke()
  end
end

-- la onda que suena, encima de la tabla, en su profundidad
local function slice_xy(k, ox, oy, scale)
  local N = V.N
  return ox + (k - 1) / (N - 1) * TW, oy - V.y[k] * TA * scale
end

local function draw_slice(t, dt)
  local ox, oy = row_origin(V.pos)
  local wob = pv("wobble")
  local scale = (0.6 + 0.6 * V.env) * (1 + math.sin(t * 5.2) * wob * 0.08 * V.env)
  local N = V.N
  local floor = math.floor
  local lv = 5 + 10 * math.min(1, V.env * 1.2 + flash * 0.3)

  -- borde negro para que se separe de las filas
  screen.level(0)
  for off = -1, 1, 2 do
    local px, py = slice_xy(1, ox, oy + off, scale)
    screen.move(floor(px) + 0.5, floor(py) + 0.5)
    for k = 3, N, 2 do
      local x, y = slice_xy(k, ox, oy + off, scale)
      screen.line(floor(x) + 0.5, floor(y) + 0.5)
    end
    screen.stroke()
  end

  -- fantasma (fatness): la misma onda corrida un poco, respirando
  local fat = pv("fatness")
  if fat > 0.02 then
    local sh = fat * 2.5 * math.sin(t * 2.3) + 1
    local px, py = slice_xy(1, ox + sh, oy - 1, scale)
    for k = 3, N, 2 do
      local x, y = slice_xy(k, ox + sh, oy - 1, scale)
      G.line(1 + fat * 3, px, py, x, y)
      px, py = x, y
    end
  end
  local px, py = slice_xy(1, ox, oy, scale)
  for k = 2, N do
    local x, y = slice_xy(k, ox, oy, scale)
    G.line(lv, px, py, x, y)
    px, py = x, y
  end

  -- notas del arpegio: cometas que corren por la onda
  for i = #riders, 1, -1 do
    local c = riders[i]
    c.u = c.u + dt * 2.6
    if c.u >= 1 then table.remove(riders, i)
    else
      for tail = 0, 3 do
        local u = c.u - tail * 0.035
        if u >= 0 then
          local k = floor(u * (N - 1)) + 1
          local x, y = slice_xy(k, ox, oy, scale)
          G.px(c.lv * (1 - tail * 0.25) * (1 - c.u * 0.5), x, y - 1)
        end
      end
    end
  end

  -- shimmer: chispas que suben desde la onda
  local sh = pv("shimmer")
  if sh > 0.02 and V.env > 0.02 and math.random() < sh * 0.9 then
    local k = math.random(1, N)
    local x, y = slice_xy(k, ox, oy, scale)
    sparks[#sparks + 1] = {x = x, y = y, v = 8 + math.random() * 10, life = 1}
  end
  for i = #sparks, 1, -1 do
    local s = sparks[i]
    s.y = s.y - s.v * dt
    s.life = s.life - dt * 0.9
    if s.life <= 0 or s.y < 0 then table.remove(sparks, i)
    else G.px(2 + s.life * 12, s.x + math.sin(s.y * 0.4) * 1.5, s.y) end
  end
  -- crackle: chispas sueltas sobre la tabla
  if crackle_amt > 0 then
    for i = 1, math.floor(crackle_amt * 9) do
      local d = math.random()
      local x0, y0 = row_origin(d)
      G.px(15, x0 + math.random() * TW, y0 + (math.random() - 0.5) * TA * 2)
    end
  end

  -- riel de posición a la izquierda de la tabla
  local rp = pl("pos")
  local wp = pl("warp")
  local ax, ay = row_origin(0)
  local bx, by = row_origin(1)
  ax, bx = ax - 4, bx - 4
  G.line(2 + rp * 5, ax, ay, bx, by)
  -- rango del scan
  local sc = pv("scan")
  if sc > 0.02 then
    local p0 = util.clamp(pv("pos") - sc * 0.35, 0, 1)
    local p1 = util.clamp(pv("pos") + sc * 0.35, 0, 1)
    G.line(5, ax + (bx - ax) * p0, ay + (by - ay) * p0, ax + (bx - ax) * p1, ay + (by - ay) * p1)
  end
  local p = pv("pos")
  G.rect(8 + rp * 7, ax + (bx - ax) * p - 2, ay + (by - ay) * p, 2, 1)
  G.rect(15, ax + (bx - ax) * V.pos - 1, ay + (by - ay) * V.pos - 1, 2, 2)
  -- warp: al moverlo se ilumina el borde de la onda que suena
  if wp > 0 then
    local x1, y1 = row_origin(V.pos)
    G.line(15 * wp, x1, y1 + TA + 2, x1 + TW, y1 + TA + 2)
    local wl = math.floor(pv("warp") * TW + 0.5)
    if wl > 0 then G.line(15, x1, y1 + TA + 3, x1 + wl, y1 + TA + 3) end
  end
end

-- el acorde en la rueda de 12 notas (arriba a la izquierda)
local WX, WY, WR = 14, 15, 8
local function wheel_xy(pc, rad)
  local a = (pc / 12) * 2 * math.pi - math.pi / 2
  return WX + math.cos(a) * rad, WY + math.sin(a) * rad
end

local function draw_wheel(t, dt)
  local root = current_note or last_note
  local lit = current_note ~= nil
  local tones = {}
  if root then
    for i, iv in ipairs(four_tone_intervals(chord_name())) do
      tones[#tones + 1] = (root + iv) % 12
    end
  end
  for pc = 0, 11 do
    local x, y = wheel_xy(pc, WR)
    G.px(2, x, y)
  end
  if #tones > 0 then
    local base = lit and 1 or 0.35
    local sorted = {}
    for _, pc in ipairs(tones) do sorted[#sorted + 1] = pc end
    table.sort(sorted)
    for i = 1, #sorted do
      local a, b = sorted[i], sorted[i % #sorted + 1]
      if a ~= b then
        local x1, y1 = wheel_xy(a, WR)
        local x2, y2 = wheel_xy(b, WR)
        G.line((4 + 6 * V.env) * base + chord_flash / PULSE * 6, x1, y1, x2, y2)
      end
    end
    for i, pc in ipairs(tones) do
      local x, y = wheel_xy(pc, WR)
      if i == 1 then G.rect(15 * base, x - 1, y - 1, 2, 2)
      else G.px(11 * base, x, y) end
    end
  end
  -- cometas: cada nota del arpegio sale de su lugar en la rueda
  for i = #comets, 1, -1 do
    local c = comets[i]
    c.r = c.r + dt * 20
    if c.r > 7 then table.remove(comets, i)
    else
      local r0 = WR + c.r
      local x1, y1 = wheel_xy(c.pc, r0)
      local x2, y2 = wheel_xy(c.pc, math.max(WR, r0 - 3))
      G.line(c.lv * (1 - c.r / 8), x2, y2, x1, y1)
    end
  end
end

-- la envolvente (ataque / decay) con un punto donde está la voz
local function draw_env(t)
  local x0, y0, w, h = 1, 37, 27, 7
  local a = math.min(1, pv("atk") / 2)
  local r = math.min(1, pv("rel") / 4)
  local xa = x0 + 1 + a * 8
  local xs = xa + 4
  local xr = xs + 3 + (w - 16) * 0.45
  local xe = math.min(x0 + w, xr + 1 + r * 10)
  local ys = y0 - h * 0.7
  local la = 3 + pl("atk") * 12
  local lr = 3 + pl("rel") * 12
  G.line(la, x0, y0, xa, y0 - h)
  G.line(3, xa, y0 - h, xs, ys)
  G.line(3, xs, ys, xr, ys)
  G.line(lr, xr, ys, xe, y0)
  if V.env > 0.01 then
    -- el punto sube y baja con la envolvente que suena
    G.rect(15, x0 + (xe - x0) * 0.5 - 1, y0 - V.env * h - 1, 2, 2)
  end
end

-- faders: 9 columnitas abajo a la izquierda
local function fader_norm(p)
  if p.opt then
    local n = #params:lookup_param(p.id).options
    return (pv(p.id) - 1) / (n - 1)
  end
  return (pv(p.id) - p.min) / (p.max - p.min)
end

-- indicador de 3x3 bajo cada fader (alternados arriba / abajo para que
-- no se peguen entre vecinos)
local FADER_ICON = {
  atk     = {"..#", ".##", "###"},   -- rampa que sube
  rel     = {"#..", "##.", "###"},   -- rampa que cae
  barrido = {".##", "#..", ".##"},   -- arranca corrido y vuelve
  scan    = {".#.", "#.#", "#.#"},   -- ida y vuelta del LFO
  filtro  = {"##.", "..#", "..#"},   -- pasa bajos
  drive   = {"#.#", ".#.", "#.#"},   -- chispa
  wobble  = {".#.", "#.#", ".#."},   -- tiembla
  fatness = {"##.", "###", ".##"},   -- dos ondas encimadas
  shimmer = {".#.", "###", ".#."},   -- destello
}

local function draw_faders()
  for i, p in ipairs(P) do
    local x = 1 + (i - 1) * 3
    local focused = (focus_index == i)
    local pp = pl(p.id)
    local lv = focused and 15 or (pp > 0 and 6 + 9 * pp or 6)
    G.line(focused and 3 or 1, x, 41, x, 55)
    -- barrido es bipolar: marca el centro
    if p.min < 0 then G.px(focused and 6 or 3, x + 1, 48) end
    local v = fader_norm(p)
    local cy = math.floor(54 - v * 13 + 0.5)
    G.rect(lv, x - (focused and 1 or 0), cy, focused and 3 or 2, 2)
    -- indicador
    local low = (i % 2 == 0)
    local iy = low and 61 or 57
    local il = focused and 15 or math.floor(5 + 8 * pp + 0.5)
    if low then G.px(focused and 5 or 2, x, 57) G.px(focused and 5 or 2, x, 59) end
    local ic = FADER_ICON[p.id]
    for r = 1, 3 do
      local row = ic[r]
      for c = 1, 3 do
        if row:sub(c, c) == "#" then G.px(il, x - 2 + c, iy + r - 1) end
      end
    end
  end
end

-- panel derecho: osciloscopio, espectro + filtro, arpegio
local function draw_right(t)
  local x0 = 98
  -- banco: 8 puntos arriba
  for m = 1, #WT.banks do
    G.rect(pv("model") == m and 12 or 2, x0 + 1 + (m - 1) * 3, 0, 2, 1)
  end
  -- retener: rombo de 3x3 arriba a la derecha
  local lk = hold_on and (current_note and 13 or 8) or 3
  lk = math.min(15, lk + hold_flash * 0.25)
  G.px(lk, 125, 0) G.px(lk, 124, 1) G.px(lk, 126, 1) G.px(lk, 125, 2)
  if hold_on then G.px(lk, 125, 1) end

  -- osciloscopio: un ciclo
  local N = V.N
  local mid = 11
  G.line(1, x0, mid, 127, mid)
  local lv = 4 + 11 * math.min(1, V.amp * 1.5)
  local sc = 0.15 + 0.85 * V.env
  local px, py
  for xx = 0, 29 do
    local k = math.floor(xx / 29 * (N - 1)) + 1
    local y = mid - V.y[k] * 7 * sc
    if px then G.line(lv, px, py, x0 + xx, y) end
    px, py = x0 + xx, y
  end

  -- espectro: 14 armónicos y la curva del filtro encima
  local base = 50
  local fp = pl("filtro")
  for h = 1, 14 do
    local x = x0 + 1 + (h - 1) * 2
    local m = math.sqrt(V.spec[h]) * 26
    local hh = math.min(26, math.floor(m + 0.5))
    G.px(1, x, base)
    if hh > 0 then
      for y = 0, hh - 1 do
        local u = y / 26
        G.px(3 + 12 * (1 - u) * math.min(1, V.amp * 2 + 0.3), x, base - 1 - y)
      end
    end
    local fy = math.floor(base - 1 - math.min(1, math.sqrt(V.filt[h]) * 0.75) * 25 + 0.5)
    G.px(3 + fp * 12, x, fy)
  end

  -- patrón del arpegio: escalera de puntos
  local pat = pv("arp_pattern")
  local order
  if pat == 6 then
    order = {}
    for i = 1, 6 do order[i] = (math.floor(t * 4) * 7 + i * 5) % 4 + 1 end
  else
    order = step_order(pat, pat == 7 and 8 or 4)
  end
  local top = (pat == 7) and 8 or 4
  local ap = pl("arp")
  local blink = (math.floor(t * 6) % 2 == 0)
  local base_lv = k2_held and (blink and 15 or 8) or (arp_on and 6 + ap * 6 or 2 + ap * 8)
  local gw = math.min(3, math.floor(26 / #order))
  for i, idx in ipairs(order) do
    local x = x0 + 1 + (i - 1) * gw
    local y = 61 - (idx - 1) * (5 / (top - 1))
    local cur = arp_on and arp_step_lit > 0 and idx == arp_step_lit
    G.rect(cur and 15 or base_lv, x, math.floor(y), math.max(1, gw - 1), 1)
  end
  for i = 1, pv("arp_rate") do
    G.px(k2_held and 12 or (arp_on and 5 or 2), x0 + 1 + (i - 1) * 2, 63)
  end
  local gl = math.floor(params:get("arp_gate") * 18 + 0.5)
  if gl > 0 then G.line(k2_held and 10 or (arp_on and 4 or 1), x0 + 10, 63, x0 + 10 + gl, 63) end
end

-- dibujos de los bancos (aparecen al cambiar con K3 + E1)
local MODEL_ICON = {
  CRISTAL = {
    "    #######    ",
    "   #+#+++#+#   ",
    "  #++#+++#++#  ",
    " ############# ",
    "  #+++#+#+++#  ",
    "   #++#+#++#   ",
    "    #+#+#+#    ",
    "     ##+##     ",
    "      ###      ",
    "       #       ",
  },
  VOCAL = {
    "    #######    ",
    "  ##+++++++##  ",
    " #++#######++# ",
    "#++#.......#++#",
    "#+#.........#+#",
    "#++#.......#++#",
    " #++#######++# ",
    "  ##+++++++##  ",
    "    #######    ",
  },
  DIGITAL = {
    "  # # # # # #  ",
    " ############# ",
    " #+++++++++++# ",
    "##+#########+##",
    " #+#.......#+# ",
    "##+#.......#+##",
    " #+#########+# ",
    " #+++++++++++# ",
    " ############# ",
    "  # # # # # #  ",
  },
  ORGANO = {
    "        #        ",
    "      # # #      ",
    "    # # # # #    ",
    "  # # # # # # #  ",
    "# # # # # # # # #",
    "# # # # # # # # #",
    "+ + + + + + + + +",
    "#################",
    "#+++++++++++++++#",
    "#################",
  },
  SYNC = {
    "  #   #  #   # ",
    " ##  ## ##  ## ",
    "# # # ### # # #",
    "  ##  # # ##  #",
    "  #   #  #    #",
    "               ",
    "###############",
    "+      +      +",
  },
  METAL = {
    "      ###      ",
    "     #+++#     ",
    "    #+++++#    ",
    "    #+++++#    ",
    "   #+++++++#   ",
    "   #+++++++#   ",
    "  #+++++++++#  ",
    " ############# ",
    "       #       ",
    "      ###      ",
  },
  BITS = {
    "      ###      ",
    "    ###+###    ",
    "  ###+++++###  ",
    "###+++++++++###",
    "...............",
    "###.........###",
    "  ###.....###  ",
    "    ###.###    ",
    "      ###      ",
  },
  RESO = {
    "       #       ",
    "      #+#      ",
    "      #+#      ",
    "     #+++#     ",
    "#   #+++++#    ",
    "##++++++++##   ",
    "#++++++++++##  ",
    "#+++++++++++## ",
    "###############",
  },
}
local ICON_LV = {["#"] = 15, ["+"] = 9, ["."] = 4}

local function draw_overlays()
  if model_flash > 0 then
    local a = math.min(1, model_flash / PULSE)
    local rows = MODEL_ICON[WT.names[pv("model")]]
    local w, h = #rows[1], #rows
    local x0, y0 = math.floor(CX - w / 2), math.floor(CY - h / 2)
    screen.level(0)
    screen.rect(x0 - 2, y0 - 2, w + 4, h + 4)
    screen.fill()
    for ch, l in pairs(ICON_LV) do
      local lv = math.floor(l * a + 0.5)
      if lv > 0 then
        screen.level(lv)
        for y = 1, h do
          local r = rows[y]
          for x = 1, w do
            if r:sub(x, x) == ch then screen.rect(x0 + x - 1, y0 + y - 1, 1, 1) end
          end
        end
        screen.fill()
      end
    end
  elseif chord_flash > 0 or k3_held then
    -- nombre del acorde, solo mientras se elige (K3)
    local root = current_note or last_note
    local txt = (root and note_names[(root % 12) + 1] or "") ..
      (chord_suffix[chord_name()] ~= "" and chord_suffix[chord_name()] or (root and "" or "maj"))
    -- modo acorde apagado: solo la nota (o "1" si todavía no se tocó nada)
    if params:get("chord_on") == 1 then txt = root and note_names[(root % 12) + 1] or "1" end
    screen.font_face(1)
    screen.font_size(8)
    local w = screen.text_extents(txt)
    local a = k3_held and 1 or math.min(1, chord_flash / PULSE)
    screen.level(0)
    screen.rect(CX - w / 2 - 2, CY - 5, w + 4, 9)
    screen.fill()
    screen.level(math.floor(15 * a))
    screen.move(CX - w / 2, CY + 2)
    screen.text(txt)
  end
end

-- ---- splash ----
local function draw_splash(alpha)
  screen.clear()
  local lv = math.max(0, math.min(15, math.floor(15 * alpha)))
  screen.level(lv)
  screen.font_face(1)
  screen.font_size(16)
  local txt = "C H O R D E X"
  local w = screen.text_extents(txt)
  screen.move(64 - w / 2, 24)
  screen.text(txt)
  -- "WT": la tabla CRISTAL apilada, pasando de seno a sierra
  local rows = WT.rows_for(1)
  local t = util.time()
  for r = 1, WT.ROWS, 3 do
    local d = (r - 1) / (WT.ROWS - 1)
    local ox, oy = 40 + d * 14, 52 - d * 14
    local row = rows[r]
    local glow = math.max(0, 1 - math.abs(d - (t * 0.5) % 1) * 4)
    screen.level(math.max(0, math.floor((3 + glow * 12) * alpha)))
    screen.move(ox, oy - row[1] * 4)
    for q = 2, WT.RW do screen.line(ox + (q - 1) / (WT.RW - 1) * 34, oy - row[q] * 4) end
    screen.stroke()
  end
  screen.update()
end

local function tick(dt)
  for k, v in pairs(pulse) do pulse[k] = math.max(0, v - 1) end
  model_flash = math.max(0, model_flash - 1)
  chord_flash = math.max(0, chord_flash - 1)
  hold_flash = math.max(0, hold_flash - 1)
  flash = math.max(0, flash - dt * 3)
end

function redraw()
  local now = util.time()
  if splash_start then
    local e = now - splash_start
    if e < uma_intro.DUR then
      uma_intro.render(e)
      screen.update()
      return
    end
    e = e - uma_intro.DUR
    local t1 = SPLASH_IN
    local t2 = t1 + SPLASH_HOLD
    local t3 = t2 + SPLASH_FADE
    if e < t1 then draw_splash(e / SPLASH_IN) return
    elseif e < t2 then draw_splash(1) return
    elseif e < t3 then draw_splash(1 - (e - t2) / SPLASH_FADE) return
    else splash_start = nil end
  end

  local dt = last_t and math.min(0.2, now - last_t) or 1 / 24
  last_t = now
  tick(dt)
  compute_wt(now)

  screen.clear()
  draw_table(now)
  draw_slice(now, dt)
  draw_wheel(now, dt)
  draw_env(now)
  draw_faders()
  draw_right(now)
  G.flush()
  draw_overlays()
  screen.update()
end
