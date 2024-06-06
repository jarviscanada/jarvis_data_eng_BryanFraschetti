#! /bin/sh

# Capture CLI arguments
cmd=$1
db_username=$2
db_password=$3

# Start docker
# systemctl status creates an interactive prompt (replaced it with is-active)
sudo systemctl is-active docker || systemctl start docker

# Check container status (Redirect stdout and stderr)
docker container inspect jrvs-psql > /dev/null 2>&1
container_status=$? # Exit code of previous command

# $?=0 means success, in which case the container exists
# Else, no container exists

# User switch case to handle create|stop|start opetions
case $cmd in 
  create)

    # Check if the container is already created
    if [ $container_status -eq 0 ]; then
      echo 'Container already exists'
      exit 1	
    fi

    # Check # of CLI arguments
    if [ $# -ne 3 ]; then
      echo 'Create requires username and password'
      exit 1
    fi

    # Create container
    docker volume create pgdata

    # Start the container
    docker run --name jrvs-psql -e POSTGRES_PASSWORD=$db_password -e POSTGRES_USER=$db_username -d -v pgdata:/var/lib/postgresql/data -p 5432:5432 postgres

    # Exit with the same code as the docker run cmd (0 = Success, Else = Failed)
    exit $?
    ;;

  start|stop) 
    # Check instance status; exit 1 if container has not been created
    if [ $container_status -ne 0 ]; then
      echo "Container has not been created"
      exit 1
    fi

    # Start or stop the container
    docker container $cmd jrvs-psql
    exit $?
    ;;	
  
  *)
    echo 'Illegal command'
    echo 'Commands: start|stop|create'
    exit 1
    ;;
esac