params.accession = "SRR1777174"

process prefetch {
  container "https://depot.galaxyproject.org/singularity/sra-tools%3A3.2.1--h4304569_1"
  input:
    val accession
  output:
    path "${accession}/${accession}.sra"
  """
  prefetch ${accession}
  """
}

workflow {
  prefetch(channel.fromPath("${accession}.txt").splitText().map{it -> it.trim()})
}