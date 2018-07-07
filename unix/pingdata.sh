
IP=$1
if [ "$IP" == "" ]; then
echo "no ip"
fi

echo $IP > pingdata.log
date >> pingdata.log
ping $IP >> pingdata.log 
