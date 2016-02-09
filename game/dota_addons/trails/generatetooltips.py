import os

ability_prefix = "\"DOTA_Tooltip_Ability_"
modifier_prefix = "\"DOTA_Tooltip_"
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
				truncated_line = line[len('[x] '):]
				# print(truncated_line)
				ability['name'], rest_of_line = truncated_line.split(' (')
				ability['internal_name'], ability['desc'] = rest_of_line.split(") : ")

				ability['effects'] = []
				abilities.append(ability)
				continue

			if line[0] == '~':
				print(line)
				modifier = {}
				truncated_line = line[len('~ '):]
				modifier['name'], rest_of_line = truncated_line.split(' (')
				modifier['internal_name'], modifier['desc'] = rest_of_line.split(") : ")
				print(modifier['name'])
				print(modifier['internal_name'])
				print(modifier['desc'])
				modifiers.append(modifier)
				continue

			# print(line)

			# Special case for aghs descriptions, woo good code
			if (ability and "Scepter - " in line):
				ability['effects'].append((line[len("Scepter - "):], "Aghanim_Description"))
				continue
			
			if (not ability) or ("(" not in line) or ("(Scepter" in line):
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
		name = ability['internal_name'].replace(" ", "_")
		outfile.write('\t\t{}{}" "{}"\n'.format(ability_prefix, name, ability['name']))
		outfile.write('\t\t{}{}_Description" "{}"\n'.format(ability_prefix, name, ability['desc']))
		for effect, key in ability['effects']:
			# print(key)
			# print(effect)
			outfile.write('\t\t{}{}_{}" "{}"\n'.format(ability_prefix, name, key, effect))
		outfile.write("\n")
	for modifier in modifiers:
		name = modifier['internal_name'].replace(" ", "_")
		print('\t\t{}{}" "{}"\n'.format(modifier_prefix, name, modifier['name']))
		print('\t\t{}{}_Description" "{}"\n'.format(modifier_prefix, name, modifier['desc']))
		outfile.write('\t\t{}{}" "{}"\n'.format(modifier_prefix, name, modifier['name']))
		outfile.write('\t\t{}{}_Description" "{}"\n'.format(modifier_prefix, name, modifier['desc']))
		outfile.write("\n")
