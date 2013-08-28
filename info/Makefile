
all : backerup.dvi backerup.pdf backerup.info  backerup.man

backerup.dvi : backerup.texi version.texi
	texi2dvi  backerup.texi

backerup.pdf : backerup.texi version.texi
	texi2pdf backerup.texi

backerup.info : backerup.texi version.texi
	makeinfo $*

backerup.texi :: version.texi

backerup.man : backerup.info
	info2man $<  > $@

clean : 
	rm -f backerup.dvi backerup.pdf backerup.info backerup.man \
	backerup.cps backerup.vr backerup.tp backerup.pg backerup.op backerup.ky \
	backerup.fn backerup.toc bbackerup.cp backerup.aux backerup.log


