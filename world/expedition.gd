extends RefCounted

const Relic := preload("res://world/relic.gd")
const SIZE := 64
const RELIC_COUNT := 409
const DEPTH := 8
const BOUNDS := Rect2i(0, 0, SIZE, SIZE)
const VOLUME := Vector3i(SIZE, SIZE / DEPTH, DEPTH)
const AXES := [Vector3i.RIGHT, Vector3i.UP, Vector3i.BACK]

var seed_value: int
var start: Vector2i
var finish: Vector2i
var distances := PackedInt32Array()
var _ports: Array[Dictionary] = []
var relics := {}


func _init(map_seed: int) -> void:
	seed_value = map_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = map_seed
	for i in SIZE * SIZE:
		_ports.append({})
	_join_blocks(rng)
	# A block has eight corners and at most six links to other blocks.
	# Start its twisting passage at an unused corner and preserve that end.
	# This leaves at least 512 dead ends before choosing start and finish.
	var reserved := {}
	for x in range(0, VOLUME.x, 2):
		for y in range(0, VOLUME.y, 2):
			for z in range(0, VOLUME.z, 2):
				var leaf := _carve_block(Vector3i(x,y,z), rng)
				reserved[leaf] = true
	# Some extra links allow round trips and other ways past an encounter.
	for i in SIZE * SIZE:
		var cell := _cell(i)
		var direction: Vector3i = AXES[rng.randi_range(0,2)]
		var grid := grid_of(cell) + direction
		if not _inside(grid) or rng.randf() >= .09:
			continue
		if reserved.has(cell) or reserved.has(cell_at_grid(grid)):
			continue
		var exits := ports(cell)
		if exits.size() < 4 and not exits.has(direction) and ports(cell_at_grid(grid)).size() < 4:
			_connect(cell, direction, rng)
	_choose_endpoints(rng)
	_place_relics(rng)


func _place_relics(rng: RandomNumberGenerator) -> void:
	var dead_ends: Array[Vector2i] = []
	for index in _ports.size():
		if _ports[index].size() == 1:
			var cell := _cell(index)
			if cell != start and cell != finish:
				dead_ends.append(cell)
	var first_kind := rng.randi_range(0, Relic.Kind.size() - 1)
	for i in RELIC_COUNT:
		var draw := rng.randi_range(i, dead_ends.size() - 1)
		var cell := dead_ends[draw]
		dead_ends[draw] = dead_ends[i]
		dead_ends[i] = cell
		relics[cell] = (first_kind + i) % Relic.Kind.size()


func _carve_block(origin: Vector3i, rng: RandomNumberGenerator) -> Vector2i:
	var axes := AXES.duplicate()
	for i in range(2,0,-1):
		var j := rng.randi_range(0,i)
		var saved: Vector3i = axes[i]
		axes[i] = axes[j]
		axes[j] = saved
	var free_corners: Array[Vector3i] = []
	for index in 8:
		var candidate := Vector3i(index & 1, (index >> 1) & 1, (index >> 2) & 1)
		if ports(cell_at_grid(origin + candidate)).is_empty():
			free_corners.append(candidate)
	var corner := free_corners[rng.randi_range(0, free_corners.size() - 1)]
	var at := origin + corner
	# This Gray-code path visits each corner once through a shared face.
	for axis: int in [0,1,0,2,0,1,0]:
		var step: Vector3i = axes[axis]
		if (at-origin) * step != Vector3i.ZERO:
			step = -step
		_connect(cell_at_grid(at),step,rng)
		at += step
	return cell_at_grid(origin + corner)


func _join_blocks(rng: RandomNumberGenerator) -> void:
	var stack: Array[Vector3i] = [Vector3i.ZERO]
	var visited := {Vector3i.ZERO: true}
	var directions := [Vector3i.LEFT,Vector3i.RIGHT,Vector3i.UP,Vector3i.DOWN,Vector3i.FORWARD,Vector3i.BACK]
	while not stack.is_empty():
		var block := stack.back() as Vector3i
		var options: Array[Vector3i] = []
		for face: Vector3i in directions:
			var other := block+2*face
			if _inside(other) and not visited.has(other):
				options.append(face)
		if options.is_empty():
			stack.pop_back()
			continue
		var face := options[rng.randi_range(0,options.size()-1)]
		var side := rng.randi_range(0,1)
		# Each macro face reserves two possible corners: y=z for X exits,
		# x=z for Y exits, x!=y for Z exits. No corner satisfies all three,
		# so a room gains at most two outside links on top of its local path.
		var corner: Vector3i
		if face.x:
			corner = Vector3i(int(face.x>0),side,side)
		elif face.y:
			corner = Vector3i(side,int(face.y>0),side)
		else:
			corner = Vector3i(side,1-side,int(face.z>0))
		_connect(cell_at_grid(block+corner), face, rng)
		var next := block+2*face
		visited[next] = true
		stack.append(next)


# Eight rows fold back and forth on each storey. Adjacent addresses in the
# 64×64 plan remain adjacent in space even where a row changes elevation.
static func grid_of(cell: Vector2i) -> Vector3i:
	@warning_ignore("integer_division")
	var storey := cell.y / DEPTH
	var z := cell.y % DEPTH
	return Vector3i(cell.x, storey, z if storey % 2 == 0 else DEPTH-1-z)


static func cell_at_grid(grid: Vector3i) -> Vector2i:
	var row := grid.z if grid.y % 2 == 0 else DEPTH-1-grid.z
	return Vector2i(grid.x, grid.y * DEPTH + row)


static func _inside(grid: Vector3i) -> bool:
	return grid == grid.clamp(Vector3i.ZERO, VOLUME - Vector3i.ONE)


static func _index(cell: Vector2i) -> int:
	return cell.y * SIZE + cell.x


static func _cell(index: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(index % SIZE, index / SIZE)


func _connect(cell: Vector2i, face: Vector3i, rng: RandomNumberGenerator) -> void:
	var count := rng.rand_weighted(PackedFloat32Array([.58,.31,.11])) + 1
	var zones := PackedInt32Array()
	while zones.size() < count:
		var zone := rng.randi_range(0,8)
		if zone not in zones:
			zones.append(zone)
	zones.sort()
	var other := cell_at_grid(grid_of(cell) + face)
	_ports[_index(cell)][face] = zones
	_ports[_index(other)][-face] = zones


func ports(cell: Vector2i) -> Dictionary:
	return _ports[_index(cell)]


func neighbours(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var grid := grid_of(cell)
	for face: Vector3i in ports(cell):
		result.append(cell_at_grid(grid + face))
	return result


func distance_from(cell: Vector2i) -> int:
	return distances[_index(cell)]


func _choose_endpoints(rng: RandomNumberGenerator) -> void:
	finish = _cell(rng.randi_range(0, SIZE*SIZE-1))
	distances.resize(SIZE * SIZE)
	distances.fill(-1)
	distances[_index(finish)] = 0
	var queue: Array[Vector2i] = [finish]
	var candidates: Array[Vector2i] = []
	var farthest := finish
	var finish_grid := grid_of(finish)
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		var distance := distance_from(cell)
		var offset := (grid_of(cell) - finish_grid).abs()
		if offset.y >= 2 and offset.z >= 2 and offset.x >= 4:
			farthest = cell
			if distance >= 42 and distance <= 54:
				candidates.append(cell)
		for next in neighbours(cell):
			var index := _index(next)
			if distances[index] < 0:
				distances[index] = distance + 1
				queue.append(next)
	start = farthest if candidates.is_empty() else candidates[rng.randi_range(0,candidates.size()-1)]
