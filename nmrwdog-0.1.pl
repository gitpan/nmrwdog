# -------------------------------------------------------------------------
# nmrwdog.pl v.1.0
# Mosaiq Dicom/Namer watchdog utility , (c) Atif Kirimli, Mesi Medikal
# watch windows application log on the Dicom/Namer workstation
# if detect a faulting Nmrwin.exe or dcmwin.exe , exit with 11 exit code
# batch file starts a reboot of the Dicom/Namer machine afterwards.
# updates screen and namer-watchdog.log file periodically about status
# -------------------------------------------------------------------------

use Win32::EventLog;

# CUSTOMIZE THESE IF NEEDED
$WAIT_TIME       = 15 ;			# check event log every WAIT_TIME seconds
$REPORT_EVERY    = 4 * 60  ;    # 4*60 : report every 1 hour on screen and log
$LOG_FILE    = "namer-watchdog.log" ;   # log file name
$VERSION = '0.1';

# DO NOT TOUCH BELOW
#################################################################################

my $report1 = 0;
print "Mosaiq Namer watchdog started  $cur_time\n";
&logOutput ("Mosaiq Namer watchdog started  $cur_time" ) ;
$lastrecs  = 0 ;
$lastbase  = 0 ;
		
 while ( 1 ) {   # repeat for-ever and check the event log for dcm/nmr crash faults

 $handle=Win32::EventLog->new("Application", $ENV{ComputerName})
        or &my_die("Can't open Application EventLog\n");
 $handle->GetNumber($recs)
        or &my_die ("Can't get number of EventLog records\n");
 $handle->GetOldest($base)
        or &my_die ("Can't get number of oldest EventLog record\n");

    if ( $base != $lastbase || $recs != $lastrecs ) 
		{
#			print ("recs: $recs , base: $base \n");
			$x = $lastbase + $lastrecs  ; 
			while (   ($x < ($base + $recs ))  && ( $x != 0 ) ) 
			{
				$handle->Read(EVENTLOG_FORWARDS_READ|EVENTLOG_SEEK_READ, $x, $hashRef)
					or &my_die ("Can't read EventLog entry #$x\n");
				$src = $hashRef->{Source} ; 		
				{
					Win32::EventLog::GetMessageText($hashRef);
					$msg = $hashRef->{Message} ;
#					print "[$src]: Entry $x: $msg\n";
					if (  &isFaulty($msg)  )
					 {
					 	print "[$src]: Entry $x: $msg\n";
						&logOutput (" fault found: $msg\n") ;
						&logOutput ("  exit with 11");
						&logOutput ("---------------");
					     print "\n####---FAULT_DCM/NMR_Found---#### \n";
						 exit 11;
					 }
				}
			   $x++;
			}
			$lastrecs = $recs ; 
			$lastbase = $base ; 
		}
	$report1 ++ ;
	if($report1 >= $REPORT_EVERY)
	    {   $t = &getTimeStamp;
			print "Checking eventlog for faulting Dicom/Namer events, $t : ($base-$recs)\n"; 
			&logOutput(" Checking eventlog for faulting Dicom/Namer events. ($base-$recs)") ; 
			$report1 = 0 ;
		}
	
	$handle->Close();
	sleep $WAIT_TIME;
 }
 
 
 
# functions below
 
 sub isFaulty
 {  my ($m) = @_;
 
	if ( ($msg =~ /nmrwin/i ) &&  ($msg =~ /faulting/i ) )   { return 1 } ;
	if ( ($msg =~ /dcmwin/i ) &&  ($msg =~ /faulting/i ) )   { return 1 } ;

	#below is for test
	#if ( ($msg =~ /snmp/i ) &&  ($msg =~ /termin/i ) )   { return 1 } ;
  
 return 0;
 }
 

sub getTimeStamp  
     {
       my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =  localtime ;
       my $now = sprintf("%04d%02d%02d_%02d%02d%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec );
    return ($now) ;
  }

sub strTrim   
	{  my ($l) = @_;
	   $l =~ s/^\s+//;
	   $l =~ s/\s+$//;
  return $l; 
}

sub logOutput
	{
	my ($m) = @_;   	my $t = &getTimeStamp;
	open LOG, ">>$LOG_FILE";
		print LOG "$t : $m\n";
	close LOG;	
}


sub my_die             # print $m and exit with 0
{  my ($m) = @_;
print "$m";
exit 0;
}
 