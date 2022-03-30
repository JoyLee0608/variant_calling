version 1.0

import "./tasks_variants_calling.wdl" as tvc
workflow cnvnator {
    call tvc.call_CNVnator

}