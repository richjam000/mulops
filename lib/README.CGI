README: lib  ( Just for the CGI )

This directory to contain non-standard (ie: Not in OS provided perl ) perl modules 
that are specifically required by mulops.
Only putting this under my source-tree to help with development and testing.
You can also download an install (and test) the latest versions from the official source.

mulops will find the modules in the default mulops "lib" directory.
IF you install them in a different directory you will need to make sure that directory is 
in your PERL5LIB search path.
You could put something like this into your .profile:
	PERL5LIB=$PERL5LIB:/usr/share/lib
	export PERL5LIB

# CGI & CGI.pm
  Only needed for web GUI.
