// Import generic module functions
include { initOptions; saveFiles } from './functions'

params.options = [:]
options        = initOptions(params.options)

process MAKE_BED_MASK {
    tag "$meta.id"
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'bed', meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/python:3.8.3"
    } else {
        container "quay.io/biocontainers/python:3.8.3"
    }

    input:
    tuple val(meta), path(vcf), path(bed)
    path  fasta

    output:
    tuple val(meta), path("*.bed")  , emit: bed
    tuple val(meta), path("*.fasta"), emit: fasta

    script:  // This script is bundled with the pipeline, in nf-core/viralrecon/bin/
    def prefix = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    """
    make_bed_mask.py \\
        $vcf \\
        $bed \\
        ${prefix}.bed

    ## Rename fasta entry by sample name and not reference genome
    FASTA_NAME=\$(head -n1 $fasta | sed 's/>//g')
    sed "s/\${FASTA_NAME}/${meta.id}/g" $fasta > ${prefix}.fasta
    """
}
