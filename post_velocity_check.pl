#!/usr/local/bin/perl
use File::Tail;
#use Time::HiRes;

use lib "/home/newwebsite/Geo-IP-1.38/lib/";
use Geo::IP;
use strict;
#my $fname = "/var/log/nginx-http.log";
my $fname = "/home/testwebsite/logs/access_log";
#my $fname = "/usr/local/etc/apache22/logs/access_log";
sub get_cn($);
my @pars;
my %interval=();
my %count=();
my $match="";
my @whitelist= ('1.1.1.1');
my $logfile = File::Tail->new(name=>$fname, maxinterval=>1, adjustafter=>2, tail=>20 );
my @url;
my $flag=0;
$VAR::mesg="";
my $hn=`hostname`;

sub get_cn($)
        {
my $val;
my $i=Geo::IP->open("/home/newwebsite/GeoLiteCity.dat", GEOIP_STANDARD );
 my $r=$i->record_by_name(@_);
if($r){
$val=$r->country_name;
return $val;
        }
        }


sub alrt()
 {
 my $to='me@my-supportcompany.com';
 my $from='http_logcheck@test-website.com';
 my $subject="post url in $hn";

 open(SM, "|/usr/sbin/sendmail -t") or die "cant open sendmail";
 print SM "To: $to\n";
 print SM "From: $from\n";
 print SM "Subject: $subject\n\n";
 print SM "$VAR::mesg\n";
 close(SM);
 }

my $trigger=`date +"%s"`+4;
my $ctime;
print "first trigger: time-$trigger\n";

 while(defined(my @log=$logfile->read)){
  my @logs = @log;

foreach my $log_inst(@logs){
#print $log_inst;
my $skip=0;
if($log_inst =~ m/"POST\s/)
        {
#print $log_inst;
@pars=split(' ',$log_inst);
#print @pars;
my $ip=$pars[0];
my $arr=$pars[6];
#print "$arr\n";
my $el="$arr\n";
$match=$ip.$arr;
my $cn=get_cn($ip);
#print "$el from $ip\n";
if ($ip ~~ \@whitelist || $cn eq "United States")
                {
#       print "$ip is from $cn\n";
                $skip=1;
                }

     if($match ~~ \@url)
        {

        my $etime=`date +"%s"`;
#       print "end time is $etime\n";

        my $diff=$etime-$interval{$match};
#print "diffence for $match now is $diff\n";
        $count{$match}+=1;
#       print "$match     $count{$match} times \n";
                if ($diff<=30 && ($count{$match}%10==0))
                    {
                #       print "ALERT more than $count{$match} conn: from $ip. $cn link: $el\n";
                     $VAR::mesg =$VAR::mesg."$count{$match} post req from $ip country:$cn in $diff seconds. link: $el";
                #print $VAR::mesg;
                        #               alrt();

                        $flag=1;
#               print $VAR::mesg;
                    }




        }
    elsif($skip!=1)
    #else
        {
    push (@url, $match);

my $stime=`date +"%s"`;
$interval{$match}=$stime;
$count{$match}=1;
#print "push time for $match is $interval{$match}. country $cn\n";
        }

     }




  }

$ctime=`date +"%s"`;
#print "cheking $ctime agaist $trigger\n";
                        if($ctime>=$trigger)     {

        #               elsif($diff>30 && $count{$match}<5) {
                        #print "only $count{$match} matches in $diff seconds. deleting..\n";
                     #   print "trigerred $VAR::mesg";
                                if($flag==1) {
                                                alrt();
                                                $VAR::mesg="";
                                                delete $interval{$match};
                                                delete $count{$match};
                                                $flag=0;
                                                 undef @url
                                                        }
                        $trigger+=60;
                                                  }

}
