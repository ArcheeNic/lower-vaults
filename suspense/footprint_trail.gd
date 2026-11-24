extends RefCounted

# Keep the bends between footfalls, including the height of a stair landing.
# Entries are addressed by serial so wrapping the ring cannot invalidate a live cursor.
const CAPACITY := 192
const LIFETIME := 11.5
var clock := 0.0
var first := 0
var next := 0
var points := PackedVector3Array()
var times := PackedFloat64Array()
var steps := PackedByteArray()
var _next_sample := 0.0


func _init() -> void:
	points.resize(CAPACITY)
	times.resize(CAPACITY)
	steps.resize(CAPACITY)


func record(delta: float, point: Vector3, footfall: bool) -> void:
	clock += delta
	if next > first and point.distance_squared_to(position_at(next - 1)) > 16:
		# A fall rescue starts a fresh route across the discontinuity.
		first = next
		_next_sample = clock
	if clock >= _next_sample or footfall:
		var slot := next % CAPACITY
		points[slot] = point
		times[slot] = clock
		steps[slot] = int(footfall)
		next += 1
		first = maxi(first, next - CAPACITY)
		_next_sample = clock + .10
	while first < next and clock - time_at(first) > LIFETIME:
		first += 1


func find_start(listener: Vector3, forward: Vector3) -> int:
	var best := -1
	var best_score := INF
	for entry in range(first, next):
		if not is_step(entry):
			continue
		var age := clock - time_at(entry)
		var offset := position_at(entry) - listener
		if age < 2.1 or offset.length() < 5.5:
			continue
		# Prefer a step about six seconds back which is behind the listener.
		var score := absf(age - 6.4) + 3.0 * maxf(0, forward.dot(offset.normalized()))
		if score < best_score:
			best_score = score
			best = entry
	return best


func position_at(entry: int) -> Vector3:
	return points[entry % CAPACITY]


func time_at(entry: int) -> float:
	return times[entry % CAPACITY]


func is_step(entry: int) -> bool:
	return steps[entry % CAPACITY] != 0


func shift_origin(shift: Vector3) -> void:
	for entry in range(first, next):
		points[entry % CAPACITY] -= shift
