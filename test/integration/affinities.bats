#!/usr/bin/env bats

load helpers

function teardown() {
	swarm_manage_cleanup
	stop_docker
}

@test "container affinty" {
	start_docker_with_busybox 2
	swarm_manage

	run docker_swarm run --name c1 -e constraint:node==node-1 -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c2 -e affinity:container==c1 -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c3 -e affinity:container!=c1 -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c4 --label 'com.docker.swarm.affinities=["container==c1"]' -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c5 --label 'com.docker.swarm.affinities=["container\!=c1"]' -d busybox:latest sh
	[ "$status" -eq 0 ]

	run docker_swarm inspect c1
	# FIXME: This will help debugging the failing test.
	echo $output
	[ "$status" -eq 0 ]
	[[ "${output}" == *'"Name": "node-1"'* ]]

	run docker_swarm inspect c2
	[ "$status" -eq 0 ]
	[[ "${output}" == *'"Name": "node-1"'* ]]

	run docker_swarm inspect c3
	[ "$status" -eq 0 ]
	[[ "${output}" != *'"Name": "node-1"'* ]]

	run docker_swarm inspect c4
	[ "$status" -eq 0 ]
	[[ "${output}" == *'"Name": "node-1"'* ]]

	run docker_swarm inspect c5
	[ "$status" -eq 0 ]
	[[ "${output}" != *'"Name": "node-1"'* ]]
}

@test "image affinity" {
	start_docker_with_busybox 2
	swarm_manage

	# Create a new image just on the second host.
	run docker -H ${HOSTS[1]} tag busybox test
	[ "$status" -eq 0 ]

	# pull busybox to force the refresh images
	# FIXME: this is slow.
	run docker_swarm pull busybox
	[ "$status" -eq 0 ]

	run docker_swarm run --name c1 -e affinity:image==test -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c2 -e affinity:image!=test -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c3 --label 'com.docker.swarm.affinities=["image==test"]' -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c4 --label 'com.docker.swarm.affinities=["image\!=test"]' -d busybox:latest sh
	[ "$status" -eq 0 ]

	run docker_swarm inspect c1
	# FIXME: This will help debugging the failing test.
	echo $output
	[ "$status" -eq 0 ]
	[[ "${output}" == *'"Name": "node-1"'* ]]

	run docker_swarm inspect c2
	[ "$status" -eq 0 ]
	[[ "${output}" != *'"Name": "node-1"'* ]]

	run docker_swarm inspect c3
	[ "$status" -eq 0 ]
	[[ "${output}" == *'"Name": "node-1"'* ]]

	run docker_swarm inspect c4
	[ "$status" -eq 0 ]
	[[ "${output}" != *'"Name": "node-1"'* ]]
}

@test "label affinity" {
	start_docker_with_busybox 2
	swarm_manage

	run docker_swarm run --name c1 --label test.label=true -e constraint:node==node-1 -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c2 -e affinity:test.label==true -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c3 -e affinity:test.label!=true -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c4  --label 'com.docker.swarm.affinities=["test.label==true"]' -d busybox:latest sh
	[ "$status" -eq 0 ]
	run docker_swarm run --name c5  --label 'com.docker.swarm.affinities=["test.label\!=true"]' -d busybox:latest sh
	[ "$status" -eq 0 ]

	run docker_swarm inspect c1
	# FIXME: This will help debugging the failing test.
	echo $output
	[ "$status" -eq 0 ]
	[[ "${output}" == *'"Name": "node-1"'* ]]

	run docker_swarm inspect c2
	# FIXME: This will help debugging the failing test.
	echo $output
	[ "$status" -eq 0 ]
	[[ "${output}" == *'"Name": "node-1"'* ]]

	run docker_swarm inspect c3
	[ "$status" -eq 0 ]
	[[ "${output}" != *'"Name": "node-1"'* ]]

	run docker_swarm inspect c4
	[ "$status" -eq 0 ]
	[[ "${output}" == *'"Name": "node-1"'* ]]

	run docker_swarm inspect c5
	[ "$status" -eq 0 ]
	[[ "${output}" != *'"Name": "node-1"'* ]]
}
