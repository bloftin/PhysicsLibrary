package Noosphere::baseconf;

use vars qw(%base_config);

%base_config = (

	# secret portion of hashes
	
	HASH_SECRET => 'fill_me_with_random_junk',

	# System paths
	
	BASE_DIR => '/var/www/pm',
	ENTITY_DIR => '/var/www/pm/data/entities',

	# Web paths
	
	MAIN_SITE => 'planetphysics.org',
	IMAGE_SITE => 'images.planetphysics.org',
	FILE_SITE => 'aux.planetphysics.org',
	STATIC_SITE => 'aux.planetphysics.org',
	ENTITY_SITE => 'aux.planetphysics.org',
	
	BUG_URL => 'http://bugs.planetphysics.org',
	DOC_URL => 'http://aux.planetphysics.org/doc',
	
	# E-mail config
	
	FEEDBACK_EMAIL => 'feedback@planetphysics.org',
	SYSTEM_EMAIL => 'pm@planetphysics.org',
	REPLY_EMAIL => 'noreply@planetphysics.org',

	# Database configuration

	DBMS => 'mysql',	# should be a valid DBI name for your DBMS
	DB_NAME => 'pm',
	DB_USER => 'pm',
	DB_PASS => '*******',
	DB_HOST => 'localhost',

	# Project customization

	PROJECT_NAME => 'PlanetPhysics',
	PROJECT_NICKNAME => 'PP',
	SLOGAN => 'Physics for the people, by the people.',
	SUBJECT_DOMAIN => 'Physics',

	# banned ips (usually people trying to mirror the site)

	BANNED_IPS => {
		'x.y.z.1'=>1,
		'x.y.z.2'=>1},

	# misc options

	CLASSIFICATION_SUPPORTED => 1,
	RENDERING_OUTPUT_FILE => 'planetphysics.html',

	# End of config
);

