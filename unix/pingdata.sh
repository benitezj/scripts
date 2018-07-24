
IP=$1
if [ "$IP" == "" ]; then
echo "no ip"
fi

echo $IP > pingdata.log

date >> pingdata.log

ping -W 1000 -c 500 $IP >> pingdata.log 

root -b pingdata.C

open pingdata.png