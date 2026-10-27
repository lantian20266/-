extends Control
## Orthographic projection of a rotatable spherical passive graph.
signal picked(id: String)
var model
var yaw := 0.0
var pitch := -0.12
var zoom := 1.0
var dragging := false
var drag_distance := 0.0
var selected := ""
var hovered := ""
var projected: Dictionary = {}
const COLORS = [Color("e9ad63"),Color("af9bea"),Color("e77791"),Color("69d5c5"),Color("86b8f4")]

func _ready() -> void:
	clip_contents=true
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)

func focus_class() -> void:
	yaw=-model.start_id*TAU/10.0
	pitch=-0.85
	zoom=1.0
	selected=model.root_id()
	queue_redraw()

func sphere_point(lon: float, lat: float) -> Vector3:
	var v := Vector3(sin(lon+yaw)*cos(lat),sin(lat),cos(lon+yaw)*cos(lat))
	return v.rotated(Vector3.RIGHT,pitch)

func screen_point(v: Vector3) -> Vector2:
	return size*Vector2(0.5,0.49)+Vector2(v.x,-v.y)*radius()

func radius() -> float:
	return minf(size.x*0.43,size.y*0.40)*zoom

func nearest(point: Vector2) -> String:
	var best := ""
	var distance := 12.0
	for id in projected:
		if projected[id].z<0.08: continue
		var d := point.distance_to(screen_point(projected[id]))
		if d<distance:
			distance=d
			best=id
	return best

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom=clampf(zoom+0.2,0.7,4.0)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom=clampf(zoom-0.2,0.7,4.0)
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging=true
				drag_distance=0
			else:
				dragging=false
				if drag_distance<6:
					var id := nearest(event.position)
					if not id.is_empty():
						selected=id
						picked.emit(id)
		accept_event()
	if event is InputEventMouseMotion:
		if dragging:
			drag_distance+=event.relative.length()
			yaw+=event.relative.x*0.008
			pitch=clampf(pitch+event.relative.y*0.006,-1.2,1.2)
		hovered=nearest(event.position)
		tooltip_text="" if hovered.is_empty() else model.nodes[hovered].title+"\n"+model.effect_text(hovered)
	queue_redraw()

func _draw() -> void:
	if model==null: return
	var center := size*Vector2(0.5,0.49)
	var r := radius()
	draw_circle(center,r+5,Color("152b3b"))
	draw_circle(center,r,Color("09141f"))
	# Sphere meridians and parallels, attenuated on the far hemisphere.
	for meridian in range(12):
		var previous := sphere_point(meridian*TAU/12.0,-PI/2)
		for step in range(1,49):
			var v := sphere_point(meridian*TAU/12.0,-PI/2+step*PI/48)
			draw_line(screen_point(previous),screen_point(v),Color(0.18,0.34,0.44,0.3 if v.z>0 else 0.07),1,true)
			previous=v
	for latitude in range(-3,4):
		var previous := sphere_point(0,latitude*PI/8)
		for step in range(1,97):
			var v := sphere_point(step*TAU/96,latitude*PI/8)
			draw_line(screen_point(previous),screen_point(v),Color(0.18,0.34,0.44,0.3 if v.z>0 else 0.07),1,true)
			previous=v
	projected.clear()
	for id in model.nodes:
		var n: Dictionary=model.nodes[id]
		if n.kind!="asc": projected[id]=sphere_point(n.lon,n.lat)
	for edge in model.edges:
		var start: Vector3=projected[edge[0]]
		var end: Vector3=projected[edge[1]]
		var lit: bool=model.active(edge[0]) and model.active(edge[1])
		var previous := start
		for step in range(1,17):
			var v := start.slerp(end,float(step)/16).normalized()
			var col := Color("e5c581") if lit else Color("385566")
			col.a=0.9 if v.z>0 else 0.14
			draw_line(screen_point(previous),screen_point(v),col,2.5 if lit else 1.5,true)
			previous=v
	var ordered: Array=projected.keys()
	ordered.sort_custom(func(a,b): return projected[a].z<projected[b].z)
	for id in ordered:
		var n: Dictionary=model.nodes[id]
		var v: Vector3=projected[id]
		var p := screen_point(v)
		var visible_front := v.z>0.08
		var col: Color=COLORS[n.sector]
		var learned: bool=model.active(id)
		var available: bool=model.can_allocate(id)
		var node_radius := (8.0 if n.kind in ["root","keystone"] else 5.0 if n.kind=="notable" else 3.0)*clampf(zoom,0.85,1.3)
		col.a=1.0 if visible_front else 0.15
		if available and visible_front: draw_circle(p,node_radius+5,Color(0.9,0.78,0.48,0.2))
		draw_circle(p,node_radius+2,col)
		draw_circle(p,node_radius,col if learned else Color("101e2b") if visible_front else Color("0b1721"))
		if n.kind=="keystone":
			draw_polyline(PackedVector2Array([p+Vector2(0,-6),p+Vector2(6,0),p+Vector2(0,6),p+Vector2(-6,0),p+Vector2(0,-6)]),col,1.5,true)
		if learned and visible_front: draw_circle(p,2.5,Color("fff2ca"))
		if (id==selected or id==hovered) and visible_front: draw_arc(p,node_radius+8,0,TAU,40,Color("fff1c7"),2,true)
		if visible_front and n.kind=="root":
			draw_string(ThemeDB.fallback_font,p+Vector2(-30,29),n.title,HORIZONTAL_ALIGNMENT_LEFT,-1,16,col)
