extends Node3D
## Story order is independent of exploration; visiting a later landmark cannot skip a clue.
var game
var stage := 0
var discovered: Array = []
var landmarks: Array = []
var route := PackedVector2Array([Vector2(0,12),Vector2(-7,7),Vector2(9,-12),Vector2(-10,-35),Vector2(12,-55),Vector2(-8,-75),Vector2(8,-85),Vector2(8,-99),Vector2(0,-113),Vector2(0,-134),Vector2(-8,-151)])
const MAP_BOUNDS = Rect2(-30,-170,60,190)

func _ready() -> void:
	landmarks=[
		{"id":"decree","name":"王后魔镜","chapter":1,"pos":Vector3(-7,0,7),"text":"魔镜碎片映出王后的命令：白雪必须消失。沿猎人留下的脚印进入森林。"},
		{"id":"hunter","name":"猎人放行处","chapter":1,"pos":Vector3(9,0,-12),"text":"猎人的手记：我放走了那个孩子。她穿过七座山，往矿工的小屋去了。无面的追兵只是魔镜制造的影子。"},
		{"id":"cottage","name":"七人小屋","chapter":2,"pos":Vector3(-10,0,-35),"text":"七只碗、七把椅子和七张小床，证明白雪曾在这里避难。餐桌已陷入地板；一盏矿灯指向山后的矿井。"},
		{"id":"mine","name":"七矮人矿道","chapter":3,"pos":Vector3(12,0,-55),"text":"矿工留下警告：不要给陌生人开门。王后正在伪装成商贩；矿井却传来第八个人的脚步。"},
		{"id":"lace","name":"束身腰带","chapter":4,"pos":Vector3(-8,0,-75),"text":"紧勒的腰带曾让白雪昏倒，七位矿工剪断它救了她。切断残留咒线，循商贩的脚印寻找下一件毒物。"},
		{"id":"comb","name":"淬毒梳子","chapter":4,"pos":Vector3(8,0,-85),"text":"毒梳曾藏在白雪发间，矿工取下梳子才让她醒来。如今梳齿变成地上的尖刺，苹果的甜味从前方飘来。"},
		{"id":"apple","name":"半红毒苹果","chapter":4,"pos":Vector3(8,0,-99),"text":"王后吃下无毒的一半，诱白雪咬下红色的一半。净化苹果残核后，通往镜庭的封印出现裂纹。"},
		{"id":"mirror","name":"镜庭封印","chapter":5,"pos":Vector3(0,0,-134),"text":"魔镜守卫已倒下。镜中倒映出白雪的玻璃棺：故事还停在她倒下的那一页。取回真名，前往圣堂。"},
		{"id":"coffin","name":"玻璃棺圣堂","chapter":6,"pos":Vector3(-8,0,-151),"text":"七位矿工守护着玻璃棺。你用真名稳住棺中的白雪，移去毒苹果残片；她终于醒来。此处是改编版的解救结局。"}
	]
	build_world()

func build_world() -> void:
	game.obstacle(Vector3(0,-0.5,-75),Vector3(60,1,190),Color("283335"))
	for x in [-30,30]: game.obstacle(Vector3(x,1,-75),Vector3(1,3,190),Color("26313b"))
	for z in [20,-170]: game.obstacle(Vector3(0,1,z),Vector3(60,3,1),Color("26313b"))
	# Walkable route ribbon. Props are offset from the route so the story remains reachable.
	for i in range(route.size()-1):
		var a := route[i]
		var b := route[i+1]
		var middle := (a+b)*0.5
		var road = game.box(self,Vector3(middle.x,0.018,middle.y),Vector3(5,0.035,a.distance_to(b)+1),Color("625d4c"))
		road.rotation.y=atan2(b.x-a.x,b.y-a.y)
	for i in range(landmarks.size()):
		var p: Vector3=landmarks[i].pos
		game.box(self,p+Vector3(0,0.025,0),Vector3(9,0.05,8),Color("495152"))
		game.sign_at(p+Vector3(0,3.3,0),"%02d · %s"%[i+1,landmarks[i].name])
		make_prop(i,p)
	# Forest trunks and canopies on the outside of the main route.
	for i in range(20):
		var x := -23.0 if i%2==0 else 23.0
		var z := 4.0-floorf(i/2.0)*9.0
		game.obstacle(Vector3(x,1.5,z),Vector3(1.1,3,1.1),Color("433c31"))
		game.box(self,Vector3(x,4,z),Vector3(4,3,4),Color("25493d"))
	# Increasing furniture subsidence is kept off the clear central walking line.
	for i in range(12):
		var x := -20.0 if i%2==0 else 20.0
		var prop = game.obstacle(Vector3(x,0.9-i*0.085,-30-i*10),Vector3(3,2,1.4),Color("6c5946"))
		prop.rotation.z=i*0.055
	game.gate=game.obstacle(Vector3(0,1.6,-113),Vector3(59,3.2,0.8),Color("70465e"))
	game.sign_at(Vector3(0,4,-113),"镜庭封印 · 毒苹果线索 + 清除六名追兵 · E")
	game.box(self,Vector3(0,0.08,12),Vector3(4,0.16,4),Color("387e78"))
	game.sign_at(Vector3(0,3,12),"林边营地 · E 恢复并保存")
	game.box(self,Vector3(-19,0.5,-35),Vector3(1.5,1,1.2),Color("bc8833"))
	game.sign_at(Vector3(-19,1.7,-35),"矿工补给箱 · E")

func make_prop(index: int, p: Vector3) -> void:
	match index:
		0,7:
			game.obstacle(p+Vector3(0,1.8,-2.5),Vector3(3.2,3.6,0.5),Color("a48c67"))
			game.box(self,p+Vector3(0,1.9,-2.19),Vector3(2.6,2.9,0.12),Color("6f91a8"))
		1:
			game.box(self,p+Vector3(2,0.4,0),Vector3(2,0.8,1),Color("725641"))
			game.box(self,p+Vector3(2,0.9,0),Vector3(0.2,0.15,2.5),Color("bac0ba"))
		2:
			# Open-front cottage with seven seats and seven beds; no roof blocking the camera.
			game.obstacle(p+Vector3(0,1.7,-5),Vector3(12,3.4,0.4),Color("68574a"))
			for side in [-1,1]: game.obstacle(p+Vector3(side*6,1.7,0),Vector3(0.4,3.4,10),Color("68574a"))
			game.obstacle(p+Vector3(0,0.45,-1.8),Vector3(5,0.9,1.5),Color("806849"))
			for j in range(7):
				game.box(self,p+Vector3(-2.1+j*0.7,0.96,-1.8),Vector3(0.35,0.12,0.35),Color("d7ccb7"))
				game.box(self,p+Vector3(-4.5+j*1.5,0.35,-3.8),Vector3(1,0.7,1.5),Color("8c9390"))
				game.box(self,p+Vector3(-3+j,0.25,0.5),Vector3(0.55,0.5,0.55),Color("8d7554"))
		3:
			for side in [-1,1]: game.obstacle(p+Vector3(side*3,2,-3),Vector3(1,4,2),Color("5f636c"))
			game.box(self,p+Vector3(0,4,-3),Vector3(7,1,2),Color("4e535b"))
			for side in [-1,1]: game.box(self,p+Vector3(side*0.7,0.08,0),Vector3(0.1,0.15,7),Color("8b8b82"))
		4,5,6:
			game.obstacle(p+Vector3(2,0.6,0),Vector3(2,1.2,1.6),Color("6c4c3c"))
			if index==4:
				game.box(self,p+Vector3(2,1.3,0),Vector3(1.6,0.1,0.3),Color("b24452"))
			elif index==5:
				for j in range(7): game.box(self,p+Vector3(1.4+j*0.2,1.4,0),Vector3(0.1,0.4,0.4),Color("b8a9d3"))
			else:
				game.box(self,p+Vector3(1.8,1.6,0),Vector3(0.4,0.6,0.6),Color("b73140"))
				game.box(self,p+Vector3(2.2,1.6,0),Vector3(0.4,0.6,0.6),Color("c8cc87"))
		8:
			game.obstacle(p+Vector3(0,0.5,-3),Vector3(2.5,1,4),Color("728c9a"))
			var lid = game.box(self,p+Vector3(0,1.2,-3),Vector3(2.6,0.3,4.1),Color(0.6,0.85,0.92,0.4))
			lid.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			game.box(self,p+Vector3(0,1,-3),Vector3(0.8,0.3,2),Color("dedbd2"))

func discover_nearby(pos: Vector3) -> void:
	for i in range(landmarks.size()):
		if pos.distance_to(landmarks[i].pos)<15 and not discovered.has(i): discovered.append(i)

func nearest(pos: Vector3) -> int:
	var result := -1
	var best := 3.2
	for i in range(landmarks.size()):
		var distance := pos.distance_to(landmarks[i].pos)
		if distance<best:
			best=distance
			result=i
	return result

func interact_at(index: int) -> String:
	if index<0 or index>=landmarks.size(): return ""
	if index>stage: return "这里有故事残痕。请先调查："+str(landmarks[stage].name)
	if index<stage: return str(landmarks[index].text)
	if index==7 and not game.boss_defeated(): return "魔镜仍被守卫控制。先击败镜庭中的魔镜守卫。"
	stage+=1
	if not discovered.has(index): discovered.append(index)
	if stage==landmarks.size(): game.won=true
	return str(landmarks[index].text)

func objective() -> String:
	if stage>=landmarks.size(): return "白雪已苏醒 · 剧情试验完成，可继续探索或回营地保存"
	if stage==7:
		if game.guard_kills()<6: return "清除魔镜追兵 %d / 6，再到封印门按 E"%game.guard_kills()
		if not game.gate_open: return "到镜庭封印门按 E，解除毒苹果的咒印"
		if not game.boss_defeated(): return "击败魔镜守卫，取回白雪的真名"
	return "第%d章节点 · 调查 %s [E]"%[landmarks[stage].chapter,landmarks[stage].name]

func target() -> Vector3:
	if stage>=landmarks.size(): return Vector3(0,0,12)
	if stage==7:
		if game.guard_kills()<6:
			for e in game.enemies:
				if not e.boss and e.hp>0: return e.node.position
		if not game.gate_open: return Vector3(0,0,-110)
		if not game.boss_defeated(): return Vector3(0,0,-125)
	return landmarks[stage].pos
