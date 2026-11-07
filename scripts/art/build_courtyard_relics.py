"""Original bell, iron brazier and ceramic tesserae; no external asset inputs."""
import bpy, math, random
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parents[2]/'assets/world/relics'
OUT.mkdir(parents=True,exist_ok=True)
R=random.Random(7031)
def reset():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,col,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Roughness'].default_value=.85;p.inputs['Metallic'].default_value=metal;return m
bronze=mat('Bronze',(.24,.18,.09),.65);iron=mat('Iron',(.07,.065,.055),.65);coal=mat('Coal',(.05,.03,.02));wood=mat('Wood',(.12,.09,.055))
def mesh(name,vs,fs,m):
 d=bpy.data.meshes.new(name);d.from_pydata(vs,[],fs);d.update();o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);o.data.materials.append(m);return o
def lathe(name,profile,m,n=64):
 vs=[(r*math.cos(a*math.tau/n),r*math.sin(a*math.tau/n),h) for r,h in profile for a in range(n)]
 fs=[]
 for i in range(len(profile)-1):
  for a in range(n):b=i*n+a;c=i*n+(a+1)%n;fs.append((b,c,c+n,b+n))
 o=mesh(name,vs,fs,m)
 for p in o.data.polygons:p.use_smooth=True
 return o
def rod(name,points,r,m):
 curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.bevel_depth=r;curve.bevel_resolution=2
 sp=curve.splines.new('POLY');sp.points.add(len(points)-1)
 for p,co in zip(sp.points,points):p.co=(*co,1)
 ob=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(ob);ob.data.materials.append(m);bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.convert(target='MESH');ob.select_set(False)
 return ob
def cube(name,pos,size,m):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos);o=bpy.context.object;o.name=name;o.scale=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(m)
 mod=o.modifiers.new('Worn edges','BEVEL');mod.width=.025;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name);o.select_set(False);return o
def export(name):
 for m in list(bpy.data.materials):
  objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==m]
  if not objects:continue
  bpy.ops.object.select_all(action='DESELECT')
  for o in objects:o.select_set(True)
  bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=m.name
 bpy.ops.export_scene.gltf(filepath=str(OUT/name),export_format='GLB')
reset()
# Continuous outer/inner bell wall and thick rolled lip; open mouth remains visible.
profile=[(.03,1.72),(.33,1.72),(.43,1.57),(.48,1.25),(.58,.85),(.76,.43),(1.04,.15),(1.08,.07),(1.02,0),(.89,.035),(.87,.14),(.65,.43),(.48,.86),(.38,1.25),(.3,1.52),(.03,1.55)]
lathe('Bell shell',profile,bronze)
for h,r in [(.2,.99),(.33,.84),(1.41,.46)]:lathe('Cast bands',[(r,h-.025),(r+.025,h),(r,h+.025)],bronze)
rod('Crown eye',[(.24*math.cos(a*math.tau/32),0,1.87+.22*math.sin(a*math.tau/32)) for a in range(33)],.065,bronze)
rod('Clapper stem',[(0,0,1.55),(.14,0,.26)],.045,iron)
bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=8,radius=.16,location=(.14,0,.26));bpy.context.object.data.materials.append(iron)
# Tilt the whole bell, then seat the lowest metal point on the floor.
from mathutils import Euler
rotation=Euler((-1.2,0,-.55)).to_matrix()
for ob in list(bpy.context.scene.objects):
 for v in ob.data.vertices:v.co=rotation@(ob.matrix_world@v.co)
 ob.matrix_world.identity()
low=min(v.co.z for ob in bpy.context.scene.objects for v in ob.data.vertices)
for ob in bpy.context.scene.objects:
 for v in ob.data.vertices:v.co.z-=low
cube('Broken headstock',(-.85,.35,.12),(1.7,.24,.24),wood).rotation_euler.z=.4
export('fallen_bell.glb')
reset()
lathe('Fire bowl',[(.12,.78),(.3,.82),(.49,1.03),(.53,1.12),(.48,1.13),(.44,1.02),(.25,.88),(.12,.86)],iron,48)
for a in [0,math.tau/3,math.tau*2/3]:
 rod('Splayed leg',[(math.cos(a)*.47,math.sin(a)*.47,0),(math.cos(a)*.28,math.sin(a)*.28,.5),(math.cos(a)*.35,math.sin(a)*.35,.89)],.055,iron)
 cube('Foot',(math.cos(a)*.47,math.sin(a)*.47,.025),(.23,.17,.05),iron)
for a in [i*math.tau/8 for i in range(8)]:
 rod('Basket rib',[(math.cos(a)*.31,math.sin(a)*.31,.85),(math.cos(a)*.52,math.sin(a)*.52,1.12),(math.cos(a)*.49,math.sin(a)*.49,1.33)],.026,iron)
lathe('Basket rim',[(.48,1.29),(.515,1.29),(.515,1.34),(.48,1.34)],iron,48)
for k in range(13):
 a=R.random()*math.tau;r=R.random()*.32
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=R.uniform(.08,.15),location=(math.cos(a)*r,math.sin(a)*r,.98));bpy.context.object.data.materials.append(coal)
export('iron_brazier.glb')
reset()
colors=[mat('Tessera limestone',(.43,.41,.32)),mat('Tessera slate',(.09,.12,.115)),mat('Tessera ochre',(.29,.22,.105)),mat('Tessera oxide',(.23,.105,.075))]
vs=[[] for _ in colors];fs=[[] for _ in colors]
def tile(x,z,index,w=.135):
 # Godot ground y=-.15; upper tessera surface at -.115, no overlap with board apron.
 y=-.14;size=w/2;start=len(vs[index]);h=.025
 vs[index]+=[(x+dx*size,-z-dz*size,y+dy*h) for dx,dy,dz in [(-1,0,-1),(1,0,-1),(1,1,-1),(-1,1,-1),(-1,0,1),(1,0,1),(1,1,1),(-1,1,1)]]
 fs[index]+=[tuple(start+i for i in face) for face in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)]]
# Interrupted geometric border, weathered in coherent missing patches.
for side in range(4):
 a=side*math.pi/2
 for j in range(-52,53):
  for row in range(3):
   u=j*.15;v=9.2+row*.15
   if math.sin(u*1.1+side*2)+math.cos(u*.43-row*.2)>1.1 or R.random()<.055:continue
   x=u*math.cos(a)-v*math.sin(a);z=u*math.sin(a)+v*math.cos(a)
   tile(x,z,0 if row!=1 else (2 if j%8<4 else 1))
# Damaged eight-point rosette on the entrance side.
for ix in range(-10,11):
 for iz in range(-10,11):
  x=ix*.15;z=iz*.15;r=math.hypot(x,z);a=math.atan2(z,x)
  if r>1.5 or ((x+.6)**2+(z-.7)**2<.32) or R.random()<.08:continue
  col=0
  if r>1.28:col=2
  elif r<.85+.25*math.cos(8*a):col=3 if r>.35 else 2
  else:col=1
  tile(x,10.8+z,col)
for i,m in enumerate(colors):mesh(m.name,vs[i],fs[i],m)
export('ceremonial_mosaic.glb')
