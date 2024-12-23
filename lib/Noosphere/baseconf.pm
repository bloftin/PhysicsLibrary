package Noosphere::baseconf;

use vars qw(%base_config);

%base_config = (

	# secret portion of hashes
	
	HASH_SECRET => 'physics',

	# System paths
	
	BASE_DIR => '/var/www/pp/noosphere',
	ENTITY_DIR => '/var/www/pp/noosphere/data/entities',

	# Web paths
	
	MAIN_SITE => 'planetphysics.org',
	IMAGE_SITE => 'images.planetphysics.org',
	FILE_SITE => 'aux.planetphysics.org',
	STATIC_SITE => 'aux.planetphysics.org',
	ENTITY_SITE => 'aux.planetphysics.org',
	
	#BUG_URL => 'bugs.planetmath.org',
	BUG_URL => 'http://tiny.cc/PCCAV',
	#BUG_URL => 'https://sourceforge.net/tracker/?atid=1126522&group_id=251294&func=browse',
	DOC_URL => 'http://aux.planetphysics.org/doc',
	
	# E-mail config
	
	FEEDBACK_EMAIL => 'planetphsyics@phys-x.org',
	SYSTEM_EMAIL => 'planetphysics@phys-x.org',
	REPLY_EMAIL => 'planetphysics@phys-x.org',

	# Database configuration

	DBMS => 'mysql',	# should be a valid DBI name for your DBMS
	DB_NAME => 'PlanetPhys',
	DB_USER => 'username',
	DB_PASS => 'dbpassword',
	DB_HOST => 'virginia.cc.vt.edu',


	# Project customization

	PROJECT_NAME => 'PlanetPhysics',
	PROJECT_NICKNAME => 'PP',
	SLOGAN => 'Physics for the people, by the people.',
	SUBJECT_DOMAIN => 'physics',

	# banned ips (usually people trying to mirror the site)

	BANNED_IPS => {
		'x.y.z.1'=>1,
		'x.y.z.2'=>1},

	# misc options

	CLASSIFICATION_SUPPORTED => 1,
	RENDERING_OUTPUT_FILE => 'planetphysics.html',

	# End of config
);

