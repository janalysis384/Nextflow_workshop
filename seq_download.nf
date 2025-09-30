params.SRR = "SRR1777174"
params.out = "${projectDir}/output"
params.store = "${projectDir}/downloads"
params.storeDir = "${projectDir}/cache"
params.run_fastqc = false

if (!params.run_fastqc) {
    log.warn "Conditional run: Please provide --run_fastqc true"
    exit 0
}

process prefetch {
    storeDir params.storeDir
	publishDir params.store, mode: 'copy', overwrite: true
	container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.2.1--h4304569_1"
	output:
		path "${params.SRR}"
	"""
		prefetch ${params.SRR}
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
        path "${input.simpleName}_fastqc.html"
    
    when:
        params.run_fastqc
   
    """
    fastqc ${input}
    """
}


workflow {
c1 = (prefetch | fastDump) 
quality = ngsUtils(c1)


    if (params.run_fastqc) {
        FastQCout = FastQC(c1)
    } 
}

