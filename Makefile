PREFIX     ?= /usr/local
BINDIR      = $(PREFIX)/bin
LIBDIR      = $(PREFIX)/lib/feline

CC          = cc
CFLAGS      = -Os -Wall -Wextra -std=c11
LDFLAGS     = -Wl,-x,-S,-dead_strip

SCRIPTS     = download/feline-download \
              convert/feline-convert \
              clean/feline-clean \
              context/feline-context \
              snap/feline-snap \
              search/feline-search \
              scrape/feline-scrape \
              lock/feline-lock

.PHONY: all clean install uninstall

all: feline

feline: src/feline.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o feline src/feline.c
	@strip feline 2>/dev/null || true

install: all
	@echo "Installing feline to $(BINDIR)"
	install -d $(BINDIR)
	install -d $(LIBDIR)
	install -m 755 feline $(BINDIR)/feline
	@for s in $(SCRIPTS); do \
		name=$$(basename $$s); \
		echo "  installing $$name"; \
		install -m 755 src/$$s $(BINDIR)/$$name; \
	done
	@echo "Done. Run 'feline --help' to get started."

uninstall:
	rm -f $(BINDIR)/feline
	@for s in $(SCRIPTS); do \
		name=$$(basename $$s); \
		rm -f $(BINDIR)/$$name; \
	done
	rmdir $(LIBDIR) 2>/dev/null || true

clean:
	rm -f feline
