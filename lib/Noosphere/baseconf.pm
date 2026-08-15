package Noosphere::baseconf;

use vars qw(%base_config);

%base_config = (

	# secret portion of hashes
	
	HASH_SECRET => 'physics_for_life_freedom',

	# System paths
	
	BASE_DIR => '/var/www/pp',
	ENTITY_DIR => '/var/www/pp/data/entities',

	# Commands

	latex2htmlcmd => '/usr/bin/latex2html',

	# Web paths
	
	MAIN_SITE => 'physicslibrary.org',
	IMAGE_SITE => 'images.physicslibrary.org',
	FILE_SITE => 'aux.physicslibrary.org',
	STATIC_SITE => 'aux.physicslibrary.org',
	ENTITY_SITE => 'aux.physicslibrary.org',
	
	#BUG_URL => 'bugs.planetmath.org',
	BUG_URL => 'https://github.com/bloftin/PhysicsLibrary/issues',
	#BUG_URL => 'https://sourceforge.net/tracker/?atid=1126522&group_id=251294&func=browse',
	DOC_URL => 'https://aux.physicslibrary.org/doc',
	
	# E-mail config
	
	FEEDBACK_EMAIL => 'admin@physicslibrary.org',
	SYSTEM_EMAIL => 'admin@physicslibrary.org',
	REPLY_EMAIL => 'admin@physicslibrary.org',

	# Database configuration

	DBMS => 'MariaDB',	# should be a valid DBI name for your DBMS
	DB_NAME => 'pp',
	DB_USER => 'ec2-user',
	DB_PASS => 'Sup#rn0va',
	DB_HOST => 'localhost',


	# Project customization

	PROJECT_NAME => 'Physics Library',
	PROJECT_NICKNAME => 'PP',
	SLOGAN => 'An open source physics library',
	SUBJECT_DOMAIN => 'physics',

	# banned ips (usually people trying to mirror the site)

	BANNED_IPS => {
		'x.y.z.1'=>1,
		'x.y.z.2'=>1},

	# misc options

	CLASSIFICATION_SUPPORTED => 1,
	RENDERING_OUTPUT_FILE => 'physicslibrary.html',

	# End of config
);

