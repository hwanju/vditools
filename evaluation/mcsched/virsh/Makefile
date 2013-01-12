all:
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-lockstat
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-lockholder
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-pvspinlock
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-unfairlock
	./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-delayedresched
	VCPU=1 ./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched
	VCPU=1 ./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-lockstat
	VCPU=1 ./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-lockholder
	VCPU=1 ./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-unfairlock
	VCPU=1 ./gen_xml.plx 8ubuntu1104 guest_config ../config/eval_config xml_template -mcsched-delayedresched
	MC=Y ./gen_xml.plx 1win7_64bit guest_config ../config/eval_config xml_template -mcsched
clean:
	rm -f *.xml
confclean:
	rm -f guest_config
