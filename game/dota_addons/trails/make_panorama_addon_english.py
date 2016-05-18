import os

directoryname = "panorama/localization/panoramatooltips"

filenames = os.listdir(directoryname)
with open('panorama/localization/addon_english.txt', mode='w', encoding='utf-16') as outfile:
	with open("panorama/localization/tooltips_start_template.txt") as infile:
		outfile.write(infile.read())
	for fname in filenames:
		with open(os.path.join(directoryname, fname)) as infile:
			outfile.write(infile.read())
	with open("panorama/localization/tooltips_end_template.txt") as infile:
		outfile.write(infile.read())