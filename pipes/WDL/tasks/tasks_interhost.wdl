
task multi_align_mafft_ref {
  File           reference_fasta
  Array[File]+   assemblies_fasta # fasta files, one per sample, multiple chrs per file okay
  String         fasta_basename = basename(reference_fasta, '.fasta')
  Int?           mafft_maxIters
  Float?         mafft_ep
  Float?         mafft_gapOpeningPenalty
  String?        docker="quay.io/broadinstitute/viral-phylo"

  command {
    interhost.py --version | tee VERSION
    interhost.py multichr_mafft \
      ${reference_fasta} ${sep=' ' assemblies_fasta} \
      . \
      ${'--ep' + mafft_ep} \
      ${'--gapOpeningPenalty' + mafft_gapOpeningPenalty} \
      ${'--maxiters' + mafft_maxIters} \
      --outFilePrefix align_mafft-${fasta_basename} \
      --preservecase \
      --localpair \
      --sampleNameListFile align_mafft-${fasta_basename}-sample_names.txt \
      --loglevel DEBUG
  }

  output {
    #File         sampleNamesFile    = "align_mafft-${fasta_basename}-sample_names.txt"
    Array[File]+  alignments_by_chr  = glob("align_mafft-${fasta_basename}*.fasta")
    String        viralngs_version   = read_string("VERSION")
  }

  runtime {
    docker: "${docker}"
    memory: "28 GB"
    cpu: 8
    dx_instance_type: "mem2_ssd1_v2_x8"
  }
}

task multi_align_mafft {
  Array[File]+   assemblies_fasta # fasta files, one per sample, multiple chrs per file okay
  String         out_prefix = "aligned"
  Int?           mafft_maxIters
  Float?         mafft_ep
  Float?         mafft_gapOpeningPenalty
  String?        docker="quay.io/broadinstitute/viral-phylo"

  command {
    interhost.py --version | tee VERSION
    interhost.py multichr_mafft \
      ${sep=' ' assemblies_fasta} \
      . \
      ${'--ep' + mafft_ep} \
      ${'--gapOpeningPenalty' + mafft_gapOpeningPenalty} \
      ${'--maxiters' + mafft_maxIters} \
      --outFilePrefix ${out_prefix} \
      --preservecase \
      --localpair \
      --sampleNameListFile ${out_prefix}-sample_names.txt \
      --loglevel DEBUG
  }

  output {
    File        sampleNamesFile   = "${out_prefix}-sample_names.txt"
    Array[File] alignments_by_chr = glob("${out_prefix}*.fasta")
    String      viralngs_version  = read_string("VERSION")
  }

  runtime {
    docker: "${docker}"
    memory: "7 GB"
    cpu: 8
    dx_instance_type: "mem1_ssd1_v2_x8"
  }
}

task index_ref {
  File     referenceGenome
  String?  docker="quay.io/broadinstitute/viral-core"

  command {
    read_utils.py --version | tee VERSION
    read_utils.py novoindex "${referenceGenome}"
    read_utils.py index_fasta_samtools "${referenceGenome}"
    read_utils.py index_fasta_picard "${referenceGenome}"
  }

  output {
    File   referenceNix     = "*.nix"
    File   referenceFai     = "*.fasta.fai"
    File   referenceDict    = "*.dict"
    String viralngs_version = read_string("VERSION")
  }
  runtime {
    docker: "${docker}"
    memory: "4 GB"
  }
}


