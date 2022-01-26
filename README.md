# Vriant_calling

## Usage
```
# generate configuration json
$ womtool inputs variant_calling.wdl > variant_calling.json

# set configuration json file under instruction
$ vi variant_calling.json

# execute wdl
$ cromwell run variant_calling.wdl --inputs variant_calling.json
```
