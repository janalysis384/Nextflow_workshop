//nextflow.enable.dsl=2//

params.out = "${projectDir}/output"
params.store = "${projectDir}/downloads"
params.url = null
params.infile = null
params.prefix = "SamSeq"
params.fileformat = ".fasta"

process downloadFile {
	storeDir params.store
	publishDir params.out, mode: 'copy', overwrite: true
    input: 
        val url
	output:
		path "input_sequence.sam"

	""" 
	wget ${params.url} -O input_sequence.sam
	"""
}

process removeHeaderofSAM {
	publishDir params.out, mode: 'copy', overwrite: true
    input:
        path inputfile
	output:
		path "allLines.sam"
	"""
        grep -ve "^@" ${inputfile} > allLines.sam
	"""
}

process splitSeqs {
	publishDir params.out, mode: 'copy', overwrite: true
    input:
        path inputfile
	output:
		// path "Seq_*.fasta"
		path "${params.prefix}*${params.fileformat}"
	"""
		split -l 1 -d --additional-suffix ${params.fileformat} ${inputfile} ${params.prefix}
	"""
}

process countStart{
    publishDir params.out, mode: 'copy', overwrite: true
	input:
	    path inputfiles
	output:
	    path "${inputfiles.getSimpleName()}_startcount.txt"
	"""
		grep -o "ATG" ${inputfiles} | wc -l > ${inputfiles.getSimpleName()}_startcount.txt
	"""
}

process countStop{
    publishDir params.out, mode: 'copy', overwrite: true
	input:
	    path inputfiles
	output:
	    path "${inputfiles.getSimpleName()}_stopcount.txt"
	"""
		grep -oiE "TAA|TAG|TGA" ${inputfiles} | wc -l > ${inputfiles.getSimpleName()}_stopcount.txt
	"""
}


process makeSummary {
    publishDir params.out, mode: 'copy', overwrite: true
	input:
		path infile
    output:
        path "summary.csv"
    """
     for f in \$(ls ${infile}); do echo -n "\$f, "; cat \$f; done > summary.csv
    """
}

workflow {
	if (params.url != null && params.infile == null) { 
        file = downloadFile(Channel.from(params.url)) 
    } else if (params.infile != null && params.url == null) {
        file = Channel.fromPath(params.infile) 
    } else { 
        print "Error: Please provide either --url or --infile"
        System.exit(0)
    }

   c1 = (file | removeHeaderofSAM | splitSeqs | flatten)

	start = countStart(c1)
	stop = countStop(c1)
    merging = start.concat(stop)| collect
    makeSummary(merging)
}