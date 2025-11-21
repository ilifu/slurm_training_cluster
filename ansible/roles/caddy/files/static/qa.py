#!/usr/bin/env python3
"""
Quality assessment and filtering for FASTQ files.

Simulates quality control by filtering sequences based on their average quality score.
Outputs only "good quality" sequences (average quality > threshold).

Usage: python qa.py <input_fastq> <output_fastq>
"""

import sys

def calculate_quality_score(quality_string):
    """Calculate average quality score from a quality string."""
    if not quality_string:
        return 0
    scores = [ord(c) - 33 for c in quality_string]  # Convert Phred+33 to numeric
    return sum(scores) / len(scores)

def filter_fastq(input_file, output_file, quality_threshold=20):
    """Filter FASTQ file based on average quality score."""
    sequences_read = 0
    sequences_kept = 0

    with open(input_file, 'r') as inf, open(output_file, 'w') as outf:
        while True:
            # Read one FASTQ record (4 lines)
            header = inf.readline().strip()
            if not header:
                break

            sequence = inf.readline().strip()
            plus = inf.readline().strip()
            quality = inf.readline().strip()

            sequences_read += 1

            # Calculate quality score and filter
            avg_quality = calculate_quality_score(quality)

            if avg_quality >= quality_threshold:
                # Write record if quality is good
                outf.write(f"{header}\n{sequence}\n{plus}\n{quality}\n")
                sequences_kept += 1

    return sequences_read, sequences_kept

def main():
    if len(sys.argv) != 3:
        print("Usage: python qa.py <input_fastq> <output_fastq>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    try:
        sequences_read, sequences_kept = filter_fastq(input_file, output_file)
        print(f"Quality Assessment Results:")
        print(f"  Input file: {input_file}")
        print(f"  Output file: {output_file}")
        print(f"  Sequences read: {sequences_read}")
        print(f"  Sequences kept: {sequences_kept}")
        print(f"  Filtered out: {sequences_read - sequences_kept}")
        print(f"  Pass rate: {100 * sequences_kept / sequences_read:.1f}%")
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()