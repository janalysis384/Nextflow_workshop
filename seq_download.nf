params.SRR = "accessions.txt"
params.out = "${projectDir}/output"
params.store = "${projectDir}/downloads"
params.storeDir = "${projectDir}/cache"
params.run_fastqc = false

params.cut_window_size  = 4
params.cut_mean_quality = 20
params.length_required  = 50
params.average_qual     = 0

/* if (!params.run_fastqc) {
    log.warn "Conditional run: Please provide --run_fastqc true"
    exit 0
} */

process prefetch {
    storeDir params.storeDir
	publishDir params.store, mode: 'copy', overwrite: true
	container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.2.1--h4304569_1"
	
	tag "${accession}"
	input: 
		val accession

	output:
		path "${accession}"
	"""
		prefetch ${accession}
	"""
}

process fastDump {
	publishDir params.out, mode: 'copy', overwrite: true
	container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.2.1--h4304569_1"
	input:
		path input
	output:
		path "${input}.fastq"
	"""
		fastq-dump --split-3 ${input}
	"""
}

process ngsUtils {
    storeDir params.storeDir
	publishDir params.out, mode: 'copy', overwrite: true
	container "https://depot.galaxyproject.org/singularity/ngsutils%3A0.5.9--py27h9801fc8_5"
	input:
		path input
	output:
		path "stats.txt"
	"""
		fastqutils stats ${input} > stats.txt
	"""
}

process FastQC {
    storeDir params.storeDir
	publishDir params.out, mode: 'copy', overwrite: true
	container "https://depot.galaxyproject.org/singularity/fastqc%3A0.12.1--hdfd78af_0"
	input:
		path input
	output:
		path "${input.simpleName}_fastqc.zip"
        /* path "${input.simpleName}_fastqc.html" */
    
    when:
        params.run_fastqc
   
    """
    fastqc ${input}
    """
}

process FastP{
	//storeDir params.storeDir
	publishDir "${params.out}/fastp", mode: 'copy', overwrite: true
	container "https://depot.galaxyproject.org/singularity/fastp%3A1.0.1--heae3180_0"
	
    tag "${sample_id}"

    input:
    path read_file

    output:
    path "${sample_id}_trimmed.fastq", emit: trimmed
    path "${sample_id}_fastp.json", emit: json
    path "${sample_id}_fastp.html", emit:html

    script:
    sample_id = read_file.getSimpleName()

    """
    fastp \
        --in1 ${read_file} \
        --out1 ${sample_id}_trimmed.fastq \
        --html ${sample_id}_fastp.html \
        --json ${sample_id}_fastp.json
    """
}


process MultiQC{
	publishDir params.out, mode: 'copy', overwrite: true
	container "https://depot.galaxyproject.org/singularity/multiqc%3A1.29--pyhdfd78af_0"
	

    input:
    path read_file 

    output:
    path "${read_file}_multiqc_*"


	"""
	multiqc .
	"""
}


process Spades{
	publishDir params.out, mode: 'copy', overwrite: true
	container "https://depot.galaxyproject.org/singularity/spades%3A4.2.0--h8d6e82b_2"
	input:
    path read_file 

    output:
    path "${read_file.getSimpleName()}"


	"""
	spades.py -s ${read_file} -o ${read_file.getSimpleName()}
	"""

}

workflow {
SRR = channel.fromPath(params.SRR).splitText().map{it -> it.trim()}
c1 = (prefetch(SRR) | fastDump) 
quality = ngsUtils(c1)


    if (params.run_fastqc) {
        FastQCout = FastQC(c1)
    }
FastPout=FastP(c1) 

//MultiQC(FastQCout.collect())

Spades(FastPout.trimmed)
}

