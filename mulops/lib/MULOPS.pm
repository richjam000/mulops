package MULOPS;
# Richard Jamieson : 16/6/2016
# Based on functional spec (20160428-1)
# See: https://sourceforge.net/projects/mulops
# Catalogs in JSON format
# CATALOG: Valid operators :  Numeric(==,!=,<,>,<=,>=) String(eq,ne,lt,gt,le,ge) Match(=~ and value can be a RE)

use strict;
use base qw(Exporter);
@MULOPS::EXPORT = qw(mulops printDoc);
use warnings;
use JSON;
use HTTP::Lite;
use Capture::Tiny::Extended qw/capture tee capture_merged tee_merged/;


BEGIN {
    $MULOPS::VERSION = '4.00';
}


sub mulops {
   ###########################################################################################
   # If no mulops_command argument passed - then just list all avaliable commands/descriptions
   # Else - process the command + arguments

   my ($mulops_command_arg,$mulops_mode,$catalog_cache,$mulops_output_cache) = @_;

   return if defined($mulops_output_cache->{$mulops_command_arg}->{exit_code}) ;

   my @catalogs_list = keys %$catalog_cache ;
   foreach my $catalog (@catalogs_list) {
         my $mulops_catalog;
         if (! defined($catalog_cache->{$catalog}->{'catalog'})) {
            # print "Cache Add : $catalog \n";
            $mulops_catalog = &getCatalog($catalog) ;
            $catalog_cache->{$catalog} = $mulops_catalog;
         } else {
            # print "Cache Find : $catalog \n";
             $mulops_catalog = $catalog_cache->{$catalog} ;
         }
         my $cat_description = $mulops_catalog->{'catalog-description'} ;
         my $cat_name = $mulops_catalog->{'catalog'} ;
         my $cat_version = $mulops_catalog->{'catalog-version'} ;
         my $cat_author = $mulops_catalog->{'author'} ;
         my @cat_commands = keys %{$mulops_catalog->{'mulops-commands'}} ;

         if ( $mulops_command_arg eq 'all' ) {
            foreach my $cat_command (@cat_commands) {
               mulops($cat_command,$mulops_mode,$catalog_cache,$mulops_output_cache) ;
            }
           next;
         }

         my $mulops_oscommand_variations = $mulops_catalog->{'mulops-commands'}->{$mulops_command_arg}->{'variations'} ; # Array

         if ($mulops_oscommand_variations) { 

            my $mulops_oscommand_description = $mulops_catalog->{'mulops-commands'}->{$mulops_command_arg}->{'description'} ; # Scalar
            $mulops_oscommand_description = 'NoValues' unless defined $mulops_oscommand_description ;
            $mulops_output_cache->{$mulops_command_arg}->{description} = $mulops_oscommand_description ;

            $mulops_output_cache->{$mulops_command_arg}->{cat_name} = $cat_name ;

            my $variation_arraysize = scalar @$mulops_oscommand_variations ;
            my $variation_lastelement =  $variation_arraysize - 1 ;
            foreach my $oscommand_index (0 .. $variation_lastelement) {
               my @mulops_oscommand_variation_fields = (keys %{$mulops_oscommand_variations->[$oscommand_index]});
               # all fields except "oscommand" are used as "selectors" (ie: lookup values )
               my @oscommand_selector_fields = grep !/oscommand/, @mulops_oscommand_variation_fields;
               my $selectors_match = "yes" ;
               foreach my $oscommand_selector_field (@oscommand_selector_fields) {
                  my $cat_selector_operator = $mulops_oscommand_variations->[$oscommand_index]->{$oscommand_selector_field}->[0];
                  my $cat_selector_val = $mulops_oscommand_variations->[$oscommand_index]->{$oscommand_selector_field}->[1];
                  mulops($oscommand_selector_field,"execute",$catalog_cache,$mulops_output_cache) ;
                  my $mulops_selector_value = $mulops_output_cache->{$oscommand_selector_field}->{execute};
                  my $match_test="\"$mulops_selector_value\" $cat_selector_operator \"$cat_selector_val\"";
                  if ( ! eval $match_test ) {
                     $selectors_match = "no" ;
                     last ;   # stop checking the @oscommand_selector_fields
                  }
               }
               if ( "$selectors_match" eq "no" ) {
                  # Try the next variation
                  next ;
               }

               # So  - at this point we have found the matching record.
               return if ( $mulops_mode eq 'description' ) ;

               my $mulops_oscommand_variation = $mulops_oscommand_variations->[$oscommand_index]->{'oscommand'};
               if ($mulops_oscommand_variation) {
                  
                  # Put oscommand into the cache
                  $mulops_output_cache->{$mulops_command_arg}->{oscommand} = $mulops_oscommand_variation ;
                  # Put oscommands catalog json into the cache
                  my $catalog_output = to_json($mulops_oscommand_variations->[$oscommand_index], {utf8 => 1, pretty => 1}) ;
                  $mulops_output_cache->{$mulops_command_arg}->{catalog} = $catalog_output ;
                  return if ( $mulops_mode eq 'catalog' ) ;

                  if ($mulops_mode eq "execute") {
                     if ( not defined($mulops_output_cache->{$mulops_command_arg}->{execute})) {
                        if ( $mulops_command_arg =~ /.doc$/ ) {
                           my $mulops_doc = printDoc($mulops_oscommand_variation) ;
                           $mulops_output_cache->{$mulops_command_arg}->{exit_status} = 'pass' ;
                           $mulops_output_cache->{$mulops_command_arg}->{execute} = $mulops_doc ;
                        } else {
                           # Execute the OS command
                           # print "Execute: $mulops_command_arg \n" ; # very useful debug line for checking the cacheing !
                           my ($merged, $return) = capture_merged {
                              return system( $mulops_oscommand_variation );
                           };
                           if ( $return != 0 ) {
                              $mulops_output_cache->{$mulops_command_arg}->{exit_status} = 'fail' ;
                           } else {
                              $mulops_output_cache->{$mulops_command_arg}->{exit_status} = 'pass' ;
                           }
                           chomp($merged);
                           $mulops_output_cache->{$mulops_command_arg}->{execute} = $merged ;
                           # print "RJ: mulops_command_arg cached add: $merged \n";
                        }
                     }  
                  }
               } 
               # Stop checking catalogs ( found catalog entry - and processed all variations )
               # Yes- that means expect all variations of one mulops_command to be in the same catalog.
               return ;
            }
         }
   }
   #print "Processed all catalogs and not found $mulops_command_arg \n";
   return if $mulops_command_arg eq 'all' ;
 
   my $NoValues = 'NoValues (Please email Richard.Jamieson at scsuk.net, if you can fill in the blanks)';
   $mulops_output_cache->{$mulops_command_arg}->{execute} = "$NoValues" if ! defined($mulops_output_cache->{$mulops_command_arg}->{execute}) ;
   $mulops_output_cache->{$mulops_command_arg}->{exit_status} = 'fail' if ! defined($mulops_output_cache->{$mulops_command_arg}->{exit_status});
   $mulops_output_cache->{$mulops_command_arg}->{oscommand} = "$NoValues" if ! defined($mulops_output_cache->{$mulops_command_arg}->{oscommand}) ;
   $mulops_output_cache->{$mulops_command_arg}->{catalog} = 'NoValues' if ! defined($mulops_output_cache->{$mulops_command_arg}->{catalog}) ;
   $mulops_output_cache->{$mulops_command_arg}->{cat_name} = 'NoValues' if ! defined($mulops_output_cache->{$mulops_command_arg}->{cat_name}) ;
   $mulops_output_cache->{$mulops_command_arg}->{description} = 'NoValues' if ! defined($mulops_output_cache->{$mulops_command_arg}->{description}) ;
}
###########################################################################################
# Params = catalog
# Return = hashref
sub getCatalog {
   # Can add another parameter later - to signify format and maybe source of catalog
   my ($catalog) = @_;
   #print "Get Catalog : $catalog \n";
   my $mulops_catalog ;
   #      if (( -r $catalog ) || ( $catalog =~ "^http:" )) {
   if ( $catalog =~ "^http:" ) {
      my $http = HTTP::Lite->new;
      my $req = $http->request("$catalog") or die "Unable to get document: $!";
      die "Request failed ($req): ".$http->status_message() if $req ne "200";
      my $mulops_url_data = $http->body();
      $mulops_catalog = from_json($mulops_url_data);
   } else {
     my $mulops_file_data;
     local $/; #Enable 'slurp' mode
     open my $fh, "<", "$catalog";
     $mulops_file_data = <$fh>;
     close $fh;
     $mulops_catalog = from_json($mulops_file_data);
   }
   return $mulops_catalog ;
}
###########################################################################################
# printDoc
sub printDoc {
   my $default_doc_dir = $ENV{MULOPS_DOCS};
   my $mulops_doc = $default_doc_dir . '/' . $_[0];		# Name the file
   #open(INFO, "$mulops_doc") or die "No Doc: '$mulops_doc'";		# Open the file
   open(INFO, "$mulops_doc") or return("No doc: $mulops_doc");		# Open the file
   my @lines = <INFO>;		# Read it into an array
   close(INFO);			# Close the file
   return "@lines";			# Print the array
}

1;
__END__

=head1 NAME

 mulops - Multi Operating System tool
          Simple consistent commands..

=head1 SYNOPSIS

 use MULOPS;	# Imports "mulops" subroutine

 # Initialise mulops_output_cache (ie: dont do this again for subsequent mulops calls )
 my $mulops_output_cache = {}   ;

 # Initialise catalog_cache (ie: dont do this again for subsequent mulops calls )
 my $env_catalogs = $ENV{'MULOPS_CATALOGS'};
 my @catalogs = split(' ', $env_catalogs) if defined($env_catalogs);
 if (! @catalogs) {
   @catalogs = glob("$default_catalogs_dir/mulcat.*.json");
 }
 my %catalog_cache = map { $_ => {} } @catalogs;
 my $catalog_cache = \%catalog_cache ;

 # Pick a mulops-command - eg: "model'
 $mulops_command='model';

 # Run Mulops
 mulops($mulops_command,$mulops_mode,$catalog_cache,$mulops_output_cache) ;

 # After running mulops $mulops_output_cache will have been populated.
 $mulops_output_cache->{$mulops_command}->{cat_name}   # name of catalog
 $mulops_output_cache->{$mulops-command}->{"catalog"}      # catalog entry from catalog
 $mulops_output_cache->{$mulops-command}->{"description"}  # description of mulops-command
 $mulops_output_cache->{$mulops-command}->{"oscommand"}    # the OS command
 $mulops_output_cache->{$mulops-command}->{"execute"}      # Execution output (if any)
 $mulops_output_cache->{$mulops-command}->{"exit_status"}  # Exit sttus of oscommand (if any)

 # Can now extract results from the catalog
 eg:
 $Server_model = $mulops_output_cache->{"model"}->{"execute"};
 print "Server model is $Server_model";


 ------------------------------------------------------------------------
 @catalogs:	 	array of mulops JSON catalog names
 $mulops_command_arg:	mulops command argument
 $mulops_mode:		["execute"|"oscommand"|"catalog"]
			execute:  the oscommand is executed.
			oscommand: the oscommands is displayed only.
			catalog:  the catalog entry for the command is displayed.
 $catalog_cache:	Can pass cached catalogs.
			Only expect this to be used by mulops itself for recursion routines.
 $mulops_output_cache   Can pass cached mulops results ( eg: descriptions, oscommands and execution-output )
			$mulops_output_cache->{$mulops-command}->{"description"}
			$mulops_output_cache->{$mulops-command}->{"oscommand"}
			$mulops_output_cache->{$mulops-command}->{"execute"}

=head1 DESCRIPTION

 Different operating systems have different ways of doing the same thing.
 ( eg: showing total amount of system memory ).
 This tool aims to help to provide a consistent way to do the same things
 across multiple operating systems.
 The tool can be used for one-off commands, to create portable system
 programs, or just for education

=head1 INSTALL

 Follow instructions in "mulops readme" - or...
 Copy this module to a directory in your $PERL5LIB search path.

=head1 AUTHORS

 Richard Jamieson richard.jamieson@scsuk.net


