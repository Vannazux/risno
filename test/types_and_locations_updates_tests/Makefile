export ELASTIC_PORT=9298
export ELASTIC_URL=localhost:$(ELASTIC_PORT)
CSV=$(wildcard sample_data/*.csv)
TST=$(CSV:.csv=.tst)
TYPE_CSV=$(wildcard test_type/*.csv)
TYPE_TST=$(TYPE_CSV:.csv=.tst.type)
CITY_CSV=$(wildcard test_city/*.csv)
CITY_TST=$(CITY_CSV:.csv=.tst.city)

.PHONY: elastic_running stop all clean distclean test type

all: test

elastic_running:
	./ensure_elastic_running

elastic.id: elastic_running

types_injected: elastic.id ../../elasticsearch/mappings/types/types
	../../elasticsearch/mappings/types/types
	@touch types_injected
cities_injected: elastic.id ../../elasticsearch/mappings/cities/inject_cities_in_elasticsearch.sh ../../elasticsearch/mappings/cities/cp-france.csv ../../elasticsearch/mappings/cities/city_unboost_terms.txt
	@echo
	@echo injecting cities... please be patient
	@echo ... really patient !!!!
	../../elasticsearch/mappings/cities/inject_cities_in_elasticsearch.sh
	@touch cities_injected

%.tst.inserted: %.csv types_injected cities_injected elastic.id
	./insert_sample_data $<
	touch $@
%.tst.type.updated: %.tst.inserted types_injected elastic.id ../../tools/update_type.py
	@curl -sf $(ELASTIC_URL)/_all/_refresh
	python ../../tools/update_type.py
	@touch $@
%.tst.type: %.csv %.tst.type.updated elastic.id
	@curl -sf $(ELASTIC_URL)/_all/_refresh >/dev/null
	./validate_types $<
	@touch $@
%.tst.city.updated: %.tst.inserted cities_injected elastic.id ../../tools/update_locations.py
	@curl -sf $(ELASTIC_URL)/_all/_refresh
	python ../../tools/update_locations.py
	@touch $@
%.tst.city: %.csv %.tst.city.updated elastic.id
	@curl -sf $(ELASTIC_URL)/_all/_refresh >/dev/null
	./validate_cities $<
	@touch $@
%.tst: %.tst.type %.tst.city
	@touch $@

test: $(TST) type city

type: $(TYPE_TST)

city: $(CITY_TST)

stop:
	docker stop `cat elastic.id`
	rm elastic.id

clean:
	rm -f sample_data/*.tst*

distclean: clean stop
	rm -f cities_injected types_injected
