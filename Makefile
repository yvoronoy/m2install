all:
	cat src/bin/m2install.sh | head -n 72 > m2install.sh.tmp
	cat src/functions.sh | tail -n +2 >> m2install.sh.tmp
	cat src/bin/m2install.sh | tail -n +74 >> m2install.sh.tmp
	mv m2install.sh.tmp m2install.sh
	chmod +x m2install.sh
