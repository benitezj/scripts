#g++ -I$ROOTSYS/include -Wall -fPic -c checkrootfile.c -o ./checkrootfile
g++ -g -Wall `root-config --cflags --libs` -L$ROOTSYS/lib checkrootfile.c -o ./checkrootfile
