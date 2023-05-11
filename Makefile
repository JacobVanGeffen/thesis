PAPER = thesis
TEX = $(wildcard *.tex)
BIB = chapters/jitsynth/n.bib chapters/depsynth/n.bib chapters/depsynth/p.bib
FIGS = $(wildcard figs/*.pdf figs/*.pgf figs/*.png figs/*.tex code/* data/*.tex)

.PHONY: all clean nr spell

$(PAPER).pdf: $(TEX) $(BIB) $(FIGS)
	bin/latexrun --bibtex-args=-min-crossrefs=100 $(PAPER)
#	echo $(FIGS)
#	pdflatex $(PAPER)
#	bibtex -min-crossrefs=99 $(PAPER)
#	pdflatex $(PAPER)
#	pdflatex $(PAPER)

nr: data/make-nr.py $(wildcard data/*.csv)
	$< > data/nr.tex

clean:
	rm -rf latex.out
	rm -f *.dvi *.aux *.bbl *.blg *.log *.out $(PAPER).pdf


ASPELL_CMDS=\
	--add-tex-command="autoref p" \
	--add-tex-command='begin pp' \
	--add-tex-command='bibliography p' \
	--add-tex-command='bibliographystyle p' \
	--add-tex-command='cc p' \
	--add-tex-command='citeauthor p' \
	--add-tex-command='citep p' \
	--add-tex-command='citet p' \
	--add-tex-command='color p' \
	--add-tex-command="cref p" \
	--add-tex-command="captionsetup op" \
	--add-tex-command='definecolor ppp' \
	--add-tex-command='eqref p' \
	--add-tex-command='errmessage p' \
	--add-tex-command='fvset p' \
	--add-tex-command='hypersetup p' \
	--add-tex-command='lstdefinelanguage popp' \
	--add-tex-command='lstinputlisting op' \
	--add-tex-command='lstset p' \
	--add-tex-command='mathit p' \
	--add-tex-command='mathrm p' \
	--add-tex-command='newcommand pp' \
	--add-tex-command='providecommand pp' \
	--add-tex-command='renewcommand pp' \
	--add-tex-command='setitemize p' \
	--add-tex-command='setlist op' \
	--add-tex-command='special p' \
	--add-tex-command='texttt p' \
	--add-tex-command='mathtt p' \
	--add-tex-command='usetikzlibrary p' \
	--add-tex-command='Crefname ppp' \
	--add-tex-command='DeclareMathOperator pp' \
	--add-tex-command='PassOptionsToPackage pp' \
	--add-tex-command='VerbatimInput p' \

spell:
	@ for i in *.tex latex.out/*.bbl; do aspell -t $(ASPELL_CMDS) -p ./aspell.words -c $$i; done
	@ for i in *.tex; do bin/double.pl $$i; done
	@ for i in *.tex; do bin/abbrv.pl  $$i; done
	@ bash bin/hyphens.sh *.tex
	@ ( head -1 aspell.words ; tail -n +2 aspell.words | LC_ALL=C sort ) > aspell.words~
	@ mv aspell.words~ aspell.words
