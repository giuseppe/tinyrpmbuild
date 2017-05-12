all:

check:
	bash -c "PATH=$$(pwd):$$PATH tests/run_tests.sh"
