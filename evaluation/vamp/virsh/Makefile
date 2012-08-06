all:
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -vamp
	MC=Y ./gen_xml.plx 1win7_64bit guest_config ../config/eval_config xml_template -vamp
clean:
	rm -f *.xml
confclean:
	rm -f guest_config
