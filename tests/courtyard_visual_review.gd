extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var scene = load('res://scenes/main.tscn').instantiate()
 root.add_child(scene)
 await create_timer(2).timeout
 var stage=OS.get_environment('REVIEW_STAGE')
 if stage == 'baseline':
  var court=scene.get_node('VisualWorld/GroundedCourtyard')
  var details=court.get_node('CloisterAndBurialGround')
  court.remove_child(details)
  details.free()
  var output=[]
  var status=OS.execute('git',['show','3c511c0:materials/world/courtyard_ground.gdshader'],output)
  if status != 0:
   push_error('Cannot load original ground shader for comparison')
   quit(1)
   return
  var shader=Shader.new()
  shader.code=output[0]
  var material=ShaderMaterial.new()
  material.shader=shader
  court.get_node('ContinuousGround').material_override=material
 var directory=OS.get_environment('REVIEW_DIRECTORY')
 if directory.is_empty(): directory=ProjectSettings.globalize_path('user://courtyard-review')
 DirAccess.make_dir_recursive_absolute(directory)
 for night in [false,true]:
  scene.get_node('DayNightPresentation')._apply(night,false)
  await create_timer(1).timeout
  var samples=[]
  for frame in range(60):
   var start=Time.get_ticks_usec()
   await process_frame
   samples.append((Time.get_ticks_usec()-start)/1000.0)
  samples.sort()
  print('BENCH ',stage,' night=',night,' median_ms=',samples[30],' p95_ms=',samples[57], ' draws=',Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),' triangles=',Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
  get_root().get_texture().get_image().save_png(directory+'/court-'+stage+('-night.png' if night else '-day.png'))
 quit()
