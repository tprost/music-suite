
PLUGIN_PATH=~/appsupport/sibelius/Plugins
# EXAMPLE=~/Documents/Musik/Konserter/Flöjt/*.sib
EXAMPLE=~/Documents/Musik/Etyder/Kontrapunkt/Fuga\ 106.sib

test:
	iconv -f UTF-8 -t UTF-16LE <ExportJSON.plgx >ExportJSON.plgy
	cat LE.bom ExportJSON.plgy >ExportJSON.plg
	rm ExportJSON.plgy
	cp ExportJSON.plg $(PLUGIN_PATH)/JSON/ExportJSON.plg

	open -a /Applications/Sibelius\ 6.app $(EXAMPLE)


