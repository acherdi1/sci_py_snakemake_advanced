# Let's move some technical steps to common.smk just to make Snakefile short and clean
# E.g.: Load samples data table, configure config file path
include: "rules/common.smk"

# Steps that check RAW reads QC metrics
include: "rules/reads_qc.smk"
# Steps that download reference genome and build bowtie2 indexes
include: "rules/indexes.smk"
# Steps that align fastq files reads and check QC
include: "rules/align_reads.smk"
# Steps that build reads coverage tracks for raw signal visualization
include: "rules/coverage_track.smk"
# TODO: MACS2 steps

# 'first' rule in file, which is executed by default
rule all:
    input:
        # Reads MultiQC report
        rules.reads_multiqc.output,

        # Reads FASTQC reports for all samples
        expand(
            rules.reads_fastqc.output.html,
            sample=SAMPLES_DF.index
        ),

        # Reads coverage tracks for each sample
        expand(
            rules.bam_bigwig.output,
            genome=config['genome'],
            sample=SAMPLES_DF.index
        ),

        # TODO: MACS2 *.narrowPeak peaks
        expand(
            "results/macs2/{sample}_{genome}_peaks.narrowPeak",
            genome=config['genome'],
            sample=SAMPLES_DF.index
        )

rule callpeak:
    input:
        treatment="results/bams_sorted/{sample}_{genome}.sorted.bam",
    output:
        multiext("results/macs2/{sample}_{genome}",
                 "_peaks.xls",
                 "_peaks.narrowPeak",
                 "_summits.bed"
                 )
    params:
        "-f BAM -g hs"
    wrapper:
        "0.74.0/bio/macs2/callpeak"

rule all_results_bundle:
    input: rules.all.input
    output: "chip_seq_results.tar.gz"
    shell: "tar -czvf {output} {input} logs benchmarks images"