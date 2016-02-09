import os

directoryname = "resource/tooltips"

filenames = os.listdir(directoryname)
with open('resource/addon_english.txt', mode='w', encoding='utf-16') as outfile:
	with open("resource/tooltips_start_template.txt") as infile:
		outfile.write(infile.read())
	for fname in filenames:
		with open(os.path.join(directoryname, fname)) as infile:
			outfile.write(infile.read())
	with open("resource/tooltips_end_template.txt") as infile:
		outfile.write(infile.read())