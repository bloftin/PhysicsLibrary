package Noosphere;

use strict;

use vars qw{%HANDLERS %NONTEMPLATE};

# this module defines a "registry" of handler functions for Noosphere.
# these are the "func" in the "op=func" CGI params.  the parameters these 
# handlers take are standardized to params, userinf, uploads, where
# params are CGI parameters, userinf is the logged in user's information,
# and uploads is information for an http upload event.
#
# having this registry eliminates the need to do a large number of string 
# comparisons at every request from the client to figure out which
# handler function to call.  instead we just do one hash lookup always.
#
# any new handler function that is directly accessible to a Noosphere 
# client should have a line added here, NOT in Noosphere.pm.
#

# call the correct handler for an op
#
sub dispatch {
  my $handler_hr = shift;   # hashref to handler "registry"
  my $params = shift;       # normal paramaters to any action
  my $userinf = shift;
  my $upload = shift || {};
  
  my $content = '';

  if (defined $handler_hr->{$params->{op}}) {
    $content = &{$handler_hr->{$params->{op}}}($params, $userinf, $upload);
  }

  return $content;
}

# the registry itself
#
%HANDLERS = (

  # front page stuff	
  #
  'frontpage' => \&getFrontPage,
  
  # new user stuff
  #
  'newuser' => \&getNewUser,
  'activate' => \&getActivate,
 
  # admin commands
  #
  'cachecont' => \&cacheControl,
  'rerender' => \&reRenderObj,
  'adminedit' => \&adminObjectEditor,
  'adminclassify' => \&adminClassify,
  'adminstats' => \&adminStats,
  'confirmreq' => \&confirmReq,
  'denyreq' => \&denyReqForm,
  'deletereq' => \&deleteReqForm,
  'confirmallreq' => \&confirmAllReq,
  'dbadmin' => \&dbAdmin,
  'ise' => \&makeISE,
  'deluser' => \&delUser,
  'deactivate' => \&deactivate,
  'reactivate' => \&reactivate,
  'blacklist' => \&blacklistEditor,
  'editscore' => \&editScore,

  # errors
  #
  'showise' => \&showISE,

  # news
  #
  'oldnews' => \&getNewsSummary,
  'postnews' => \&postNews,

  # msc stuff
  #
  'mscsearch' => \&mscSearch,
  'mscbrowse' => \&mscBrowse,
 
  # user info
  #
  'settings' => \&getSettings,
  'getuser' => \&getUser_wrapper,
  'edituser' => \&editUserData,
  'editprefs' => \&editUserPrefs,
  'edituserobjs' => \&userEditObjectList,
  'userobjs' => \&userGenericList,
  'usermsgs' => \&userGenericList,
  'usercorsf' => \&userGenericList,
  'usercorsr' => \&userGenericList,
  'pwchangereq' => \&pwChangeRequest,
  'pwchange' => \&pwChange,
  'watches' => \&listWatches,
  
  # orphaning and adopting
  #
  'orphanage' => \&orphanage,
  'abandon' => \&abandonObject,
  'adopt' => \&adoptObject,
  'transfer' => \&transferObject,
  'sendobj' => \&sendObject,
  'acceptobj' => \&acceptObject,
  'rejectobj' => \&rejectObject,
  'ownerhistory' => \&showOwnerHistory,
  
  # acl editing
  #
  'acledit' => \&ACLEditor,

  # collaboration
  #
  'collab' => \&collabMain,
  'editcollab' => \&editCollab,
  'collab_edit_comment' => \&editCollabComment,
  'collab_release_lock' => \&collabReleaseLock,
  'collab_publish' => \&publishCollab,
  'addsitedoc' => \&addSiteDoc,

  # encyclopedia object stuff
  #
  'enchrono' => \&encyclopediaChrono,
  'preamble' => \&getPreamble,
  'getrefs' => \&getEnRefsTo,
#  'editobj' => \&editObject,
  'delobj' => \&delObject,
  'en' => \&getEncyclopedia,
  'adden' => \&addEncyclopedia, 
  'linkpolicy' => \&edit_linkpolicy,

  # encyclopedia revisions stuff
  #
  'vbrowser' => \&getVersionBrowser,
  'rollback' => \&rollBack,
  'viewver' => \&getVersion,
  #BB: revision difference viewer
  'viewdiff' => \&getVersionDiff,

  # messages
  #
  'messageschrono' => \&messagesChrono,
  'showwatchers' => \&showWatchers,
  'getmsg' => \&getMessage,
  'postmsg' => \&postMessage,
  'forums' => \&getForumsTop,

  # polls
  # 
  'vote' => \&vote,
#  'viewpoll' => \&getObj,  
  'viewpolls' => \&viewPolls,
  'newpoll' => \&addPoll,
  'getpoll' => \&getPoll,
  
  # notices
  #
  'exercise_option' => \&exerciseOption,
  'notices' => \&viewNotices,

  # prompt choice callbacks
  #
  'make_symmetric' => \&makeSymmetric,
  
  # noosphere mail
  #
  'mailbox' => \&mailBox,
  'oldmail' => \&oldMail,
  'sentmail' => \&sentMail,
  'sendmail' => \&sendMailForm,
  'getmail' => \&getMail,
  'unsend' => \&unsendMail,
  'replymail' => \&replyMail,

  # super-template test
  #
  'supertest' => \&templateTest,

  # stats
  #
  'globalcors' => \&globalViewCorrections,
  'unproven' => \&unprovenTheorems,
  'useractivity' => \&showUserActivity,
  'sysstats' => \&getSystemStats,
  'userlist' => \&userList,
  'unclassified' => \&unclassifiedObjects,
  'hitinfo' => \&getHitInfo,
  
  # requests (non-admin ops)
  #
  'reqlist' => \&reqList,
  'oldreqs' => \&oldReqs,
  'addreq' => \&addReq,
  'updatereq' => \&updateReq,

  # corrections
  #
  'correct' => \&postCorrection,
  'getcors' => \&getCorrections,
  'editcors' => \&editCorrections,
  'editfiledcors' => \&editFiledCorrections,
  'rejectcor' => \&rejectCorrection,
  'retractcor' => \&retractCorrectionUI,

  # viewing an object
  #
  'getobj' => \&getObj,

  # generic browsing and editing
  #
  'listobj' => \&listGeneric,
  'edit' => \&genericEditor,
  'browse' => \&browseGeneric,
  'addobj' => \&addGeneric,

  # groups
  #
  'authorlist' => \&showAuthorList,
  'groupedit' => \&groupEditor,
  'memberedit' => \&memberEditor,
  'addusertogroup' => \&addUserToGroup_wrapper,
  'creategroup' => \&createEditorGroup,

  # searching
  #
  'search' => \&vsSearch,
  'oldsearch' => \&search,
  'adv_search' => \&advSearch,

  # docs
  #
  'latexguidelines' => \&getLatexGuidelines,
  'assocguidelines' => \&getAssocGuidelines,
  'license' => \&getLicense,
  'about' => \&getAbout,
  'feedback' => \&getFeedback,
  'sitedoc' => \&siteDoc,  # collaborative site docs

  # misc
  #
  'randomentry' => \&getRandomEntry,
);

# a list of functions not to include in a template; that is, their results show
# up in just a naked window
#
%NONTEMPLATE = ( 
  'checkword' => \&checkword,
  'help' => \&getHelp,
  'httpupload' => \&httpUpload,
  'viewobj' => \&getObj,
  'explain_err' => \&explainError,
);

1;
