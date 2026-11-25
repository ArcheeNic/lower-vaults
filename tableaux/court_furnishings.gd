extends RefCounted

# Built into the court's material batches. The recessed works have a continuous
# coping so neither the walker nor a pursuing monster can fall into the cut.
static func is_recessed(id: int) -> bool:
	return id in [1, 3, 8, 9, 11, 14, 15, 17, 20, 25, 26, 29]


static func footprint(id: int, center: Vector2) -> Rect2:
	var size := Vector2(5.8, 3.4) if is_recessed(id) else Vector2(4.8, 2.6)
	return Rect2(center - size * .5, size)


static func build(room: Node3D, id: int, bed: Rect2) -> void:
	var at := Vector3(bed.get_center().x, 0., bed.get_center().y)
	if is_recessed(id):
		_recess(room, bed)
		if id in [3, 9, 14, 15, 17, 25]:
			_drive(room, at, id)
		else:
			_cistern(room, at, id)
	elif id in [2, 16, 18, 24, 28]:
		_instrument(room, at, id)
	elif id in [19, 21, 22, 23, 27, 31]:
		_specimens(room, at, id)
	elif id in [0, 4, 5, 7, 10]:
		_tiers(room, at, id)
	else:
		_worktable(room, at, id)


static func _recess(room: Node3D, bed: Rect2) -> void:
	room._slab(bed, -1.65, .22, "basalt")
	var p := bed.position
	var end := bed.end
	var center := bed.get_center()
	for x: float in [p.x, end.x]:
		room._solid_box(Vector3(x, -.5, center.y), Vector3(.28, 2.3, bed.size.y + .28), room._skin)
		room.box(Vector3(x, .65, center.y), Vector3(.38, .10, bed.size.y + .38), room._handrail)
	for z: float in [p.y, end.y]:
		room._solid_box(Vector3(center.x, -.5, z), Vector3(bed.size.x - .28, 2.3, .28), room._skin)
		room.box(Vector3(center.x, .65, z), Vector3(bed.size.x - .38, .10, .38), room._handrail)


static func _drive(room: Node3D, at: Vector3, id: int) -> void:
	# A horizontal axle crosses the pit, seated in bearings at either end.
	var axle := at + Vector3.UP * .34
	room.beam(axle - Vector3.RIGHT * 2.83, axle + Vector3.RIGHT * 2.83, .24, .24, "iron")
	for side: float in [-1., 1.]:
		var foot := axle + Vector3.RIGHT * side * 2.2
		room.box(foot - Vector3.UP * .95, Vector3(.60, 2., .83), "basalt")
		room.column(foot, Vector3(.48, .56, .48), "brass", Vector3(0, 0, PI * .5))
	for i in 2:
		var hub := axle + Vector3.RIGHT * (-1.05 + i * 1.9)
		var radius := 1.47 if i == 0 else .91
		var rim := "wood" if id == 9 else "rust"
		room.ring(hub, radius, .14, rim, Vector3(0, 0, PI * .5))
		for spoke in 4:
			var angle := (spoke + .25 * i) * PI / 4.
			var offset := Vector3(0, cos(angle), sin(angle)) * radius
			room.beam(hub - offset, hub + offset, .13, .12, "iron")


static func _cistern(room: Node3D, at: Vector3, id: int) -> void:
	room.box(at - Vector3.UP * .42, Vector3(5.54, .12, 3.14), "glass")
	for i in 3:
		var post := at + Vector3(-1.85 + i * .60, 0, -.66)
		var h := 1.72 - i * .37
		room.column(post + Vector3.UP * (h * .5 - .45), Vector3(.19, h, .19), "brass")
		for j in 4:
			room.box(post + Vector3.UP * (h - .55 - j * .17), Vector3(.28, .055, .22), "salt")
	for i in 2:
		var outlet := at + Vector3(1.40 + i * .48, .18, .72 - i * .95)
		room.column(outlet - Vector3.UP * .23, Vector3(.56, .85, .56), "iron")
		room.ring(outlet + Vector3.UP * .20, .29, .075, "rust" if id == 11 else "stone")


static func _instrument(room: Node3D, at: Vector3, id: int) -> void:
	room._solid_box(at + Vector3.UP * .37, Vector3(3.1, .74, 2.4), "basalt")
	var hub := at + Vector3.UP * 1.75
	room.column(at + Vector3.UP * 1.06, Vector3(.36, .70, .36), "brass")
	if id == 18:
		for i in 3:
			var heel := at + Vector3((i - 1) * .94, .94, 0)
			room.box(heel, Vector3(.69, .38, .29), "brass")
			for sign_x: float in [-1., 1.]:
				var tine := heel + Vector3.RIGHT * sign_x * .26
				room.beam(tine, tine + Vector3.UP * (1.65 - i * .31), .16, .18, "brass")
	else:
		room.ball(hub, Vector3.ONE * .66, "iron")
		for i in 3:
			room.ring(hub, .83 + .14 * i, .047, "brass", Vector3(.35 + i * .56, .82 * i, .29))


static func _specimens(room: Node3D, at: Vector3, id: int) -> void:
	room._solid_box(at + Vector3.UP * .28, Vector3(4.6, .56, 2.55), room._skin)
	for i in 5:
		var p := at + Vector3((i - 2) * .82, .55, .33 * cos(i * 1.7))
		var height := .78 + .73 * sin((i + .35) * PI / 5.)
		if id in [19, 21, 22]:
			var tip := p + Vector3(0, height + .28, -.48)
			room.beam(p, tip, .18, .21, "bone")
			room.beam(tip, tip + Vector3(.13, .16, .61), .13, .14, "bone")
		elif id in [27, 31]:
			room.column(p + Vector3.UP * height * .5, Vector3(.18, height, .18), "moss")
			room.ball(p + Vector3.UP * height, Vector3(.91, .43, .80), "bone" if id == 27 else "pearl")
		else:
			room.cone(p + Vector3.UP * height * .5, Vector3(.64, height, .76), "glass", Vector3(0, 0, .16 * (i - 2)))


static func _tiers(room: Node3D, at: Vector3, id: int) -> void:
	room._solid_box(at + Vector3.UP * .28, Vector3(4.8, .56, 2.6), room._skin)
	room._solid_box(at + Vector3(0, .73, -.42), Vector3(4.35, .34, 1.57), room._skin)
	for x: float in [-1.7, 0., 1.7]:
		var seat := at + Vector3(x, .99, -.72)
		room.box(seat, Vector3(1.38, .17, .85), "wood" if id == 7 else "chalk")
		room.box(seat + Vector3(0, .43, -.38), Vector3(1.25, .86, .19), room._skin, Vector3(-.12, 0, 0))


static func _worktable(room: Node3D, at: Vector3, id: int) -> void:
	room._solid_box(at + Vector3.UP * .50, Vector3(4.55, 1., 2.36), "wood")
	room.box(at + Vector3.UP, Vector3(4.8, .14, 2.58), "wood")
	for side: float in [-1., 1.]:
		for i in 4:
			var drawer := at + Vector3((i - 1.5) * 1.02, .58, side * 1.19)
			room.box(drawer, Vector3(.94, .43, .09), "wood")
			room.box(drawer + Vector3(0, .03, side * .065), Vector3(.29, .06, .09), "brass")
	for i in 4:
		var file := at + Vector3((i - 1.5) * .93, 1.11, .37 * sin(i * 2.))
		for sheet in (2 + i % 3):
			room.box(file + Vector3.UP * sheet * .10, Vector3(.71, .09, .94), "cloth" if id == 13 else "chalk", Vector3(0, .11 * (i - sheet), 0))
