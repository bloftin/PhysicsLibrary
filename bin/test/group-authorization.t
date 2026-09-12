#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../lib";

{
    package TemplateNS;
    sub new { bless {}, shift }
    sub unsetKeys { }
    sub setKey { }
    sub expand { return 'group form' }
}

require Noosphere::Groups;

no warnings 'redefine';
no warnings 'once';

our (@added, @deleted, @acl_added);
our $group_owner = 7;
our $has_acl = 0;

sub reset_state {
    @added = ();
    @deleted = ();
    @acl_added = ();
    $group_owner = 7;
    $has_acl = 0;
}

package Noosphere;

sub getConfig {
    my $key = shift;
    return 'objects' if $key eq 'en_tbl';
    return 'collab' if $key eq 'collab_tbl';
    return {books => {title => ['text']}} if $key eq 'generic_schema';
    return 'groups' if $key eq 'groups_tbl';
    return 'gmember' if $key eq 'gmember_tbl';
    return 'users' if $key eq 'user_tbl';
    return 100 if $key eq 'access_admin';
    return undef;
}

sub errorMessage { return 'ERROR: '.$_[0] }
sub paddingTable { return $_[0] }
sub makeBox { return $_[1] }
sub qhtmlescape { return $_[0] }
sub lookupfield {
    my ($table, $field, $where) = @_;
    return $main::group_owner if $table eq 'groups' && $field eq 'userid';
    return 'target user' if $table eq 'users' && $field eq 'username';
    return 42 if $table eq 'users' && $field eq 'uid' && $where eq 'uid=42';
    return undef if $table eq 'gmember';
    return 'object title' if $field eq 'title';
    return 'group name' if $field eq 'groupname';
    return undef;
}
sub hasPermissionTo { return $main::has_acl }

package main;

*Noosphere::addGroup = sub { return 123 };
*Noosphere::addACL = sub { push @acl_added, [@_] };
*Noosphere::memberEditor = sub { return 'member editor' };
*Noosphere::addUserToGroup = sub { push @added, [@_] };
*Noosphere::deleteAllUsersFromGroup = sub { push @deleted, ['members', @_] };
*Noosphere::deleteGroup = sub { push @deleted, ['group', @_] };
*Noosphere::getAdminGroups = sub { return '[groups]' };

my $owner = {uid => 7, data => {access => 1}};
my $other = {uid => 8, data => {access => 1}};
my $admin = {uid => 9, data => {access => 100}};

reset_state();
like(Noosphere::addUserToGroup_wrapper({groupid => 99, userid => 42}, $other),
    qr/aren't the admin/, 'non-admin cannot add a user to another group');
is(scalar @added, 0, 'rejected add did not call addUserToGroup');

reset_state();
like(Noosphere::addUserToGroup_wrapper({groupid => 99, userid => 42}, $owner),
    qr/User Added|target user/, 'group owner can add a user');
is_deeply(\@added, [[99, 42]], 'allowed add uses requested group and user');

reset_state();
Noosphere::groupEditor({delgroup => 1, selected_99 => 1}, $other);
is_deeply(\@deleted, [], 'forged group delete skips groups the user does not own');

reset_state();
Noosphere::groupEditor({delgroup => 1, selected_99 => 1}, $owner);
is_deeply(\@deleted, [['members', 99], ['group', 99]], 'group owner can delete own group');

reset_state();
like(Noosphere::createEditorGroup({from => 'objects', id => 1017}, $other),
    qr/can't change access/, 'cannot create editor group without ACL authority');
is_deeply(\@acl_added, [], 'rejected editor group did not add ACL');

reset_state();
$has_acl = 1;
is(Noosphere::createEditorGroup({from => 'objects', id => 1017}, $other),
    'member editor', 'ACL authority can create editor group');
is(scalar @acl_added, 1, 'allowed editor group adds ACL');

reset_state();
is(Noosphere::createEditorGroup({from => 'objects', id => 1017}, $admin),
    'member editor', 'site admin can create editor group');
is(scalar @acl_added, 1, 'admin editor group adds ACL');

done_testing();
