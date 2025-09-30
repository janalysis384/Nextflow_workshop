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

process countSequences {
    storeDir params.store
	publishDir params.out, mode: 'copy', overwrite: true
    input:
		path infile
	output:
		path "countSeq.txt"

	""" 
	grep ">" ${infile} | wc -l > countSeq.txt
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

process countBases {
    input:
        path infasta
    output:
        path "${infasta.getSimpleName()}_numbases.txt"
    """ 
    tail -n 1 ${infasta} | wc -m > ${infasta.getSimpleName()}_numbases.txt 
    """
}

process countRepeats {
    publishDir params.out, mode: 'copy', overwrite: true
	input:
		path infile
    output:
        path "${infile.getSimpleName()}_repeatcount.txt"
    """
    grep -o "GCCGCG" ${infile} | wc -l > ${infile.getSimpleName()}_repeatcount.txt
    """
} 

process makeSummary {
    publishDir params.out, mode: 'copy', overwrite: true
	input:
		path infile
    output:
        path "summary.csv"
    """
    for i in \$(ls ${infile}); do 
        echo -n "\$i, " | cut -d "_" -f 2 | tr -d "\n"
        echo -n ", "
        cat \$i
    done > summary_unsorted.csv
    cat summary_unsorted.csv | sort > summary.csv
    """
}

workflow {
	downloadChannel = downloadFile()
    countSequences(downloadChannel)
	singlefastas = splitSequences(downloadChannel).flatten()
    singlefastas.view()
    countBases(singlefastas)
    repeats = countRepeats(singlefastas)
    repeats.view()
    repeats.collect().view()
    makeSummary(repeats.collect())
}

