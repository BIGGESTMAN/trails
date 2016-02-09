import os

directoryname = "scripts/npc/heroes"

filenames = os.listdir(directoryname)
with open('scripts/npc/npc_heroes_custom.txt', 'w') as outfile:
	with open("scripts/npc/heroes_start_template.txt") as infile:
		outfile.write(infile.read())
	for fname in filenames:
		with open(os.path.join(directoryname, fname)) as infile:
			outfile.write(infile.read())
	with open("scripts/npc/abilities_end_template.txt") as infile:
		outfile.write(infile.read())