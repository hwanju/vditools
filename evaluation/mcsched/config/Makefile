all:
	./gen_config.plx 8ubuntu1104 eval_config -mcsched
	./gen_config.plx 8ubuntu1104 eval_config -mcsched-lockstat
	./gen_config.plx 1ubuntu1104+7ubuntu1104up eval_config -mcsched
	./gen_config.plx 2ubuntu1104+6ubuntu1104up eval_config -mcsched
	./gen_config.plx 1win7_64bit+7ubuntu1104 eval_config -mcsched
clean:
	rm -f config_*.py
confclean:
	rm -f eval_config
