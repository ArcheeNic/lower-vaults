"""Build the eccentric drive of the ironworks. The shaft lies on Blender's Z axis."""
from pathlib import Path
import math
import bpy
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
def alloy(name, rgb, metallic):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*rgb, 1)
    p.inputs["Metallic"].default_value = metallic
    p.inputs["Roughness"].default_value = .47
    return m

oxide = alloy("Red iron oxide", (.22,.061,.021), .63)
cast = alloy("Cast iron", (.083,.095,.104), .68)
brass = alloy("Lubricated bearing", (.43,.256,.085), .78)
cut = alloy("Ground tooth", (.31,.33,.31), .74)

def paint(m):
    ob=bpy.context.object
    ob.data.materials.append(m)
    return ob

def shell(r, width, z, mat):
    bpy.ops.mesh.primitive_cylinder_add(vertices=72,radius=r,depth=width,location=(0,0,z))
    return paint(mat)

def annulus(inside,outside,z,depth,mat):
    n=96
    rings=[(inside,z-depth*.5),(outside-.07,z-depth*.5),(outside,z-depth*.5+.065),
           (outside,z+depth*.5-.065),(outside-.07,z+depth*.5),(inside,z+depth*.5)]
    vs=[];faces=[]
    for r,h in rings:
        for i in range(n):
            a=i*math.tau/n
            vs.append((r*math.cos(a),r*math.sin(a),h))
    for j in range(len(rings)):
        for i in range(n):
            k=(i+1)%n; l=(j+1)%len(rings)
            faces.append((j*n+i,j*n+k,l*n+k,l*n+i))
    m=bpy.data.meshes.new("Rolled flange")
    m.from_pydata(vs,[],faces)
    obj=bpy.data.objects.new(mat.name,m)
    bpy.context.collection.objects.link(obj)
    m.materials.append(mat)

def bar(a,b,w,thickness,mat):
    a,b=Vector(a),Vector(b)
    bpy.ops.mesh.primitive_cube_add(size=1,location=(a+b)*.5)
    obj=paint(mat)
    obj.scale=(w,thickness,(b-a).length)
    obj.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()

def radial(r,angle,z):
    return (r*math.cos(angle),r*math.sin(angle),z)

annulus(3.82,4.58,0,.87,oxide)
annulus(4.17,4.65,.44,.17,cut)
annulus(4.17,4.65,-.44,.17,cut)
annulus(3.64,3.86,0,.96,cast)
annulus(1.03,1.32,0,1.13,oxide)
shell(1.03,1.53,0,cast)
shell(.68,1.76,0,brass)
shell(.36,2.46,0,cut)
for i in range(10):
    a=math.tau*i/10
    for sign in (-1,1):
        bar(radial(1.18,a,.0),radial(3.85,a+sign*.152,.0),.23,.30,oxide)
    for side in (-1,1):
        xyz=radial(4.39,a,side*.55)
        bpy.ops.mesh.primitive_cylinder_add(vertices=6,radius=.112,depth=.12,location=xyz)
        paint(brass)
for i in range(52):
    a=i*math.tau/52
    bpy.ops.mesh.primitive_cube_add(size=1,location=radial(4.74,a,0))
    obj=paint(cast)
    obj.scale=(.39,.30,.72)
    obj.rotation_euler.z=a
bpy.ops.object.select_all(action="SELECT")
bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
bpy.ops.object.join()
bpy.context.scene.cursor.location=(0,0,0)
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
bpy.context.object.name="Crankwheel"
bpy.ops.export_scene.gltf(filepath=str(Path(__file__).resolve().parents[1]/"models"/"crankwheel.glb"),use_selection=True,export_format="GLB",export_animations=False)
