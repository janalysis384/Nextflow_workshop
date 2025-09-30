params.SRR = "SRR1777174"
params.out = "${projectDir}/output"
params.store = "${projectDir}/downloads"
params.storeDir = "${projectDir}/cache"

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

workflow {
(prefetch | fastDump | ngsUtils)

}