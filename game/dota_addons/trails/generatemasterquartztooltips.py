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
		if ":" in line and line[-1:] != ")" and (not ") : " in line):
			# num_of_existing_effects = len(ability['desc_lines'])
			ability['desc_lines'].append((line.split(" : ")))
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
			for effect, key in ability['effects']:
				# effect_num = ability['effects'].index((effect,key)) + 1
				# if effect_num <= i:
					# outfile.write('\t\t{}{}_{}" "{}"\n'.format(ability_prefix, name, key, effect))
				outfile.write('\t\t{}{}_{}" "{}"\n'.format(ability_prefix, name, key, effect))
			outfile.write("\n")

with open('panorama/localization/panoramatooltips/master_quartz_tooltips.txt', mode='w', encoding='utf-8') as outfile:
	outfile.write("\n")
	for ability in abilities:
		for effect,description in ability['desc_lines']:
			outfile.write('\t"masterquartz_{}_desc" "{}"\n'.format(effect.replace(" ", "_"), description))
			outfile.write('\t"masterquartz_{}" "{}"\n'.format(effect.replace(" ", "_"), effect))