import os

ability_prefix = "\"DOTA_Tooltip_Ability_item_master_"
directoryname = "hero_abilities"
filename = "Master Quartz.txt"

special_values = ["Note", "Lore"]

abilities = []
ability = None

with open(os.path.join(directoryname, filename), encoding="utf-8") as infile:
	for line in infile:
		line = line.strip()
		if not line:
			continue

		if not ':' in line and not '-' in line and not '(' in line and (not line == "Master Quartz"):
			ability = {}
			ability['name'] = line
			ability['desc_lines'] = []
			ability['effects'] = []
			abilities.append(ability)
			continue
		if '-' in line:
			ability['desc_lines'].append(line)
			continue
		if ":" in line and line[-1:] != ")" and (not ") : " in line):
			# num_of_existing_effects = len(ability['desc_lines'])
			ability['desc_lines'].append("\n<font color='#FE9A2E'>" + line.replace(" :", ":</font>"))
			continue

		if (not ability) or ("(" not in line) or (line[:1] == "~"):
			continue

		effect, value = line.split(')')
		name, key = effect.split(" (")
		key = key.replace(" ", "_")
		ability['effects'].append((name.upper() + ":", key.capitalize()))
ability = None

with open('resource/tooltips/master_quartz_tooltips.txt', mode='w', encoding='utf-8') as outfile:
	outfile.write("\n")
	for ability in abilities:
		for i in range(1,6):
			name = ability['name'].replace(" ", "_") + "_" + str(i)
			outfile.write('\t\t{}{}" "{}"\n'.format(ability_prefix, name, ability['name']))
			desc_string = ""
			for line in ability['desc_lines']:
				effect_num = ability['desc_lines'].index(line)
				if effect_num <= i:
					desc_string = desc_string + line
				else:
					desc_string = desc_string + "<font color='#4C4C4C'>" + line.replace("FE9A2E", "633C12") + "</font>"
			outfile.write('\t\t{}{}_Description" "{}"\n'.format(ability_prefix, name, desc_string))

			for effect, key in ability['effects']:
				# effect_num = ability['effects'].index((effect,key)) + 1
				# if effect_num <= i:
					# outfile.write('\t\t{}{}_{}" "{}"\n'.format(ability_prefix, name, key, effect))
				outfile.write('\t\t{}{}_{}" "{}"\n'.format(ability_prefix, name, key, effect))
			outfile.write("\n")
