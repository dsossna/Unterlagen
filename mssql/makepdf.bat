@echo off
del *.toc *.aux *.bbl *.blg *mk *.log *.xml *.bib *.out *.fls
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
