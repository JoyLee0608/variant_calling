version 1.0

workflow variant_calling {
    meta {
        description: "Variats calling for WGS bam file. "
        author: "Jilong Liu"
        email:  "liu_jilong@gzlab.ac.cn"
    }

    input {
        File RefFasta
        File RefIndex
        File RefDict
        String sampleName
        File inputBAM
        File bamIndex
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa
    }

    call call_svaba{
        input: RefFasta = RefFasta,
                RefIndex = RefIndex,
                RefDict = RefDict,
                sampleName = sampleName,
                inputBAM = inputBAM,
                bamIndex = bamIndex,
                Refamb = Refamb,
                Refann = Refann,
                Refbwt = Refbwt,
                Refsa = Refsa,
                Refpac = Refpac 
    }

    call call_gatk{
        input:  RefFasta = RefFasta, 
                RefIndex = RefIndex,
                RefDict = RefDict,
                sampleName = sampleName,
                inputBAM = inputBAM,
                bamIndex = bamIndex
    }

    call call_MANTA{
        input: RefFasta = RefFasta,
            RefIndex = RefIndex,
            RefDict = RefDict,
            sampleName = sampleName,
            inputBAM = inputBAM,
            bamIndex = bamIndex,
            Refamb = Refamb,
            Refann = Refann,
            Refbwt = Refbwt,
            Refsa = Refsa,
            Refpac = Refpac  
    }
}

task call_svaba{
    meta {
        description: "Call Sructure Variant using svaba"
    }
    input {
        File RefFasta
        File RefIndex
        File RefDict
        String sampleName
        String inputBAM
        String bamIndex
        File INTERVAL
        Int NUM_THREAD = 8 
        String MEMORY = "70 GB"
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa
    }
    command {
        set -e

        mc alias set  \
        bioisland-variation https://tos-s3.miracle.ac.cn  \
        AKLTNmY1MTBhZmQ0MjBlNDg0YTgxZTkyZmU1MDgzNjMyZTA  \
        TVRsa05USTVZekkxWTJKak5EZzJNbUl4T1RReU16STBOakkzWTJabE1EWQ==

        mc cp  ${inputBAM} ${sampleName}.bam
        mc cp  ${bamIndex} ${sampleName}.bai

        md5sum ${sampleName}.bam ${sampleName}.bai >${sampleName}.md5


        svaba run \
        -t ${sampleName}.bam \
        -p ${NUM_THREAD} \
        -a ${sampleName} \
        -G ${RefFasta} \
        --germline \
        -k ${INTERVAL}
        
        # to produce a explict output
        ls ${sampleName}.log
        ls ${sampleName}.svaba.indel.vcf
        ls ${sampleName}.svaba.sv.vcf
        ls ${sampleName}.svaba.unfiltered.indel.vcf
        ls ${sampleName}.svaba.unfiltered.sv.vcf
    }
    runtime {
        docker: "registry.miracle.ac.cn/public/svaba:v1-python3-hczv2" 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        File log = "${sampleName}.log"
        File indelVcf = "${sampleName}.svaba.indel.vcf"
        File svVcf = "${sampleName}.svaba.sv.vcf"
        File unIndelVcf = "${sampleName}.svaba.unfiltered.indel.vcf"
        File unSvVcf = "${sampleName}.svaba.unfiltered.sv.vcf"
        File md5 = "${sampleName}.md5"
    }
}

task call_gatk{
    meta {
        description: "Call SNV/INDEL using GATK"
    }
    input {
        File RefFasta
        File RefIndex
        File RefDict
        String sampleName
        String inputBAM
        String bamIndex
        Int NUM_THREAD = 8
        String MEMORY = "50 GB"

    }
    command {
        set -e
        
        mc alias set  \
        bioisland-variation https://tos-s3.miracle.ac.cn  \
        AKLTNmY1MTBhZmQ0MjBlNDg0YTgxZTkyZmU1MDgzNjMyZTA  \
        TVRsa05USTVZekkxWTJKak5EZzJNbUl4T1RReU16STBOakkzWTJabE1EWQ==

        mc cp  ${inputBAM} ${sampleName}.bam
        mc cp  ${bamIndex} ${sampleName}.bai

        md5sum ${sampleName}.bam ${sampleName}.bai >${sampleName}.md5

        gatk \
        HaplotypeCaller \
        -R ${RefFasta} \
        -I ${sampleName}.bam \
        --emit-ref-confidence GVCF \
        --pair-hmm-implementation LOGLESS_CACHING \
        --native-pair-hmm-threads ${NUM_THREAD} \
        --sample-ploidy 2 \
        -O ${sampleName}.raw.indels.snps.vcf.gz
    }
    runtime {
        docker: "registry.miracle.ac.cn/public/gatk:4.0.4.0-hczv2" 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"
    }
    output {
        File rawVCF = "${sampleName}.raw.indels.snps.vcf.gz"
        File rawVCFIndex = "${sampleName}.raw.indels.snps.vcf.gz.tbi"
        File md5 = "${sampleName}.md5"
    }
}

task call_MANTA{
    meta {
        description: "Call Structure Variants using MANTA"
    }
    input {
        File RefFasta
        File RefIndex
        File RefDict
        String sampleName
        String inputBAM
        String bamIndex
        File MANTA_INTERVAL
        File MANTA_INTERVAL_index
        File Region
        Int NUM_THREAD = 8 
        String MEMORY = "70 GB"
        File Refamb
        File Refann
        File Refbwt
        File Refpac
        File Refsa
        
    }
    command {
        set -e
        
        mc alias set  \
        bioisland-variation https://tos-s3.miracle.ac.cn  \
        AKLTNmY1MTBhZmQ0MjBlNDg0YTgxZTkyZmU1MDgzNjMyZTA  \
        TVRsa05USTVZekkxWTJKak5EZzJNbUl4T1RReU16STBOakkzWTJabE1EWQ==

        mc cp  ${inputBAM} ${sampleName}.bam
        mc cp  ${bamIndex} ${sampleName}.bai

        md5sum ${sampleName}.bam ${sampleName}.bai >${sampleName}.md5

        # generate script and config
        configManta.py \
        --bam  ${sampleName}.bam \
        --referenceFasta ${RefFasta} \
        --callRegions ${MANTA_INTERVAL} 
        
        # run script
        MantaWorkflow/runWorkflow.py \
        -j ${NUM_THREAD}

        # genotyping
        graphtyper genotype_sv \
        ${RefFasta} \
        MantaWorkflow/results/variants/diploidSV.vcf.gz \
        --sam ${sampleName}.bam \
        --region_file=${Region} \
        --threads=${NUM_THREAD}

        # merge vcf files
        ls sv_results/*/*.vcf.gz > ${sampleName}.vcf_file_list
        bcftools concat --naive --file-list ${sampleName}.vcf_file_list -Oz -o ${sampleName}.merge.vcf.gz
        tabix -p vcf ${sampleName}.merge.vcf.gz

        # generate output
        cp MantaWorkflow/results/stats/alignmentStatsSummary.txt ${sampleName}.alignmentStatsSummary.txt
        cp MantaWorkflow/results/stats/svCandidateGenerationStats.tsv ${sampleName}.svCandidateGenerationStats.tsv
        cp MantaWorkflow/results/stats/svCandidateGenerationStats.xml ${sampleName}.svCandidateGenerationStats.xml
        cp MantaWorkflow/results/stats/svLocusGraphStats.tsv ${sampleName}.svLocusGraphStats.tsv
        cp MantaWorkflow/results/variants/candidateSmallIndels.vcf.gz ${sampleName}.candidateSmallIndels.vcf.gz
        cp MantaWorkflow/results/variants/candidateSmallIndels.vcf.gz.tbi ${sampleName}.candidateSmallIndels.vcf.gz.tbi
        cp MantaWorkflow/results/variants/candidateSV.vcf.gz ${sampleName}.candidateSV.vcf.gz
        cp MantaWorkflow/results/variants/candidateSV.vcf.gz.tbi ${sampleName}.candidateSV.vcf.gz.tbi
        cp MantaWorkflow/results/variants/diploidSV.vcf.gz ${sampleName}.diploidSV.vcf.gz
        cp MantaWorkflow/results/variants/diploidSV.vcf.gz.tbi ${sampleName}.diploidSV.vcf.gz.tbi

        cp MantaWorkflow/runWorkflow.py ${sampleName}.runWorkflow.py
        cp MantaWorkflow/runWorkflow.py.config.pickle ${sampleName}.runWorkflow.py.config.pickle
        cp MantaWorkflow/workflow.error.log.txt ${sampleName}.workflow.error.log.txt
        cp MantaWorkflow/workflow.exitcode.txt ${sampleName}.workflow.exitcode.txt
        cp MantaWorkflow/workflow.warning.log.txt ${sampleName}.workflow.warning.log.txt


    }
    runtime {
        docker: "registry.miracle.ac.cn/public/manta:v1-python2-hczv2" 
        cpu: "${NUM_THREAD}" 
        memory: "${MEMORY}"
        disk: "250 GB"

    }
    output {
        File alignmentStatsSummary = "${sampleName}.alignmentStatsSummary.txt"
        File svCandidateGenerationStatsTsv = "${sampleName}.svCandidateGenerationStats.tsv"
        File svCandidateGenerationStatsXml = "${sampleName}.svCandidateGenerationStats.xml"
        File svLocusGraphStats = "${sampleName}.svLocusGraphStats.tsv"
        File candidateSmallIndels = "${sampleName}.candidateSmallIndels.vcf.gz"
        File candidateSmallIndelsIndex = "${sampleName}.candidateSmallIndels.vcf.gz.tbi"
        File candidateSV = "${sampleName}.candidateSV.vcf.gz"
        File candidateSVIndex = "${sampleName}.candidateSV.vcf.gz.tbi"
        File rawVcf = "${sampleName}.diploidSV.vcf.gz"
        File rawVcfIndex = "${sampleName}.diploidSV.vcf.gz.tbi"

        File merge = "${sampleName}.merge.vcf.gz"
        File mergeIndex = "${sampleName}.merge.vcf.gz.tbi"
        File vcfFileList = "${sampleName}.vcf_file_list"
        File runWorkflow = "${sampleName}.runWorkflow.py"
        File configPickle = "${sampleName}.runWorkflow.py.config.pickle"
        File errorLog = "${sampleName}.workflow.error.log.txt"
        File exitCode = "${sampleName}.workflow.exitcode.txt"
        File warningLog = "${sampleName}.workflow.warning.log.txt"
        File md5 = "${sampleName}.md5"
    }
}