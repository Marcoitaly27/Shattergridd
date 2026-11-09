"""Original ruined watercourse and fossil bone masonry for SHATTERGRID."""
from pathlib import Path
# Reuse authored mesh/block helpers without building or modifying the cloister.
source=Path(__file__).with_name('build_cloister.py').read_text()
exec(source[:source.index('# Three adjoining bays')])
OUT=Path(__file__).resolve().parents[2]/'assets/world/aqueduct/ruins.glb'
bone=mat('Ancient_bone',(.42,.38,.27))
# Elevated stone watercourse: piers, voussoirs, supporting masonry and an open channel.
for x in [8,14,20,26,32,38]:
 height=5.0
 block('Spread footing',(x,.05,-22),(2.3,.4,2.5))
 for row in range(int(height/.65)):
  block('Pier course',(x,.35+row*.65,-22),(1.35,.62,1.8),bevel=.06)
 block('Pier capital',(x,4.72,-22),(1.8,.4,2.1),bevel=.045)
for bay,cx in enumerate([11,17,23,29,35]):
 broken=bay==2
 for j in range(19):
  if broken and 4<=j<=14:continue
  lo=j*math.pi/19+.008;hi=(j+1)*math.pi/19-.008
  vs=[]
  for z in [-22.9,-21.1]:
   for r,t in [(2.3,lo),(3.0,lo),(3.0,hi),(2.3,hi)]:vs.append((cx+math.cos(t)*r,4.8+math.sin(t)*r,z))
  mesh('Arch stone',vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(3,7,6,2),(0,4,7,3),(1,2,6,5)],bevel=.045)
 if not broken:
  for k in range(6):
   x=cx+(k-2.5)
   block('Channel bed',(x,8.02,-22),(.97,.38,2.15))
   for z in [-22.92,-21.08]:block('Channel wall',(x,8.52,z),(.97,.65,.3))
  # Fill haunches: load-bearing masonry above the arch shoulders.
  for side in [-1,1]:
   for row in range(3):
    for k in range(2-row//2):
     x=cx+side*(2.6-k*.65)
     block('Spandrel',(x,5.4+row*.72,-22),(.63,.69,1.8))
for i in range(23):
 ob=block('Collapsed channel',(R.uniform(20,26),.1,R.uniform(-24,-19)),(R.uniform(.5,1.1),R.uniform(.25,.6),R.uniform(.6,1.2)))
 from mathutils import Matrix
 center=sum((v.co for v in ob.data.vertices),Vector())/len(ob.data.vertices)
 turn=Matrix.Rotation(R.uniform(-.3,.3),3,'Z')
 for v in ob.data.vertices:v.co=center+turn@(v.co-center)
 low=min(v.co.z for v in ob.data.vertices)
 for v in ob.data.vertices:v.co.z-=low+.15
# Angle the watercourse along the far side of the strategic view.
for ob in bpy.context.scene.objects:
 if ob.type!='MESH':continue
 for v in ob.data.vertices:
  u=v.co.x-8;depth=-v.co.y+22
  v.co.x=-5+u*.8-depth*.6
  v.co.y=-(-21+u*.6+depth*.8)
  v.co.z=(v.co.z+.15)*.72-.15
# Low ruined wall surrounds the fossil's lower shaft rather than placing it on a stand.
for row in range(4):
 for col in range(5):
  if row==3 and col in [0,4]:continue
  block('Fossil masonry',(-10+(col-2)*.8,.12+row*.57,1.8),(.77,.54,1.1),bevel=.06)
# Organic, bowed long bone with an expanded articular head, fluted shaft and broken tip.
vs=[];fs=[];rings=36;sides=24
for i in range(rings):
 t=i/(rings-1)
 center=Vector((-10.7+2.6*t, .5+5.7*t,2.5+.3*math.sin(t*math.pi)))
 radius=.27+.43*math.exp(-((t-.88)/.13)**2)+.28*math.exp(-((t-.06)/.12)**2)
 for j in range(sides):
  a=j*math.tau/sides
  r=radius*(1+.10*math.cos(a*3)+R.uniform(-.025,.025))
  vs.append(tuple(center+Vector((math.cos(a)*r,math.sin(a)*r*.35,math.sin(a)*r*.72))))
for i in range(rings-1):
 for j in range(sides):a=i*sides+j;b=i*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
fs.extend([tuple(range(sides-1,-1,-1)),tuple((rings-1)*sides+j for j in range(sides))])
ob=mesh('Ancient_bone',vs,fs,bone)
for poly in ob.data.polygons:poly.use_smooth=True
for material in [stone,bone]:
 bpy.ops.object.select_all(action='DESELECT')
 objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==material]
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name='Aqueduct_stone' if material==stone else 'Ancient_bone'
OUT.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(OUT),export_format='GLB')
