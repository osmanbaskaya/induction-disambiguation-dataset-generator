.SECONDARY:
SHELL := /bin/bash
PATH:= ../bin/:${PATH}

### 1.1 BIN INSTALLATION
bin:
	cd ../bin; make

### Ontonotes Details:
ONTO_ANNOTATION=../uwsd/data/ontonotes_v5/data/files/data/english/annotations
ONTO_SENSE_INVENTORY=../uwsd/data/ontonotes_v5/data/files/data/english/metadata/sense-inventories

### Default parameters for dataset generation 
IAA=0.9 #Inter-annotator agreement 
MIN_INST=300  # Min # of instance 
LEXICON=3.0 # Lexicon we'll use for the experiments. Wordnet 3.0
IGNORE_SET=be.v have.v  # avoid using these target words while dataset construction.

SEED=1

ontonotes-stats.txt:
	python ontonotes-stats.py ${ONTO_ANNOTATION} ${ONTO_SENSE_INVENTORY} | tee $@

words-filtered%.txt:
	python type-filtering.py ${ONTO_ANNOTATION} ${ONTO_SENSE_INVENTORY} 1 $* > $@
	wc $@

onto-wn%-mapping.txt: words-filtered.txt
	onto-wn-mapper.py ${ONTO_SENSE_INVENTORY} $< $* > $@

### Stemming related ###
mf-stems.%: # most frequent stems for noun verb etc
	cat celex/stemmer.out | awk '{if($$3=="$*" || $$3=="x$*")print $$1,$$2,$$5;}' > tmp
	cat celex-missing-verbs | awk '{print $$1,$$2,1;}' >> tmp
	python stem_table.py <(cat tmp | sort) > $@
	rm tmp

#ontonotes.aw.tw.gz: words-filtered.txt onto-wn3.0-mapping.txt
	#onto-testset-create.py $^ ${ONTO_ANNOTATION} | gzip > $@

### Ontonotes Test set ###

on.all.gz: 
	python ontonotes-preprocess.py ${ONTO_ANNOTATION} ${ONTO_SENSE_INVENTORY} | gzip > $@
	zcat $@ | wc

on.%.instance-info.txt: on.%.gz
	zcat $< | cut -f1 | sort | uniq -c > $@

on.filtered.gz: on.all.gz
	python onto-filter.py $< --iaa=${IAA} --min-instance=${MIN_INST} --lexicon ${LEXICON} --ignore-set ${IGNORE_SET} | gzip > $@
	make on.filtered.instance-info.txt

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
