extends RefCounted

const MAPS = [
	{"id":"CH01_M01","name":"宫廷外苑","goal":"发现王后追杀令","level":3,"enemies":"镜影猎犬、失名追兵","checkpoint":true,"theme":"court"},
	{"id":"CH01_M02","name":"白石回廊","goal":"调查歪斜画像","level":4,"enemies":"镜影猎犬、失名追兵","checkpoint":false,"theme":"hall"},
	{"id":"CH01_M03","name":"魔镜偏殿","goal":"读取魔镜残片","level":5,"enemies":"镜影猎犬、失名追兵","checkpoint":false,"theme":"mirror"},
	{"id":"CH01_M04","name":"王家猎场","goal":"寻找猎人踪迹","level":6,"enemies":"镜影猎犬、失名追兵","checkpoint":false,"theme":"hunt"},
	{"id":"CH01_M05","name":"猎人林道","goal":"读取放行手记","level":7,"enemies":"镜影猎犬、失名追兵","checkpoint":true,"theme":"forest"},
	{"id":"CH01_M06","name":"弃猎营地","goal":"击退魔镜追兵","level":8,"enemies":"镜影猎犬、失名追兵","checkpoint":false,"theme":"camp"},
	{"id":"CH01_M07","name":"回声密林","goal":"用刻痕辨认重复林道","level":9,"enemies":"镜影猎犬、失名追兵","checkpoint":false,"theme":"echo"},
	{"id":"CH01_M08","name":"七山隘口","goal":"击败无面追猎者并开启山路","level":10,"enemies":"镜影猎犬、失名追兵","checkpoint":true,"theme":"pass"}
]

const XP_PER_LEVEL = 100
const XP_QUADRATIC = 50

static func total_xp(level: int) -> int:
	var steps := maxi(level-1,0)
	return XP_QUADRATIC*steps*steps+XP_PER_LEVEL*steps

static func earned_level(xp: int) -> int:
	var level := 1
	while level<60 and total_xp(level+1)<=xp: level+=1
	return level
