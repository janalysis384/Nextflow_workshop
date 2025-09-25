//nextflow.enable.dsl=2//

params.out = "${projectDir}/output"
params.store = "${projectDir}/downloads"
params.downloadurl = "https://tinyurl.com/cqbatch1"
params.prefix = "seq_"

process downloadFile {
	storeDir params.store
	publishDir params.out, mode: 'copy', overwrite: true
	output:
		path "batch1.fasta"

	""" 
	wget ${params.downloadurl} -O batch1.fasta
	"""
}


process splitSequences {
    
    publishDir params.out, mode: 'copy', overwrite: true
	input:
		path infile
	output:
		path "${params.prefix}*.fasta"
	"""
    split -l 2 -d --additional-suffix .fasta ${infile} ${params.prefix}
    """
}

workflow {
	downloadChannel = downloadFile()
	splitSequences(downloadChannel)
}