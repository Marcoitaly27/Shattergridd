extends 'res://tests/capture_smoke.gd'
func _run() -> void:
 await _test_sequence('hunter')
 await _test_sequence('witch')
 await _test_restart(false)
 await _test_restart(true)
 await _test_victory_restart()
 print('Ground capture/restart: %d checks, %d failures' % [checks, failures])
 quit(0 if failures == 0 else 1)
