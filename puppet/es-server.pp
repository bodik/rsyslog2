class { 'elasticsearch':
	manage_repo  => true,
	repo_version => '1.2',
	java_install => true,
	config => { 'cluster.name' => 'mrx' }
}

elasticsearch::instance { 'es01': }

elasticsearch::plugin{'lmenezes/elasticsearch-kopf':
	module_dir => 'kopf',
	instances  => 'es01'
}
elasticsearch::plugin{'mobz/elasticsearch-head':
	module_dir => 'head',
	instances  => 'es01'
}
elasticsearch::plugin{'bleskes/sense':
	module_dir => 'sense',
	instances  => 'es01'
}
