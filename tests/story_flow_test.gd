extends SceneTree
## Run with an isolated APPDATA profile. Does not load the player's normal build.
var failures: Array[String]=[]
var checks := 0

func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition: failures.append(description)
	print(("PASS " if condition else "FAIL ")+description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn")
	var game = scene.instantiate()
	game.test_mode=true
	root.add_child(game)
	await process_frame
	await physics_frame
	game.set_physics_process(false)
	check(game.story.landmarks.size()==9,"Nine story landmarks")
	check(game.story.stage==0,"Starts at queen's mirror")
	game.story.interact_at(6)
	check(game.story.stage==0,"Cannot skip directly to poison apple")
	check(not game.open_story_gate(),"Gate blocks missing clues and guards")
	for i in range(7):
		game.player.position=game.story.landmarks[i].pos
		check(game.story.nearest(game.player.position)==i,"Landmark interaction range %d"%i)
		game.interact()
		check(game.story.stage==i+1,"E advances story %d"%i)
		game.interact()
		check(game.story.stage==i+1,"Repeated interaction is idempotent %d"%i)
	check(not game.open_story_gate(),"Apple clue alone cannot open gate")
	game.story.interact_at(7)
	check(game.story.stage==7,"Mirror requires boss defeat")
	for e in game.enemies:
		if not e.boss: game.damage(e,10000)
	check(game.guard_kills()==6,"Six guards counted independently of boss")
	game.player.position=Vector3(0,0,-110)
	game.interact()
	check(game.gate_open,"Gate opens with story and combat prerequisites")
	for e in game.enemies:
		if e.boss: game.damage(e,10000)
	check(not game.won,"Boss death does not prematurely finish rescue")
	for i in [7,8]:
		game.player.position=game.story.landmarks[i].pos
		game.interact()
	check(game.story.stage==9 and game.won,"Glass coffin completes rescue")
	check(game.story.target()==Vector3(0,0,12),"Completed route points back to camp")
	game.minimap._process(1.0)
	check(game.minimap.known(Vector2(-8,-151)),"Exploration reveals current location")
	check(not game.minimap.known(Vector2(29,19)),"Unvisited terrain stays concealed")
	game.minimap.set_layout(true)
	check(game.minimap.expanded,"Expanded map mode")
	check(game.minimap.in_map(game.minimap.map_point(Vector2(-8,-151))),"Coffin fits expanded map")
	game.minimap.set_layout(false)
	# Reachability validation against actual collision geometry, with the gate open.
	await physics_frame
	var grid := AStarGrid2D.new()
	grid.region=Rect2i(-28,-168,57,187)
	grid.cell_size=Vector2.ONE
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var shape := SphereShape3D.new()
	shape.radius=0.42
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.exclude=[game.player.get_rid()]
	for x in range(-28,29):
		for z in range(-168,19):
			query.transform=Transform3D(Basis.IDENTITY,Vector3(x,0.85,z))
			if not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): grid.set_point_solid(Vector2i(x,z))
	var previous := Vector2i(0,12)
	for landmark in game.story.landmarks:
		var target := Vector2i(roundi(landmark.pos.x),roundi(landmark.pos.z))
		check(not grid.get_id_path(previous,target).is_empty(),"Collision route reaches "+str(landmark.name))
		previous=target
	# Save and reload on a dedicated path; the test profile is also isolated by the runner.
	game.saved_path="user://story_flow_test.cfg"
	game.test_mode=false
	game.player.position=Vector3(0,0,12)
	game.interact()
	var expected_drops: int=game.drops.size()
	var restored = scene.instantiate()
	restored.test_mode=true
	restored.saved_path="user://story_flow_test.cfg"
	root.add_child(restored)
	restored.load_build()
	restored.set_physics_process(false)
	check(restored.story.stage==9 and restored.won,"Saved story completion restores")
	check(restored.gate_open and restored.boss_defeated(),"Saved gate and boss restore")
	check(restored.drops.size()==expected_drops,"Uncollected loot survives save")
	check(restored.minimap.known(Vector2(-8,-151)),"Exploration survives save")
	check(restored.talents.points+restored.talents.allocated.size()==140,"140 point budget preserved")
	restored.queue_free()
	# Render the real main scene and UI for visual review when requested.
	if "--capture" in OS.get_cmdline_user_args():
		game.player.position=Vector3(-10,0,-30)
		game.camera.position=game.player.position+Vector3(0,15,12)
		game.camera.look_at(game.player.position+Vector3(0,0,-2))
		game.quest_label.text="剧情试验 · 七人小屋 / 七只碗、七把椅子、七张床"
		game.interaction_label.text="E 调查童话线索 · M 展开地图"
		game.message.text=""
		game.minimap.set_layout(true)
		for i in range(game.story.route.size()-1):
			for step in range(20):
				var p: Vector2=game.story.route[i].lerp(game.story.route[i+1],step/20.0)
				game.player.position=Vector3(p.x,0,p.y)
				game.minimap._process(1.0)
		game.player.position=Vector3(-10,0,-30)
		game.minimap.set_layout(false)
		game._physics_process(0.016)
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/小地图预览.png")
		game.minimap.set_layout(true)
		for _i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/剧情地图预览.png")
	print("RESULT: %d checks, %d failures"%[checks,failures.size()])
	for failure in failures: push_error(failure)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
