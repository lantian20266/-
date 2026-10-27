extends Node3D

var player: CharacterBody3D
var body: Node3D
var sword: MeshInstance3D
var camera: Camera3D
var hud: Label
var message: Label
var tree_panel: Control
var talents = preload("res://talent_model.gd").new()
var enemies: Array = []
var drops: Array = []
var solids: Array = []
var hp := 100.0
var stamina := 100.0

var kills := 0
var coins := 0
var weapon_bonus := 0

var facing := Vector3(0,0,-1)
var attack_time := 0.0
var attack_length := 0.55
var attack_hit := false
var heavy := false
var dash := 0.0
var hurt_cd := 0.0
var skill_cd := 0.0
var combo := 0
var gate_open := false
var won := false
var chest_open := false
var notice_time := 0.0
var gate: StaticBody3D

var tuning := [6.0,1.0,1.0]
var saved_path := "user://build.cfg"
var story
var minimap
var quest_label: Label
var interaction_label: Label
var test_mode := false

func material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.material_override = material(color)
	parent.add_child(n)
	n.position = pos
	return n

func obstacle(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var n := StaticBody3D.new()
	add_child(n)
	n.position = pos
	box(n,Vector3.ZERO,size,color)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	n.add_child(c)
	solids.append(Rect2(Vector2(pos.x-size.x/2,pos.z-size.z/2),Vector2(size.x,size.z)))
	return n

func sign_at(pos: Vector3, text_value: String) -> Label3D:
	var l := Label3D.new()
	l.text = text_value
	l.font_size = 38
	l.pixel_size = 0.012
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)
	l.position = pos
	l.modulate = Color(0.85,0.9,0.94)
	return l

func actor(pos: Vector3, color: Color) -> CharacterBody3D:
	var a := CharacterBody3D.new()
	add_child(a)
	a.position = pos
	var c := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.7
	c.shape = shape
	c.position.y = 0.85
	a.add_child(c)
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.7
	mesh.mesh = cap
	mesh.material_override = material(color)
	mesh.position.y = 0.85
	a.add_child(mesh)
	return a

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.055,0.065,0.08)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.65,0.74,0.85)
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-30,0)
	sun.light_energy = 1.4
	add_child(sun)
	story=preload("res://story_map.gd").new()
	story.game=self
	add_child(story)
	player = actor(Vector3(0,0,10),Color(0.3,0.72,0.78))
	body = Node3D.new()
	player.add_child(body)
	sword = box(body,Vector3(0.65,1,-0.65),Vector3(0.13,0.13,1.3),Color(0.86,0.87,0.77))
	for p in [Vector3(3,0,-18),Vector3(-3,0,-30),Vector3(7,0,-52),Vector3(-3,0,-72),Vector3(3,0,-86),Vector3(4,0,-103)]:
		spawn_enemy(p,false)
	spawn_enemy(Vector3(0,0,-125),true)
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 54
	make_ui()
	if not test_mode: load_build()
	notify("白雪残章：先调查营地旁的王后魔镜。E 调查，M 展开地图，Tab 天赋。")

func spawn_enemy(pos: Vector3, boss: bool) -> void:
	var a := actor(pos,Color(0.7,0.27,0.28) if boss else Color(0.62,0.48,0.4))
	if boss:
		a.scale = Vector3.ONE*1.6
	var label := Label3D.new()
	label.position.y = 2.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	a.add_child(label)
	enemies.append({"node":a,"hp":380.0 if boss else 65.0,"max":380.0 if boss else 65.0,"boss":boss,"cd":0.0,"wind":0.0,"label":label,"flash":0.0})

func make_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025,0.035,0.05,0.88)
	backdrop.position = Vector2(16,16)
	backdrop.size = Vector2(760,126)
	canvas.add_child(backdrop)
	hud = Label.new()
	hud.position = Vector2(30,24)
	hud.add_theme_font_size_override("font_size",19)
	canvas.add_child(hud)
	message = Label.new()
	message.position = Vector2(28,640)
	message.size=Vector2(880,135)
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size",20)
	canvas.add_child(message)
	quest_label=Label.new()
	quest_label.position=Vector2(28,150)
	quest_label.add_theme_font_size_override("font_size",20)
	canvas.add_child(quest_label)
	interaction_label=Label.new()
	interaction_label.position=Vector2(28,188)
	interaction_label.add_theme_font_size_override("font_size",18)
	canvas.add_child(interaction_label)
	minimap=preload("res://minimap.gd").new()
	minimap.game=self
	canvas.add_child(minimap)
	tree_panel = preload("res://talent_ui.gd").new()
	tree_panel.model = talents
	tree_panel.game = self
	canvas.add_child(tree_panel)
	tree_panel.hide()
	talents.changed.connect(func(): hp=minf(hp,max_hp()))

func max_hp() -> float:
	return maxf(30.0,100.0+talents.bonus("life"))

func skill_cooldown() -> float:
	return 5.0*(1.0-clampf(talents.bonus("cooldown"),-0.5,0.65))

func notify(value: String) -> void:
	message.text=value
	notice_time=14.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_M and not tree_panel.visible:
			minimap.set_layout(not minimap.expanded)
		if event.keycode==KEY_TAB and not minimap.expanded:
			tree_panel.visible=not tree_panel.visible
		if event.keycode==KEY_E and not tree_panel.visible and not minimap.expanded: interact()
		if event.keycode==KEY_SPACE and not tree_panel.visible and not minimap.expanded and stamina>=25 and dash<=0:
			dash=0.22
			stamina-=25
			attack_time=0
		if event.keycode==KEY_Q and not tree_panel.visible and not minimap.expanded and skill_cd<=0 and hp>0:
			skill_cd=skill_cooldown()
			ring(player.position,4,Color(0.95,0.52,0.16))
			for e in enemies:
				if e.hp>0 and e.node.position.distance_to(player.position)<4: damage(e,38*(1+talents.bonus("skill")))
	if event is InputEventMouseButton and event.pressed and not tree_panel.visible and not minimap.expanded and hp>0:
		if event.button_index==MOUSE_BUTTON_LEFT: begin_attack(false)
		if event.button_index==MOUSE_BUTTON_RIGHT: begin_attack(true)

func begin_attack(is_heavy: bool) -> void:
	if attack_time>0 or dash>0 or stamina<(20 if is_heavy else 8): return
	heavy=is_heavy
	combo=combo%3+1
	attack_length=(0.85 if heavy else 0.48)/tuning[1]
	attack_time=attack_length
	attack_hit=false
	stamina-=20 if heavy else 8

func _physics_process(dt: float) -> void:
	if not is_instance_valid(player): return
	if tree_panel.visible or minimap.expanded: return
	hurt_cd=maxf(0,hurt_cd-dt)
	skill_cd=maxf(0,skill_cd-dt)
	notice_time-=dt
	if notice_time<=0: message.text=""
	stamina=minf(100,stamina+dt*(19+talents.bonus("regen")))
	var motion := Vector3.ZERO
	if not tree_panel.visible and hp>0:
		motion=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),0,float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
		var mouse := get_viewport().get_mouse_position()
		var origin := camera.project_ray_origin(mouse)
		var direction := camera.project_ray_normal(mouse)
		if absf(direction.y)>0.001:
			var target := origin+direction*((0.8-origin.y)/direction.y)
			var aim := target-player.position
			aim.y=0
			if aim.length()>0.2: facing=aim.normalized()
	if dash>0:
		dash-=dt
		if motion.length()>0: facing=motion
		player.velocity=facing*17
	else:
		player.velocity=motion*tuning[0]*(1+talents.bonus("speed"))*(0.35 if attack_time>0 else 1.0)
	player.velocity.y=-2
	player.move_and_slide()
	body.rotation.y=atan2(-facing.x,-facing.z)
	if attack_time>0:
		attack_time=maxf(0,attack_time-dt)
		var phase := 1.0-attack_time/attack_length
		sword.rotation.y=lerpf(-1.4,1.9,phase)
		sword.position.x=sin(phase*PI)*0.9
		if phase>0.42 and not attack_hit:
			attack_hit=true
			ring(player.position+facing,1.5*tuning[2]*(1+talents.bonus("reach")),Color(0.98,0.83,0.44))
			for e in enemies:
				var diff: Vector3=e.node.position-player.position
				if e.hp>0 and diff.length()<2.8*tuning[2]*(1+talents.bonus("reach")) and facing.dot(diff.normalized())>0.1:
					var amount: float = (35.0 if heavy else 18.0+combo*3)*(1+talents.bonus("damage"))+weapon_bonus
					if heavy: amount*=1+talents.bonus("heavy")
					damage(e,amount)
	else:
		sword.rotation.y=0
		sword.position.x=0.65
	for e in enemies: enemy_tick(e,dt)
	for d in drops:
		if is_instance_valid(d.node):
			d.node.rotation.y+=dt*2
	camera.position=camera.position.lerp(player.position+Vector3(0,15,12),minf(1,dt*8))
	camera.look_at(player.position+Vector3(0,0,-2))
	hud.text="失序童话 / 白雪主线试验地图 · 灰盒 0.3\n生命 %d / %d   耐力 %d   武器 +%d   碎片 %d   追兵 %d / 6\nWASD 移动 · 鼠标瞄准 · 左键连击 / 右键重击 · 空格闪避\nQ 余烬震荡 [%.1fs] · E 调查 / 拾取 · M 地图 · Tab 星球天赋"%[hp,max_hp(),stamina,weapon_bonus,coins,guard_kills(),skill_cd]

	quest_label.text=story.objective()
	interaction_label.text=interaction_hint()

func enemy_tick(e: Dictionary, dt: float) -> void:
	if e.hp<=0: return
	var a: CharacterBody3D=e.node
	e.label.text=("魔镜守卫 " if e.boss else "魔镜追兵 ")+"%d / %d"%[e.hp,e.max]
	e.cd=maxf(0,e.cd-dt)
	if hp<=0 or won or tree_panel.visible: return
	if e.boss and not gate_open: return
	var offset := player.position-a.position
	offset.y=0
	var distance := offset.length()
	if e.wind>0:
		e.wind-=dt
		e.label.modulate=Color(1,0.35,0.15)
		if e.wind<=0:
			ring(a.position,3.3 if e.boss else 1.8,Color(0.95,0.24,0.2))
			if distance<(3.3 if e.boss else 1.8) and dash<=0 and hurt_cd<=0:
				hp=maxf(0,hp-(28 if e.boss else 12)*(1-clampf(talents.bonus("guard"),-0.5,0.65)))
				hurt_cd=0.45
				if hp<=0: notify("你已倒下。Tab → 重新开始试炼。")
			e.cd=1.4 if e.boss else 1.1
		return
	e.label.modulate=Color.WHITE
	if distance>14: return
	if distance<(2.6 if e.boss else 1.45) and e.cd<=0:
		e.wind=0.85 if e.boss else 0.6
		ring(a.position,3.3 if e.boss else 1.8,Color(0.6,0.24,0.15),e.wind)
		return
	if distance>1.2:
		var move := offset.normalized()
		var query := PhysicsRayQueryParameters3D.create(a.position+Vector3.UP*0.8,a.position+Vector3.UP*0.8+move*1.8)
		query.exclude=[a.get_rid()]
		if get_world_3d().direct_space_state.intersect_ray(query):
			var sideways := Vector3(-move.z,0,move.x)
			var side_query := PhysicsRayQueryParameters3D.create(a.position+Vector3.UP,a.position+Vector3.UP+sideways*2)
			side_query.exclude=[a.get_rid()]
			move=-sideways if get_world_3d().direct_space_state.intersect_ray(side_query) else sideways
		for other in enemies:
			if other!=e and other.hp>0:
				var separation: Vector3=a.position-other.node.position
				separation.y=0
				if separation.length()<1.1: move+=separation*1.2
		a.velocity=move.normalized()*(2.4 if e.boss else 2.8)
		a.velocity.y=-2
		a.move_and_slide()

func damage(e: Dictionary, value: float) -> void:
	e.hp-=value
	var popup := Label3D.new()
	popup.text=str(int(value))
	popup.position=e.node.position+Vector3(0,2.6,0)
	popup.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	popup.font_size=48
	popup.modulate=Color(1,0.8,0.35)
	add_child(popup)
	var tween := create_tween()
	tween.tween_property(popup,"position:y",popup.position.y+1,0.6)
	tween.tween_callback(popup.queue_free)
	if e.hp<=0:
		kills+=1
		if kills%2==0:
			talents.grant_points(1)
			talents.changed.emit()
		hp=minf(max_hp(),hp+talents.bonus("heal"))
		spawn_drop(e.node.position,e.boss)
		e.node.hide()
		e.node.collision_layer=0
		e.node.collision_mask=0
		if e.boss:
			notify("魔镜守卫已倒下。调查镜庭封印取回真名，再前往玻璃棺。")

func spawn_drop(pos: Vector3, boss: bool, saved_bonus: int=-1) -> void:
	var n := Node3D.new()
	add_child(n)
	n.position=pos+Vector3(0,0.5,0)
	box(n,Vector3.ZERO,Vector3(0.35,0.65,0.35),Color(0.85,0.56,1) if boss else Color(0.4,0.85,0.9))
	var bonus := saved_bonus if saved_bonus>=0 else (14 if boss else randi_range(2,8))
	var drop_label := sign_at(pos+Vector3(0,1.5,0),"[E] 猎刃 +%d"%bonus)
	drops.append({"node":n,"bonus":bonus,"label":drop_label})

func ring(pos: Vector3, radius: float, color: Color, duration: float=0.22) -> void:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius=maxf(0.05,radius-0.07)
	torus.outer_radius=radius
	mesh.mesh=torus
	mesh.material_override=material(color)
	add_child(mesh)
	mesh.position=pos+Vector3(0,0.06,0)
	var timer := get_tree().create_timer(duration)
	timer.timeout.connect(mesh.queue_free)

func guard_kills() -> int:
	var count := 0
	for e in enemies:
		if not e.boss and e.hp<=0: count+=1
	return count

func boss_defeated() -> bool:
	for e in enemies:
		if e.boss: return e.hp<=0
	return false

func open_story_gate() -> bool:
	if gate_open: return true
	if story.stage<7 or guard_kills()<6: return false
	gate_open=true
	gate.queue_free()
	return true

func interaction_hint() -> String:
	if hp<=0: return "已倒下 · Tab 重新开始试炼"
	var index: int=story.nearest(player.position)
	if index>=0: return "[E] 调查 / 回顾："+str(story.landmarks[index].name)
	for d in drops:
		if player.position.distance_to(d.node.position)<2.5: return "[E] 拾取猎刃 +%d"%d.bonus
	if player.position.distance_to(Vector3(0,0,12))<4: return "[E] 营地恢复 / 保存剧情与构筑"
	if player.position.distance_to(Vector3(-19,0,-35))<3 and not chest_open: return "[E] 打开矿工补给箱"
	if absf(player.position.z+113)<4 and not gate_open: return "[E] 解封镜庭（完成毒苹果线索，并清除六名追兵）"
	return "沿林间小路前进 · 金色圆环指向当前任务"

func interact() -> void:
	if hp<=0: return
	# A nearby story interaction takes priority; completed clues can be reread.
	var index: int=story.nearest(player.position)
	if index>=0:
		notify(story.interact_at(index))
		return
	for d in drops.duplicate():
		if player.position.distance_to(d.node.position)<2.5:
			weapon_bonus=maxi(weapon_bonus,d.bonus)
			coins+=10
			d.node.queue_free()
			d.label.queue_free()
			drops.erase(d)
			notify("已拾取猎刃，自动装备较高伤害武器；碎片 +10。")
			return
	if player.position.distance_to(Vector3(0,0,12))<4:
		hp=max_hp()
		stamina=100
		if test_mode: return
		var config := ConfigFile.new()
		talents.save_to(config)
		config.set_value("build","weapon",weapon_bonus)
		config.set_value("story","version",1)
		config.set_value("story","stage",story.stage)
		config.set_value("story","discovered",story.discovered)
		config.set_value("story","visited",minimap.visited.keys())
		config.set_value("story","gate",gate_open)
		config.set_value("story","chest",chest_open)
		config.set_value("story","coins",coins)
		var healths: Array=[]
		for e in enemies: healths.append(e.hp)
		config.set_value("story","enemies",healths)
		var items: Array=[]
		for d in drops: items.append({"pos":d.node.position-Vector3(0,0.5,0),"bonus":d.bonus})
		config.set_value("story","drops",items)
		var result := config.save(saved_path)
		notify("已恢复并保存剧情、探索区域、掉落与构筑。" if result==OK else "恢复成功，但保存失败："+str(result))
	elif player.position.distance_to(Vector3(-19,0,-35))<3 and not chest_open:
		chest_open=true
		spawn_drop(Vector3(-19,0,-34),false)
		notify("矿工补给箱已打开，再按 E 拾取。")
	elif absf(player.position.z+113)<4 and not gate_open:
		notify("镜庭封印解除，击败前方的魔镜守卫。" if open_story_gate() else "封印未解除：完成毒苹果线索，并清除六名追兵。")
	else:
		notify("靠近剧情地点、掉落物、营地或封印门后按 E。")

func load_build() -> void:
	var config := ConfigFile.new()
	if config.load(saved_path)!=OK: return
	talents.load_from(config)
	weapon_bonus=int(config.get_value("build","weapon",0))
	hp=max_hp()
	if int(config.get_value("story","version",0))!=1: return
	story.stage=clampi(int(config.get_value("story","stage",0)),0,story.landmarks.size())
	var discovered_data = config.get_value("story","discovered",[])
	if discovered_data is Array:
		for i in discovered_data:
			if i is int and i>=0 and i<story.landmarks.size() and not story.discovered.has(i): story.discovered.append(i)
	var visited_data = config.get_value("story","visited",[])
	if visited_data is Array:
		for cell in visited_data:
			if cell is Vector2i and abs(cell.x)<10 and cell.y>=-35 and cell.y<=5: minimap.visited[cell]=true
	var healths = config.get_value("story","enemies",[])
	if healths is Array:
		for i in range(mini(healths.size(),enemies.size())):
			if not (healths[i] is float or healths[i] is int): continue
			enemies[i].hp=clampf(float(healths[i]),0,enemies[i].max)
			if enemies[i].hp<=0:
				kills+=1
				enemies[i].node.hide()
				enemies[i].node.collision_layer=0
				enemies[i].node.collision_mask=0
	if bool(config.get_value("story","gate",false)): open_story_gate()
	chest_open=bool(config.get_value("story","chest",false))
	coins=maxi(0,int(config.get_value("story","coins",0)))
	var items = config.get_value("story","drops",[])
	if items is Array:
		for item in items:
			if item is Dictionary and item.get("pos") is Vector3 and item.get("bonus") is int:
				spawn_drop(item.pos,false,clampi(item.bonus,0,100))
	won=story.stage==story.landmarks.size()