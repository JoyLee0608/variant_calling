version 1.0

import "./tasks_variants_calling.wdl" as tvc
workflow GangSTR {
    call tvc.call_GangSTR

}