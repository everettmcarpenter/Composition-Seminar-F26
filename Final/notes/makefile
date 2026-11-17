.PHONY: main clean FORCE

main: main.pdf

main.pdf: FORCE
	pdflatex -output-directory=build main.tex
	biber build/main.bcf
	pdflatex -output-directory=build main.tex
	pdflatex -output-directory=build main.tex

clean:
	pdflatex -output-directory=build -C
