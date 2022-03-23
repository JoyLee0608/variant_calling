version 1.0

task call_GangSTR{
    meta {
        description: "Call tandem repeats using GangSTR"
    }
    input {
        String docker = "registry.miracle.ac.cn/miracle_cloud/str-toolkit:v1"

        String sampleName
        File inputBAM
        File bamIndex

        File RefFasta
        File RefIndex
        File RefDict
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa

        File TRregions

        Int NUM_THREAD = 5 
        String MEMORY = "10 GB"
        
    }
    command {
        GangSTR --bam ${inputBAM} \
        --ref ${RefFasta} \
        --regions ${TRregions} \
        --out ${sampleName} \
        --include-ggl \
        --bam-samps ${sampleName} \
        --output-readinfo


        
        # to produce a explict output
        ls ${sampleName}.vcf
        ls ${sampleName}.readinfo.tab
        ls ${sampleName}.samplestats.tab
        ls ${sampleName}.insdata.tab
    }
    runtime {
        docker: docker 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        File vcf="${sampleName}.vcf"
        File readinfo = "${sampleName}.readinfo.tab"
        File samplestats = "${sampleName}.samplestats.tab"
        File insdata = "${sampleName}.insdata.tab"
    }
}

task call_CNVnator{}
    meta {
        description: "Call CNV using CNVnator"
    }
    input {
        String docker = "registry-vpc.miracle.ac.cn/miracle_cloud/cnvnator:v1"

        String sampleName
        File inputBAM
        File bamIndex

        File RefFasta
        File RefIndex
        File RefDict
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa

        # how to introduce a filepath with files under it. test for array
        Array[File] splitRefs

        Int NUM_THREAD = 5 
        String MEMORY = "10 GB"
        
    }
    command {
        # extracting reads from bam
        cnvnator -root ${sampleName}.root \
        -chrom 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 \
        -tree ${inputBAM}

        # Generating a read depth histogram
        cnvnator -root ${sampleName}.root \
        -his 100 

        # Calculating statistics
        cnvnator -root ${sampleName}.root \
        -stat 100

        # RD signal partitioning
        cnvnator -root ${sampleName}.root \
        -partition 100

        # CNV calling
        cnvnator -root ${sampleName}.root 
        -call 100 \
        > ${sampleName}.cnvnator

        # Exporting CNV calls as VCFs
        cnvnator2VCF.pl -prefix ${sampleName} \
        -reference GRCh38 \
        ${sampleName}.cnvnator \
        . \
        > ${sampleName}.cnvnator.vcf

    }
    runtime {
        docker: docker 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        File vcf="${sampleName}.cnvnator.vcf"
        File cnvnator = "${sampleName}.cnvnator"
    }
}