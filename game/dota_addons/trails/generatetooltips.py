import os

ability_prefix = "\"DOTA_Tooltip_Ability_"
modifier_prefix = "\"DOTA_Tooltip_"
item_prefix = "item_"
directoryname = "hero_abilities"
filenames = os.listdir(directoryname)

special_values = ["Note", "Lore"]

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
				print(truncated_line)
				ability['name'], rest_of_line = truncated_line.split(' (')
				ability['internal_name'], ability['desc'] = rest_of_line.split(") : ")

				ability['effects'] = []
				if ability['desc'][:len("S-Craft")] == "S-Craft":
					nil, description_string = ability['desc'].split(": ")
					ability['desc'] = "<font color='#FE9A2E'>S-Craft</font>: {}".format(description_string)
				abilities.append(ability)
				continue

			if line[0] == '~':
				print(line)
				modifier = {}
				truncated_line = line[len('~ '):]
				modifier['name'], rest_of_line = truncated_line.split(' (')
				modifier['internal_name'], modifier['desc'] = rest_of_line.split(") : ")
				# print(modifier['name'])
				# print(modifier['internal_name'])
				# print(modifier['desc'])
				modifiers.append(modifier)
				continue

			# print(line)

			if (line[:len("Enhanced : ")] == "Enhanced : "):
				ability['desc'] = ability['desc'] + "\n<font color='#FE9A2E'>{}</font>".format(line)

			if ("Delay" in line):
				nil, ability['delay'] = line.split(': ')
				continue
			
			if (not ability) or ("(" not in line):
				continue

			special = any((special_value in line) for special_value in special_values)

			effect, value = line.split(') :')
			name, key = effect.split(" (")
			# print(name)
			# print(key)
			key = key.replace(" ", "_")
			if not special:
				ability['effects'].append((name.upper() + ":", key.capitalize()))
			else:
				ability['effects'].append((value[1:], key.capitalize()))
	ability = None

with open('resource/tooltips/generated_tooltips.txt', mode='w', encoding='utf-8') as outfile:
	outfile.write("\n")
	for ability in abilities:
		current_ability_prefix = ability_prefix
		if ability['is_quartz']:
			current_ability_prefix = current_ability_prefix + item_prefix

		name = ability['internal_name'].replace(" ", "_")
		outfile.write('\t\t{}{}" "{}"\n'.format(current_ability_prefix, name, ability['name']))

		delay_string = ""
		if ability['is_quartz']:
			delay_string = r"\n\n<font color='#0040FF'>DELAY: {}</font>".format(ability['delay'])
		outfile.write('\t\t{}{}_Description" "{}{}"\n'.format(current_ability_prefix, name, ability['desc'], delay_string))

		for effect, key in ability['effects']:
			# print(key)
			# print(effect)
			outfile.write('\t\t{}{}_{}" "{}"\n'.format(current_ability_prefix, name, key, effect))
		outfile.write("\n")
	for modifier in modifiers:
		name = modifier['internal_name'].replace(" ", "_")
		print('\t\t{}{}" "{}"\n'.format(modifier_prefix, name, modifier['name']))
		print('\t\t{}{}_Description" "{}"\n'.format(modifier_prefix, name, modifier['desc']))
		outfile.write('\t\t{}{}" "{}"\n'.format(modifier_prefix, name, modifier['name']))
		outfile.write('\t\t{}{}_Description" "{}"\n'.format(modifier_prefix, name, modifier['desc']))
		outfile.write("\n")
