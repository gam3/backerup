
all : backerup.dvi backerup.pdf backerup.info 

backerup.dvi : backerup.texi
	texi2dvi  backerup.texi

backerup.pdf : backerup.texi
	texi2pdf backerup.texi

backerup.info : backerup.texi
	makeinfo $*

backerup.texi : version.info

backerup.man : backerup.info
	info2man $*

