//nextflow.enable.dsl=2//

params.out = "${projectDir}/output"
params.store = "${projectDir}/downloads"
params.downloadurl = "https://tinyurl.com/cqbatch1"

process downloadFile {
	storeDir params.store
	publishDir params.out, mode: 'copy', overwrite: true
	output:
		path "batch1.fasta"

	""" 
	wget https://tinyurl.com/cqbatch1 -O batch1.fasta
	"""
}
process countSeqs {
	publishDir params.out, mode: 'copy', overwrite: true
	input:
		path inputfile
	output:
		path "numseqs.txt"
	"""
	grep ">" ${inputfile} | wc -l > numseqs.txt
	"""
}

process getFirstSeq {
	publishDir params.out, mode: 'copy', overwrite: true
	input:
		path inputfile
	output:
		path "firstSeq.fasta"
	"""
	head -n 2 ${inputfile} > firstSeq.fasta
	"""
} 
//could also pipe
//downloadFile | countSeqs | getFirstSeq//
//
workflow {
	downloadChannel = downloadFile()
	countSeqs(downloadChannel)
	getFirstSeq(downloadChannel)
}