"""Original SHATTERGRID environment meshes. Run with Blender --background --python.
Coordinates below use game x, height, depth. No third-party source geometry.
"""
import bpy, math, random
from pathlib import Path
from mathutils import Vector
R=random.Random(61109)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
OUT=Path(__file__).resolve().parents[2]/'assets/world/cloister/courtyard_details.glb'
def mat(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=.95
 return m
stone=mat('Weathered limestone',(.31,.32,.275)); bark=mat('Dead wood',(.105,.087,.064)); grass=mat('Dry sedge',(.17,.185,.09)); inset=mat('Carved recess',(.085,.09,.075))
def coord(p):return (p[0],-p[2],p[1])
def mesh(name,verts,faces,material=stone,bevel=0):
 data=bpy.data.meshes.new(name);data.from_pydata([coord(p) for p in verts],[],faces);data.update()
 o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);o.data.materials.append(material)
 if bevel:
  bpy.context.view_layer.objects.active=o
  mod=o.modifiers.new('Worn arrises','BEVEL');mod.width=bevel;mod.segments=2
  bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
# Each dressed block has individually worn corners, rather than perfect shared edges.
def block(name,p,size,material=stone,bevel=.045):
 x,y,z=p;a,b,c=[v/2 for v in size]
 verts=[(x+dx*a+R.uniform(-.012,.012), y+dy*b, z+dz*c+R.uniform(-.012,.012)) for dx,dy,dz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 return mesh(name,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)],material,bevel)
# Three adjoining bays, last arch broken. Clear approach from cathedral to ritual court.
for x in [-11,-6,-1,4]:
 for tier in range(7):
  block('Pier course',(x,.12+tier*.44,-12.5),(.74,.42,.9))
 block('Pier plinth',(x,-.015,-12.5),(1.22,.27,1.32))
 block('Impost',(x,3.06,-12.5),(1.14,.24,1.27))
 # Small attached shafts support the arch moulding.
 for offset in [-.42,.42]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.15,depth=2.7,location=coord((x+offset,1.45,-12.0)))
  bpy.context.object.data.materials.append(stone)
for bay,cx in enumerate([-8.5,-3.5,1.5]):
 for j in range(17):
  if bay==2 and 5<=j<=11:continue
  lo=j*math.pi/17+.009;hi=(j+1)*math.pi/17-.009
  verts=[]
  for z in [-12.98,-12.02]:
   for r,t in [(2.11,lo),(2.51,lo),(2.51,hi),(2.11,hi)]:
    verts.append((cx+math.cos(t)*r,3.0+math.sin(t)*r,z))
  mesh('Arch voussoir',verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)],bevel=.025)
 # Broken spandrel courses above sound bays, separated into masonry courses.
 if bay<2:
  for row in range(2):
   for k in range(5):block('Coping',(cx+(k-2)*.98,5.55+row*.35,-12.5),(.95,.33,.98))
for j in range(13):
 o=block('Fallen arch stone',(R.uniform(-.2,3.2),.04,R.uniform(-13.2,-10.3)),(R.uniform(.35,.65),.27,R.uniform(.35,.8)))
 o.rotation_euler.z=R.uniform(-1.3,1.3)
# Sample the existing cathedral base so graves are neither buried nor floating.
from mathutils.bvhtree import BVHTree
existing=set(bpy.context.scene.objects)
bpy.ops.import_scene.gltf(filepath=str(OUT.parents[1]/'cathedral/cathedral_stone.glb'))
imported=set(bpy.context.scene.objects)-existing
verts=[];faces=[]
for ob in imported:
 if ob.type!='MESH':continue
 offset=len(verts)
 for v in ob.data.vertices:
  q=ob.matrix_world@v.co
  verts.append((q.x*70-39,q.y*88.582+8,q.z*47.814-.15))
 faces.extend([tuple(offset+i for i in poly.vertices) for poly in ob.data.polygons])
terrain=BVHTree.FromPolygons(verts,faces)
for ob in imported:bpy.data.objects.remove(ob,do_unlink=True)
def ground_height(x,z):
 hit=terrain.ray_cast(Vector((x,-z,50)),Vector((0,0,-1)))
 return max(-.15,hit[0].z) if hit[0] is not None and hit[0].z<3 else -.15
# Cemetery: aligned graves with arched or shouldered headstones, supported at the base.
for idx,(x,z) in enumerate([(-11.4,-5.2),(-14,-5.2),(-11.7,-1.4),(-14.3,-1.4),(-12,2.4)]):
 base_height=ground_height(x,z)+.15
 w=.42;h=R.uniform(1.0,1.35)
 profile=[(-w,0),(w,0),(w,h-.28)]
 profile += [(math.cos(t)*w,h-.28+math.sin(t)*.32) for t in [i*math.pi/10 for i in range(1,11)]]
 verts=[(x+u,y-.12+base_height,z+d) for d in [-.14,.14] for u,y in profile]
 n=len(profile);faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 o=mesh('Headstone',verts,faces,bevel=.035)
 block('Grave slab',(x,ground_height(x,z+1.15)+.09,z+1.15),(.96,.14,1.8),bevel=.06)
 # Restrained carved mark; a dark recess sits just inside the bevelled face.
 block('Recess vertical',(x,h*.6+base_height,z+.145),(.045,.31,.008),inset,.0)
 block('Recess horizontal',(x,h*.65+base_height,z+.145),(.22,.04,.008),inset,.0)
for x,z in [(-14.5,4.8),(-11.5,6.0)]:
 base_height=ground_height(x,z)+.15
 block('Sarcophagus foot',(x,-.04+base_height,z),(1.48,.2,2.7),bevel=.06)
 block('Sarcophagus chest',(x,.36+base_height,z),(1.2,.64,2.38),bevel=.07)
 block('Sarcophagus lid',(x,.75+base_height,z),(1.48,.18,2.7),bevel=.07)
 block('Lid carved strip',(x,.843+base_height,z),(.09,.01,1.6),inset,.0)
# Tapered, nonuniform branching mesh; roots reach the soil. No leaf transparency.
def branch(points,radii):
 verts=[];faces=[];sides=9
 for i,p in enumerate(points):
  p=Vector(p);t=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(i-1,0)])
  t.normalize();u=t.cross(Vector((0,0,1)))
  if u.length<.01:u=t.cross(Vector((1,0,0)))
  u.normalize();v=t.cross(u)
  for j in range(sides):verts.append(tuple(p+(u*math.cos(j*2*math.pi/sides)+v*math.sin(j*2*math.pi/sides))*radii[i]*(1+R.uniform(-.1,.1))))
 for i in range(len(points)-1):
  for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;faces.append((a,b,b+sides,a+sides))
 faces.extend([tuple(range(sides-1,-1,-1)),tuple((len(points)-1)*sides+j for j in range(sides))])
 o=mesh('Dead ash',verts,faces,bark)
 for poly in o.data.polygons:poly.use_smooth=True
 return o
base=Vector((8.7,-.15,-11.8))
def bp(p):return tuple(base+Vector(p))
branch([bp(p) for p in [(0,0,0),(.12,1.2,.06),(-.12,2.4,0),(.25,3.6,.12),(.1,5.1,.3),(.5,6.3,.45)]],[.44,.34,.27,.2,.12,.025])
for k in range(8):
 a=k*2.4;start=Vector((.05,1.8+k*.42,.05));end=start+Vector((math.cos(a)*(1.8-k*.08),1.25,math.sin(a)*1.1))
 mid=start.lerp(end,.55)+Vector((0,-.15,0))
 branch([bp(start),bp(mid),bp(end),bp(end+Vector((.18,.7,.1)))],[.16-k*.012,.1,.04,.006])
 branch([bp(mid),bp(mid+Vector((math.cos(a+.8)*.7,.7,math.sin(a+.8)*.7))),bp(mid+Vector((math.cos(a+.8),1.2,math.sin(a+.8))))],[.055,.025,.004])
for k in range(6):
 a=k*math.pi/3;branch([bp((0,.25,0)),bp((math.cos(a)*.65,.04,math.sin(a)*.65)),bp((math.cos(a)*1.35,0,math.sin(a)*1.35))],[.18,.1,.005])
# Sparse grass patches near burial ground and pier footings, never on the board.
verts=[];faces=[]
for cluster in range(150):
 if cluster<95:x,z=R.uniform(-15,-10),R.uniform(-6,7)
 else:x,z=R.uniform(-12,10),R.uniform(-14,-11)
 for blade in range(R.randint(4,9)):
  x0=x+R.uniform(-.18,.18);z0=z+R.uniform(-.18,.18);h=R.uniform(.12,.4);a=R.random()*math.tau;w=.018
  i=len(verts);verts.extend([(x0-math.cos(a)*w,-.14,z0-math.sin(a)*w),(x0+math.cos(a)*w,-.14,z0+math.sin(a)*w),(x0+R.uniform(-.15,.15),h-.14,z0+R.uniform(-.15,.15))]);faces.extend([(i,i+1,i+2),(i+2,i+1,i)])
mesh('Sedge patches',verts,faces,grass)
# Batch by material to keep scene draw calls low.
for material in [stone,bark,grass,inset]:
 bpy.ops.object.select_all(action='DESELECT')
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==material]
 for o in objects:o.select_set(True)
 if objects:
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=material.name.replace(' ','_')
OUT.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB',export_yup=True)
print('Courtyard detail triangles',sum(len(o.data.polygons) for o in bpy.context.scene.objects if o.type=='MESH'))
