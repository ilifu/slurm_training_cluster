#!/usr/bin/env python3
"""
Generate dummy FASTQ files for testing NextFlow pipelines.

Usage: python generate_data.py <output_dir> <num_samples>
"""

import sys
import os
import random

def generate_fastq(filename, num_sequences=100):
    """Generate a dummy FASTQ file with simulated sequences."""
    bases = ['A', 'T', 'G', 'C']

    with open(filename, 'w') as f:
        for i in range(num_sequences):
            # Header
            seq_id = f"seq_{i+1}"
            f.write(f"@{seq_id}\n")

            # Sequence (random 100bp)
            sequence = ''.join(random.choice(bases) for _ in range(100))
            f.write(f"{sequence}\n")

            # Quality header
            f.write("+\n")

            # Quality scores (simulated, ASCII 33-126 range for Phred quality)
            quality = ''.join(chr(random.randint(33, 90)) for _ in range(100))
            f.write(f"{quality}\n")

def main():
    if len(sys.argv) != 3:
        print("Usage: python generate_data.py <output_dir> <num_samples>")
        sys.exit(1)

    output_dir = sys.argv[1]
    num_samples = int(sys.argv[2])

    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)

    # Generate FASTQ files for each sample
    for i in range(1, num_samples + 1):
        filename = os.path.join(output_dir, f"sample_{i}.fastq")
        generate_fastq(filename)
        print(f"Generated {filename}")

    print(f"Successfully created {num_samples} FASTQ files in {output_dir}")

if __name__ == "__main__":
    main()
