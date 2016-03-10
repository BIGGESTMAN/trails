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

		if not ':' in line and not '-' in line and not '(' in line:
			ability = {}
			ability['name'] = line
			ability['desc'] = ""
			ability['effects'] = []
			abilities.append(ability)
			continue
		if '-' in line:
			ability['desc'] = ability['desc'] + line
			continue
		if ":" in line and line[-1:] != ")":
			ability['desc'] = ability['desc'] + "\n<font color='#FE9A2E'>" + line.replace(" :", ":</font>")
			continue

		if (not ability) or ("(" not in line) or (line[-1:] != ")"):
			continue

		effect, value = line.split(')')
		name, key = effect.split(" (")
		key = key.replace(" ", "_")
		ability['effects'].append((name.upper() + ":", key.capitalize()))
ability = None

with open('resource/tooltips/master_quartz_tooltips.txt', mode='w', encoding='utf-8') as outfile:
	outfile.write("\n")
	for ability in abilities:
		name = ability['name'].replace(" ", "_")
		outfile.write('\t\t{}{}" "{}"\n'.format(ability_prefix, name, ability['name']))
		outfile.write('\t\t{}{}_Description" "{}"\n'.format(ability_prefix, name, ability['desc']))

		for effect, key in ability['effects']:
			outfile.write('\t\t{}{}_{}" "{}"\n'.format(ability_prefix, name, key, effect))
		outfile.write("\n")
