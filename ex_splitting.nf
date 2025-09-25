//nextflow.enable.dsl=2//

params.out = "${projectDir}/output"
params.store = "${projectDir}/downloads"
params.downloadurl = "https://tinyurl.com/cqbatch1"
//params.prefix = "seq"

process downloadFile {
	storeDir params.store
	publishDir params.out, mode: 'copy', overwrite: true
	output:
		path "batch1.fasta"

	""" 
	wget https://tinyurl.com/cqbatch1 -O batch1.fasta
	"""
}


process splitSequences {
    
    publishDir params.out, mode: 'copy', overwrite: true
	input:
		path infile
	output:
		path "seq_*.fasta"
	"""
    split -l 2 -d --additional-suffix .fasta ${infile} seq_
    """
}

workflow {
	downloadChannel = downloadFile()
	splitSequences(downloadChannel)
}