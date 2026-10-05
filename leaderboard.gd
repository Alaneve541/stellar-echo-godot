extends Node

# ================= 联网配置 =================
const BLOB_KEY = "Op3JhkmMEYREEHPXvpWksTh8"
const BASE_URL = "https://api.textdb.online"
const READ_URL = "https://textdb.online/"

# ================= 本地备份 =================
const LOCAL_FILE = "user://leaderboard.json"

var entries := []
var http_write: HTTPRequest
var http_read: HTTPRequest
var online_ok := false

func _ready():
	http_write = HTTPRequest.new()
	add_child(http_write)
	http_write.request_completed.connect(_on_write_response)

	http_read = HTTPRequest.new()
	add_child(http_read)
	http_read.request_completed.connect(_on_read_response)

	load_local()
	fetch_online()

func load_local():
	if FileAccess.file_exists(LOCAL_FILE):
		var file = FileAccess.open(LOCAL_FILE, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK:
			var data = json.data
			if data is Dictionary and data.has("entries"):
				entries = data["entries"]
			elif data is Array:
				entries = data

func save_local():
	var file = FileAccess.open(LOCAL_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"entries": entries}, "  "))
	file.close()

func fetch_online():
	var url = READ_URL + BLOB_KEY
	var err = http_read.request(url)
	if err != OK:
		print("联网请求失败: ", err)

func push_online():
	var body = JSON.stringify({"entries": entries})
	var encoded_body = body.uri_encode()
	var url = BASE_URL + "/update/?key=" + BLOB_KEY + "&value=" + encoded_body
	http_write.request(url)
	print("上传排行榜: ", entries.size(), " 条")

func _on_write_response(result, code, headers, body):
	print("上传返回码: ", code)

func _on_read_response(result, code, headers, body):
	print("读取返回码: ", code)
	if code != 200:
		return

	var text = body.get_string_from_utf8()
	print("读取内容: ", text)
	if text == "" or text == "null":
		return

	var json = JSON.new()
	if json.parse(text) != OK:
		return

	var data = json.data
	if data is Dictionary and data.has("entries"):
		entries = data["entries"]
		online_ok = true
		print("联网排行榜: ", entries.size(), " 条")
		save_local()
	elif data is Array:
		entries = data
		online_ok = true
		print("联网排行榜: ", entries.size(), " 条")
		save_local()

func submit(username: String, wave: int, kills: int, level: int):
	if username == "":
		return

	var d = Time.get_date_dict_from_system()
	var date_str = str(d["year"]) + "-" + str(d["month"]) + "-" + str(d["day"])

	var found = false
	for i in range(entries.size()):
		if entries[i]["name"] == username:
			found = true
			if wave > entries[i]["wave"] or (wave == entries[i]["wave"] and kills > entries[i]["kills"]):
				entries[i]["wave"] = wave
				entries[i]["kills"] = kills
				entries[i]["level"] = level
				entries[i]["date"] = date_str
			break

	if not found:
		entries.append({
			"name": username,
			"wave": wave,
			"kills": kills,
			"level": level,
			"date": date_str
		})

	entries.sort_custom(func(a, b):
		if a["wave"] != b["wave"]:
			return a["wave"] > b["wave"]
		return a["kills"] > b["kills"]
	)

	if entries.size() > 50:
		entries = entries.slice(0, 50)

	save_local()
	push_online()

func get_entries() -> Array:
	return entries

func is_online() -> bool:
	return online_ok

func get_text() -> String:
	if entries.size() == 0:
		return "暂无记录"
	var t = ""
	t += "排名   指挥官        波次   击杀   等级   日期\n"
	t += "────────────────────────────────────────\n"
	for i in range(entries.size()):
		var e = entries[i]
		var rank = str(i + 1)
		var name_padded = e["name"]
		while name_padded.length() < 10:
			name_padded += " "
		t += rank + "      " + name_padded + "  " + str(e["wave"]) + "     " + str(e["kills"]) + "     " + str(e["level"]) + "     " + e["date"] + "\n"
	return t
