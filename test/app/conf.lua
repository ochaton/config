etcd = {
	instance_name = 'instance_01',
	prefix = '/instance',
	endpoints = {"http://etcd:2379"},
	fencing_enabled = true,
}

box = {
	background = false,
	log_level = 6,
	log_format = 'plain'
}

app = {

}