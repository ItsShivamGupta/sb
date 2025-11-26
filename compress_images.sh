#!/bin/bash

# Image Compression Script for ScaleBold Website
# This script compresses large images to improve loading performance

echo "=========================================="
echo "ScaleBold Image Compression Tool"
echo "=========================================="
echo ""

# Initialize counters
total_original_size=0
total_compressed_size=0
files_processed=0

# Create report file
report_file="compression_report_$(date +%Y%m%d_%H%M%S).txt"
echo "Image Compression Report - $(date)" > "$report_file"
echo "=========================================" >> "$report_file"
echo "" >> "$report_file"

# Function to get file size in bytes
get_file_size() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$1"
    else
        stat -c%s "$1"
    fi
}

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(( bytes / 1024 ))KB"
    else
        echo "$(( bytes / 1048576 ))MB"
    fi
}

# Function to compress JPEG/JPG files
compress_jpeg() {
    local file="$1"
    local original_size=$(get_file_size "$file")
    
    # Skip if already small
    if [ $original_size -lt 512000 ]; then
        return
    fi
    
    echo "Compressing: $file ($(format_bytes $original_size))"
    
    # Backup original
    cp "$file" "wp-content/uploads/originals/$(basename "$file").backup"
    
    # Compress using sips (macOS built-in tool)
    sips -s format jpeg -s formatOptions 85 "$file" --out "${file}.tmp" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        mv "${file}.tmp" "$file"
        local new_size=$(get_file_size "$file")
        local saved=$(( original_size - new_size ))
        local percent=$(( saved * 100 / original_size ))
        
        echo "  ✓ Compressed: $(format_bytes $original_size) → $(format_bytes $new_size) (saved ${percent}%)"
        echo "$file: $(format_bytes $original_size) → $(format_bytes $new_size) (saved ${percent}%)" >> "$report_file"
        
        total_original_size=$(( total_original_size + original_size ))
        total_compressed_size=$(( total_compressed_size + new_size ))
        files_processed=$(( files_processed + 1 ))
    else
        echo "  ✗ Failed to compress $file"
        rm -f "${file}.tmp"
    fi
}

# Function to convert PNG to WebP (for large PNGs)
convert_png_to_webp() {
    local file="$1"
    local original_size=$(get_file_size "$file")
    
    # Skip if already small
    if [ $original_size -lt 512000 ]; then
        return
    fi
    
    echo "Converting to WebP: $file ($(format_bytes $original_size))"
    
    # Backup original
    cp "$file" "wp-content/uploads/originals/$(basename "$file").backup"
    
    # Get the base filename without extension
    local base="${file%.png}"
    local webp_file="${base}.webp"
    
    # Convert to WebP
    cwebp -q 85 "$file" -o "$webp_file" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        local new_size=$(get_file_size "$webp_file")
        local saved=$(( original_size - new_size ))
        local percent=$(( saved * 100 / original_size ))
        
        echo "  ✓ Converted: $(format_bytes $original_size) → $(format_bytes $new_size) (saved ${percent}%)"
        echo "$file → $webp_file: $(format_bytes $original_size) → $(format_bytes $new_size) (saved ${percent}%)" >> "$report_file"
        
        # Also compress the original PNG using sips
        sips -s format png "$file" --out "${file}.tmp" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            mv "${file}.tmp" "$file"
        fi
        
        total_original_size=$(( total_original_size + original_size ))
        total_compressed_size=$(( total_compressed_size + new_size ))
        files_processed=$(( files_processed + 1 ))
    else
        echo "  ✗ Failed to convert $file"
    fi
}

echo "Scanning for large images..."
echo ""

# Process JPG/JPEG files over 500KB
echo "Processing JPEG files..."
find ./wp-content/uploads -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | while read file; do
    compress_jpeg "$file"
done

echo ""
echo "Processing PNG files..."
# Process PNG files over 500KB
find ./wp-content/uploads -type f -iname "*.png" | while read file; do
    convert_png_to_webp "$file"
done

echo ""
echo "=========================================="
echo "Compression Complete!"
echo "=========================================="
echo ""
echo "Report saved to: $report_file"
echo ""

# Calculate total savings
if [ $files_processed -gt 0 ]; then
    total_saved=$(( total_original_size - total_compressed_size ))
    total_percent=$(( total_saved * 100 / total_original_size ))
    
    echo "" >> "$report_file"
    echo "=========================================" >> "$report_file"
    echo "Summary:" >> "$report_file"
    echo "Files processed: $files_processed" >> "$report_file"
    echo "Total original size: $(format_bytes $total_original_size)" >> "$report_file"
    echo "Total compressed size: $(format_bytes $total_compressed_size)" >> "$report_file"
    echo "Total saved: $(format_bytes $total_saved) (${total_percent}%)" >> "$report_file"
    
    echo "Summary:"
    echo "  Files processed: $files_processed"
    echo "  Total original size: $(format_bytes $total_original_size)"
    echo "  Total compressed size: $(format_bytes $total_compressed_size)"
    echo "  Total saved: $(format_bytes $total_saved) (${total_percent}%)"
fi

echo ""
echo "Original files backed up to: wp-content/uploads/originals/"
