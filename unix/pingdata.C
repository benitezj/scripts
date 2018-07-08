#include <fstream>
#include <iostream>
#include <string>
#include <vector>
//#include <TGraph>
//#include <TCanvas>

vector<string> split(const string &s, char delim) {
  stringstream ss(s);
  string item;
  vector<string> tokens;
  while (getline(ss, item, delim)) {
    tokens.push_back(item);
  }
  return tokens;
}

void pingdata(){


  TGraph G;

  std::ifstream infile("pingdata.log");
  if(! infile.is_open()){
    cout<<"failed to open input file list:"<<endl;
    return;
  }

  string ip;
  std::getline(infile,ip);
  string date;
  std::getline(infile,date);
  


  int packet=0;
  unsigned counter=0;
  unsigned counterdrop=0;
  std::string line;
  while (std::getline(infile, line)){
    //std::cout<<line.c_str()<<std::endl;
 
    vector<string> items=split(line,' ');
    if(items.size()==0) continue;

    ////read the start time

    ///get the ip 
    //PING 189.199.117.125 (189.199.117.125): 56 data byte
    // if(items[0].compare("PING")==0){
    //   std::cout<<items[1]<<std::endl;
    //   ip=items[1];
    // }

    ////read packet delay
    //64 bytes from 189.199.117.125: icmp_seq=0 ttl=248 time=16.462 ms
    //if(items[1].compare("bytes")==0) std::cout<<items[4]<<" "<<items[6]<<std::endl;
    if(items[1].compare("bytes")==0){
      //std::cout<<items[4]<<" "<<items[6]<<std::endl;
      vector<string> seq=split(items[4],'=');
      vector<string> delay=split(items[6],'=');
      //std::cout<<seq[1]<<" "<<delay[1]<<std::endl;

      G.SetPoint(counter,atoi(seq[1].c_str()),atoi(delay[1].c_str()));
      //G.SetBinContent(atoi(seq[1].c_str()),atoi(delay[1].c_str()));
      packet=atoi(seq[1].c_str());
      counter++;
    }else
    
    ///// these are droped packets
    //Request timeout for icmp_seq 146
    if(items[1].compare("timeout")==0){
      G.SetPoint(counter,atoi(items[4].c_str()),1);
      //counterdrop++;
      counter++;
    }



  }  

  TCanvas C("Cpingdata","",1200,500);
  TLine linegraph;
  C.Clear();
  G.SetTitle(TString("")+ip.c_str()+", "+date.c_str());
  G.GetXaxis()->SetTitle("packet number");
  G.GetYaxis()->SetTitle("delay [ms]");
  G.GetYaxis()->SetRangeUser(1,1000);
  C.SetLogy(1);
  G.Draw("la");
  linegraph.DrawLine(1,100,packet,100);
  C.Print("pingdata.png");
  
  gROOT->ProcessLine(".q");
}
