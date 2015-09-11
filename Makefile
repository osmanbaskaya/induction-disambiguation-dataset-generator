SHELL := /bin/bash
.SECONDARY:
PATH:= ../bin/:${PATH}

### 1.1 BIN INSTALLATION
bin:
	cd ../bin; make

### Ontonotes Details:
ONTO_ANNOTATION=../uwsd/data/ontonotes_v5/data/files/data/english/annotations
ONTO_SENSE_INVENTORY=../uwsd/data/ontonotes_v5/data/files/data/english/metadata/sense-inventories

SEED=1

ontonotes-stats.txt:
	ontonotes-stats.py ${ONTO_ANNOTATION} ${ONTO_SENSE_INVENTORY} #| tee $@

words-filtered%.txt:
	type-filtering.py ${ONTO_ANNOTATION} ${ONTO_SENSE_INVENTORY} 1 $* > $@
	wc $@

onto-wn%-mapping.txt: words-filtered.txt
	onto-wn-mapper.py ${ONTO_SENSE_INVENTORY} $< $* > $@

### Stemming related ###
mf-stems.%: # most frequent stems for noun verb etc
	cat celex/stemmer.out | awk '{if($$3=="$*" || $$3=="x$*")print $$1,$$2,$$5;}' > tmp
	cat celex-missing-verbs | awk '{print $$1,$$2,1;}' >> tmp
	stem_table.py <(cat tmp | sort) > $@
	rm tmp

#ontonotes.aw.tw.gz: words-filtered.txt onto-wn3.0-mapping.txt
	#onto-testset-create.py $^ ${ONTO_ANNOTATION} | gzip > $@

### Ontonotes Test set ###

on.all.gz: 
	ontonotes-preprocess.py ${ONTO_ANNOTATION} ${ONTO_SENSE_INVENTORY} | gzip > $@
	zcat $@ | wc

on.keys.gz: on.all.gz
	zcat $< | cut -f1,2,4 | awk '{printf "%s %s %s\n", $$1, $$2, $$3}' | gzip > $@

on.%.keys: on.keys.gz
	zcat $< | grep -P "\w+\.$* " > $@

on.context.gz: on.all.gz
	zcat $< | cut -f2,8,9 | extract-test-context.py | tee >(gzip > $@) | wc

%-tw-list.txt: %.all.gz
	zcat $< | cut -f1 | sort | uniq > $@

# IAA based filtering for ontonotes
on-tw-list%.txt: on.all.gz 
	zcat $< | awk -F '\t' '{if ($$7 >= $*) printf("%s\n", $$1)}' | sort | uniq > $@

## Key creation. We are using instances whose IAA >= 90
../keys/on.%-0.9.key: on.all.gz
	zcat $< | grep -P "\.$*\t" | awk -F '\t' '{if ($$7 >= 0.9)\
	printf("%s %s %s\n", $$1, $$2, $$4)}' | tee >(wc -l >&2) > $@
