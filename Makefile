# Makefile for compiling Typst documents to PDF and PNG

# Find all .typ files in the current directory
TYPST_FILES := $(wildcard *.typ)
# Generate corresponding PDF targets
PDF_TARGETS := $(TYPST_FILES:.typ=.pdf)
# Generate corresponding PNG directory targets
PNG_TARGETS := $(TYPST_FILES:.typ=.png_dir)

.PHONY: all clean help
.SECONDARY: # Don't delete intermediate files

# Default target - compile all documents
all: $(PDF_TARGETS) $(PNG_TARGETS)

# Help target
help:
	@echo "Available targets:"
	@echo "  all        - Compile all .typ files to PDF and PNG"
	@echo "  %.pdf      - Compile specific .typ file to PDF"
	@echo "  %.png_dir  - Compile specific .typ file to PNG directory"
	@echo "  clean      - Remove all generated files"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make all           # Compile all documents"
	@echo "  make main.pdf      # Compile only main.typ to PDF"
	@echo "  make main.png_dir  # Compile only main.typ to PNG directory"

# Rule to compile .typ to .pdf
%.pdf: %.typ
	@echo "Compiling $< to $@..."
	typst compile "$<" "$@"

# Rule to compile .typ to PNG directory
%.png_dir: %.typ
	@echo "Compiling $< to png_output/$*/..."
	@mkdir -p "png_output/$*"
	typst compile "$<" "png_output/$*/{n}.png" --format png

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -f *.pdf
	rm -rf png_output/
	@echo "Clean complete."

# Show status of targets
status:
	@echo "Typst files found: $(TYPST_FILES)"
	@echo "PDF targets: $(PDF_TARGETS)"
	@echo "PNG targets: $(PNG_TARGETS)"
