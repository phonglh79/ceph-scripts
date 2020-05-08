#!/bin/sh

radosgw-admin user list | jq -r -M .[] | while read user;
do
	bytes_quota=`radosgw-admin user info --uid=$user | jq 'select(.user_quota.enabled==true)|.user_quota.max_size'`
	bytes_used=`radosgw-admin user stats --uid=$user 2>/dev/null | jq .stats.total_bytes`
	re='^[0-9]+$'	
	if ! [[ $bytes_quota =~ $re ]];
	then
		bytes_quota=1
		bytes_used=0
	fi
	if ! [[ $bytes_used =~ $re ]];
	then
		bytes_used=0
	fi

	percent=`bc <<< "100*$bytes_used/$bytes_quota"`
        if (( $percent >= 80 ));
	then
		quota=bytes_quota		
		for unit in KB MB GB TB PB;
		do
			let quota/=1024
			if (( quota < 1024 )); then break; fi
		done
		email=`radosgw-admin user info --uid=$user | jq -M -r .email`
		echo -e  "Hello user $user,\n\nYour S3 usage has reached $percent% of your quota ($quota$unit).\n\n\nRegards,\nCern S3 service team" | mail -s "Cern S3 Storage quota notice" $email 
	fi	
done
