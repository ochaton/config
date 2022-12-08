#!/usr/bin/env tarantool

require 'config' {
	instance_name = 'instance_01',
	master_selection_policy = 'etcd.cluster.master',
	file = 'conf.lua',
}

box.schema.user.grant('guest', 'super', nil, nil, { if_not_exists = true })

