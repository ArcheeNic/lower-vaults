extends Node3D

static var iron: StandardMaterial3D
static var mica: StandardMaterial3D
static var cube := BoxMesh.new()
var shutter := Node3D.new()
var time := 0.0

func build(target:Vector3,index:int) -> void:
	if not iron:
		iron=StandardMaterial3D.new()
		iron.albedo_color=Color("403f3e")
		iron.metallic=.55
		iron.roughness=.72
		mica=StandardMaterial3D.new()
		mica.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mica.albedo_color=Color("a7a49a")
	time=index*.7
	var source:=target+Vector3(-6.8,10.8,3.7)
	position=source
	basis=Basis.looking_at(source.direction_to(target),Vector3.UP)
	var lamp:=SpotLight3D.new()
	lamp.spot_range=23.
	lamp.spot_angle=24.
	lamp.spot_angle_attenuation=.65
	lamp.spot_attenuation=.65
	lamp.light_color = Color("e7d3ab") if index in [4,7,12] else Color("d0dfee")
	lamp.light_energy=12.5
	lamp.shadow_enabled=true
	lamp.shadow_bias=.025
	lamp.light_volumetric_fog_energy=3.4
	lamp.set_meta("steady_power",lamp.light_energy)
	lamp.add_to_group("scene_lights")
	add_child(lamp)
	var grating:=Node3D.new()
	add_child(grating)
	grating.position.z=-1.72
	grating.add_child(shutter)
	for side in [-1.,1.]:
		_plate(grating,Vector3(side*.89,0,0),Vector3(.13,1.97,.16),iron)
		_plate(grating,Vector3(0,side*.93,0),Vector3(1.72,.11,.16),iron)
	for i in range(-2,3):
		_plate(shutter,Vector3(i*.33,0,0),Vector3(.12,1.84,.14),iron)
	# A suspended inspection lantern. The stay runs to the far side of the nave.
	var base:=transform.affine_inverse()
	var anchor_a:Vector3=base*Vector3(-27,source.y+6.,source.z-.8)
	var anchor_b:Vector3=base*Vector3(27,source.y+4.5,source.z+1.1)
	var joint:Vector3=base*(source+Vector3.UP*1.3)
	_stay(anchor_a,joint,.085)
	_stay(joint,anchor_b,.085)
	_stay(joint,Vector3(0,.42,.24),.055)
	for side in [-1.,1.]:
		_plate(self,Vector3(side*.39,0,.21),Vector3(.09,.91,.65),iron)
		_plate(self,Vector3(0,side*.41,.21),Vector3(.80,.09,.65),iron)
	_plate(self,Vector3(0,0,.48),Vector3(.72,.72,.14),iron)
	_plate(self,Vector3(0,0,.075),Vector3(.39,.39,.04),mica)

func _stay(a:Vector3,b:Vector3,width:float) -> void:
	var link:=MeshInstance3D.new()
	link.mesh=cube
	link.material_override=iron
	link.transform=Transform3D(Basis.looking_at(a.direction_to(b),Vector3.UP).scaled_local(Vector3(width,width,a.distance_to(b))),(a+b)*.5)
	add_child(link)

func _plate(parent:Node3D,at:Vector3,size3:Vector3,mat:Material) -> void:
	var m:=MeshInstance3D.new()
	m.mesh=cube
	m.material_override=mat
	m.position=at
	m.scale=size3
	parent.add_child(m)

func _process(delta:float) -> void:
	time+=delta
	shutter.rotation.z=.16*sin(time*.27)
