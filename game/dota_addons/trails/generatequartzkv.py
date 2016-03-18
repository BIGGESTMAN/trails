import os

name_prefix = "item_"
master_name_prefix = "item_master_"
directoryname = "hero_abilities"
filenames = os.listdir(directoryname)

target_type_strings = {'U' : "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET", 'A' : "DOTA_ABILITY_BEHAVIOR_POINT_TARGET | DOTA_ABILITY_BEHAVIOR_AOE", 'N' : "DOTA_ABILITY_BEHAVIOR_NO_TARGET"}
target_team_strings = {'F' : "DOTA_UNIT_TARGET_TEAM_FRIENDLY", 'E' : "DOTA_UNIT_TARGET_TEAM_ENEMY", 'B' : "DOTA_UNIT_TARGET_TEAM_BOTH"}
element_strings = {'F' : "fire", 'E' : "earth", 'W' : "water", 'I' : "wind", 'T' : "time", 'S' : "space", 'M' : "mirage"}
element_indices = ["F", "E", "W", "I", "T", "S", "M"]
stat_increases = ["bonus_health", "bonus_ep", "bonus_str", "bonus_ats", "bonus_def", "bonus_adf", "bonus_mov", "bonus_spd"]

shop_category_names = {('F', "consumables"), ('E', "attributes"), ('W', "weapons_armor"), ('I', "misc"), ('T', "basics"), ('S', "support"), ('M', "magics")}

items = []
masterquartz = []
item = None

def GetFieldString(field_value):
	field_string = "FIELD_INTEGER"
	if " " in field_value:
		for level_value in field_value.split(" "):
			if not (float(level_value) % 1 == 0):
				field_string = "FIELD_FLOAT"
				break
	else:
		field_value = field_value.replace("%", "")
		if not (float(field_value) % 1 == 0):
			field_string = "FIELD_FLOAT"
	return field_string

def WriteQuartzDefinition(file, item, items_written, masterquartz_level = None):
	inheritedItem = None
	name = None
	script_file = None
	shop_interactions = None
	cost = None
	texture_name = None
	inheritedEffects = []
	if masterquartz_level:
		name = '{}{}_{}'.format(master_name_prefix, item['internal_name'], masterquartz_level)
		script_file = 'master_quartz/{}'.format(item['internal_name'])
		shop_interactions = "0"
		cost = "0"
		texture_name = "item_master_{}".format(item['internal_name'])
		for normalquartz in items:
			if normalquartz['internal_name'] == item['art'].split("/")[masterquartz_level - 1]:
				inheritedItem = normalquartz
				break
		inheritedEffects = inheritedItem['effects']
	else:
		inheritedItem = item
		name = '{}{}'.format(name_prefix, item['internal_name'])
		script_file = 'arts/{}/{}'.format(element_strings[item['element']], item['internal_name'])
		shop_interactions = "1"
		cost = item['quartz_cost']
		texture_name = "item_quartz_{}_{}".format(element_strings[item['element']], item['tier'])
		item['effects'].append(("element", str(element_indices.index(inheritedItem['element']))))

	file.write('\t"{}" {{\n'.format(name))
	file.write('\t\t"ID"\t"{}"\n'.format(2001 + items_written))
	file.write('\t\t"BaseClass"\t"item_lua"\n')
	file.write('\t\t"ScriptFile"\t"{}"\n'.format(script_file))

	channeled_behavior_string = ""
	if ('channel_time' in inheritedItem):
		channeled_behavior_string = " | DOTA_ABILITY_BEHAVIOR_CHANNELED"
	file.write('\t\t"AbilityBehavior"\t"{}{}"\n'.format(target_type_strings[inheritedItem['target_type']], channeled_behavior_string))

	file.write('\t\t"AbilityUnitTargetTeam"\t"{}"\n'.format(target_team_strings[inheritedItem['target_team']]))
	file.write('\t\t"AbilityUnitTargetType"\t"{}"\n'.format("DOTA_UNIT_TARGET_HERO | DOTA_UNIT_TARGET_BASIC"))
	file.write('\t\t"Model"\t"models/props_gameplay/red_box.vmdl"\n')
	file.write('\t\t"Effect"\t"particles/generic_gameplay/dropped_item.vpcf"\n')
	file.write('\t\t"AbilityTextureName"\t"{}"\n'.format(texture_name))
	file.write('\t\t"AbilityCastAnimation"\t"ACT_DOTA_TELEPORT"\n')
	file.write('\t\t"ItemAliases"\t"{}"\n'.format(item['internal_name']))
	file.write('\t\t"AbilityCooldown"\t"{}"\n'.format(inheritedItem['delay']))
	file.write('\t\t"AbilityCastPoint"\t"{}"\n'.format(inheritedItem['cast_point']))
	if ('cast_range' in inheritedItem):
		file.write('\t\t"AbilityCastRange"\t"{}"\n'.format(inheritedItem['cast_range']))
	file.write('\t\t"AbilityManaCost"\t"{}"\n'.format(inheritedItem['manacost']))
	if ('channel_time' in inheritedItem):
		file.write('\t\t"AbilityChannelTime"\t"{}"\n'.format(inheritedItem['channel_time']))
	file.write('\t\t"ItemCost"\t"{}"\n'.format(cost))
	file.write('\t\t"ItemDroppable"\t"{}"\n'.format(shop_interactions))
	file.write('\t\t"ItemSellable"\t"{}"\n'.format(shop_interactions))
	file.write('\t\t"ItemPurchasable"\t"{}"\n'.format(shop_interactions))
	file.write('\t\t"ItemDeclarations"\t"DECLARE_PURCHASES_TO_TEAMMATES | DECLARE_PURCHASES_IN_SPEECH | DECLARE_PURCHASES_TO_SPECTATORS"\n')
	file.write('\t\t"ItemShareability"\t"ITEM_NOT_SHAREABLE"\n')
	if masterquartz_level:
		file.write('\t\t"MaxUpgradeLevel"\t"5"\n')
		file.write('\t\t"ItemBaseLevel"\t"{}"\n'.format(masterquartz_level))
	file.write('\t\t"AbilitySpecial" {\n')
	for key, value in (item['effects']):
			value = value.replace("/", " ")
			file.write('\t\t\t"00" {{\n'.format())
			file.write('\t\t\t\t"var_type"\t"{}"\n'.format(GetFieldString(value)))
			file.write('\t\t\t\t"{}"\t"{}"\n'.format(key, value))
			file.write('\t\t\t}\n')
	for key, value in (inheritedEffects):
		if not key in stat_increases:
			value = value.replace("/", " ")
			file.write('\t\t\t"00" {{\n'.format())
			file.write('\t\t\t\t"var_type"\t"{}"\n'.format(GetFieldString(value)))
			file.write('\t\t\t\t"{}"\t"{}"\n'.format(key, value))
			file.write('\t\t\t}\n')
	file.write('\t\t}\n')
	file.write('\t}\n')


for fname in filenames:
	quartzfile = False
	masterquartzfile = False
	with open(os.path.join(directoryname, fname), encoding="utf-8") as infile:
		for line in infile:
			line = line.strip()
			if not line:
				continue

			if not (quartzfile or masterquartzfile):
				if (line == "Quartz"):
					quartzfile = True
					continue
				elif (line == "Master Quartz"):
					masterquartzfile = True
					continue
				else:
					break

			if quartzfile:
				if line[0] == '[':
					item = {}
					item['element'] = line[1]
					item['tier'] = line[2]
					item['target_type'] = line[3]
					item['target_team'] = line[4]
					truncated_line = line[len('[----] '):]
					item['name'], rest_of_line = truncated_line.split(' (')
					item['internal_name'], item['desc'] = rest_of_line.split(") : ")

					item['effects'] = []
					items.append(item)
					continue

				if ("EP Cost" in line):
					nil, item['manacost'] = line.split(': ')
					continue
				if ("Cast Range" in line):
					nil, item['cast_range'] = line.split(': ')
					continue
				if ("Cast Point" in line):
					nil, item['cast_point'] = line.split(': ')
					continue
				if ("Delay" in line):
					nil, item['delay'] = line.split(': ')
					continue
				if (line[:len("Price : ")] == "Price : "):
					nil, item['quartz_cost'] = line.split(': ')
					continue
				if (line[:len("Max Channel Duration : ")] == "Max Channel Duration : "):
					nil, item['channel_time'] = line.split(': ')
					continue
				
				if (not item) or ("(" not in line):
					continue

				effect, value = line.split(') :')
				name, key = effect.split(" (")
				key = key.replace(" ", "_")
				item['effects'].append((key, value[1:]))
			else:
				if not ':' in line and not '-' in line and not '(' in line:
					item = {}
					item['name'] = line
					item['effects'] = []
					item['internal_name'] = item['name'].lower()
					masterquartz.append(item)
					continue

				if ("Art - " in line):
					nil, item['art'] = line.split("- ")
					item['art'] = item['art'].lower().replace(" ", "_")
					if not "/" in item['art']:
						for i in range(0, 4):
							item['art'] = item['art'] + "/" + item['art'] # pretend it says the art name individually for each level
					continue

				if (not item) or (") : " not in line):
					continue

				effect, values = line.split(') : ')
				name, key = effect.split(" (")
				key = key.replace(" ", "_")
				item['effects'].append((key, values))
	item = None


items_written = 0
with open('scripts/npc/items/generated_items.txt', mode='w', encoding='utf-8') as outfile:
	outfile.write("\n")
	for item in items:
		WriteQuartzDefinition(outfile, item, items_written)
		items_written = items_written + 1

with open('scripts/npc/items/generated_masterquartz_items.txt', mode='w', encoding='utf-8') as outfile:
	for item in masterquartz:
		for i in range(1,6):
			WriteQuartzDefinition(outfile, item, items_written, i)
			items_written = items_written + 1

with open('scripts/shops.txt', mode='w', encoding='utf-8') as outfile:
	with open("scripts/shops_start_template.txt") as infile:
		outfile.write(infile.read())
	for element, category in shop_category_names:
		outfile.write('\t"{}"\n\t{{\n'.format(category))

		for item in items:
			if (item['element'] == element):
				outfile.write('\t\t"item"\t"{}{}"\n'.format(name_prefix, item['internal_name']))
		outfile.write('\t}\n\n')
	with open("scripts/shops_end_template.txt") as infile:
		outfile.write(infile.read())