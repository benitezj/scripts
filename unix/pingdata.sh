
IP=$1
if [ "$IP" == "" ]; then
echo "no ip"
fi

echo $IP > pingdata.log
date >> pingdata.log
ping -W 1000 $IP >> pingdata.log 
