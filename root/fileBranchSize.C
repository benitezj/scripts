
void fileBranchSize(TString TreeName="Events", TString FileName=""){
  TFile file(FileName.Data());
  if(file.IsZombie()){ cout<<"Bad input file"<<endl; return;}

  TTree * tree = (TTree*) file.Get(TreeName.Data());
  if(tree== NULL) { cout<<"Bad input tree"<<endl; return;}


  Int_t nbranches = tree->GetListOfBranches()->GetEntries();
  float totbytes = tree->GetTotBytes();
  float totbytes_sum=0;
  //cout<<std::setprecision(5);
  cout<<"SIZE [Mb]    Weight   BranchName"<<endl;
  for(int b=0; b<nbranches; b++){
    TBranch * Br=(TBranch*)tree->GetListOfBranches()->At(b);
    float bytes=Br->GetTotBytes("*"); 
    
    cout<<bytes/1e6<<"    "<<bytes/totbytes<<"   "<<Br->GetName()<<endl;
   
    totbytes_sum += Br->GetTotBytes("*");
  }

  //cout<<nbranches<<endl;
  cout<<"TTree::GetTotBytes = "<<totbytes/1e6<<"    ,   Branch Sum = "<<totbytes_sum/1e6<<endl;

  gROOT->ProcessLine(".q");
}
