extends Node

var meal_types : Dictionary = {
	0: {
		"name" : "omurice",
		"price" : 50
	},
	1: {
		"name" : "cat_latte",
		"price" : 75
	},
}

var inventory : Dictionary = {
	0: {
		"name" : "omurice",
		"price" : 50,
		"count" : 0
	},
	1: {
		"name" : "cat_latte",
		"price" : 75,
		"count" : 0
	},
}

var shop : Dictionary = {
	0 : {
		"name" : "chef_cat",
		"price" : 1000,
		"buyed" : false
	},
	1 : {
		"name" : "cats",
		"price" : 500,
	}
}
