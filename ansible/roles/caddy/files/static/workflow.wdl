version 1.0

task generate_data {
    input {
        Int num_samples = 3
        String output_dir = "results"
        File generate_script
    }

    command {
        python ${generate_script} ${output_dir} ${num_samples}
    }

    output {
        Array[File] fastq_files = glob("${output_dir}/sample_*.fastq")
    }

    runtime {
        docker: "python:3.13-slim"
        cpus: 1
        requested_memory_mb_per_core: 1024
        runtime_minutes: 5
        queue: "training"
    }
}

task quality_assessment {
    input {
        File input_fastq
        File qa_script
    }

    String output_filename = basename(input_fastq, ".fastq") + ".filtered.fastq"

    command {
        python ${qa_script} ${input_fastq} ${output_filename}
    }

    output {
        File filtered_fastq = output_filename
    }

    runtime {
        docker: "python:3.13-slim"
        cpus: 1
        requested_memory_mb_per_core: 1024
        runtime_minutes: 10
        queue: "training"
    }
}

task alignment {
    input {
        Array[File] filtered_fastqs
        File align_script
    }

    command {
        python ${align_script} alignment_results.txt ${sep=' ' filtered_fastqs}
    }

    output {
        File results = "alignment_results.txt"
    }

    runtime {
        docker: "python:3.13-slim"
        cpus: 2
        requested_memory_mb_per_core: 1024
        runtime_minutes: 15
        queue: "training"
    }
}

workflow bioinformatics_pipeline {
    input {
        Int num_samples = 3
        String output_dir = "results"
        File generate_script = "generate_data.py"
        File qa_script = "qa.py"
        File align_script = "align.py"
    }

    call generate_data {
        input:
            num_samples = num_samples,
            output_dir = output_dir,
            generate_script = generate_script
    }

    scatter (fastq in generate_data.fastq_files) {
        call quality_assessment {
            input:
                input_fastq = fastq,
                qa_script = qa_script
        }
    }

    call alignment {
        input:
            filtered_fastqs = quality_assessment.filtered_fastq,
            align_script = align_script
    }

    output {
        Array[File] qa_results = quality_assessment.filtered_fastq
        File alignment_results = alignment.results
    }
}
