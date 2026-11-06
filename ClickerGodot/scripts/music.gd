extends AudioStreamPlayer
## Música chiptune generada por código: arpegio + bajo sobre I–vi–IV–V.
## Se pre-calcula un loop de 8 compases en trozos durante los primeros frames y
## luego se reproduce como un WAV normal en bucle.
## Es un placeholder hasta tener una pista real (basta con poner un .ogg en `stream`
## y quitar este script).

const MIX_RATE := 22050
const BPM := 100.0
const BARS := 8
const SAMPLES_PER_FRAME := 4000
## Do – La menor – Fa – Sol (notas MIDI).
const CHORDS := [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]]
## [nota del acorde, octava] para cada corchea; la segunda mitad usa la variación.
const ARPEGGIO := [[0, 0], [1, 0], [2, 0], [0, 1], [2, 0], [1, 0], [0, 1], [1, 1]]
const ARPEGGIO_B := [[0, 1], [2, 0], [1, 0], [2, 0], [0, 1], [1, 1], [2, 1], [1, 1]]
const LEAD_VOLUME := 0.10
const BASS_VOLUME := 0.05

var _data := PackedByteArray()
var _total := 0
var _generated := 0


func _ready() -> void:
	_total = int(BARS * 4 * 60.0 / BPM * MIX_RATE)
	_data.resize(_total * 2)


func _process(_delta: float) -> void:
	if _generated >= _total:
		return
	var end := mini(_generated + SAMPLES_PER_FRAME, _total)
	for i in range(_generated, end):
		_data.encode_s16(i * 2, int(clampf(_sample(i), -1.0, 1.0) * 32767.0))
	_generated = end
	if _generated >= _total:
		_start()


func _start() -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = _data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = _total
	stream = wav
	play()
	set_process(false)


func _sample(frame: int) -> float:
	var t := frame / float(MIX_RATE)
	var beat := t * BPM / 60.0
	var bar := floori(beat / 4.0)
	var chord: Array = CHORDS[bar % CHORDS.size()]

	var step := floori(beat * 2.0)
	var step_time := (beat * 2.0 - step) * 30.0 / BPM
	var pattern: Array = ARPEGGIO if bar < BARS / 2.0 else ARPEGGIO_B
	var arp: Array = pattern[step % pattern.size()]
	var note: int = chord[arp[0]] + 12 * arp[1]
	var lead := _triangle(_freq(note) * t) * exp(-step_time * 5.0) * LEAD_VOLUME

	var beat_time := (beat - floorf(beat)) * 60.0 / BPM
	var bass := _square(_freq(chord[0] - 12) * t) * exp(-beat_time * 3.0) * BASS_VOLUME
	return lead + bass


static func _freq(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


static func _triangle(phase: float) -> float:
	return 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0


static func _square(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
