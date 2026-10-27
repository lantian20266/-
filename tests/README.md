# 测试目录

story_flow_test.gd：50项剧情、碰撞可达性、小地图与存档检查。运行方式为Godot --headless --path 工程目录 --script res://tests/story_flow_test.gd。

应将进程APPDATA和LOCALAPPDATA指定到工作区独立目录，避免接触玩家存档。测试使用story_flow_test.cfg。非headless运行时追加 -- --capture 可输出实机预览图片。地图测试不替代人工战斗与天赋验收。
