extends Node

var enabled: bool = true
var players: Array[AudioStreamPlayer] = []
var samples: Dictionary = {}
var cursor: int = 0

func _ready() -> void:
	for n in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db=-15
		add_child(voice)
		players.append(voice)

func play(cue: String) -> void:
	if not enabled or players.is_empty(): return
	if not samples.has(cue): samples[cue]=make_sample(cue)
	var voice := players[cursor%players.size()]
	cursor+=1
	voice.stream=samples[cue]
	voice.play()

func make_sample(cue: String) -> AudioStreamWAV:
	var length := .10
	var frequency := 480.0
	var noise := .03
	match cue:
		"step": length=.07; frequency=110; noise=.45
		"place": length=.18; frequency=180; noise=.12
		"gate": length=.32; frequency=85; noise=.25
		"error": length=.17; frequency=140; noise=.02
		"welcome": length=.27; frequency=610; noise=.01
		"radio": length=.38; frequency=330+float(cursor%4)*55; noise=.01
	var bytes := PackedByteArray()
	var count := int(length*22050)
	bytes.resize(count*2)
	var random := RandomNumberGenerator.new()
	random.seed=7281
	for n in range(count):
		var t := float(n)/22050
		var envelope := (1.0-exp(-t*300))*exp(-t*28)
		var pitch := frequency*(1.0+t*1.5 if cue=="welcome" else 1.0-t*.8)
		var wave := sin(TAU*pitch*t)*.5+sin(TAU*pitch*2*t)*.12+random.randf_range(-1,1)*noise
		bytes.encode_s16(n*2,int(clampf(wave*envelope,-1,1)*26000))
	var stream := AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	stream.data=bytes
	return stream
