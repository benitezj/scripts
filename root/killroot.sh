for r in `ps | grep root | grep -v root.exe | awk -F" " '{print $1}'` ; do kill -9 $r; done
