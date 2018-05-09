export TUPLECONFIG=data/TupleMaker_VHbbResonance/TupleMaker-job.cfg
export TUPLENFILES=20

###Input path
#export TUPLEINPATH=/nfs/uiowapc/data/CxAODSamples/DB00-04-03
#export TUPLEINPATH=/nfs/uiowapc/data/CxAODSamples/DB00-05-01
#export TUPLEINPATH=/nfs/uiowapc/data/CxAODSamples/DB00-05-Xbb
#export TUPLEINPATH=/nfs/uiowapc/data/CxAODSamples/DB00-06-01
#export TUPLEINPATH=/nfs/uiowapc/data/CxAODSamples/DB00-07-00
#export TUPLEINPATH=/nfs/uiowapc/data/CxAODSamples/DB00-07-00b
#export TUPLEINPATH=/nfs/uiowapc/data/CxAODSamples/DB00-07-01
export TUPLEINPATH=/nfs/uiowapc/data/CxAODSamples/DB00-07-02
#export TUPLEINPATH=$OUTPUTDIR/CxAODSamples/Test

export TUPLESAMPLENAME=mc15_13TeV.302396.MadGraphPythia8EvtGen_A14NNPDF23LO_HVT_Agv1_VzZH_llqq_m1000.merge.DAOD_EXOT12.e4069_s2608_r6765_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.302401.MadGraphPythia8EvtGen_A14NNPDF23LO_HVT_Agv1_VzZH_llqq_m1500.merge.DAOD_EXOT12.e4069_s2608_r6765_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.302401.MadGraphPythia8EvtGen_A14NNPDF23LO_HVT_Agv1_VzZH_llqq_m1500.merge.DAOD_EXOT12.e4069_s2608_r6765_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.341734.MadGraphPythia8EvtGen_A14NNPDF23LO_ggA500_Zh125_llbb.merge.DAOD_HIGG2D4.e4137_s2608_s2183_r6869_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.361420.Sherpa_CT10_Ztautau_Pt0_70_CVetoBVeto.merge.DAOD_EXOT12.e3733_s2608_s2183_r6869_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.361413.Sherpa_CT10_Zmumu_Pt700_1000_BFilter.merge.DAOD_EXOT12.e4133_s2608_s2183_r6869_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.302406.MadGraphPythia8EvtGen_A14NNPDF23LO_HVT_Agv1_VzZH_llqq_m2000.merge.DAOD_EXOT12.e4069_s2608_r6765_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.410000.PowhegPythiaEvtGen_P2012_ttbar_hdamp172p5_nonallhad.merge.DAOD_EXOT12.e3698_s2608_s2183_r6765_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.361403.Sherpa_CT10_Zmumu_Pt140_280_CFilterBVeto.merge.DAOD_EXOT12.e3651_s2586_s2174_r6869_r6282_p2419
#export TUPLESAMPLENAME=data15_13TeV.00284285.physics_Main.merge.DAOD_EXOT12.f643_m1518_p2425
#export TUPLESAMPLENAME=data15_13TeV.00284484.physics_Main.merge.DAOD_EXOT12.f644_m1518_p2425
#export TUPLESAMPLENAME=mc15_13TeV.361504.MadGraphPythia8EvtGen_A14NNPDF23LO_Zee_Np4.merge.DAOD_EXOT12.e3898_s2608_s2183_r6630_r6264_p2419
#export TUPLESAMPLENAME=mc15_13TeV.302401.MadGraphPythia8EvtGen_A14NNPDF23LO_HVT_Agv1_VzZH_llqq_m1500.merge.DAOD_EXOT12.e4069_s2608_r6765_r6282_p2419
#export TUPLESAMPLENAME=mc15_13TeV.410011.PowhegPythiaEvtGen_P2012_singletop_tchan_lept_top.merge.DAOD_EXOT12.e3824_s2608_s2183_r7326_r6282_p2436

###Output path
export TUPLEOUTPATH=$OUTPUTDIR/CxTupleSamples/Test

###########################################
####Make and plot a ntuple
###########################################
export TUPLECHANNEL=$1
rm -rf $TUPLEOUTPATH/$TUPLESAMPLENAME
tuplemaker local
rm -f $TUPLEOUTPATH/$TUPLESAMPLENAME/*.root 
mv $TUPLEOUTPATH/$TUPLESAMPLENAME/data-output/tuple.root $TUPLEOUTPATH/$TUPLESAMPLENAME/
ls -l $TUPLEOUTPATH/$TUPLESAMPLENAME/tuple.root

