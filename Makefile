all: build

build:
	mkdocs build

serve:
	mkdocs serve

clean:
	$(RM) -r site/

.PHONY : build clean serve
