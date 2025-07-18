extends Control

@onready var panel := $PanelContenido
@onready var btn_inventory := $TabBar/BtnInventory

var inventory_scene := preload("res://scene/Interface/Tabs/InventoryTab.tscn")

func _ready():
	btn_inventory.pressed.connect(show_inventory)
	show_inventory()  # Mostrar primero el inventario al abrir el menú

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		cerrar_menu()

func show_inventory():
	_switch_tab(inventory_scene)

func _switch_tab(scene: PackedScene):
	for child in panel.get_children():
		child.queue_free()
	var new_tab = scene.instantiate()
	panel.add_child(new_tab)

func cerrar_menu():
	get_tree().paused = false
	queue_free()
