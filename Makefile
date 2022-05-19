info:
	echo "make pdf"

.SILENT:

pdf:
	dot -Tpdf docs/alt_alpha.dot -o docs/alt_alpha.pdf
