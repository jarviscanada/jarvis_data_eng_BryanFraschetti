# Script usage
# ./scripts/host_info.sh psql_host psql_port db_name psql_user psql_password

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

# Hardware specifications
lscpu_out=$(lscpu)

cpu_number=$(echo "$lscpu_out" | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out" | egrep "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out" | egrep "^Model\sname:" | sed "s/Model\sname:\s*//" | xargs)
cpu_mhz=$(echo "$lscpu_out" | egrep "^CPU\sMHz:" | awk '{print $3}' | xargs)
l2_cache=$(echo "$lscpu_out" | egrep "^L2\scache:" | awk '{print $3}' | xargs)
total_mem=$(free -m | egrep "Mem:" | awk '{print $2}' | xargs)

# Current time
timestamp=$(date -u --rfc-3339='seconds' | sed "s/+00:00//" | xargs)

# Create insert statement
insert_stmt="INSERT INTO host_info (
  hostname, cpu_number, cpu_architecture, 
  cpu_model, cpu_mhz, l2_cache, timestamp, 
  total_mem
) 
VALUES 
  (
    '$hostname', '$cpu_number', '$cpu_architecture', 
    '$cpu_model', '$cpu_mhz', '$l2_cache', 
    '$timestamp', '$total_mem'
  );

"

# Assign psql password to environment variable
export PGPASSWORD=$psql_password

# Execute psql statement
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"

exit $?
