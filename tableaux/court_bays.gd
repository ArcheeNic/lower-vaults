extends RefCounted

const SIDES := [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]


static func build(room: Node3D, id: int) -> void:
	var wells: Array[Rect2] = []
	for face: Vector3i in [Vector3i.UP, Vector3i.DOWN]:
		for zone: int in room.ports.get(face, []):
			wells.append(room._well_rect(zone).grow(1.1))
	for sector: Vector2i in room._courts:
		var rect: Rect2 = room._sector_rect(sector, room.COURT_EDGES)
		var variant := sector.x * 3 + sector.y + id
		# A single screen straddles each shared edge. Different offsets leave
		# a view past one end of the screen into the next bay.
		for axis: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			if room.has_court(sector + axis):
				_fit(room, id, rect, axis, variant, wells, false)
		# At the head of a court the rim would otherwise dissolve into fog.
		# Frame one closed edge, preserving the socket and the view of the drop.
		for i in SIDES.size():
			var side: Vector2i = SIDES[(i + variant) % SIDES.size()]
			if room.has_court(sector + side):
				continue
			var face := Vector3i(side.x, 0, side.y)
			var has_socket := false
			for zone: int in room.ports.get(face, []):
				if room._port_sector(face, zone) == sector:
					has_socket = true
					break
			if not has_socket and _fit(room, id, rect, side, variant + 1, wells, true):
				break


static func _fit(room: Node3D, id: int, rect: Rect2, side: Vector2i, variant: int, wells: Array[Rect2], rim: bool) -> bool:
	var normal := Vector2(side)
	var along := Vector2(-side.y, side.x)
	var edge := rect.get_center() + normal * rect.size * .5
	if rim:
		edge -= normal * .67
	var half_size := normal.abs() * .55 + along.abs() * 2.48
	var hand := 1. if variant % 2 else -1.
	for offset: float in [hand * 1.85, -hand * 2.55, 0., hand * 3.45]:
		var p := edge + along * offset
		var bounds := Rect2(p - half_size, 2. * half_size)
		var clear := true
		for well in wells:
			if well.intersects(bounds):
				clear = false
				break
		if not clear:
			continue
		# Keep the start landing and the finish door clear to either side.
		if bounds.intersects(Rect2(-1.65, 2.25, 3.3, 4.35)):
			continue
		var at := Vector3(p.x, 0, p.y)
		var tangent := Vector3(along.x, 0, along.y) * hand
		var inward := Vector3(-normal.x, 0, -normal.y)
		_build_screen(room, id, at, tangent, inward, variant)
		return true
	return false


static func _build_screen(room: Node3D, id: int, at: Vector3, along: Vector3, inward: Vector3, variant: int) -> void:
	var up := Vector3.UP
	var wide := along.abs()
	var deep := inward.abs()
	# The stepped face, its shelf ends and any protruding fittings remain
	# above a low, continuous footing with matching physical collision.
	var observatory := id in [2, 16, 18, 20, 24, 28]
	# On a broad floor the full meridian occurs once in five partitions.
	# Count actual placements: wells can rule out a nominal grid position.
	var form := int([1, 2, 0, 1, 2][(room.bay_lights.size() + id) % 5]) if observatory else 0
	var base_height := .38 if form == 2 else .68
	var post_width := .55 if form == 2 else (1.16 if form == 1 else .84)
	var post_height := 2.42 if form == 2 else (3.20 if form == 1 else 3.86)
	var casing: String = "iron" if form == 2 else room._skin
	room._solid_box(at + up * base_height * .5, wide * 4.9 + deep * 1.02 + up * base_height, casing)
	room.box(at + up * base_height, wide * 4.94 + deep * 1.07 + up * .13, room._handrail)
	var post := at - along * 1.85
	room._solid_box(post + up * post_height * .5, wide * post_width + deep * .9 + up * post_height, casing)
	room.box(post + up * post_height, wide * (post_width + .10) + deep * 1.07 + up * .16, room._handrail)
	if observatory and form == 1:
		# Two blackened leaves mask the light above and below an observing
		# slit; the opening runs through the full thickness of the wall.
		var mask := at + along * .45
		room._solid_box(mask + up * 1.08, wide * 3.58 + deep * .74 + up * 2.16, "basalt")
		room.box(mask + up * 2.18, wide * 3.62 + deep * .82 + up * .08, "brass")
		room._solid_box(mask + up * 2.96, wide * 3.58 + deep * .67 + up * .86, "basalt")
		for x: float in [-1.59, 1.59]:
			room.column(mask + along * x + up * 2.38, Vector3(.19, .40, .19), "brass")
		for j in 6:
			var vane := mask + along * (.29 + j * .23)
			room.box(vane + up * (3.48 + .045*j), wide * .09 + deep * .48 + up * (.22 + .09*j), "iron")
	elif observatory and form == 2:
		# The sloped transit bed has a brass sight tube, guide rail and
		# counterweight. Its diagonal can be read from across the court.
		for i in 4:
			var height := 1.10 + i * .55
			var step := at + along * (-.96 + i * .92)
			room._solid_box(step + up * height * .5, wide * .93 + deep * .76 + up * height, "stone")
			room.box(step + up * height, wide * .97 + deep * .82 + up * .14, "brass")
		var tail := at - along * 1.33 + up * 1.54
		var head := at + along * 1.97 + up * 3.69
		room.beam(tail, head, .36, .34, "iron")
		room.beam(head - (head-tail).normalized()*.65, head, .51, .49, "brass")
		room.ball(tail, Vector3(.51,.61,.51), "rust")
	elif observatory:
		var hub := at + along * .36 + up * 2.01
		var axis := Vector3.RIGHT if absf(along.x) > .5 else Vector3.BACK
		room.ring(hub, 1.38, .20, room._skin, axis * PI * .5)
		room.ring(hub, 1.13, .065, "brass", axis * PI * .5)
		room.beam(hub - along * 1.20 - up * .53, hub + along * 1.20 + up * .53, .14, .17, "brass")
		room.ball(hub, Vector3.ONE * .48, "pearl")
		var fin := at + along * 1.95
		room._solid_box(fin + up * 1.01, wide * .78 + deep * .82 + up * 2.02, room._skin)
	elif id in [6, 7, 12, 13, 14, 30, 32]:
		# On both faces, shelves step down from the solid end of the stack.
		for i in 3:
			var shelf := at + along * (-.90 + i * 1.22)
			var tiers := 4 - (i + variant % 2) / 2
			room.box(shelf + up * (tiers * .31 + .72), wide * 1.21 + up * (tiers * .62) + deep * .15, "wood")
			for j in tiers:
				var ledge := shelf + up * (.79 + j * .62)
				room.box(ledge, wide * 1.26 + deep * .88 + up * .10, "wood")
				for k in 3:
					var file := ledge + along * ((k - 1) * .34) + up * .26
					room.box(file, wide * .28 + deep * .73 + up * (.36 + .06 * ((i+j+k)%3)), "cloth" if k == 1 else "wood")
	elif id in [1, 3, 8, 9, 11, 15, 17, 25, 29]:
		# Return pipes and their collars change height across the partition.
		for i in 4:
			var foot := at + along * (-1.04 + i * .96)
			var height := 1.55 + .54 * ((i + variant) % 4)
			room.column(foot + up * (.66 + height * .5), Vector3(.70, height, .70), "rust")
			for h: float in [.82, .48 + height]:
				room.column(foot + up * h, Vector3(.87, .16, .87), "iron")
			room.cone(foot + up * (.73 + height), Vector3(.76, .21, .76), "brass")
	elif id in [19, 21, 22, 23, 26, 27, 31]:
		var stone := "salt" if id in [23, 26] else ("bone" if id in [19, 21, 22] else "moss")
		for i in 4:
			var foot := at + along * (-.95 + i * .91)
			var height := 1.65 + 1.35 * sin((i + .48) * PI / 4.)
			var tip := foot + up * (.69 + height) - along * .42
			room._part("outcrop", stone, foot.lerp(tip, .5) + up * .34, Vector3(.76, height, .68),
				Basis(Vector3.UP.cross(along), -.12))
			room.beam(tip - up * .20, tip + along * .46 + up * .17, .24, .28, stone)
	else:
		# Stepped masonry with a deep, open clerestory between the piers.
		var end := at + along * 1.66
		room._solid_box(end + up * 1.52, wide * 1.36 + deep * .91 + up * 3.04, room._skin)
		room._solid_box(at + up * 1.03, wide * 3.1 + deep * .72 + up * 2.06, room._skin)
		room.beam(post + up * 3.48, end + up * 3.48, .86, .42, room._skin)
		for x: float in [-.63, .07, .77]:
			room.column(at + along * x + up * 2.70, Vector3(.24, 1.34, .24), room._handrail)
		room.beam(post + up * 2.02, end + up * 2.02, .89, .16, room._handrail)
	var bracket := post + up * minf(2.60, post_height - .44)
	var lens := bracket + inward * .68
	room.beam(bracket, lens, .16, .15, "iron")
	room.box(lens, Vector3(.32, .46, .32), "pearl")
	for dy: float in [-.24, .24]:
		room.box(lens + up * dy, Vector3(.39, .07, .39), room._handrail)
	room.bay_lights.append(lens)
