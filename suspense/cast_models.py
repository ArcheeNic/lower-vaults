"""Regenerate the ten articulated presences with Blender in background mode."""
import math
from pathlib import Path

import bpy
from mathutils import Vector

OUT = Path(__file__).resolve().parents[1] / "models/presences"
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)


def vec(p):
    return Vector((p[0], -p[2], p[1]))


def mat(name, rgb, metal=0.0, rough=.78):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, 1)
    m.use_nodes = True
    node = m.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = (*rgb, 1)
    node.inputs["Metallic"].default_value = metal
    node.inputs["Roughness"].default_value = rough
    return m


wool = mat("Peat wool", (.092,.107,.112))
ink = mat("Lampblack", (.028,.034,.038))
linen = mat("Salt linen", (.39,.38,.30))
hide = mat("Cordovan leather", (.16,.075,.045))
green = mat("Petrol oilskin", (.071,.159,.148))
ochre = mat("Burnt ochre", (.28,.130,.052))
red = mat("Oxide velvet", (.24,.065,.043))
bronze = mat("Weathered brass", (.42,.255,.097), .56, .48)
iron = mat("Blued iron", (.13,.16,.177), .61, .54)
ivory = mat("Worn bone", (.61,.57,.43), .04)
lead = mat("Patinated lead", (.23,.27,.28), .54)
paper = mat("Vellum", (.57,.49,.32))
parts = {}
group = None


def part(name, pivot=(0,0,0)):
    global group
    group = name
    parts.setdefault(name, (pivot, []))


def obj(o, material, smooth=True):
    o.data.materials.append(material)
    if smooth:
        for face in o.data.polygons:
            face.use_smooth = True
    parts[group][1].append(o)


def ball(p, sizes, m):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=vec(p))
    o = bpy.context.object
    o.scale = (sizes[0],sizes[2],sizes[1])
    obj(o,m)


def rod(a,b,r,m,r2=None,n=12):
    a,b=vec(a),vec(b)
    d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=n, radius1=r, radius2=r if r2 is None else r2,
                                    depth=d.length,location=(a+b)*.5)
    o=bpy.context.object
    o.rotation_euler = d.to_track_quat("Z","Y").to_euler()
    obj(o,m)


def ring(p,r,bar,normal,m):
    bpy.ops.mesh.primitive_torus_add(major_segments=36, minor_segments=7, major_radius=r,
                                    minor_radius=bar,location=vec(p))
    o=bpy.context.object
    o.rotation_euler=vec(normal).to_track_quat('Z','Y').to_euler()
    obj(o,m)


def block(p,size,m):
    bpy.ops.mesh.primitive_cube_add(size=1,location=vec(p))
    o=bpy.context.object
    o.scale=(size[0],size[2],size[1])
    obj(o,m,False)


def surface(vertices, faces, material, smooth=False):
    mesh=bpy.data.meshes.new(material.name)
    mesh.from_pydata([vec(p) for p in vertices],[],faces)
    mesh.update()
    o=bpy.data.objects.new(material.name,mesh)
    bpy.context.collection.objects.link(o)
    obj(o,material,smooth)


def coat(rings,m,fold=.05):
    # The seam radii and the offsets of consecutive rings give every coat a different cut.
    n=28
    vs=[]
    for x,y,z,rx,rz in rings:
        for i in range(n):
            a=math.tau*i/n
            wave=1+fold*(math.sin(a*7+.6*y)+.35*math.cos(a*3-y))
            vs.append((x+rx*wave*math.cos(a),y,z+rz*wave*math.sin(a)))
    faces=[]
    for row in range(len(rings)-1):
        for i in range(n):
            j=(i+1)%n
            faces.append((row*n+i,(row+1)*n+i,(row+1)*n+j,row*n+j))
    faces.append(tuple(range(n)))
    faces.append(tuple(range(len(vs)-1,len(vs)-n-1,-1)))
    surface(vs,faces,m,True)


def leg(s,x,y,z,height,boot=ink):
    part("leg_l" if s<0 else "leg_r",(x,y,z))
    rod((x,y,z),(x+s*.022,y-height*.51,z+.025),.091,boot,.075)
    rod((x+s*.022,y-height*.51,z+.025),(x,y-height+.08,z),.072,boot,.055)
    sole = y-height
    coat([(x,sole+.015,z+.068,.086,.164),(x,sole+.044,z+.068,.086,.164),
          (x,sole+.1,z+.071,.078,.144),(x,sole+.15,z+.015,.063,.074)],boot,.023)
    block((x,sole+.027,z-.034),(.13,.054,.096),iron)


def head(x,y,z,size,m,mask=None):
    # Asymmetric hood, jaw, brow and nose read as volumes in a grazing light.
    # Garment and mask design changes by trade rather than reusing a painted face.
    slender = .59 if trade in ("watchman","scribe") else .74
    coat([(x,y-size*.84,z,size*.43,size*.42),
          (x,y-size*.22,z,size*slender,size*.72),
          (x,y+size*.46,z-size*.04,size*.83,size*.79),
          (x+.02,y+size*.83,z-size*.13,size*.68,size*.59),
          (x+.028,y+size*1.02,z-size*.31,size*.26,size*.28)],m,.052)
    if mask is None:
        return
    if trade in ("lantern","pilgrim","spindle","pall","frame"):
        skin = ink if trade in ("lantern","pilgrim","pall") else hide
        coat([(x+.012,y-size*.62,z+size*.38,size*.19,size*.40),
              (x,y-.025,z+size*.53,size*.49,size*.34),
              (x-.009,y+size*.31,z+size*.46,size*.51,size*.32)],skin,.032)
        for sign in [-1,1]:
            rod((x+sign*size*.62,y+size*.47,z+size*.42),
                (x+sign*size*.43,y-size*.52,z+size*.55),size*.124,m,size*.073)
        if trade == "pall":
            rod((x,y+size*.13,z+size*.68),(x,y-size*.51,z+size*.99),size*.12,lead,size*.02)
    else:
        plate = mask if trade not in ("bell","collector") else bronze
        coat([(x+.012,y-size*.90,z+size*.33,size*.15,size*.32),
              (x,y-size*.34,z+size*.49,size*.54,size*.36),
              (x,y+size*.41,z+size*.44,size*.62,size*.41)],plate,.018)
        for sign in [-1,1]:
            ball((x+sign*size*.25,y+.01,z+size*.815),(size*.105,size*.123,size*.055),ink)
        tip = size*1.31 if trade in ("scribe","collector") else size*.94
        rod((x,y+size*.24,z+size*.79),(x+.01,y-size*.38,z+tip),size*.127,plate,size*.041)



def visor(x,y,z,size):
    # A folded metal visor over the hood. The opening under the brow is a
    # literal gap between its lames, backed by a recessed black eye slit.
    def v(a,b,c): return (x+a*size,y+b*size,z+c*size)
    for side in [-1,1]:
        def face(points, metal):
            poly=[v(a*side,b,c) for a,b,c in points]
            surface(poly,[tuple(range(len(poly))),tuple(reversed(range(len(poly))))],metal)
        face([(0,.43,.99),(.66,.37,.70),(.77,.18,.66),(.47,.14,1.02),
              (.12,.09,1.22),(0,.17,1.28)],lead)
        face([(.06,.055,1.19),(.57,.12,.99),(.67,.02,.80),
              (.48,-.44,.87),(.20,-.69,1.07),(.07,-.40,1.22)],iron)
        face([(.05,.16,1.13),(.64,.21,.82),(.62,-.03,.84),(.04,-.03,1.13)],ink)
        rod(v(side*.61,.23,.85),v(side*.61,.23,.94),size*.064,bronze,n=6)
        for j in range(3):
            a=.23+j*.11
            rod(v(side*a,-.22,1.16-j*.055),v(side*(a+.035),-.41,1.105-j*.055),
                size*.019,ink,n=5)
    surface([v(0,.23,1.24),v(-.12,.04,1.18),v(0,-.39,1.51),v(.12,.04,1.18)],
            [(0,1,2),(0,2,3),(2,1,0),(3,2,0)],bronze)


def figure(x,h,cloak,hood,hem=.26):
    coat([(x,.27*h,0,hem*h*.50,.16*h),(x,.52*h,0,hem*h*.44,.125*h),
          (x,.68*h,-.008,.112*h,.083*h),(x,.78*h,0,.142*h,.092*h),
          (x,.82*h,0,.071*h,.058*h)],cloak,.095)
    # Cut overlapping gores on the bias. Their staggered tips and raised
    # centre seams cast separate shadows even when the fabric is backlit.
    for panel in range(13):
        angle = math.tau*panel/13
        twist = .08*math.sin(panel*3.7)
        bottom = h*(.224+.024*math.sin(2.1*panel))
        def edge(a, y, rx, rz):
            return (x+rx*h*math.cos(a),y,rz*h*math.sin(a))
        vertices = [edge(angle-.24,.575*h,hem*.46,.132),
                    edge(angle+.24,.575*h,hem*.46,.132),
                    edge(angle+.22+twist,bottom+.029*h,hem*.565,.167),
                    edge(angle-.19+twist,bottom,hem*.57,.172),
                    edge(angle+twist,.39*h,hem*.59,.183)]
        surface(vertices,[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],cloak)
    for i in range(4):
        y = (.61+.041*i)*h
        block((x+.025*h,y,.113*h),(.058*h,.011*h,.014*h),hide)
        rod((x+.044*h,y,.112*h),(x+.044*h,y,.129*h),.007*h,bronze,n=6)
    head(x,.907*h,0,.098*h,hood,ivory)
    if trade in ("lantern","bell","pall","spindle","frame"):
        visor(x,.907*h,0,.098*h)
    # Long seams, a shoulder cape and the outside edge of a deep, weighted pleat.
    coat([(x,.68*h,-.004,.147*h,.104*h),(x,.76*h,-.012,.145*h,.102*h),
          (x,.82*h,-.012,.075*h,.067*h)],cloak,.11)
    belt = hide if trade not in ("bell","frame") else wool
    coat([(x,.57*h,0,hem*h*.43,.129*h),(x,.595*h,0,hem*h*.42,.125*h)],belt,.025)
    if trade in ("bell","frame","spindle"):
        surface([(x-.09*h,.59*h,.124*h),(x+.10*h,.59*h,.124*h),
                 (x+.14*h,.25*h,.146*h),(x+.01*h,.22*h,.166*h),
                 (x-.11*h,.27*h,.15*h)],[(0,1,2,3,4),(4,3,2,1,0)],hide if trade=="bell" else linen)
    if trade in ("pilgrim","pall","scribe","lantern"):
        rod((x-.085*h,.785*h,.065*h),(x+.078*h,.578*h,.12*h),.027*h,belt,.018*h)



def arm(a,b,c,m):
    rod(a,b,.097,m,.078)
    rod(b,c,.084,m,.058)
    x,y,z=c
    coat([(x,y-.046,z,.048,.032),(x,y+.032,z,.061,.039),
          (x,y+.062,z-.009,.046,.036)],hide,.02)
    for i in range(4):
        knuckle=(x+(i-1.5)*.023,y-.032,z+.009)
        tip=(knuckle[0]+.007,y-.082-.012*math.sin(i),z+.026)
        rod(knuckle,tip,.014,hide,.009,n=7)
    rod((x-.046,y+.013,z),(x-.071,y-.032,z+.039),.017,hide,.012,n=7)


def export(name):
    for key,(pivot,objects) in parts.items():
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects: o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
        o=bpy.context.object
        o.name=key
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        bpy.context.scene.cursor.location=vec(pivot)
        bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+".glb")), export_format="GLB",
                              use_selection=True, export_animations=False, export_yup=True)
    bpy.ops.object.delete(use_global=False)
    parts.clear()


trade = "lantern"
# Lantern keeper. A hood cuts across the silver death mask; the left hand shields the wick.
part("body")
figure(0,2.58,wool,ink,.29)
coat([(0,.26,0,.32,.24),(0,.50,-.01,.34,.24),(0,1.45,0,.235,.19),(0,1.94,0,.32,.20)],wool,.105)
# The cape is pinned on one side. Each hanging strap has a metal keeper
# and a squared weight; the lantern illuminates the folds from below.
for side in [-1,1]:
    seam=[(side*.19,1.98,.138),(side*.24,1.78,.166),
          (side*.18,1.51,.171),(side*.245,1.16,.19),(side*.30,.68,.23)]
    for a,b in zip(seam,seam[1:]): rod(a,b,.010,hide,.008,n=6)
    for x,y,z in seam[1:]:
        rod((x,y,z),(x,y,z+.012),.018,bronze,n=6)
for i in range(3):
    x=-.17+i*.106
    end=.52+i*.082
    surface([(x-.025,1.49,.192),(x+.025,1.49,.192),(x+.045,end,.273),
             (x-.011,end-.05,.278)],[(0,1,2,3),(3,2,1,0)],hide)
    block((x+.013,end+.06,.28),(.062,.019,.023),lead)
arm((.29,1.96,0),(.35,1.64,0),(.41,1.66,.12),wool)
arm((-.29,1.94,0),(-.31,1.56,.02),(-.18,1.35,.12),wool)
for s in [-1,1]: leg(s,s*.125,.68,0,.67)
part("equipment",(.41,1.66,.12))
ring((.41,1.56,.12),.085,.017,(0,0,1),iron)
for yy in [1.23,1.47]: rod((.41,yy,.12),(.41,yy+.047,.12),.13,bronze,.106)
for sx in [-1,1]:
    for sz in [-1,1]:
        rod((.41+sx*.07,1.27,.12+sz*.075),(.41+sx*.07,1.48,.12+sz*.075),.012,bronze)
for yy in [1.28,1.335,1.445]:
    ring((.41,yy,.12),.111,.008,(0,1,0),iron)
for side in [-1,1]:
    rod((.41-.073,1.27,.12+side*.079),(.41+.073,1.47,.12+side*.079),.008,iron)
rod((.41,1.49,.12),(.41,1.536,.12),.099,bronze,.045,n=8)
export("lamplighter")

trade = "bell"
# Bell keeper. A carved yoke and a bell almost as broad as the crouched porter.
part("body")
figure(-.14,1.93,red,hide,.37)
arm((-.33,1.47,0),(-.50,1.40,.04),(-.49,1.70,.04),hide)
arm((.06,1.45,0),(.27,1.39,.08),(.34,1.71,.04),hide)
rod((-.73,1.78,0),(.90,1.93,0),.088,hide)
for s in [-1,1]: leg(s,-.14+s*.18,.66,0,.65)
part("equipment",(.61,1.91,0))
rod((.61,1.72,0),(.61,1.91,0),.045,bronze)
coat([(.61,.62,0,.43,.41),(.61,.70,0,.45,.42),(.61,.79,0,.36,.35),
      (.61,1.23,0,.23,.22),(.61,1.47,0,.14,.14),(.61,1.73,0,.07,.07)],bronze,.012)
ring((.61,.72,0),.42,.023,(0,1,0),bronze)
ball((.61,.60,0),(.09,.1,.09),iron)
export("bell_keeper")

trade = "collector"
# Ditch collector. A wicker pannier rides above six bowed, asynchronously placed limbs.
part("body")
ball((0,.69,0),(.41,.27,.49),green)
head(0,.88,.34,.185,hide,ivory)
for t in range(7):
    ring((0,.85+t*.055,-.15),.34-.010*abs(t-4),.022,(0,1,0),ochre)
for j in range(10):
    a=math.tau*j/10
    rod((.29*math.cos(a),.78,-.15+.29*math.sin(a)),(.34*math.cos(a),1.18,-.15+.34*math.sin(a)),.021,hide)
for s in [-1,1]:
    part("leg_l" if s<0 else "leg_r",(s*.24,.70,0))
    for i in range(3):
        z=-.40+i*.36
        a=(s*.24,.69,z*.7)
        b=(s*(.69+.09*(i%2)),.61,z+.11)
        c=(s*(.90-.07*i),.045,z+.27)
        rod(a,b,.069,green,.051)
        ball(b,(.057,.058,.058),bronze)
        rod(b,c,.050,hide,.032)
        rod(c,(c[0]-.08*s,.025,c[2]+.12),.033,ivory,.011)
export("collector")

trade = "pall"
# A lone standard-bearer carries the pall on a brass shoulder yoke.
part("body")
figure(0,1.82,ink,linen,.29)
rod((-.53,2.18,.08),(.53,2.18,.08),.036,bronze)
rod((.23,.22,.08),(.23,2.20,.08),.038,bronze)
arm((.18,1.39,0),(.32,1.16,.07),(.23,1.51,.08),wool)
arm((-.18,1.39,0),(-.28,1.13,.12),(.18,1.04,.08),wool)
for s in [-1,1]: leg(s,s*.14,.67,0,.66)
part("equipment",(0,2.14,0))
vs=[];faces=[]
for i in range(19):
    x=(i-9)*.086
    peak=.17*math.exp(-((abs(x)-.43)/.16)**2)
    for j in range(9):
        z=(j-4)*.095
        y=2.14+peak-.22*(abs(z)/.38)**2+.027*math.cos(i*.87+j*.66)
        vs.append((x,y,z))
for i in range(18):
    for j in range(8):
        a=i*9+j;faces.append((a,a+1,a+10,a+9))
surface(vs,faces,red)
for i in range(13):
    x=(i-6)*.123
    rod((x,1.93,.38),(x,1.73+.06*math.sin(i*2),.39),.015,bronze,.008)
export("pall_bearers")

trade = "diver"
# Diver. Two lead-soled boots, leather bellows, a bolted breastplate and a hose to the helmet.
part("body")
ball((0,1.13,0),(.40,.55,.30),green)
ball((0,1.48,.10),(.47,.18,.27),bronze)
ball((0,1.87,0),(.37,.37,.34),bronze)
ring((0,1.85,.305),.206,.036,(0,0,1),iron)
ball((0,1.85,.32),(.19,.19,.033),ink)
for i in [-1,0,1]:
    ln=.178 if i==0 else .139
    rod((i*.095,1.85-ln,.356),(i*.095,1.85+ln,.356),.013,bronze)
    rod((-ln,1.85+i*.095,.356),(ln,1.85+i*.095,.356),.013,bronze)
arm((-.36,1.45,0),(-.47,1.05,.03),(-.43,.78,.11),green)
arm((.36,1.45,0),(.53,1.13,.05),(.58,1.28,.24),green)
rod((-.11,.70,-.27),(-.11,1.64,-.27),.176,iron)
for angle in range(9):
    a=math.pi*angle/8
    ball((.42*math.cos(a),1.49,.12+.238*math.sin(a)),(.028,.028,.028),bronze)
for s in [-1,1]:
    rod((s*.25,1.47,.257),(s*.22,.78,.21),.045,hide)
    block((s*.22,.95,.263),(.14,.13,.038),bronze)
part("equipment",(.28,1.84,-.05))
hose=[(.28,1.84,-.05),(.49,2.10,-.06),(.59,2.03,-.19),(.63,1.62,-.30),(.50,1.10,-.35),(.21,.91,-.33)]
for a,b in zip(hose,hose[1:]): rod(a,b,.065,ink)
for s in [-1,1]:
    part("leg_l" if s<0 else "leg_r",(s*.19,.86,0))
    rod((s*.18,.89,0),(s*.24,.21,.03),.17,green,.122)
    block((s*.24,.102,.102),(.32,.17,.45),lead)
export("diver")

trade = "pilgrim"
# The pilgrim faces back along his path. A conical rain hat hides the turned face.
part("body")
figure(0,2.05,linen,ink,.28)
coat([(0,.55,-.045,.32,.20),(0,1.10,-.09,.26,.18),(0,1.64,-.12,.30,.17)],linen,.13)
rod((0,1.94,-.04),(0,2.39,-.09),.55,ochre,.023,32)
ring((0,1.94,-.04),.54,.023,(0,1,0),hide)
ball((.0,1.31,-.22),(.22,.24,.13),ochre)
for sx in [-.10,.10]:
    rod((sx,1.55,-.24),(sx,1.11,-.29),.027,hide)
for i in range(5):
    a=i*.12+1.19
    rod((-.36,a,-.29),(.36,a-.14,-.21),.026,hide)
for s in [-1,1]:
    leg(s,s*.13,.76,0,.75)
part("equipment",(-.34,1.41,.06))
rod((-.62,.035,.17),(-.34,2.00,.04),.034,hide)
rod((-.62,.035,.17),(-.50,.66,.13),.024,bronze)
arm((-.22,1.56,-.04),(-.30,1.22,.06),(-.42,1.46,.06),linen)
export("returning_pilgrim")

trade = "frame"
# Empty-frame porter. A diamond-cut frame suspended above a bent, half-covered face.
part("body")
figure(-.16,1.80,ochre,ink,.28)
for s in [-1,1]: leg(s,-.16+s*.13,.64,0,.63)
part("body")
arm((.02,1.36,.02),(.30,1.58,.04),(.49,1.83,.05),hide)
arm((-.33,1.36,0),(-.49,1.49,.03),(-.56,1.82,.04),hide)
part("equipment",(0,1.84,.03))
def frame(x,y):
    return (x*.977-y*.212+.06, x*.212+y*.977+2.47,.055)
corners=[(-.83,-.60),(.83,-.60),(.83,.60),(-.83,.60)]
for i in range(4):
    a,b=corners[i],corners[(i+1)%4]
    rod(frame(*a),frame(*b),.078,hide, n=6)
    rod(frame(a[0]*.92,a[1]*.88),frame(b[0]*.92,b[1]*.88),.027,bronze)
    ball(frame(*a),(.09,.10,.088),bronze)
    for t in [.07,.13,.87,.93]:
        at=frame(a[0]*(1-t)+b[0]*t,a[1]*(1-t)+b[1]*t)
        ball(at,(.057,.067,.104),bronze)
export("frame_porter")

trade = "watchman"
# Watchman made thin by the height of the galleries. Three ivory tines and narrow stilt feet.
part("body")
coat([(0,1.22,0,.19,.15),(0,1.52,-.015,.205,.16),(0,2.03,0,.125,.12),
      (0,2.33,0,.32,.18),(0,2.44,0,.11,.104)],wool,.06)
for s in [-1,1]:
    rod((s*.27,2.32,0),(s*.23,1.28,.04),.077,iron,.041)
    rod((s*.23,1.28,.04),(s*.22,1.12,.08),.036,ivory,.009)
for sx in [-1,1]:
    rod((sx*.07,2.33,.13),(sx*.18,1.33,.13),.028,lead,.011)
part("equipment",(0,2.47,0))
head(0,2.61,0,.194,lead,ivory)
for i in [-1,0,1]:
    rod((i*.10,2.72,0),(i*.24,3.26-.18*abs(i),-.075),.053,ivory,.004)
for s in [-1,1]:
    part("leg_l" if s<0 else "leg_r",(s*.12,1.43,0))
    rod((s*.12,1.44,0),(s*.16,.73,.04),.067,iron,.049)
    rod((s*.16,.73,.04),(s*.19,.025,0),.043,lead,.018)
export("watchman")

trade = "scribe"
# Scribe. Laminar quills grow in a fan from each scapula; the open codex rests on the wrists.
part("body")
figure(0,1.87,wool,linen,.24)
rod((0,1.64,.11),(0,1.53,.37),.068,ivory,.009)
for s in [-1,1]:
    part("body")
    arm((s*.18,1.40,0),(s*.31,1.12,.16),(s*.12,1.20,.38),wool)
    part("leg_l" if s<0 else "leg_r",(s*.11,.68,0))
    rod((s*.11,.70,0),(s*.15,.07,.01),.066,ink,.038)
    part("wing_l" if s<0 else "wing_r",(s*.17,1.44,-.13))
    for i in range(7):
        a=(s*(.12+i*.021),1.42-i*.045,-.105)
        tip=(s*(.64+i*.109),2.48-i*.139,-.23-i*.023)
        mid=((a[0]+tip[0])*.5,(a[1]+tip[1])*.5,-.14)
        rod(a,tip,.024,bronze,.005)
        for fract in [.33,.51,.68]:
            spine=[v*(1-fract)+w*fract for v,w in zip(a,tip)]
            rod((spine[0],spine[1],spine[2]+.02),(spine[0]+s*.055,spine[1]+.098,spine[2]+.012),.012,lead,.003)
        edge1=(mid[0]+s*.106,mid[1]-.09,mid[2]-.076)
        edge2=(mid[0]-s*.08,mid[1]+.07,mid[2]+.025)
        surface([a,edge1,tip,edge2,mid],[(0,1,4),(1,2,4),(2,3,4),(3,0,4),
                                        (4,1,0),(4,2,1),(4,3,2),(4,0,3)],linen if i%3 else lead)
part("equipment",(0,1.22,.30))
for s in [-1,1]:
    surface([(0,1.24,.28),(s*.26,1.34,.25),(s*.26,1.28,.54),(0,1.17,.55)],
            [(0,1,2,3),(3,2,1,0)],paper)
export("scribe")

trade = "spindle"
# Spindle tender. A great spoked reel is wound with wire beside the hip and up over one shoulder.
part("body")
figure(-.32,1.87,green,red,.25)
for s in [-1,1]: leg(s,-.32+s*.12,.68,0,.67)
part("body")
arm((-.15,1.43,0),(.10,1.38,.07),(.34,1.49,.09),linen)
part("equipment",(.30,1.52,-.11))
for z in [-.28,.025]:
    q=(.30,1.52,z)
    ring(q,.77,.061,(0,0,1),bronze)
    ring(q,.68,.027,(0,0,1),hide)
    for i in range(6):
        a=math.tau*i/6
        p=(q[0]+.75*math.cos(a),q[1]+.75*math.sin(a),z)
        rod(q,p,.032,hide,.040)
        if z>0: rod(p,(p[0],p[1],-.28),.028,lead)
rod((.30,1.52,-.32),(.30,1.52,.15),.16,hide)
for i in range(5):
    ring((.30,1.52,-.22+i*.047),.27,.027,(0,0,1),linen)
export("spindle")
