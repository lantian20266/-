extends Control

var model
var game
var globe
var header: Label
var detail: Label
var summary: Label
var learn: Button
var class_picker: OptionButton
var start_picker: OptionButton
var asc_buttons: Array = []
var asc_nodes: Array = []
var selected := ""

func label_for(parent: Node, value: String, font_size: int=17) -> Label:
	var l := Label.new()
	l.text=value
	l.add_theme_font_size_override("font_size",font_size)
	parent.add_child(l)
	return l

func button_for(parent: Node, value: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text=value
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color=Color("080f19")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,22)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",12)
	margin.add_child(layout)
	var top := HBoxContainer.new()
	layout.add_child(top)
	header=label_for(top,"星球天赋 · 失序星图",24)
	header.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button_for(top,"回到职业起点",func(): globe.focus_class(); select_node(model.root_id()))
	button_for(top,"返回战斗 [Tab]",hide)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",22)
	layout.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	label_for(left,"拖动旋转星球 · 滚轮缩放 · 点击节点查看 / 学习",17)
	globe=preload("res://talent_globe.gd").new()
	globe.model=model
	globe.size_flags_vertical=Control.SIZE_EXPAND_FILL
	globe.picked.connect(select_node)
	left.add_child(globe)
	label_for(left,"实心：已学习   金色光圈：可学习   ◇：核心天赋（有收益与代价）",15)
	label_for(left,"沿连线从职业起点延伸，可跨入其他职业区域；背面节点转到正面后选择。",14)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x=372
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",10)
	scroll.add_child(right)
	class_picker=OptionButton.new()
	class_picker.focus_mode=Control.FOCUS_NONE
	for name_value in model.CLASS_NAMES: class_picker.add_item(name_value)
	class_picker.item_selected.connect(func(index: int): model.choose_class(index); globe.focus_class(); select_node(model.root_id()))
	right.add_child(class_picker)
	label_for(right,"出发点 · 每职业二选一",18)
	start_picker=OptionButton.new()
	start_picker.focus_mode=Control.FOCUS_NONE
	start_picker.item_selected.connect(func(index: int): model.choose_start(model.class_id*2+index); globe.focus_class(); select_node(model.root_id()))
	right.add_child(start_picker)
	label_for(right,"升华 · 每职业二选一",20)
	var asc_row := HBoxContainer.new()
	right.add_child(asc_row)
	for i in range(2):
		var b := button_for(asc_row,"",func(): model.choose_ascendancy(i); select_node("a%d_%d_0"%[model.class_id,i]))
		b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		asc_buttons.append(b)
	for i in range(4):
		var b := button_for(right,"",func(): select_node("a%d_%d_%d"%[model.class_id,model.ascendancy,i]))
		asc_nodes.append(b)
	detail=label_for(right,"",18)
	detail.custom_minimum_size.y=125
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	learn=button_for(right,"学习节点",func():
		model.allocate(selected)
		refresh()
	)
	summary=label_for(right,"",15)
	button_for(right,"重置普通天赋 · 全额返还",model.reset_passives)
	label_for(right,"600 个可学习天赋 / 10 个出发点\n灰盒提供 140 普通点，升华另计 4 点。\n切换起点返还普通点；切换职业全部返还。\n营地 E 保存；正式升级发点待加入。",14)
	label_for(right,"手感调节",18)
	for i in range(3):
		label_for(right,["移动速度","攻击动作速度","攻击距离倍率"][i],14)
		var slider := HSlider.new()
		slider.min_value=3.0 if i==0 else 0.6
		slider.max_value=10.0 if i==0 else 1.8
		slider.step=0.05
		slider.value=game.tuning[i]
		slider.value_changed.connect(func(value: float): game.tuning[i]=value)
		right.add_child(slider)
	button_for(right,"重新开始试炼（载入营地存档）",func(): get_tree().reload_current_scene())
	model.changed.connect(refresh)
	globe.focus_class()
	select_node(model.root_id())

func select_node(id: String) -> void:
	selected=id
	globe.selected=id
	refresh()

func refresh() -> void:
	if not is_instance_valid(header): return
	header.text="星球天赋  /  已用 %d / 140 · 剩余 %d · 升华 %d"%[model.allocated.size(),model.points,model.asc_points]
	class_picker.select(model.class_id)
	start_picker.clear()
	for i in range(2): start_picker.add_item(model.START_NAMES[model.class_id*2+i])
	start_picker.select(model.start_id%2)
	for i in range(2):
		asc_buttons[i].text=("● " if i==model.ascendancy else "○ ")+model.ASC_NAMES[model.class_id][i]
	for i in range(4):
		var b: Button=asc_nodes[i]
		b.visible=model.ascendancy>=0
		if model.ascendancy>=0:
			var id := "a%d_%d_%d"%[model.class_id,model.ascendancy,i]
			b.text="%s %d · %s"%["◆" if model.active(id) else "◇",i+1,model.nodes[id].title]
	if model.nodes.has(selected):
		var n: Dictionary=model.nodes[selected]
		var state := "已学习" if model.active(selected) else "可学习 · 消耗 1 点" if model.can_allocate(selected) else "尚未连通，或点数不足"
		detail.text=n.title+"\n"+model.effect_text(selected)+"\n\n"+state
		learn.text="学习升华节点 · 1 升华点" if n.kind=="asc" else "学习天赋节点 · 1 天赋点"
		learn.disabled=not model.can_allocate(selected)
	else:
		detail.text="点击星球上的节点查看效果。"
		learn.disabled=true
	summary.text="当前构筑\n攻击 %+d%% · 重击 %+d%% · 震荡 %+d%%\n生命 %d · 耐力恢复 %.1f / 秒\n移速 %+d%% · 距离 %+d%%\n减伤 %.0f%% · 震荡冷却 %.2f 秒"%[model.bonus("damage")*100,model.bonus("heavy")*100,model.bonus("skill")*100,game.max_hp(),19+model.bonus("regen"),model.bonus("speed")*100,model.bonus("reach")*100,clampf(model.bonus("guard"),-0.5,0.65)*100,game.skill_cooldown()]
	globe.queue_redraw()
