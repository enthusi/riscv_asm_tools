SRC = cat

SRC: $(SRC).s
	as -o $(SRC).o $(SRC).s 
	ld -o $(SRC) $(SRC).o   
	strip $(SRC)
	./$(SRC) test.txt test2.txt > test3.txt 
	./$(SRC) test3.txt
