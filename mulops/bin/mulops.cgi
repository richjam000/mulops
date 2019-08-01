#!/usr/bin/perl
# Richard Jamieson : 15/6/2016
# Based on functional spec (20160428-1)
# See: https://sourceforge.net/projects/mulops
# Catalogs in JSON format
#
#RJuse strict;
use warnings;
use Getopt::Std;
use File::Basename;
use File::Spec;

###########################################################################################
# Set a default location for catalogs and perl modules
my $default_catalogs_dir ;
my $default_models_dir ;

BEGIN
   {
      my $default_perlmods_dir ;
      my $default_doc_dir ;
      my $mulops_bin = dirname($0) ;
      my $abs_path_mulops_bin = File::Spec->rel2abs( $mulops_bin ) ;
      my $mulops_top_dir = dirname($abs_path_mulops_bin) ;
      $ENV{PATH} .= ":$abs_path_mulops_bin" ;
      $default_catalogs_dir = "$mulops_top_dir/catalogs" ;
      $default_models_dir = "$mulops_top_dir/models" ;
      $default_doc_dir = "$mulops_top_dir/docs" ;
      $ENV{MULOPS_DOCS} = $default_doc_dir ;
      $default_perlmods_dir = dirname($abs_path_mulops_bin) . "/lib" ;
      if ( -d $default_perlmods_dir ) {
         push ( @INC,"$default_perlmods_dir");
         $ENV{PERL5LIB} .= ":$default_perlmods_dir";
      }
   }
use JSON;	# Only required when using "MULMODEL" variable
use MULOPS;

###########################################################################################
# Process command line arguments ( See "mulops usage" )

use CGI qw/:standard :html3/; 
use CGI::Carp qw( fatalsToBrowser );

my $JSCRIPT=<<EOF;
<script language="JavaScript">
function toggle(source) {
  checkboxes = document.getElementsByName('mulops_picks');
  for(var i=0, n=checkboxes.length;i<n;i++) {
    checkboxes[i].checked = source.checked;
  }
}
</script>
EOF

;

print header;

print start_html(-title => "mulops", -BGCOLOR=>'#6698FF');
print "$JSCRIPT";
print_prompt();
print end_html;

sub print_prompt {

   print start_form;

   # Get model
   my $env_model = param('model');
   $env_model = 'solaris11' unless defined $env_model ;

   # Set mulops_mode based on model
   my $mulops_mode ;
   if ( $env_model eq 'Live' ) {
      $mulops_mode = "execute";
   } else {
      $mulops_mode = "oscommand";
   }

   # Get mulops_picks (ie:what items to display )
   my @mulops_picks = param('mulops_picks');
   my $num_mulops_picks = scalar @mulops_picks ;
   my $param_mulops_command_args;
   if ( $num_mulops_picks eq 0 ) {
      @mulops_picks = qw/all/ ;
      $param_mulops_command_args = "all"
   } else {
      $param_mulops_command_args = "@mulops_picks" ;
   }
   my @mulops_command_args = split(' ', $param_mulops_command_args);

   # Get json parameter ( determines if we just show JSON for one item )
   my $param_json = param('json');

   ###########################################################################################
   # Get details of all catalogs - and create catalogs cache
   my $env_catalogs = $ENV{'MULOPS_CATALOGS'};
   my @catalogs = split(' ', $env_catalogs) if defined($env_catalogs);
   if (! @catalogs) {
      @catalogs = glob("$default_catalogs_dir/mulcat.*.json");
   }
   my %catalog_cache = map { $_ => {} } @catalogs;
   my $catalog_cache = \%catalog_cache ;

   ###########################################################################################
   # MODELING CODE
   # If a model is used, locad up the cache with the data from that model
   my $mulops_output_cache  ;
   my $model_link;
   my $model_cache = {} ;
   if ($env_model ne "Live" )  {
      $model_link = "&model=$env_model";
      my $model_file = "$default_models_dir/model.$env_model.json";
      if ( ! -r $model_file ) { 
         print "Cant find model file : $model_file\n" ;
         exit 1 ;
      } else {
         local $/; #Enable 'slurp' mode
         open my $fh, "<", "$model_file" or die "Cant open model file : $model_file";;
         my $model_file_data = <$fh>;
         close $fh;
         $mulops_output_cache = from_json($model_file_data);
         $model_cache = $mulops_output_cache ;
      }
   }
   ###########################################################################################


   ###########################################################################################
   # Run mulops !

   foreach my $mulops_command_arg (@mulops_picks) {
      mulops($mulops_command_arg,$mulops_mode,$catalog_cache,$mulops_output_cache) ;
   }

   my $mulops_group = getSet("$default_catalogs_dir/mulgroup.default.json") ;
   my @mulops_group_keys = keys $mulops_group->{'mulgroups'} ;
   my $picked_group = param('groups');
   my $group_items = $mulops_group->{'mulgroups'}->{$picked_group}->{group};

   my %group_labels ;
   %group_labels->{'all'} = 'All Categories';
   foreach my $mulops_group_key (@mulops_group_keys) {
      my $group_description = $mulops_group->{'mulgroups'}->{$mulops_group_key}->{description};
      %group_labels->{$mulops_group_key} = $group_description ;
   }

   my @mulops_group_names = ('all');
   push (@mulops_group_names, @mulops_group_keys);

   my $param_filter = param('filter');
   $param_filter = '' unless defined($param_filter) ;

   my @vals_to_display;
   if ( $param_mulops_command_args eq "all") {
      @vals_to_display = sort keys %$mulops_output_cache ;
      @vals_to_display = grep !/^all$/, @vals_to_display; # not sure how 'all' gets in there !
      $mulops_output_cache = $model_cache ;
   } else {
      @vals_to_display = @mulops_picks;
   }

   ###########################################################################################
   # Printing
   if ( defined($param_json) ) {
      print '<PRE>';
      print "$mulops_output_cache->{$param_mulops_command_args}->{catalog}" ;
      print '</PRE>';
      exit 0;
   }

   print "<p>";
   print '<a href=https://gitlab.scsuk.net/scsuk/mulops/wikis/home><button type="button">Wiki</button></a>';
   print '<a href=https://gitlab.scsuk.net/scsuk/mulops/wikis/Get-Mulops><button type="button">Get Mulops</button></a>';
   print '<a href=/catalogs><button type="button">Catalogs</button></a>';
   
   print popup_menu(-name=>'model',
                  -values=>[qw/windows10 ubuntu14 redhat6 redhat7 centos6 centos7 solaris10 solaris11 aix hpux/],
                  -Onchange=>"this.form.submit()",
                  -default=>'solaris11');

   print popup_menu(-name=>'groups',
                  -labels=>\%group_labels,
                  -values=>[@mulops_group_names],
                  -Onchange=>"this.form.submit()");

   print '<INPUT TYPE="text" name="filter" onChange="this.form.submit()">';

   print "Filtered on: $param_filter";
   print "<br>";

   print '<table border="1" width="100%">';

   if ( $env_model ne 'Live' ) { 
      print '<col width="2%">';
      print '<col width="15%">';
      print '<col width="25%">';
      print '<col width="58%">';
   } 
      print '<tr>';
         #print '<th><input type="checkbox" onClick="toggle(this)" checked></th>';
         #RJprint '<th><input type="checkbox" onClick="toggle(this)" ></th>';
         print '<th>';
            print submit('Action','Select');
         print '</th>';
         print '<th>mulops-command</th>';
         print '<th>description</th>';
         if ( $env_model eq 'Live' ) { 
            print '<th>output</th>';
         }
         print '<th>oscommand</th>';
      print '<tr>';
      foreach my $cache_value (@vals_to_display) {
         my $display_row = 'n';
         my $cat_name = $mulops_output_cache->{$cache_value}->{'cat_name'};
         my $mulops_desc = $mulops_output_cache->{$cache_value}->{'description'} ;
         my $mulops_out = $mulops_output_cache->{$cache_value}->{'execute'};
         my $oscommand = $mulops_output_cache->{$cache_value}->{'oscommand'} ;
         my $mulops_catalog_entry = $mulops_output_cache->{$cache_value}->{catalog} ;
         if ( $oscommand =~ /^NoValues/ ) {
            $oscommand="<a href=\"mailto:Richard.Jamieson\@scsuk.net?Subject=mulops $env_model $cache_value NoValues\" target=\"_top\">$oscommand</a>";
         }
         if ( (grep /^$cache_value$/, @$group_items) || (! defined($picked_group)) || ($picked_group eq 'all')   )  {
            $display_row = 'y';
         }
         if ( $param_filter ne '') {
            if ( ($cache_value =~ /$param_filter/i) || ($mulops_desc =~ /$param_filter/i) || ($oscommand =~ /$param_filter/i) )  {
               $display_row = 'y';
            } else {
               $display_row = 'n';
            }
         }

         if ( $display_row eq 'y' ) {
         print '<tr>';
            #print '<td><input type=CHECKBOX name=mulops_picks value="' . $cache_value . '" checked></td>';
            print '<td align="center"><input type=CHECKBOX name=mulops_picks value="' . $cache_value . '" ></td>';
            print '<td>';
               print "<a href=\"/cgi-bin/mulops/bin/mulops.cgi?mulops_picks=$cache_value&json\">$cache_value</a>";
            print '</td>';
            print '<td>';
               print "$mulops_desc";
            print '</td>';
            if ( $env_model eq 'Live' ) { 
               print '<td>';
                  print '<PRE>';
                  print "$mulops_out";
                  print '</PRE>';
               print '</td>';
            }
            print '<td>';
               if ( $cache_value =~ /.doc$/ ) {
                  $mulops_doc = printDoc($oscommand) ;
                  my $nr_of_lines = $mulops_doc =~ tr/\n//;
                  if ( $nr_of_lines <= 10 ) {
                     print '<PRE>';
                     print "$mulops_doc";
                     print '</PRE>';
                  } else {
                     print "<a href=\"/docs/$oscommand\">$oscommand</a>";
                  }
               } else {
                  print "$oscommand";
            print '</td>';
            }
         print '</tr>';
         }
   }

   print '</table>';
   print end_form;
}



###########################################################################################
sub usage {
   system("mulops usage");
   exit;
}
###########################################################################################

# Params = catalog
# Return = hashref
sub getSet {
   # Can add another parameter later - to signify format and maybe source of catalog
   my ($group) = @_;
   #print "Get Set : $group \n";
   my $mulops_group;
   if ( $group =~ "^http:" ) {
      my $http = HTTP::Lite->new;
      my $req = $http->request("$group") or die "Unable to get document: $!";
      die "Request failed ($req): ".$http->status_message() if $req ne "200";
      my $mulops_url_data = $http->body();
      $mulops_group = from_json($mulops_url_data);
   } else {
     my $mulops_file_data;
     local $/; #Enable 'slurp' mode
     open my $fh, "<", "$group";
     $mulops_file_data = <$fh>;
     close $fh;
     $mulops_group = from_json($mulops_file_data);
   }
   return $mulops_group ;
}


###########################################################################################
# POD info

=head1 NAME

 mulops - Multi Operating System tool
          Simple consistent commands..

=head1 SYNOPSIS

 See "mulops manual" or "mulops usage"

=head1 DESCRIPTION

 Different operating systems have different ways of doing the same thing.
 ( eg: showing total amount of system memory ).
 This tool aims to help to provide a consistent way to do the same things
 across multiple operating systems.
 The tool can be used for one-off commands, to create portable system
 programs, or just for education


=head1 INSTALL

 See "mulops readme"

=head1 AUTHORS

 Richard Jamieson richard.jamieson@scsuk.net

