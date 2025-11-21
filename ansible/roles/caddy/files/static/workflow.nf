#!/usr/bin/env nextflow

params.output = "results"
params.samples = 3

process GENERATE_DATA {
    executor 'local'
    input:
    path generate_script

    output:
    path "${params.output}/sample_*.fastq"

    script:
    """
    python ${generate_script} ${params.output} ${params.samples}
    """
}

process QUALITY_ASSESSMENT {
    container 'python:3.13-slim'
    input:
    path fastq_file
    path qa_script

    output:
    path "${fastq_file.baseName}.filtered.fastq"

    script:
    """
    python ${qa_script} ${fastq_file} ${fastq_file.baseName}.filtered.fastq
    """
}

process ALIGNMENT {
    container 'python:3.13-slim'
    input:
    path filtered_fastqs
    path align_script

    output:
    path "alignment_results.txt"

    script:
    """
    python ${align_script} alignment_results.txt ${filtered_fastqs}
    """
}

workflow {
    // Load scripts from current directory
    generate_script = file('generate_data.py')
    qa_script = file('qa.py')
    align_script = file('align.py')

    // Generate dummy data locally
    data_files = GENERATE_DATA(generate_script)

    // Run quality assessment in parallel on each file
    filtered_files = QUALITY_ASSESSMENT(data_files.flatten(), qa_script)

    // Align all filtered sequences together
    results = ALIGNMENT(filtered_files.collect(), align_script)

    // Print results location
    results.subscribe { println "Alignment complete: ${it}" }
}
