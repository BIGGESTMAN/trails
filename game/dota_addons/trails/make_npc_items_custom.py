import os

directoryname = "scripts/npc/items"

filenames = os.listdir(directoryname)
with open('scripts/npc/npc_items_custom.txt', 'w') as outfile:
	with open("scripts/npc/abilities_start_template.txt") as infile:
		outfile.write(infile.read())
	for fname in filenames:
		with open(os.path.join(directoryname, fname)) as infile:
			outfile.write(infile.read())
	with open("scripts/npc/abilities_end_template.txt") as infile:
		outfile.write(infile.read())