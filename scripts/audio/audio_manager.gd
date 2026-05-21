## 音效管理系统 - Alpha v0.7
## 使用Godot内置AudioStreamPlayer + 程序化波形生成
## 提供战斗音效、UI音效、环境音效
extends Node2D

# === 音频播放器池 ===
var players: Array = []
var max_players: int = 8

# === 音效缓存 ===
var sound_cache: Dictionary = {}

# === 音量 ===
@export var master_volume: float = 0.5
@export var sfx_volume: float = 0.6
@export var env_volume: float = 0.3

# === 静音开关 ===
@export var muted: bool = false

func _ready() -> void:
	_init_players()
	_generate_sounds()

func _init_players() -> void:
	for i in range(max_players):
		var player = AudioStreamPlayer.new()
		player.volume_db = linear_to_db(master_volume * sfx_volume)
		add_child(player)
		players.append(player)

func _generate_sounds() -> void:
	# 生成所有程序化音效并缓存
	sound_cache["hit_light"] = _gen_hit_sound(800, 0.06, 0.3)
	sound_cache["hit_heavy"] = _gen_hit_sound(400, 0.1, 0.5)
	sound_cache["hit_boss"] = _gen_hit_sound(200, 0.12, 0.6)
	sound_cache["parry"] = _gen_parry_sound()
	sound_cache["parry_perfect"] = _gen_parry_perfect_sound()
	sound_cache["swing"] = _gen_swing_sound()
	sound_cache["jump"] = _gen_jump_sound()
	sound_cache["land"] = _gen_land_sound()
	sound_cache["hurt"] = _gen_hurt_sound()
	sound_cache["death"] = _gen_death_sound()
	sound_cache["war_cry"] = _gen_war_cry_sound()
	sound_cache["earth_shatter"] = _gen_earth_shatter_sound()
	sound_cache["boss_enrage"] = _gen_boss_enrage_sound()
	sound_cache["telegraph"] = _gen_telegraph_sound()
	sound_cache["menu_select"] = _gen_ui_select_sound()
	sound_cache["menu_confirm"] = _gen_ui_confirm_sound()
	sound_cache["enemy_die"] = _gen_enemy_die_sound()
	sound_cache["rock_fall"] = _gen_rock_fall_sound()
	sound_cache["level_up"] = _gen_level_up_sound()
	sound_cache["portal"] = _gen_portal_sound()

func play(sound_name: String, volume_mult: float = 1.0) -> void:
	if muted:
		return
	if not sound_cache.has(sound_name):
		return

	# 找一个空闲的播放器
	var player: AudioStreamPlayer = null
	for p in players:
		if not p.playing:
			player = p
			break
	if player == null:
		# 强制使用第一个
		player = players[0]
		player.stop()

	player.stream = sound_cache[sound_name]
	player.volume_db = linear_to_db(master_volume * sfx_volume * volume_mult)
	player.play()

# === 音效生成函数 ===

func _gen_hit_sound(freq: float, duration: float, decay: float) -> AudioStreamWAV:
	# 打击音效：短促的噪音脉冲 + 低频冲击
	var sample_rate: int = 22050
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)  # 16-bit

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * decay * 40)
		# 噪音 + 低频震动
		var noise: float = (randf() * 2 - 1) * 0.6
		var tone: float = sin(t * freq * TAU) * 0.4
		var val: float = (noise + tone) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_parry_sound() -> AudioStreamWAV:
	# 格挡音效：金属碰撞
	var sample_rate: int = 22050
	var duration: float = 0.12
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 30)
		# 高频金属音 + 泛音
		var val: float = (
			sin(t * 2400 * TAU) * 0.4 +
			sin(t * 3600 * TAU) * 0.25 +
			sin(t * 1200 * TAU) * 0.2 +
			(randf() * 2 - 1) * 0.15
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_parry_perfect_sound() -> AudioStreamWAV:
	# 完美格挡：更清脆的金属音 + 升调
	var sample_rate: int = 22050
	var duration: float = 0.2
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 20)
		# 升调金属音
		var freq_mod: float = 1.0 + t * 3.0  # 频率上升
		var val: float = (
			sin(t * 3000 * freq_mod * TAU) * 0.35 +
			sin(t * 4500 * freq_mod * TAU) * 0.2 +
			sin(t * 1500 * TAU) * 0.25 +
			(randf() * 2 - 1) * 0.1
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_swing_sound() -> AudioStreamWAV:
	# 挥砍音效：气流声
	var sample_rate: int = 22050
	var duration: float = 0.15
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = sin(t / duration * PI)  # 中间最大
		# 宽带噪音 + 频率扫描
		var freq: float = 200 + t * 3000
		var val: float = (
			(randf() * 2 - 1) * 0.5 +
			sin(t * freq * TAU) * 0.3
		) * envelope * 0.6
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_jump_sound() -> AudioStreamWAV:
	# 跳跃音效：短促上升音
	var sample_rate: int = 22050
	var duration: float = 0.08
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 25)
		var freq: float = 300 + t * 2000
		var val: float = sin(t * freq * TAU) * envelope * 0.5
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_land_sound() -> AudioStreamWAV:
	# 落地音效：低频冲击
	var sample_rate: int = 22050
	var duration: float = 0.1
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 35)
		var val: float = (
			sin(t * 150 * TAU) * 0.4 +
			(randf() * 2 - 1) * 0.3
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_hurt_sound() -> AudioStreamWAV:
	# 受击音效：低沉的冲击
	var sample_rate: int = 22050
	var duration: float = 0.15
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 25)
		var val: float = (
			sin(t * 200 * TAU) * 0.5 +
			sin(t * 100 * TAU) * 0.3 +
			(randf() * 2 - 1) * 0.2
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_death_sound() -> AudioStreamWAV:
	# 死亡音效：下降的低频
	var sample_rate: int = 22050
	var duration: float = 0.5
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 5)
		var freq: float = 400 - t * 600
		var val: float = (
			sin(t * freq * TAU) * 0.5 +
			sin(t * freq * 0.5 * TAU) * 0.3 +
			(randf() * 2 - 1) * 0.15
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_war_cry_sound() -> AudioStreamWAV:
	# 战吼音效：上升的共鸣
	var sample_rate: int = 22050
	var duration: float = 0.4
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = sin(t / duration * PI)
		var freq: float = 200 + t * 800
		var val: float = (
			sin(t * freq * TAU) * 0.35 +
			sin(t * freq * 1.5 * TAU) * 0.2 +
			sin(t * 100 * TAU) * 0.25
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_earth_shatter_sound() -> AudioStreamWAV:
	# 裂地斩音效：巨大的冲击波
	var sample_rate: int = 22050
	var duration: float = 0.6
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 4)
		# 前半段蓄力，后半段爆发
		var burst: float = 1.0
		if t < 0.15:
			burst = t / 0.15
		var val: float = (
			sin(t * 80 * TAU) * 0.4 +
			sin(t * 120 * TAU) * 0.3 +
			(randf() * 2 - 1) * 0.4
		) * envelope * burst
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_boss_enrage_sound() -> AudioStreamWAV:
	# Boss狂暴音效：咆哮
	var sample_rate: int = 22050
	var duration: float = 0.8
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = sin(t / duration * PI) * 0.8
		var freq: float = 150 + sin(t * 8) * 50
		var val: float = (
			sin(t * freq * TAU) * 0.4 +
			sin(t * freq * 2 * TAU) * 0.2 +
			(randf() * 2 - 1) * 0.3
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_telegraph_sound() -> AudioStreamWAV:
	# 预警音效：短促的警告音
	var sample_rate: int = 22050
	var duration: float = 0.15
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 20)
		var val: float = (
			sin(t * 1000 * TAU) * 0.5 +
			sin(t * 1500 * TAU) * 0.3
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_ui_select_sound() -> AudioStreamWAV:
	# UI选择音效
	var sample_rate: int = 22050
	var duration: float = 0.05
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var val: float = sin(t * 800 * TAU) * exp(-t * 40) * 0.4
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_ui_confirm_sound() -> AudioStreamWAV:
	# UI确认音效
	var sample_rate: int = 22050
	var duration: float = 0.1
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var val: float = (
			sin(t * 600 * TAU) * 0.3 +
			sin(t * 900 * TAU) * 0.2
		) * exp(-t * 20)
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_enemy_die_sound() -> AudioStreamWAV:
	# 敌人死亡音效
	var sample_rate: int = 22050
	var duration: float = 0.3
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 8)
		var freq: float = 500 - t * 1000
		var val: float = (
			sin(t * freq * TAU) * 0.35 +
			(randf() * 2 - 1) * 0.25
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_rock_fall_sound() -> AudioStreamWAV:
	# 落石音效
	var sample_rate: int = 22050
	var duration: float = 0.25
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 15)
		var val: float = (
			sin(t * 120 * TAU) * 0.4 +
			(randf() * 2 - 1) * 0.4
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_level_up_sound() -> AudioStreamWAV:
	# 升级音效：上升和弦
	var sample_rate: int = 22050
	var duration: float = 0.4
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 5)
		var val: float = (
			sin(t * 523 * TAU) * 0.25 +
			sin(t * 659 * TAU) * 0.2 +
			sin(t * 784 * TAU) * 0.15
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _gen_portal_sound() -> AudioStreamWAV:
	# 传送门音效：空灵的上升音
	var sample_rate: int = 22050
	var duration: float = 0.5
	var samples: int = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = sin(t / duration * PI)
		var freq: float = 300 + t * 1200
		var val: float = (
			sin(t * freq * TAU) * 0.3 +
			sin(t * freq * 0.5 * TAU) * 0.2 +
			sin(t * 200 * TAU) * 0.15
		) * envelope
		var sample: int = int(clamp(val, -1, 1) * 32767)
		data.encode_s16(i * 2, sample)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
