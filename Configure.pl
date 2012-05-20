#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Carp;
use POSIX;

=pod

=head1 NAME

Configure.pl - site configuration script

=head1 SYNOPSIS

  ./Configure.pl [--build=<site name>] [--run=<site name>] [--[no]link]

=head1 DESCRIPTION

=head1 OPTIONS

=head1 FILES

=over 4

=item ./files

List of files to be processed of the form

<path>:<skip>:<mode>:<noheader>\n

B<Configure.pl> will process I<path>.tmpl skipping the first I<skip>
lines to create I<path>-I<$RunName> with mode I<mode>.  If I<noheader>
is true then no header is added to the output file.  This is desirable
for XML files.  =item ./sites

=back

=cut

my ($SiteName)=`whoami`=~/^(\S*)/;
my ($HostName)=`hostname`=~/^([^.\n]*)/;
$SiteName.=".$HostName";
$::DoLinks=1;

my $BuildName=$SiteName;
my $RunName=$SiteName;
my %Values;
my %Used;

if (!Getopt::Long::GetOptions('build=s' => \$BuildName,
				 'run=s' => \$RunName,
				 'link!' => \$::DoLinks) || (!$BuildName) || (!$RunName)) {
  die "Usage: $0 [--build=<site name>] [--run=<site name>] [--[no]link]
BuildName and RunName will default to [user].[hostname], if they can be
established";
}


#------------------------------------------------------------------------------

sub ProcessFile ($$$$) {
  my $file=shift; # file to generate (example.tmpl generates example, $file = example)
  my $skip=shift; # n first lines to skip
  my $mode=shift; # mode of file to create
  my $noheader=shift; # skip comment header thingy

  my $template="$file.tmpl";
  my $final="$file-$RunName";

  chmod 0666,$final;	# so we can overwrite it..

  open(TMPL,$template) || croak "Can't open $template: $!";
  open(FINAL,">$final") || croak "Can't create $final: $!";

  my @tmpl = <TMPL>;
  my @out = ProcessTemplate($template, $skip, $noheader, \@tmpl);
  print FINAL @out;

  close TMPL;
  close FINAL;

  chmod $mode,$final || die "Can't set mode on $final: $!";

  MakeLink($final,$file);
}

sub ProcessTemplate {
    my ($template,  # name of .tmpl file (for header)
	$skip,
	$noheader,
	$in  # list reference of incoming template
	) = @_;
    my @in = @$in; # needed so we can shift() safely
    my @out = ();

    for(my $n=0 ; $n < $skip ; ++$n) {
	push @out, shift @in;
    }

    chomp(my $date=`date`);
    unless ( $noheader ) {
	push @out, "# !!!DO NOT EDIT!!!
# Created on $date from $template for site $BuildName/$RunName
";
    }

    my $disabled=0;
    my @ifstate;
    while(defined ($_ = shift (@in))) {
	next if /^#[^#]/;
	
	# allow [if Foo] and [if !Foo]
	if(/\[if\s+(\!?)([^\]]*)\]/) { 
	    push @ifstate,$disabled;
	    my ($inverter, $variable) = ($1, $2); # avoid long-thrown $n, cuz scary
	    $disabled=1 if !DoSubst($variable);
	    $disabled = !$disabled if $inverter;
	    
	    next;
	}

	# spliced in BenLine(tm) from suppose-RT
	$disabled = !$disabled, next if /\[else\]/;
	$disabled=pop @ifstate,next if /\[fi\]/;
    
	unless ($disabled) {
	    SweepAndSubstitute (\$_);
	    push @out, $_;
	}
	
    }
    croak "Mismatched [if...]" if $#ifstate != -1;

    # each line should JUST terminate with \n, anything else
    # may cause confusion in obscure cases (found when generating
    # EXCLUDE files for gtar)
    foreach my $line (@out) { $line =~ s/\s+$/\n/s };

    return @out;
}

#------------------------------------------------------------------------------

sub ShowUnused {
  for my $var (keys %Values) {
    print "$var not used!!!\n" unless exists($Used{$var});
  }
}

#------------------------------------------------------------------------------

sub DoSubst ($;$) {
  my $var=shift;
  my $optional=shift;
  if ((!defined $Values{$var}) and $optional) { 
    $$optional = 1;
    return "";
  }
  croak "No value set for $var on line $." unless defined($Values{$var});
  $Used{$var}=1;
  return $Values{$var};
}

#------------------------------------------------------------------------------

sub MakeLink ($$) {
  return unless $::DoLinks;

  my($from,$to) = @_;

  $from=~s/.*\///;

  print "link $from -> $to\n";
  unlink $to;
  system "ln -sf $from $to" || croak "link failed: $!";
}

#------------------------------------------------------------------------------

## main

print "Configuring for build=$BuildName run=$RunName\n";

open(SITES,"sites") || croak "Can't open sites: $!";

while (<SITES>) {
  chomp;
  next unless /^DEFAULT/;

  /^DEFAULT\.([^=]+)=(.*)$/;
  croak "(default) $1 REDEFINED!" if exists $Values{$1};
  $Values{$1}=$2;
  print "(default) $1 -> $2\n";
}

seek SITES,0,SEEK_SET;

$Values{RunName}=$RunName;
$Used{RunName}=1;
while (<SITES>) {
  chomp;
  next unless /^($RunName\.run\.|$BuildName\.build\.)/;

  /^($BuildName|$RunName)\.([^=]+)=(.*)$/;
  croak "$2 REDEFINED!" if exists $Values{$2};
  $Values{$2}=$3;
  print "$2 -> $3\n";
}
close SITES;

# Check for trailing whitespace
foreach my $key (sort keys %Values) {
  my $was = my $value = $Values{$key};
  if ($value =~ s/\s+$//) {
    # Eek!
    # value was perhaps "/some/dir " rather than "/some/dir" which 
    # will be very bloody perplexing
    
    warn "WARNING: $key set to '$was' (which has trailing whitespace): changed to '$value'\n";
    $Values{$key} = $value;
  }
}

# pre-expand any values that refer to other values, 'cuz if we don't,
# @@foo@@ is fine, but [if foo] behaves anomalously

foreach my $key (sort keys %Values) {
    my $was = $Values{$key};
    my $trap;
    my $n = SweepAndSubstitute (\$Values{$key}, \$trap);
    if (!$trap) { print "unrolled $was --> ",$Values{$key}, " in $n iterations\n" if $n }
    else { 
      print "referential value '$key' referred to nonexistant thing; discarding it\n";;
      delete $Values{$key};
    }
}

open(FILES,"files") || croak "Can't open files: $!";
my @files = <FILES>;

# allow use of [if] and values and stuff in files itself
@files = ProcessTemplate("files", 0, 0, \@files);

while((defined ($_ = shift @files))) {
  s/\s+$//; #remove all trailing whitespace, recommended by addy 28/2/2001
  next if /^#/;
  next unless (length $_); # ... skip blank lines
  my ($file,$skip,$mode,$noheader)=/^(.*):(.*):(.*):(.*)$/;
  print "ProcessFile($file,$skip,0$mode,$noheader)\n";
  ProcessFile($file,$skip,oct $mode,$noheader);
}

sub SweepAndSubstitute {
    my $stringref = shift;
    my $optional = shift;
    # warn "S&S called with: $$stringref\n";
    my $i = 0; 
    my $safety = 100;
    my $previous = $$stringref;
    # oh pls
    while ($$stringref =~ s/@@([^@]*)@@/DoSubst($1, $optional)/ge) {
	$i++;
	last if $previous eq $$stringref; # stop if we changed nothing
	croak ">$safety iterations; probably endless recurse in your sites file" if ($i > $safety);
    }
    return $i;
}

ShowUnused();
