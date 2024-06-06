# Script usage
# ./scripts/host_usage.sh psql_host psql_port db_name psql_user psql_password

psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Required number of arguments
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Host name
hostname=$(hostname -f)

# Machine statistics
vmstat_mb=$(vmstat --unit M)

memory_free=$(echo "$vmstat_mb" | awk '{print $4}'| tail -n1 | xargs)
cpu_idle=$(echo "$vmstat_mb" | awk '{print $15}' | tail -n1 | xargs)
cpu_kernel=$(echo "$vmstat_mb" | awk '{print $14}' | tail -n1 | xargs)

# Obtain disk info for the last non virtual device
disk_io=$(vmstat -d | egrep "^[^(loop|disk|[:space:])]" | tail -n1 | awk '{print $10}' | xargs)
# No egrep needed since the physical disk is the only one mounted at /
disk_available=$(df -BM / | awk '{print $4}' | tail -n1 | sed "s/M//" | xargs)

# Current time
timestamp=$(date -u --rfc-3339='seconds' | sed "s/+00:00//" | xargs)

export PGPASSWORD=$psql_password

# Host ID
obtain_host_stmt="SELECT id FROM host_info WHERE hostname='$hostname';";
host_id=$(psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -t -A -c "$obtain_host_stmt");

insert_stmt="INSERT INTO host_usage(
  timestamp, host_id, memory_free, cpu_idle, 
  cpu_kernel, disk_io, disk_available
) 
VALUES 
  (
    '$timestamp', '$host_id', '$memory_free', 
    '$cpu_idle', '$cpu_kernel', '$disk_io', 
    '$disk_available'
  );
"

psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"

exit $?