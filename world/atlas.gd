extends RefCounted

const Stone := preload("res://tableaux/stone_atlas.gd")
const Wild := preload("res://tableaux/wild_atlas.gd")
const ORIGINALS := ["Нижние своды","Приливная цистерна","Обратная обсерватория","Машинный зал"]
const COUNT := 32
var blocks := {}

func scene_at(cell:Vector2i) -> int:
	var offset := cell+Vector2i(4,2)
	var local := Vector2i(posmod(offset.x,8),posmod(offset.y,4))
	var block := Vector2i(floori(offset.x/8.),floori(offset.y/4.))
	if not blocks.has(block):
		if blocks.size()>=48:
			blocks.erase(blocks.keys()[0])
		blocks[block]=_plan(block)
	return blocks[block][local.y*8+local.x]

func _plan(block:Vector2i) -> Array[int]:
	var ids: Array[int]=[]
	for i in COUNT:
		ids.append(i)
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash(block)^230519
	for i in range(COUNT-1,0,-1):
		var j:=rng.randi_range(0,i)
		var other:=ids[j]
		ids[j]=ids[i]
		ids[i]=other
	# One mill per district. Its row rotates east-west, its column north-south:
	# even a straight walk crosses only one mill per 32 cells in either direction.
	_place(ids,8*posmod(block.x,4)+posmod(3*block.y+7,8),3)
	if block==Vector2i.ZERO:
		_place(ids,20,0)
		_place(ids,28,5)
		_place(ids,19,18)
		_place(ids,21,29)
		_place(ids,12,6)
	return ids

func _place(ids:Array[int],at:int,id:int) -> void:
	var source:=ids.find(id)
	ids[source]=ids[at]
	ids[at]=id

static func climate(id:int) -> int:
	if id<4: return id
	return Stone.CLIMATES[id-4] if id<18 else Wild.CLIMATES[id-18]

static func title(id:int) -> String:
	if id<4: return ORIGINALS[id]
	return Stone.TITLES[id-4] if id<18 else Wild.TITLES[id-18]
