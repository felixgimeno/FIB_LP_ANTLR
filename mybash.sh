rm lego
/opt/pccts/bin/antlr -gt -gl lego.g
/opt/pccts/bin/dlg -ci parser.dlg scan.c
g++ -Wstrict-overflow -std=c++11 -O3 -march=native -D_GLIBCXX_DEBUG -g3 -Wall -Wextra -o lego lego.c scan.c err.c -I/home/soft/PCCTS_v1.33/include -Wno-write-strings -Wno-unused-variable -Wno-unused-parameter -Wno-unused-label -Wno-empty-body -Wno-sign-compare -Wno-maybe-uninitialized
rm -f *.o lego.c scan.c err.c parser.dlg tokens.h mode.h
