"""Rebuild the suspended surveying instrument and the pierced bridge lanterns in Blender."""
import math
import pathlib
import bpy
from mathutils import Vector

OUTPUT = pathlib.Path(__file__).resolve().parents[1] / 'models'
OUTPUT.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

def metal(name, color, metallic, roughness, emission=0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Metallic"].default_value = metallic
    p.inputs["Roughness"].default_value = roughness
    if emission:
        p.inputs["Emission Color"].default_value = (*color, 1)
        p.inputs["Emission Strength"].default_value = emission
    return m

bronze = metal("Brushed ochre bronze", (.26,.128,.042), .66,.38)
edge = metal("Worn polished lip", (.58,.331,.119), .72,.28)
iron = metal("Black scale", (.079,.072,.06), .58,.49)
ember = metal("Wick behind mica", (1,.39,.09), .09,.35,3.2)

def finish(m, smooth=False):
    ob = bpy.context.object
    ob.data.materials.append(m)
    if smooth:
        for f in ob.data.polygons:
            f.use_smooth=True
    return ob

def lathe(profile, mat, n=72):
    vs=[]; fs=[]
    for radius,z in profile:
        for i in range(n):
            a=i*math.tau/n
            vs.append((radius*math.cos(a),radius*math.sin(a),z))
    for k in range(len(profile)-1):
        for i in range(n):
            j=(i+1)%n
            fs.append((k*n+i,k*n+j,(k+1)*n+j,(k+1)*n+i))
    me=bpy.data.meshes.new("Turned profile")
    me.from_pydata(vs,[],fs)
    ob=bpy.data.objects.new(mat.name,me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
    for f in me.polygons:
        f.use_smooth=True
    return ob

def ring(center, radius, thickness, normal, mat, segments=88):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments,minor_segments=8,location=center,major_radius=radius,minor_radius=thickness)
    ob=finish(mat,True)
    ob.rotation_euler=Vector(normal).to_track_quat("Z","Y").to_euler()
    return ob

def strut(a,b,r,mat,n=12):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cylinder_add(vertices=n, radius=r, depth=(b-a).length,location=(a+b)/2)
    ob=finish(mat,True)
    ob.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()

def export(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
    bpy.ops.object.join()
    bpy.context.object.name=name
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT/(name+".glb")), export_format='GLB',use_selection=True, export_animations=False)
    bpy.ops.object.delete(use_global=False)

# An astrolabe surrounds a turned plumb bob. Short ticks are cast into its meridian.
lathe([(.001,-3.3),(.25,-2.42),(.55,-1.60),(.62,-1.46),(.64,-1.40),(.62,-1.34),(.54,-1.34),(.56,-1.23),(.72,-1.05),(.76,-.91),(.73,-.76),(.57,-.61),(.37,-.56),(.25,-.42),(.16,-.22),(.14,1.8)],bronze)
for z,r in [(-1.42,.638),(-.94,.758),(-.81,.747),(-.57,.39),(-.29,.19)]:
    ring((0,0,z),r,.025,(0,0,1),edge,64)
for norm,r,t,m in [((.16,-1,.09),2.24,.09,bronze),((.16,-1,.09),2.37,.032,edge),((.83,.43,.16),2.13,.054,edge),((.12,-.18,1),2.16,.083,iron),((-.42,.83,.51),2.04,.045,bronze)]:
    ring((0,0,0),r,t,norm,m)
norm=Vector((.16,-1,.09)).normalized()
hor=norm.cross(Vector((0,0,1))).normalized()
up=norm.cross(hor)
for i in range(60):
    a=i*math.tau/60
    radial=hor*math.cos(a)+up*math.sin(a)
    strut(radial*2.25, radial*(2.52 if i%5==0 else 2.36),.026,edge,6)
strut((0,0,1.6),(0,0,2.9),.095,bronze)
for i in range(18):
    ob=ring((0,0,2.9+i*.39),.16,.039,(1 if i%2 else 0,0 if i%2 else 1,0),iron,18)
    # Local Y of the torus is the vertical axis for these orientations.
    ob.scale.y=1.61
strut((0,0,9.7),(0,0,24),.053,iron,8)
export("meridian")

lathe([(.01,0),(.28,0),(.28,.12),(.23,.16),(.19,.19),(.14,.31),(.112,.4),(.11,.94),(.15,1.0),(.15,1.08),(.10,1.12)],iron,32)
lathe([(.10,1.10),(.20,1.18),(.20,1.24),(.17,1.25),(.17,1.31)],bronze,32)
lathe([(.01,1.29),(.13,1.29),(.167,1.37),(.15,1.65),(.105,1.77),(.01,1.78)],ember,24)
for i in range(6):
    a=math.tau*i/6
    strut((.18*math.cos(a),.18*math.sin(a),1.23),(.165*math.cos(a),.165*math.sin(a),1.78),.019,iron,8)
lathe([(.01,1.76),(.19,1.76),(.215,1.79),(.217,1.82),(.159,1.84),(.07,1.95),(.025,2.01),(.001,2.04)],bronze,32)
ring((0,0,1.51),.168,.017,(0,0,1),bronze,32)
export("vigil")

# Hollow bronze bell with a lip, a crown and a loose clapper visible from below.
lathe([(1.9,-1.4),(2.0,-1.36),(2.06,-1.29),(2.06,-1.20),(1.93,-1.13),
       (1.69,-.90),(1.52,-.54),(1.34,.13),(1.17,1.04),(1.06,1.42),
       (.93,1.57),(.53,1.70),(.10,1.70),(.10,1.56),(.85,1.41),
       (.99,1.26),(1.10,.91),(1.24,.08),(1.42,-.62),(1.62,-1.06),(1.9,-1.4)],bronze)
for z,r in [(-1.22,2.05),(-.94,1.75),(-.78,1.64),(1.05,1.17),(1.13,1.15),(1.39,1.07)]:
    ring((0,0,z),r,.031,(0,0,1),edge)
for i in range(12):
    a=i*math.tau/12
    ob=ring((1.20*math.cos(a),1.20*math.sin(a),.82),.125,.022,(math.cos(a),math.sin(a),.18),edge,18)
    ob.scale.y=1.29
for i in range(4):
    a=i*math.pi/2
    ring((.34*math.cos(a),.34*math.sin(a),1.84),.26,.065,(-math.sin(a),math.cos(a),0),iron,24)
strut((0,0,-1.64),(0,0,1.55),.105,iron)
lathe([(.001,-1.96),(.21,-1.87),(.28,-1.75),(.27,-1.60),(.18,-1.48),(.1,-1.4)],iron,32)
for i in range(13):
    ob=ring((0,0,2.14+i*.38),.16,.043,(i%2,(i+1)%2,0),iron,18)
    ob.scale.y=1.57
strut((0,0,6.8),(0,0,32),.075,iron,8)
export("passing_bell")

# A distant surveyor under a heavy overcoat. The irregular section breaks the folds.
cloth=metal("Soot black wool",(.030,.032,.029),.0,.95)
lining=metal("Inside the hood",(.011,.012,.012),.0,.97)
def garment(levels,mat):
    n=36
    vs=[]; faces=[]
    for z,rx,ry,cx,cy in levels:
        for i in range(n):
            a=i*math.tau/n
            w=1+.085*math.sin(a*7+.4)+.048*math.cos(a*5+z)
            vs.append((cx+rx*w*math.cos(a),cy+ry*w*math.sin(a),z))
    for j in range(len(levels)-1):
        for i in range(n):
            faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    m=bpy.data.meshes.new("Folded cloth")
    m.from_pydata(vs,[],faces)
    ob=bpy.data.objects.new(mat.name,m)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
for side in (-1,1):
    strut((side*.083,side*.044,.04),(side*.075,side*.05,.66),.069,lining)
garment([(.16,.245,.15,0,.035),(.32,.246,.15,0,.03),(.90,.175,.124,-.01,0),(1.24,.202,.143,.008,0),
         (1.41,.245,.147,.02,-.008),(1.48,.216,.135,.018,0),(1.54,.08,.087,.018,0)],cloth)
garment([(1.47,.112,.119,.02,-.018),(1.56,.139,.146,.02,-.032),(1.69,.138,.139,.02,-.018),
         (1.785,.109,.111,.015,.001),(1.82,.045,.079,.015,0),(1.83,.001,.002,.007,0)],lining)
export("surveyor")
