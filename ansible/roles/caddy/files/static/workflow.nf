#!/usr/bin/env nextflow

params.output = "results"
params.samples = 3

process GENERATE_DATA {
    executor 'local'
    output:
    path "${params.output}/sample_*.fastq"

    script:
    """
    python generate_data.py ${params.output} ${params.samples}
    """
}

process QUALITY_ASSESSMENT {
    container 'python:3.13-slim'
    input:
    path fastq_file

    output:
    path "${fastq_file.baseName}.filtered.fastq"

    script:
    """
    python qa.py ${fastq_file} ${fastq_file.baseName}.filtered.fastq
    """
}

process ALIGNMENT {
    container 'python:3.13-slim'
    input:
    path filtered_fastqs

    output:
    path "alignment_results.txt"

    script:
    """
    python align.py alignment_results.txt ${filtered_fastqs}
    """
}

workflow {
    // Generate dummy data locally
    data_files = GENERATE_DATA()

    // Run quality assessment in parallel on each file
    filtered_files = QUALITY_ASSESSMENT(data_files.flatten())

    // Align all filtered sequences together
    results = ALIGNMENT(filtered_files.collect())

    // Print results location
    results.subscribe { println "Alignment complete: ${it}" }
}
