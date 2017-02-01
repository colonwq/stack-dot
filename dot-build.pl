#!/usr/bin/perl
$|=1 ;
# build DOT file for heat stack
#
# argument is the stack to procss

my $STACK = @ARGV[0] ;

#print "STACK: $STACK\n" ;

&print_header() ;

my @RESOURCES = &resource_list( $STACK ) ;

foreach my $RESOURCE ( @RESOURCES )
{
  chomp( $RESOURCE ) ;

  #print "Processing resource: $RESOURCE\n" ;

  my @DEPS = &get_deps( $STACK, $RESOURCE ) ;

  #print @DEPS ; 

  foreach my $DEP ( @DEPS )
  {
    print "$RESOURCE -> $DEP ;\n"
  }
}

&print_footer() ;

sub print_header
{
  print <<EOF;
strict digraph prof {

ranksep = 1 ;


EOF
}

sub print_footer
{
  print <<EOF;
}
EOF
}


sub get_deps
{
  my ( $STACK, $RESOURCE ) = @_ ;

  #print "get_deps called for $RESOURCE\n" ;

  my @LINES = `openstack stack resource show -f yaml $STACK $RESOURCE` ;
  my @FINDS ;

  #here is a FSM to look at the lines below and return all the lines
  #followig required_by: and start with -
  #.
  #.
  #
  #required_by:
  #- ComputeServiceChain
  #- ControllerServiceChain
  #- CephStorageServiceChain
  #- ObjectStorageServiceChain
  #- BlockStorageServiceChain
  #resource_name: DefaultPasswords
  #.
  #.
  my $FOUND_REQ = 0 ;
  foreach my $LINE ( @LINES ) 
  {
    #print "line: $LINE\n" ;
    #next if ( $LINE !=~ '^required_by' ) && ( $FOUND_REQ == 0 ) ;
    if ( $LINE =~ 'required_by' )
    {
      #print "Found required_by for $RESOURCE\n" ;
      #print $LINE ;
      $FOUND_REQ = 1 ;
      next
    }
    if ( ( $LINE =~ '^\-' ) && ( $FOUND_REQ == 1 ) )
    {
      #print "LINE: $LINE\n" ;
      $LINE =~ s/\- // ;
      chomp ($LINE ) ;
      push( @FINDS, $LINE) ;
      next ;
    }
    
  }
  return @FINDS ;
}

sub resource_list
{
  ( $STACK ) = @_ ;

  @RESOURCE_LIST = `openstack stack resource list -f yaml $STACK    | grep resource_name  | awk '{print \$2}'` ;
                  # openstack stack resource list -f yaml overcloud | grep resource_name  | awk '{print $2}'

  #print "Resource List: @RESOURCE_LIST\n" ;

  return @RESOURCE_LIST ;

}
