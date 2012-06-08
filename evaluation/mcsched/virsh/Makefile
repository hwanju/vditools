all:
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-lockstat
	MC=1 ./gen_xml.plx 1win7_64bit guest_config ../config/eval_config xml_template -mcsched
clean:
	rm -f *.xml
confclean:
	rm -f guest_config
