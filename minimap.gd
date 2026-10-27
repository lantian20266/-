extends Control
## North-up map: compact local view plus an expanded whole-route view.
var game
var expanded := false
var visited: Dictionary = {}
var clock := 0.0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_layout(false)

func set_layout(large: bool) -> void:
	expanded=large
	position=Vector2(330,70) if expanded else Vector2(970,18)
	size=Vector2(590,650) if expanded else Vector2(292,310)
	queue_redraw()

func _process(dt: float) -> void:
	if game==null or not is_instance_valid(game.player) or game.chapter_map_open: return
	clock+=dt
	if clock<0.12: return
	clock=0
	var pos: Vector3=game.player.position
	for x in range(-2,3):
		for z in range(-2,3):
			visited[Vector2i(floori(pos.x/5)+x,floori(pos.z/5)+z)]=true
	game.set_exploration(game.map_id,visited)
	queue_redraw()

func known(pos: Vector2) -> bool:
	return visited.has(Vector2i(floori(pos.x/5),floori(pos.y/5)))

func scale_factor() -> float:
	return 2.8 if expanded else 3.6

func center_world() -> Vector2:
	if expanded: return Vector2(0,0)
	return Vector2(game.player.position.x,game.player.position.z)

func map_point(pos: Vector2) -> Vector2:
	return size*Vector2(0.5,0.48)+(pos-center_world())*scale_factor()

func in_map(p: Vector2) -> bool:
	return Rect2(12,38,size.x-24,size.y-94).has_point(p)

func text_at(p: Vector2, value: String, color: Color=Color.WHITE, font_size: int=13) -> void:
	draw_string(ThemeDB.fallback_font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	if game==null or not is_instance_valid(game.player): return
	draw_style_box(panel_style(),Rect2(Vector2.ZERO,size))
	text_at(Vector2(14,24),"白雪残章 · "+("全图 [M 返回]" if expanded else "小地图 [M 展开]"),Color("e9d7a4"),17)
	var plot := Rect2(12,38,size.x-24,size.y-94)
	var current: Dictionary=game.campaign.MAPS[game.map_index]
	text_at(Vector2(14,plot.position.y+20),"%02d / 08  %s"%[game.map_index+1,current.name],Color("e4d39f"),15)
	for cell in visited:
		var corner := map_point(Vector2(cell)*5)
		var rect := Rect2(corner,Vector2.ONE*5*scale_factor()).intersection(plot)
		if rect.has_area(): draw_rect(rect,Color("25373b"))
	# Each chapter map reveals its own landmarks and local route.
	for point in game.map_route:
		var p := map_point(point)
		if in_map(p) and known(point): draw_circle(p,3,Color("92846a"))
	for marker in game.current_markers:
		var p := map_point(Vector2(marker.pos.x,marker.pos.z))
		if not in_map(p): continue
		var col := Color("70c9a3") if marker.done else Color("e0c26c") if marker.kind=="objective" else Color("b4a3d8")
		draw_circle(p,5,col)
		text_at(p+Vector2(7,-5),marker.label,col,12)
	for e in game.enemies:
		if e.hp<=0: continue
		var pos := Vector2(e.node.position.x,e.node.position.z)
		var p := map_point(pos)
		if known(pos) and in_map(p): draw_circle(p,5 if e.boss else 2.5,Color("ef7878"))
	for marker in game.current_markers:
		if marker.kind!="supply": continue
		var world := Vector2(marker.pos.x,marker.pos.z)
		var p := map_point(world)
		if known(world) and in_map(p): draw_rect(Rect2(p-Vector2.ONE*3,Vector2.ONE*6),Color("69c7db"))
	if game.exit_locked:
		var gate_point: Vector2=map_point(game.exit_position)
		if gate_point.y>plot.position.y and gate_point.y<plot.end.y:
			draw_line(Vector2(clampf(gate_point.x-18,plot.position.x,plot.end.x),gate_point.y),Vector2(clampf(gate_point.x+18,plot.position.x,plot.end.x),gate_point.y),Color("d5809b"),3)
	var target: Vector3=game.current_target
	var raw := map_point(Vector2(target.x,target.z))
	var destination := Vector2(clampf(raw.x,18,size.x-18),clampf(raw.y,44,size.y-62))
	draw_arc(destination,7,0,TAU,24,Color("f5cd63"),2,true)
	if destination.distance_to(raw)>1:
		var direction := (raw-destination).normalized()
		draw_line(destination,destination+direction*9,Color("f5cd63"),2,true)
	var player_pos := map_point(Vector2(game.player.position.x,game.player.position.z))
	var face := Vector2(game.facing.x,game.facing.z).normalized()
	var right_dir := Vector2(-face.y,face.x)
	if in_map(player_pos): draw_colored_polygon(PackedVector2Array([player_pos+face*8,player_pos-face*5+right_dir*5,player_pos-face*5-right_dir*5]),Color("f6fbff"))
	text_at(Vector2(size.x-31,plot.position.y+4),"北",Color("e9d7a4"))
	text_at(Vector2(14,size.y-36),"白▲玩家  金○任务  红●敌人",Color("bac8cc"))
	text_at(Vector2(14,size.y-17),"绿●已完成  紫●线索  蓝■补给",Color("bac8cc"))

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=Color(0.025,0.045,0.065,0.96)
	style.border_color=Color("52636c")
	style.set_border_width_all(1)
	return style
