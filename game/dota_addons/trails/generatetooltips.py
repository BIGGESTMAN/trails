import os

ability_prefix = "\"DOTA_Tooltip_Ability_"
modifier_prefix = "\"DOTA_Tooltip_"
item_prefix = "item_"
directoryname = "hero_abilities"
filenames = os.listdir(directoryname)

special_values = ["Note", "Lore"]
stat_increases = ["bonus_health", "bonus_ep", "bonus_str", "bonus_ats", "bonus_def", "bonus_adf", "bonus_mov", "bonus_spd"]

abilities = []
ability = None
modifiers = []

for fname in filenames:
	with open(os.path.join(directoryname, fname), encoding="utf-8") as infile:
		for line in infile:
			line = line.strip()
			if not line:
				continue

			if line[0] == '[':
				ability = {}
				bracket_info, truncated_line = line[1:].split("] ")
				ability['is_quartz'] = len(bracket_info) > 1
				ability['name'], rest_of_line = truncated_line.split(' (')
				ability['internal_name'], ability['desc'] = rest_of_line.split(") : ")

				ability['effects'] = []
				if ability['desc'][:len("S-Craft")] == "S-Craft":
					nil, description_string = ability['desc'].split(": ")
					ability['desc'] = "<font color='#FE9A2E'>S-Craft</font>: {}".format(description_string)
				abilities.append(ability)
				continue

			if line[0] == '~':
				modifier = {}
				truncated_line = line[len('~ '):]
				modifier['name'], rest_of_line = truncated_line.split(' (')
				modifier['internal_name'], modifier['desc'] = rest_of_line.split(") : ")
				modifiers.append(modifier)
				continue

			if (line[:len("Enhanced : ")] == "Enhanced : ") or (line[:len("200 CP Bonus : ")] == "200 CP Bonus : "):
				ability['Enhanced'] = "\n<font color='#FE9A2E'>{}</font>".format(line)

			if (line[:len("CP Cost : ")] == "CP Cost : "):
				ability['CP_Cost'] = "\n<font color='#01DF01'>{}</font>".format(line)

			if (line[:len("Cast Point : ")] == "Cast Point : "):
				nil, ability['cast_time'] = line.split(': ')
				continue
			
			if (not ability) or ("(" not in line):
				continue

			special = any((special_value in line) for special_value in special_values)

			effect, value = line.split(') :')
			name, key = effect.split(" (")
			key = key.replace(" ", "_")
			if not special:
				ability['effects'].append((name.upper() + ":", key.capitalize(), value))
			else:
				ability['effects'].append((value[1:], key.capitalize(), 0))
	ability = None

with open('resource/tooltips/generated_tooltips.txt', mode='w', encoding='utf-8') as outfile:
	outfile.write("\n")
	for ability in abilities:
		current_ability_prefix = ability_prefix
		if ability['is_quartz']:
			current_ability_prefix = current_ability_prefix + item_prefix

		name = ability['internal_name'].replace(" ", "_")
		outfile.write('\t\t{}{}" "{}"\n'.format(current_ability_prefix, name, ability['name']))

		cast_time_string = ""
		if ability['is_quartz']:
			cast_time_string = r"\n\n<font color='#4080FF'>CAST TIME: {}</font>".format(ability['cast_time'])
			ability['desc'] = ability['desc'] + "<br/>"
			for effect,key,value in ability['effects']:
				if key.lower() in stat_increases:
					ability['desc'] = ability['desc'] + "<br/>    + <font color='#EAA43D'>{}</font> {}".format(value, effect[:-1])
		else:
			if 'CP_Cost' in ability:
				ability['desc'] = ability['desc'] + ability['CP_Cost']
			if 'Enhanced' in ability:
				ability['desc'] = ability['desc'] + ability['Enhanced']
		outfile.write('\t\t{}{}_Description" "{}{}"\n'.format(current_ability_prefix, name, ability['desc'], cast_time_string))

		for effect, key, value in ability['effects']:
			if not key.lower() in stat_increases:
				outfile.write('\t\t{}{}_{}" "{}"\n'.format(current_ability_prefix, name, key, effect))
		outfile.write("\n")
	for modifier in modifiers:
		name = modifier['internal_name'].replace(" ", "_")
		outfile.write('\t\t{}{}" "{}"\n'.format(modifier_prefix, name, modifier['name']))
		outfile.write('\t\t{}{}_Description" "{}"\n'.format(modifier_prefix, name, modifier['desc']))
		outfile.write("\n")
