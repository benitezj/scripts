#include <TFile.h>
#include <TTree.h>
#include <iostream>
using namespace std;

int main(int argc,char** argv){

  if(argc!=3) return 0;

  TFile File(argv[1],"read");
  if(File.IsZombie())return 0;

  TTree* Tree=(TTree*)File.Get(argv[2]); 
  if(Tree==NULL) return 0;
  int NEV=Tree->GetEntries();
  cout<<NEV<<endl;

  return 1;
}
