import os

directoryname = "scripts/npc/units"

filenames = os.listdir(directoryname)
with open('scripts/npc/npc_units_custom.txt', 'w') as outfile:
	with open("scripts/npc/units_start_template.txt") as infile:
		outfile.write(infile.read())
	for fname in filenames:
		with open(os.path.join(directoryname, fname)) as infile:
			outfile.write(infile.read())
	with open("scripts/npc/abilities_end_template.txt") as infile:
		outfile.write(infile.read())