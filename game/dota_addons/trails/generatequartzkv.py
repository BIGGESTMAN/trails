import os

name_prefix = "item_"
directoryname = "hero_abilities"
filenames = os.listdir(directoryname)

target_type_strings = {'U' : "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET", 'A' : "DOTA_ABILITY_BEHAVIOR_POINT_TARGET | DOTA_ABILITY_BEHAVIOR_AOE", 'N' : "DOTA_ABILITY_BEHAVIOR_NO_TARGET"}
target_team_strings = {'F' : "DOTA_UNIT_TARGET_TEAM_FRIENDLY", 'E' : "DOTA_UNIT_TARGET_TEAM_ENEMY", 'B' : "DOTA_UNIT_TARGET_TEAM_BOTH"}
element_strings = {'F' : "fire", 'E' : "earth", 'W' : "water", 'I' : "wind", 'T' : "time", 'S' : "space", 'M' : "mirage"}

shop_category_names = {('F', "consumables"), ('E', "attributes"), ('W', "weapons_armor"), ('I', "misc"), ('T', "basics"), ('S', "support"), ('M', "magics")}

items = []
item = None

for fname in filenames:
	quartzfile = False
	with open(os.path.join(directoryname, fname), encoding="utf-8") as infile:
		for line in infile:
			line = line.strip()
			if not line:
				continue

			if not quartzfile:
				if ("Quartz" in line):
					quartzfile = True
					continue
				else:
					break

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
	item = None

items_written = 0

with open('scripts/npc/items/generated_items.txt', mode='w', encoding='utf-8') as outfile:
	outfile.write("\n")
	for item in items:
		outfile.write('\t"{}{}" {{\n'.format(name_prefix, item['internal_name']))
		outfile.write('\t\t"ID"\t"{}"\n'.format(2001 + items_written))
		outfile.write('\t\t"BaseClass"\t"item_lua"\n')
		outfile.write('\t\t"ScriptFile"\t"arts/{}/{}"\n'.format(element_strings[item['element']], item['internal_name']))

		channeled_behavior_string = ""
		if ('channel_time' in item):
			channeled_behavior_string = " | DOTA_ABILITY_BEHAVIOR_CHANNELED"
		outfile.write('\t\t"AbilityBehavior"\t"{}{}"\n'.format(target_type_strings[item['target_type']], channeled_behavior_string))

		outfile.write('\t\t"AbilityUnitTargetTeam"\t"{}"\n'.format(target_team_strings[item['target_team']]))
		outfile.write('\t\t"AbilityUnitTargetType"\t"{}"\n'.format("DOTA_UNIT_TARGET_HERO | DOTA_UNIT_TARGET_BASIC"))
		outfile.write('\t\t"Model"\t"models/props_gameplay/red_box.vmdl"\n')
		outfile.write('\t\t"Effect"\t"particles/generic_gameplay/dropped_item.vpcf"\n')
		outfile.write('\t\t"AbilityTextureName"\t"item_quartz_{}_{}"\n'.format(element_strings[item['element']], item['tier']))
		outfile.write('\t\t"AbilityCastAnimation"\t"ACT_DOTA_TELEPORT"\n')
		outfile.write('\t\t"ItemAliases"\t"{}"\n'.format(item['internal_name']))
		outfile.write('\t\t"AbilityCooldown"\t"{}"\n'.format(item['delay']))
		outfile.write('\t\t"AbilityCastPoint"\t"{}"\n'.format(item['cast_point']))
		if ('cast_range' in item):
			outfile.write('\t\t"AbilityCastRange"\t"{}"\n'.format(item['cast_range']))
		outfile.write('\t\t"AbilityManaCost"\t"{}"\n'.format(item['manacost']))
		if ('channel_time' in item):
			outfile.write('\t\t"AbilityChannelTime"\t"{}"\n'.format(item['channel_time']))
		outfile.write('\t\t"ItemCost"\t"{}"\n'.format(item['quartz_cost']))
		outfile.write('\t\t"ItemDroppable"\t"1"\n')
		outfile.write('\t\t"ItemSellable"\t"1"\n')
		outfile.write('\t\t"ItemDeclarations"\t"DECLARE_PURCHASES_TO_TEAMMATES | DECLARE_PURCHASES_IN_SPEECH | DECLARE_PURCHASES_TO_SPECTATORS"\n')
		outfile.write('\t\t"ItemShareability"\t"ITEM_NOT_SHAREABLE"\n')
		outfile.write('\t\t"AbilitySpecial" {\n')
		for key, value in item['effects']:
			outfile.write('\t\t\t"00" {{\n'.format())
			outfile.write('\t\t\t\t"var_type"\t"FIELD_FLOAT"\n')
			outfile.write('\t\t\t\t"{}"\t"{}"\n'.format(key, value))
			outfile.write('\t\t\t}\n')
		outfile.write('\t\t}\n')
		# outfile.write('\t\t"OnSpellStart" {{\n'.format())
		# outfile.write('\t\t\t"RunScript" {{\n'.format())
		# outfile.write('\t\t\t\t"ScriptFile"\t"arts/{}"\n'.format(element_strings[item['element']]))
		# outfile.write('\t\t\t\t"Function"\t"{}SpellCast"\n'.format(item['internal_name'].replace("_", "")))
		# outfile.write('\t\t\t}\n')
		# outfile.write('\t\t}\n')
		# outfile.write('\t\t"Modifiers" {{\n'.format())
		# outfile.write('\t\t\t"modifier_item_{}_passive" {{\n'.format(item['internal_name']))
		# outfile.write('\t\t\t\t"Passive"\t"1"\n')
		# outfile.write('\t\t\t\t"IsHidden"\t"1"\n')
		# outfile.write('\t\t\t\t"Properties" {{\n'.format())
		# outfile.write('\t\t\t\t\t"MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE"\t"{}"\n'.format("%bonus_str"))
		# outfile.write('\t\t\t\t\t"MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS"\t"{}"\n'.format("%bonus_def"))
		# outfile.write('\t\t\t\t}\n')
		# outfile.write('\t\t\t}\n')
		# outfile.write('\t\t}\n')
		outfile.write('\t}\n')
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