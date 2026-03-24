vcover merge -stats=none -strip 0 -totals merged_tests.ucdb ./*.ucdb

xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
add testbrowser ./*.ucdb
vcover merge -stats=none -strip 0 -totals regression.ucdb ./i2cmb_test_plan.ucdb ./merged_tests.ucdb
coverage open ./regression.ucdb
