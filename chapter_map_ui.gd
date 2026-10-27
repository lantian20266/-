extends Control

var game
var cards: Array[Button]=[]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color=Color(0.015,0.025,0.04,0.91)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,55)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	margin.add_child(column)
	var heading := Label.new()
	heading.text="第一章 · 王后的命令    章节路线 [M 返回]"
	heading.add_theme_font_size_override("font_size",28)
	column.add_child(heading)
	var subtitle := Label.new()
	subtitle.text="8张必经地图 · 主线结算等级 1 → 10 · 下一章需完成七山隘口"
	subtitle.add_theme_font_size_override("font_size",17)
	column.add_child(subtitle)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",6)
	scroll.add_child(list)
	for i in range(game.campaign.MAPS.size()):
		var data: Dictionary=game.campaign.MAPS[i]
		var b := Button.new()
		b.custom_minimum_size.y=66
		b.alignment=HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode=Control.FOCUS_NONE
		b.pressed.connect(func(): select_map(i))
		list.add_child(b)
		cards.append(b)
	var footer := Label.new()
	footer.text="当前地图的探索进度独立记录；未完成的出口显示前置条件。世界等级目标不是难度锁。"
	footer.add_theme_font_size_override("font_size",16)
	column.add_child(footer)
	var close := Button.new()
	close.text="返回当前地图 [M]"
	close.pressed.connect(func(): game.toggle_chapter_map())
	column.add_child(close)
	refresh()

func select_map(index: int) -> void:
	if index>game.map_unlocked:
		game.notify("尚未开放：先完成「"+str(game.campaign.MAPS[index-1].goal)+"」。")
		return
	if index==game.map_index:
		game.toggle_chapter_map()
		return
	game.load_campaign_map(index)
	game.toggle_chapter_map()

func refresh() -> void:
	if not is_inside_tree(): return
	for i in range(cards.size()):
		var data: Dictionary=game.campaign.MAPS[i]
		var unlocked := i<=game.map_unlocked
		var completed := game.completed_maps.has(data.id)
		var state := "✓ 已通關" if completed else "◆ 當前" if i==game.map_index else "可前往" if unlocked else "🔒 未解鎖"
		cards[i].text="%02d  %s    等級 %d    %s    %s"%[i+1,data.name,data.level,state,data.goal]
		cards[i].disabled=false
		cards[i].modulate=Color.WHITE if unlocked else Color(0.52,0.56,0.61)
