#!/usr/bin/perl -W -U

###########################################################################
#                                                                         #
#   Copyright (C) 2015 Wolfgang Hotwagner(code@feedyourhead.at)		  #
#                                                                         #
#   This program is free software; you can redistribute it                #
#   and/or modify it under the terms of the                               #
#   GNU General Public License as published by the                        #
#   Free Software Foundation; either version 2 of the License,            #
#   or (at your option) any later version.                                #
#                                                                         #
#   This program is distributed in the hope that it will be               #
#   useful, but WITHOUT ANY WARRANTY; without even the implied            #
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR               #
#   PURPOSE. See the GNU General Public License for more details.         #
#                                                                         #
#   You should have received a copy of the GNU General Public             #
#   License along with this program; if not, write to the Free            #
#   Software Foundation, Inc., 51 Franklin St, Fifth Floor,               #
#   Boston, MA 02110, USA                                                 #
#                                                                         #
###########################################################################


use CGI qw(param);

$gpiodir = "/sys/class/gpio";

$parmrm = param('rm');
if($parmrm != "")
{
	system("/usr/bin/atrm $parmrm");
}

$parmdose1 = param('dose1');
if($parmdose1 != "")
{
	if($parmdose1 == 2)
	{
		system("/usr/bin/sudo /usr/local/bin/gpio write 4 0 ");
	}
	else
	{
		system("/usr/bin/sudo /usr/local/bin/gpio write 4 1 ");
	}
	print "Location: http://$ENV{'HTTP_HOST'}/cgi-bin/steckdose.pl \n\n";
}

$parmdose2 = param('dose2');
if($parmdose2 != "")
{
	if($parmdose2 == 2)
	{
		system("/usr/bin/sudo /usr/local/bin/gpio write 6 0 ");
	}
	else
	{
		system("/usr/bin/sudo /usr/local/bin/gpio write 6 1 ");
	}
	print "Location: http://$ENV{'HTTP_HOST'}/cgi-bin/steckdose.pl \n\n";
}

$parmdatum = param('datum');
if($parmdatum != "")
{
$parmdose = param('dose');
$parmeinaus = param('einaus');
if( ($parmdose == 4) || ($parmdose == 6) && ( ($parmeinaus == 0) || ($parmeinaus == 1)) )
{
	$atstring = "/usr/bin/sudo /usr/local/bin/gpio write $parmdose $parmeinaus";
	$aus = system("echo $atstring | /usr/bin/at $parmdatum");
	print "Location: http://$ENV{'HTTP_HOST'}/cgi-bin/steckdose.pl \n\n";
} 
}

print "Content-type:text/html\n\n";
print <<EndOfHTML;
<html><head>
<title>Steckdosenleiste</title>

<script type="text/javascript">
function autoSubmit(dosenwahl) {
    var formObject = document.forms[dosenwahl];
    formObject.submit();
}

</script>
</head>
<body>
EndOfHTML



print "<h1>Steckdosenleiste</h1>";

$dose23=`cat $gpiodir/gpio23/value`;

print "<form action=steckdose.pl name=Dose1>\n";

if($dose23 == 1)
{
	print "Dose1: ";
	print '<input type="radio" name=dose1 onChange=autoSubmit("Dose1") value="1" checked>Ein';
	print '<input type="radio" name=dose1 onChange=autoSubmit("Dose1") value="2"> Aus';
	print '<noscript><input type=submit name=change></noscript>';
}
else
{
	print "Dose1: ";
	print '<input type="radio" name=dose1 onChange=autoSubmit("Dose1") value="1">Ein';
	print '<input type="radio" name=dose1 onChange=autoSubmit("Dose1") value="2" checked> Aus';
	print '<noscript><input type=submit name=change></noscript>';
}

print "</form>";

$dose25=`cat $gpiodir/gpio25/value`;

print "<form action=steckdose.pl name=Dose2>\n";

if($dose25 == 1)
{
	print "Dose2: ";
	print '<input type="radio" name=dose2 onChange=autoSubmit("Dose2") value="1" checked>Ein';
	print '<input type="radio" name=dose2 onChange=autoSubmit("Dose2") value="2"> Aus';
	print '<noscript><input type=submit name=change></noscript>';
}
else
{
	print "Dose2: ";
	print '<input type="radio" name=dose2 onChange=autoSubmit("Dose2") value="1">Ein';
	print '<input type="radio" name=dose2 onChange=autoSubmit("Dose2") value="2" checked> Aus';
	print '<noscript><input type=submit name=change></noscript>';
}

print "</form>";

print "<br>\n";
print "<H2> Zeitschaltungen </H2>\n";

$atq = `atq`;

my @atstrings = split(/\n/,$atq);

foreach(@atstrings)
{
	if($_ =~ /^(\d+)\t(.*)www-data/)
	{
		$nr = $1;
		$date = $2;

		$gpio = `at -c $nr | grep gpio`;
		if($gpio)
		{
			if($gpio =~ /^\/usr\/bin\/sudo \/usr\/local\/bin\/gpio write (\d+) (\d)/)
			{
				$einaus = "einschalten";
				$einaus = "ausschalten" if($2 == 0);

				if ($1 == 4) 
				{	print "<form action=steckdose.pl name=entfern>";
					print "$date ->  Dose1 $einaus\n";
					print "<input type=hidden name=rm value=$nr>";
					print "<input type=submit name=rmsub value=entfernen>";
					print "</form>";
				}
				if($1 == 6)
				{
					print "<form action=steckdose.pl name=entfern>";
					print "$date ->  Dose2 $einaus\n";
					print "<input type=hidden name=rm value=$nr>";
					print "<input type=submit name=rmsub value=entfernen>";
					print "</form>";
				}
			}
		}
	}
}

print "<br>";
print "<form action=steckdose.pl  name=zeitschaltung > ";
print "<fieldset>";
print "<legend>Neue Zeitschaltung definierten</legend>";
print "<label for=datum>Datum:</label>";
print "<input type=text name=datum><br>";
print "<input type=radio name=dose value=4 checked>Dose1";
print "<input type=radio name=dose value=6>Dose2<br>";
print "<input type=radio name=einaus value=1 checked>ein";
print "<input type=radio name=einaus value=0>aus<br>";
print "<input type=submit name=ok value=hinzuf&uuml;gen>";
print "</fieldset>";
print "</form>";

print "<br>\n";
print "<pre>\n";
print '       steckdosenleiste allows fairly complex time specifications, extending the POSIX.2 standard.  It accepts times of the form HH:MM to run a job at a specific time of day.  (If that  time  is  already  past,  the  next  day  is
       assumed.)  You may also specify midnight, noon, or teatime (4pm) and you can have a time-of-day suffixed with AM or PM for running in the morning or the evening.  You can also say what day the job will be run,
       by giving a date in the form month-name day with an optional year, or giving a date of the form MMDD[CC]YY, MM/DD/[CC]YY, DD.MM.[CC]YY or [CC]YY-MM-DD.  The specification of a date must follow  the  specifica-
       tion  of  the  time  of day.  You can also give times like now + count time-units, where the time-units can be minutes, hours, days, or weeks and you can tell at to run the job today by suffixing the time with
       today and to run the job tomorrow by suffixing the time with tomorrow.

       For example, to run a job at 4pm three days from now, you would do  4pm + 3 days, to run a job at 10:00am on July 31, you would do  10am Jul 31 and to run a job at 1am tomorrow, you would do 1am  tomor-
       row.';
print "</pre>\n";

print "</body></html>";


