"""Build the fossil, open ammonite, split egg and folded flying ray for the natural atlas."""
import math
from pathlib import Path

import bpy
from mathutils import Vector

DEST = Path(__file__).resolve().parent
TAU = math.tau
bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, rgb, metal=0.0, rough=.62):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (*rgb, 1)
    bsdf.inputs['Roughness'].default_value = rough
    bsdf.inputs['Metallic'].default_value = metal
    mat.use_backface_culling = False
    return mat


ivory = material('Old baleen', (.57,.50,.35))
ochre = material('Tooth roots', (.23,.17,.095))
pearl = material('Nacre', (.63,.54,.48),.26,.37)
copper = material('Mineral seam', (.40,.19,.085),.33,.55)
blue = material('Stone blue', (.16,.29,.32),.19,.49)
shell = material('Mineral eggshell',(.52,.59,.48),.06,.74)
egglip = material('Chalk fracture',(.82,.72,.50),0,.8)
paper = material('Graphite paper',(.11,.15,.19),.08,.7)
silver = material('Silver folds',(.53,.55,.52),.18,.58)
rust = material('Vermilion reverse',(.43,.16,.095),.06,.64)


def surface(name, verts, faces, materials, face_mats=(), smooth=False):
    mesh=bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    ob=bpy.data.objects.new(name,mesh)
    bpy.context.collection.objects.link(ob)
    for mat in materials:
        mesh.materials.append(mat)
    for i,poly in enumerate(mesh.polygons):
        poly.use_smooth=smooth
        if face_mats:
            poly.material_index=face_mats[i]
    return ob


def ellipsoid(center, size, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=center)
    obj = bpy.context.object
    obj.scale=size
    obj.data.materials.append(mat)
    for f in obj.data.polygons:
        f.use_smooth=True


def tube(points, radii, mat, sides=10):
    verts=[]; faces=[]
    pts=[Vector(p) for p in points]
    for i,p in enumerate(pts):
        tangent=(pts[min(len(pts)-1,i+1)]-pts[max(0,i-1)]).normalized()
        ref=Vector((0,0,1)) if abs(tangent.z)<.89 else Vector((1,0,0))
        n=tangent.cross(ref).normalized()
        b=tangent.cross(n)
        for j in range(sides):
            a=TAU*j/sides
            verts.append(p+radii[i]*(math.cos(a)*n+math.sin(a)*b))
    for i in range(len(points)-1):
        for j in range(sides):
            k=(j+1)%sides
            faces.append((i*sides+j,i*sides+k,(i+1)*sides+k,(i+1)*sides+j))
    faces += [tuple(reversed(range(sides))),tuple(range(len(verts)-sides,len(verts)))]
    return surface('Carved curve',verts,faces,[mat],smooth=True)


def export(name):
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
    bpy.ops.object.join()
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bpy.context.object.name=name
    bpy.ops.export_scene.gltf(filepath=str(DEST/(name+'.glb')),export_format='GLB',
                              use_selection=True,export_animations=False,export_yup=True)
    bpy.ops.object.delete()


# Toothed cetacean skull. The open lower jaws and orbital loops retain their silhouettes.
ellipsoid((0,.94,.45),(1.22,1.55,1.08),ivory)
for side in (-1,1):
    def curve(pts, rs, mat=ivory):
        tube([(x*side,y,z) for x,y,z in pts],rs,mat)
    curve([(.32,1.9,.48),(1.13,1.64,.73),(1.79,.91,.55),(1.84,.33,.06),
           (1.52,-.08,-.20),(.94,.13,-.28),(.50,.72,.04)],
          [.50,.47,.31,.25,.26,.34,.46])
    curve([(.32,1.62,.26),(.66,.87,.30),(.89,.16,.10),(.68,-.91,-.11),(.41,-2.5,-.24),(.12,-4.11,-.36)],
          [.54,.52,.47,.37,.27,.09])
    curve([(1.24,1.01,-.40),(1.39,.71,-.70),(1.21,.22,-.94),(.99,-1.08,-1.22),
           (.62,-2.68,-1.39),(.15,-4.00,-1.18)],[.30,.35,.29,.22,.15,.07])
    for i in range(14):
        t=i/14
        x=.80*(1-t)+.14
        y=-.2-3.55*t
        z=-.15-.22*t
        curve([(x,y,z),(x*1.02,y-.035,z-.16),(x*1.05,y-.07,z-.34)], [.071,.060,.013],ochre)
    curve([(.16,1.67,1.03),(.37,1.21,1.59),(.29,.4,1.48),(.19,-.59,.72),(.08,-2.37,.11)],
          [.25,.20,.17,.115,.04])
export('baleen_skull')

# Half a logarithmic nautilus shell, its outer case cut away to reveal curved septa.
N=160; sections=15
verts=[]; faces=[]; indices=[]
def shell_pt(i,phi):
    t=i/N
    angle=t*TAU*2.42+.75
    r=.065*math.exp(4.26*t)
    w=r*.35
    radial=r+w*math.cos(phi)
    return Vector((radial*math.cos(angle), w*math.sin(phi)*1.18, radial*math.sin(angle)))
for i in range(N+1):
    for j in range(sections+1):
        verts.append(shell_pt(i,math.pi*j/sections))
for i in range(N):
    for j in range(sections):
        a=i*(sections+1)+j
        faces.append((a,a+1,a+sections+2,a+sections+1))
        indices.append(1 if i%13 in (0,1) else 0)
surface('Cut shell',verts,faces,[pearl,copper],indices,True)
for phi in [0,math.pi]:
    pts=[shell_pt(i,phi) for i in range(N+1)]
    tube(pts,[.014+.055*(i/N)**2 for i in range(N+1)],copper,7)
for i in range(10,N,5):
    pts=[shell_pt(i,math.pi*j/12) for j in range(13)]
    inner,outer=pts[-1],pts[0]
    ts=[j/13 for j in range(14)]
    wall=[inner.lerp(outer,t)+Vector((-.06*math.sin(math.pi*t),-.32*(i/N)**2*math.sin(math.pi*t),.04)) for t in ts]
    idx=surface('Curved siphuncle',[*wall,*pts], [tuple(range(len(wall)+len(pts)))], [blue if i%10==0 else pearl])
    tube(wall,[.014+.035*(i/N)**2]*len(wall),copper,7)
export('ammonite')

# Hollow egg section with an angular broken upper lip, thick enough to catch light.
n=48; rows=16; verts=[]; faces=[]; ix=[]
for layer in range(2):
    for h in range(rows+1):
        for i in range(n):
            a=TAU*i/n
            top=1.88+.12*math.sin(7*a)+.15*math.sin(13*a+.7)+.12*math.sin(i*7.3)
            lat=.025+(top-.025)*h/rows
            z=-1.3*math.cos(lat)
            rad=math.sin(lat)*(1-.14*math.sin(lat-math.pi/2))*(1-.065*layer)
            verts.append((rad*math.cos(a),rad*math.sin(a),z))
    origin=layer*(rows+1)*n
    for j in range(rows):
        for i in range(n):
            f=(origin+j*n+i,origin+j*n+(i+1)%n,origin+(j+1)*n+(i+1)%n,origin+(j+1)*n+i)
            faces.append(f if layer==0 else tuple(reversed(f)))
            ix.append(layer)
for i in range(n):
    a=rows*n+i;b=rows*n+(i+1)%n
    faces.append((a,b,b+n*(rows+1),a+n*(rows+1)));ix.append(1)
surface('Split shell',verts,faces,[shell,egglip],ix,True)
export('hatched')

# Two-tone ray with a narrow thorax, creased wings and a long split tail.
v=[(0,-2.3,-.22),(0,-.25,.5),(0,1.33,.09),(0,3.5,-.58)]
faces=[]; mats=[]
for s in (-1,1):
    start=len(v)
    v.extend([(s*.45,-1.3,0),(s*1.1,-.7,.11),(s*3.6,-.85,.91),
              (s*2.4,.59,.21),(s*1.27,1.03,-.20),(s*.28,1.4,-.1)])
    a,b,c,d,e,f=range(start,start+6)
    group=[(0,a,1),(a,b,1),(b,c,1),(c,d,1),(1,d,e),(1,e,2),(2,e,f),(2,f,3)]
    faces.extend(group if s<0 else [tuple(reversed(face)) for face in group])
    mats.extend([1,0,1,0,2,1,0,2])
surface('Flying fold',v,faces,[paper,silver,rust],mats)
export('paper_ray')
