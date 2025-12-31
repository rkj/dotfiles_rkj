function swarm_exec
    # Check if service name is provided
    if test (count $argv) -lt 1
        echo "Error: Service name is required"
        return 1
    end

    # Get the service name from the first argument
    set -l service_name $argv[1]

    # Get the exec command or default to /bin/sh
    set -l exec_command
    if test (count $argv) -gt 1
        set exec_command $argv[2..-1]
    else
        set exec_command /bin/sh
    end

    # Get the node running the service
    set -l node (docker service ps -f "desired-state=running" --format "{{.Node}}" $service_name | head -n1)
    if test -z "$node"
        echo "Error: Could not find running node for service $service_name"
        return 1
    end

    # Get the container ID from the remote node
    set -l container_id (ssh $node "docker ps -q -f name=$service_name")
    if test -z "$container_id"
        echo "Error: Could not find container ID for service $service_name on node $node"
        return 1
    end

    # Execute the command in the container
    ssh -t $node "docker exec -it $container_id $exec_command"
end
