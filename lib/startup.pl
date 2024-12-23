#!/usr/bin/perl
use strict;

use Apache;
#Ben added compat line for testing
#use Apache2::compat;
use DBI();
use XML::LibXML;
use XML::LibXSLT;

# allow deep-recurisve XSL template functions
#
XML::LibXSLT->max_depth(65535);

# search engine communication
#
#use lib '/var/www/pp/noosphere/essex/essex_2004-01-05';
#use SearchClient;

# use all the modules
#
use Noosphere;

use Noosphere::Dispatch;
use Noosphere::Util;
use Noosphere::Charset;
use Noosphere::Cookies;
use Noosphere::Config;
use Noosphere::DB;
use Noosphere::Layout;
use Noosphere::Login;
use Noosphere::Ticket;
use Noosphere::News;
use Noosphere::NewUser;
use Noosphere::Docs;
use Noosphere::GetObj;
use Noosphere::EditObj;
use Noosphere::DelObj;
use Noosphere::Encyclopedia;
use Noosphere::StatCache;
use Noosphere::Stats;
use Noosphere::UserData;
use Noosphere::Messages;
use Noosphere::Polls;
use Noosphere::Forums;
use Noosphere::Latex;
use Noosphere::Admin;
use Noosphere::Users;
use Noosphere::Spell;
use Noosphere::Search;
use Noosphere::Filebox;
use Noosphere::Msc;
use Noosphere::Params;
use Noosphere::Cache;
use Noosphere::Corrections;
use Noosphere::Mail;
use Noosphere::Morphology;
use Noosphere::Collection;
use Noosphere::Crossref;
use Noosphere::Indexing;
use Noosphere::Notices;
use Noosphere::Classification;
use Noosphere::Help;
use Noosphere::Requests;
use Noosphere::Watches;
use Noosphere::IR;
use Noosphere::Template;
use Noosphere::FileCache;
use Noosphere::Pronounce;
use Noosphere::Orphan;
use Noosphere::Authors;
use Noosphere::ACL;
use Noosphere::XSLTemplate;
use Noosphere::XML;
use Noosphere::Versions;
use Noosphere::Password;
use Noosphere::GenericObject;
use Noosphere::Collab;
use Noosphere::Owners;
use Noosphere::Linkpolicy;

$ENV{MOD_PERL} or die "not running under mod_perl!";

# Ben added to try to debug connection problems
$Apache::DBI::DEBUG = 0;

# Ben added the init to save connection overhead on very first
# request of every child


1;
