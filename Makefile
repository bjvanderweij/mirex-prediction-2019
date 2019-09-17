all : training-data/ primes/
	mkdir -p results/

training-data : 
	mkdir -p training-data/
	cp data/medium/prime_midi/*.mid training-data/

primes : training-data/
	mkdir -p primes/
	find "$<" -type f | shuf | tail -n 50 | xargs -I{} mv {} "$@"

clean :
	rm -r training-data/
	rm -r primes/
