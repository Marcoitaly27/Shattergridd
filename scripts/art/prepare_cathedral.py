"""Blender: preserve the user's source and export a lighter cathedral derivative."""
import bpy
from pathlib import Path
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root/'assets/World ambientation/Old Cathedral/ruined cathedral 3d model.glb'))
for obj in bpy.context.scene.objects:
 if obj.type!='MESH': continue
 bpy.context.view_layer.objects.active=obj
 dec=obj.modifiers.new('Preserve architectural silhouette','DECIMATE');dec.ratio=0.32
 bpy.ops.object.modifier_apply(modifier=dec.name)
 print('Cathedral triangles',len(obj.data.polygons))
# A few fallen stone fragments along the damaged foundation, without physics.
import random
rng=random.Random(371)
for i in range(10):
 x=-0.32+i*0.065
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1,location=(x,0.39+rng.uniform(-0.025,0.025),0.012))
 o=bpy.context.object;o.name='Fallen masonry %02d'%i
 o.scale=(rng.uniform(0.007,0.014),rng.uniform(0.008,0.018),rng.uniform(0.005,0.01))
 o.rotation_euler=(0.1,rng.random(),rng.random()*3)
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
bpy.ops.export_scene.gltf(filepath=str(root/'assets/world/cathedral/cathedral_stone.glb'),export_format='GLB',export_animations=False)
