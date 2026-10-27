extends RefCounted
## Original connected passive graph. Rendering never controls eligibility.
signal changed

const CLASS_NAMES = ["战士", "法师", "刺客", "辅助", "射手"]
const ASC_NAMES = [["圣炉卫士", "裂地征服者"], ["星镜贤者", "灾厄织者"], ["噬影猎手", "绯刃舞者"], ["命线织者", "黎明颂者"], ["逐月游侠", "机关猎师"]]
const EFFECT_NAMES = {"damage":"攻击伤害", "heavy":"重击伤害", "life":"生命上限", "regen":"每秒耐力恢复", "skill":"震荡伤害", "heal":"击杀恢复生命", "speed":"移动速度", "reach":"攻击距离", "cooldown":"震荡冷却缩减", "guard":"受到伤害减免"}
const FLAT = ["life", "regen", "heal"]
var nodes: Dictionary = {}
var edges: Array = []
var allocated: Array = []
var asc_allocated: Array = []
var class_id := 0
var ascendancy := -1
const MAX_POINTS := 140
const START_NAMES = ["铁壁", "破军", "星镜", "灾厄", "暗影", "绯刃", "命线", "黎明", "逐月", "机关"]
var start_id := 0
var points := MAX_POINTS
var asc_points := 4

func _init() -> void:
	build_graph()

func add_node(id: String, title: String, lon: float, lat: float, effects: Dictionary, kind: String, sector: int) -> void:
	nodes[id]={"id":id,"title":title,"lon":lon,"lat":lat,"effects":effects,"kind":kind,"sector":sector,"neighbors":[]}

func link(a: String, b: String) -> void:
	edges.append([a,b])
	nodes[a].neighbors.append(b)
	nodes[b].neighbors.append(a)

func build_graph() -> void:
	var keys := ["life","heavy","skill","cooldown","damage","speed","regen","heal","reach","damage"]
	var values := [3.0,0.018,0.018,0.003,0.012,0.003,0.25,0.25,0.004,0.012]
	var titles := ["坚韧","碎甲","镜火","咏唱","猎刃","轻步","回息","续命","远锋","精准"]
	for sector in range(10):
		var lon := sector*TAU/10.0
		var class_index := int(sector/2.0)
		var root := "root_%d"%sector
		add_node(root,START_NAMES[sector]+" · 起点",lon,-0.99,{},"root",class_index)
		var previous := root
		for i in range(12):
			var id := "s%d_t%d"%[sector,i]
			add_node(id,START_NAMES[sector]+"·通路 "+str(i+1),lon,-0.83+i*0.15,{keys[sector]:values[sector]},"small",class_index)
			link(previous,id)
			previous=id
		for branch in range(8):
			previous="s%d_t%d"%[sector,branch+2]
			for j in range(6):
				var id := "s%d_b%d_%d"%[sector,branch,j]
				var key_index := (sector+branch)%10
				var effects := {keys[key_index]:values[key_index]}
				var kind := "small"
				var title: String=START_NAMES[sector]+"·"+titles[key_index]+" %d-%d"%[branch+1,j+1]
				if j==4:
					kind="notable"
					effects[keys[key_index]]*=3
				if j==5 and branch%2==0:
					kind="keystone"
					effects[keys[key_index]]*=5
					effects["life"] = float(effects.get("life",0))-5.0
					if keys[key_index]=="life": effects["damage"]=-0.015
					title=START_NAMES[sector]+"·逆命 "+str(branch+1)
				add_node(id,title,lon+0.067*(j+1),-0.83+(branch+2)*0.15+sin(j*PI/5.0)*0.04,effects,kind,class_index)
				link(previous,id)
				previous=id
	# Connect sectors at three latitude bands without routing through foreign roots.
	for sector in range(10):
		for branch in [0,4,7]:
			link("s%d_b%d_5"%[sector,branch],"s%d_t%d"%[(sector+1)%10,branch+2])
	var asc_effects := [[{"guard":0.06},{"heavy":0.15}],[{"skill":0.15},{"cooldown":0.04}],[{"damage":0.12},{"speed":0.03}],[{"life":15.0},{"regen":2.0}],[{"reach":0.06},{"damage":0.12}]]
	for c in range(5):
		for a in range(2):
			for i in range(4):
				add_node("a%d_%d_%d"%[c,a,i],ASC_NAMES[c][a]+" "+str(i+1),0,0,asc_effects[c][a].duplicate(),"asc",c)

func root_id() -> String:
	return "root_%d"%start_id

func choose_start(value: int) -> void:
	if value<0 or value>=10 or int(value/2.0)!=class_id or value==start_id: return
	reset_passives()
	start_id=value
	changed.emit()

func grant_points(amount: int) -> void:
	points=clampi(points+maxi(amount,0),0,MAX_POINTS-allocated.size())
	changed.emit()

func active(id: String) -> bool:
	return id==root_id() or allocated.has(id) or asc_allocated.has(id)

func can_allocate(id: String) -> bool:
	if not nodes.has(id) or active(id): return false
	if nodes[id].kind=="asc":
		if ascendancy<0 or asc_points<=0: return false
		for i in range(4):
			if id=="a%d_%d_%d"%[class_id,ascendancy,i]:
				return i==0 or asc_allocated.has("a%d_%d_%d"%[class_id,ascendancy,i-1])
		return false
	if points<=0 or allocated.size()>=MAX_POINTS or nodes[id].kind=="root": return false
	for neighbor in nodes[id].neighbors:
		if active(neighbor): return true
	return false

func allocate(id: String) -> bool:
	if not can_allocate(id): return false
	if nodes[id].kind=="asc":
		asc_allocated.append(id)
		asc_points-=1
	else:
		allocated.append(id)
		points-=1
	changed.emit()
	return true

func reset_passives() -> void:
	points+=allocated.size()
	allocated.clear()
	changed.emit()

func choose_class(value: int) -> void:
	if value<0 or value>4 or value==class_id: return
	points+=allocated.size()
	allocated.clear()
	asc_points+=asc_allocated.size()
	asc_allocated.clear()
	class_id=value
	start_id=value*2
	ascendancy=-1
	changed.emit()

func choose_ascendancy(value: int) -> void:
	if value<0 or value>1 or value==ascendancy: return
	asc_points+=asc_allocated.size()
	asc_allocated.clear()
	ascendancy=value
	changed.emit()

func bonus(key: String) -> float:
	var total := 0.0
	for id in allocated+asc_allocated:
		total+=float(nodes[id].effects.get(key,0.0))
	return total

func effect_text(id: String) -> String:
	var lines := PackedStringArray()
	for key in nodes[id].effects:
		var value: float=nodes[id].effects[key]
		lines.append("%s %s%s%s"%[EFFECT_NAMES[key],"+" if value>=0 else "",str(snappedf(value if key in FLAT else value*100,0.1)),"" if key in FLAT else "%"])
	return "职业起点；向相邻连线延伸。" if lines.is_empty() else "\n".join(lines)

func save_to(config: ConfigFile) -> void:
	config.set_value("planet","version",2)
	config.set_value("planet","start",start_id)
	config.set_value("planet","class",class_id)
	config.set_value("planet","asc",ascendancy)
	config.set_value("planet","allocated",allocated)
	config.set_value("planet","asc_allocated",asc_allocated)
	config.set_value("planet","points",points)
	config.set_value("planet","asc_points",asc_points)

func load_from(config: ConfigFile) -> void:
	allocated.clear()
	asc_allocated.clear()
	points=MAX_POINTS
	asc_points=4
	if int(config.get_value("planet","version",0))!=2:
		# Old IDs describe a different graph; refund instead of misassigning talents.
		class_id=0
		start_id=0
		ascendancy=-1
		changed.emit()
		return
	class_id=clampi(int(config.get_value("planet","class",0)),0,4)
	start_id=clampi(int(config.get_value("planet","start",class_id*2)),class_id*2,class_id*2+1)
	ascendancy=clampi(int(config.get_value("planet","asc",-1)),-1,1)
	var raw = config.get_value("planet","allocated",[])
	var pending: Array = raw.duplicate() if raw is Array else []
	for _pass in range(MAX_POINTS):
		var progress := false
		for id in pending.duplicate():
			if id is String and nodes.has(id) and nodes[id].kind!="asc" and allocate(id):
				pending.erase(id)
				progress=true
		if not progress: break
	raw=config.get_value("planet","asc_allocated",[])
	var pending_asc: Array=raw if raw is Array else []
	for i in range(4):
		var id := "a%d_%d_%d"%[class_id,ascendancy,i]
		if pending_asc.has(id): allocate(id)
	changed.emit()