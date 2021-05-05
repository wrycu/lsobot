# BEGIN USER VARIABLES

$logPath = "$env:USERPROFILE\Saved Games\DCS.openbeta_server\Logs\dcs.log"
$hookUrl = "HOOK_URL_HERE"

# END USER VARIABLES

# The regex to check the log messages for
$lsoEventRegex = "^.*landing.quality.mark.*"

#The number of seconds that a landing quality mark should've arrived in. Anything older than this amount is discounted as a duplicate.
$timeTarget = New-TimeSpan -Seconds 60

#Get the system time, convert to UTC, and format to HH:mm:ss
[DateTime]$sysTime = [DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')

#Check dcs.log for the last line that matches the landing quality mark regex.
try {
    $landingEvent = Select-String -Path $logPath -Pattern $lsoEventRegex | Select-Object -Last 1

}
catch {
    Write-EventLog -LogName "Application" -Source "LSO Bot" -EventId 402 -EntryType Information -Message -join ("Could not find dcs.log at ", $logPath) -Category 1
}

#If dcs.log did not contain any lines that matched the LSO regex, stop.
if ($landingEvent -eq $null ) {
    Exit
}

# Strip the log message down to the time that the log event occurred. 
$logTime = $landingEvent
$logTime = $logTime -replace "^.*(?:dcs\.log\:\d{1,5}\:)", ""
$logTime = $logTime -replace "\..*$", ""
#$logTime = $logTime.split()[-1]

#Convert the log time string to a usable time object

[DateTime]$trapTime = $logTime

#Get the difference between the LSO event and the current time

$diff = New-TimeSpan -Start $trapTime -End $sysTime

#Strip the log message down to the landing grade and add escapes for _

$Grade = $landingEvent
$Grade = $Grade -replace "^.*(?:comment=LSO:)", ""
$Grade = $Grade -replace ",.*$", ""

<# 
---------------------------------------------------------------------
                        BEGIN REGRADING
---------------------------------------------------------------------
#>

#Grade Regex
$rGRADE =    "GRADE:\S{1,3}"
$1WIRE =     "(?:WIRE# 1)"
$PERFECT =  "GRADE:_OK_"
$OK =       "GRADE:OK"
$FAIR =     "GRADE:(OK)"
$NOGRADE =  "GRADE:---"
$CUT =      "GRADE:C"
$WO =       "GRADE:WO"
$OWO =      "GRADE:OWO"
$WOAFU =    "WO\(AFU\)(TL|IC|AR)"

#Grade Remarks Regex - Removals
$SLOX = "(_|\()?(?:SLOX)(_|\))?"
$EGIW = "(_|\()?(?:EGIW)(_|\))?"
$BC = "(?:\[BC\])"

# Left and Right positions, no minor deviations
$LEFT = "(?!\))_?D?L?U?L(X|IM|IC|AR)_?(?!\))"
$RIGHT = "(?!\))_?D?L?U?R(X|IM|IC|AR)_?(?!\))"


# (X) At Start
$LULX =     "(_|\()?(?:LULX)(_|\))?"
$LURX =     "(_|\()?(?:LURX)(\)|_)?"
$HX =       "(_|\()?(?:HX)(_|\))?"
$LOX =      "(_|\()?(?:LOX)(_|\))?"
$FX =       "(_|\()?(?:FX)(_|\))?"
$NX =       "(_|\()?(?:NX)(_|\))?"
$WX =       "(_|\()?(?:WX)(_|\))?"
$DRX =      "(_|\()?(?:DRX)(_|\))?"
$DLX =      "(_|\()?(?:DLX)(_|\))?"

# (IM) In Middle
$LURIM =    "(_|\()?(?:LURIM)(_|\))?"
$LULIM =    "(_|\()?(?:LULIM)(_|\))?"
$HIM =      "(_|\()?(?:HIM)(_|\))?"
$LOIM =     "(_|\()?(?:LOIM)(_|\))?"
$DRIM =     "(_|\()?(?:DRIM)(_|\))?"
$DLIM =     "(_|\()?(?:DLIM)(_|\))?"
$FIM =      "(_|\()?(?:FIM)(_|\))?"
$SLOIM =    "(_|\()?(?:SLOIM)(_|\))?"
$WIM =      "(_|\()?(?:WIM)(_|\))?"
$TMRDIM =   "(_|\()?(?:TMRDIM)(_|\))?"
$NERDIM =   "(_|\()?(?:NERDIM)(_|\))?"

# (IC) In Close
$LURIC =    "(_|\()?(?:LURIC)(_|\))?"
$LULIC =    "(_|\()?(?:LULIC)(_|\))?"
$LOIC =     "(_|\()?(?:LOIC)(_|\))?"
$HIC =      "(_|\()?(?:HIC)(_|\))?"
$FIC =      "(_|\()?(?:FIC)(_|\))?"
$PIC =      "(_|\()?(?:PIC)(_|\))?"
$PPPIC =    "(_|\()?(?:PPPIC)(_|\))?"
$WIC =      "(_|\()?(?:WIC)(_|\))?"
$DRIC =     "(_|\()?(?:DRIC)(_|\))?"
$DLIC =     "(_|\()?(?:DLIC)(_|\))?"
$NERDIC =   "(_|\()?(?:NERDIC)(_|\))?"
$TMRDIC =   "(_|\()?(?:TMRDIC)(_|\))?"
$SLOIC =    "(_|\()?(?:SLOIC)(_|\))?"


# (AR) At Ramp
$LURAR =    "(_|\()?(?:LURAR)(_|\))?"
$LULAR =    "(_|\()?(?:LULAR)(_|\))?"
$LOAR =     "(_|\()?(?:LOAR)(_|\))?"
$HAR =      "(_|\()?(?:HAR)(_|\))?"
$FAR =      "(_|\()?(?:FAR)(_|\))?"
$SLOAR =    "(_|\()?(?:SLOAR)(_|\))?"
$PAR =      "(_|\()?(?:PAR)(_|\))?"
$WAR =      "(_|\()?(?:WAR)(_|\))?"
$DRAR =     "(_|\()?(?:DRAR)(_|\))?"
$DLAR =     "(_|\()?(?:DLAR)(_|\))?"
$NERDAR =   "(_|\()?(?:NERDAR)(_|\))?"
$TMRDAR =   "(_|\()?(?:TMRDAR)(_|\))?"

# (IW) In Wires
$LURIW =    "(_|\()?(?:LURIW)(_|\))?"
$LULIW =    "(_|\()?(?:LULIW)(_|\))?"
$LOIW =     "(_|\()?(?:LOIW)(_|\))?"
$SLOIW =    "(_|\()?(?:SLOIW)(_|\))?"
$FIW =      "(_|\()?(?:FIW)(_|\))?"
$LLIW =     "(_|\()?(?:LLIW)(_|\))?"
$LRIW =     "(_|\()?(?:LRIW)(_|\))?"
$3PTSIW =   "(_|\()?(?:3PTSIW)(_|\))?"
$BIW =      "(_|\()?(?:BIW)(_|\))?"
$EGTL =     "(_|\()?(?:EGTL)(_|\))?"


# Remove SLOX, EGIW, and BC from vocab
if ($Grade -match $SLOX ) {
    $Grade = $Grade -replace $SLOX, ""
    $Grade = $Grade -replace '\s+', ' '
    }
if ($Grade -match $EGIW) {
    $Grade = $Grade -replace $EGIW, ""
    $Grade = $Grade -replace '\s+', ' '
    }
if ($Grade -match $BC) {
    $Grade = $Grade -replace $BC, ""
    $Grade = $Grade -replace '\s+', ' '
    }

    $lockGrade = 0

#Find instances where DRX\DLX and LURX\LULX are called together, and replace with simply LURX\LULX
if ((($Grade -match $DRX) -and ($Grade -match $LURX)) -or (($Grade -match $DLX) -and ($Grade -match $LULX))) {
    $Grade = $Grade -replace $DRX, ""
    $Grade = $Grade -replace $DLX, ""
    $Grade = $Grade -replace '\s+', ' '

}

#Check for waveoffs
if (($Grade -match $WO) -or ($Grade -match $OWO) -or ($Grade -match $WOAFU)) {
    $lockGrade = 1
}

# Check for automatic Cuts
if ($lockGrade -eq 0) {
    if (($Grade -match $LLIW) -or 
        ($Grade -match $LRIW) -or 
        ($Grade -match $SLOIC) -or 
        ($Grade -match $SLOAR) -or 
        ($Grade -match $SLOIW) -or
        ($Grade -match $PPPIC)) {

            $Grade = $Grade -replace $rGRADE, $CUT
            $Grade = $Grade -replace '\s+', ' '
            $lockGrade = 1
    }
}

# Check for TMRDIC or TMRDAR and EGTL or 3PTS for a cut pass OR if TMRDIC or TMRDAR were major deviations

if ($lockGrade -eq 0) {
    if ((($Grade -match $TMRDIC) -or ($Grade -match $TMRDAR)) -and (($Grade -match $EGTL) -or ($Grade -match $3PTSIW)) ) {
        $Grade = $Grade -replace $rGRADE, $CUT
        $Grade = $Grade -replace '\s+', ' '
        $lockGrade = 1
    }
    elseif ($Grade -match "_TMRD(IC|AR)_") {
        $Grade = $Grade -replace $rGRADE, $CUT
        $Grade = $Grade -replace '\s+', ' '
        $lockGrade = 1
    }
    
}

# Check for No Grades
if ($lockGrade -eq 0) {
    if (($Grade -match $TMRDAR) -or
        ($Grade -match $TMRDIC) -or
        ($Grade -match $3PTSIW) -or 
        ($Grade -match $BIW) -or 
        ($Grade -match $EGTL) -or 
        ($Grade -match $TMRDIM) -or 
        ($Grade -match $SLOIM) -or 
        ($Grade -match $PPPIC) -or 
        ($Grade -match $DRIC) -or 
        ($Grade -match $DLIC) -or 
        ($Grade -match $LULIC) -or 
        ($Grade -match $LURIC) -or 
        ($Grade -match $NERDIC) -or 
        ($Grade -match $DRAR) -or 
        ($Grade -match $DLAR) -or 
        ($Grade -match $NERDAR) -or 
        ($Grade -match $LURAR) -or 
        ($Grade -match $LULAR) -or 
        ($Grade -match $WAR) -or 
        ($Grade -match $FIW)) {

            $Grade = $Grade -replace $rGRADE, $NOGRADE
            $Grade = $Grade -replace '\s+', ' '
            $lockGrade = 1
    }
}

#Check for oscillating flight paths and No Grade
if ($lockGrade -eq 0) {
    if (($Grade -match $LEFT) -and ($Grade -match $RIGHT)) {
        $Grade = $Grade -replace $rGRADE, $NOGRADE
        $Grade = $Grade -replace '\s+', ' '
        $lockGrade = 1        
    }
}


# Check for fair passes
if ($lockGrade -eq 0) {
    if (($Grade -match $DRX) -or 
    ($Grade -match $DLX) -or 
    ($Grade -match $DRIM) -or 
    ($Grade -match $DLIM) -or 
    ($Grade -match $LURIM) -or 
    ($Grade -match $LULIM) -or 
    ($Grade -match $NERDIM) -or 
    ($Grade -match $FIM) -or 
    ($Grade -match $WIM) -or 
    ($Grade -match $FIC) -or 
    ($Grade -match $HIC) -or 
    ($Grade -match $LOIC) -or 
    ($Grade -match $PIC) -or 
    ($Grade -match $WIC) -or 
    ($Grade -match $HAR) -or 
    ($Grade -match $FAR)) {

        $Grade = $Grade -replace $rGRADE, $FAIR
        $Grade = $Grade -replace '\s+', ' '
        $lockGrade = 1
    }
}

# Check for OK passes
if ($lockGrade -eq 0) {
    if (($Grade -match $LULX) -or 
        ($Grade -match $LURX) -or 
        ($Grade -match $FX) -or 
        ($Grade -match $HX) -or 
        ($Grade -match $HIM) -or 
        ($Grade -match $NX) -or 
        ($Grade -match $WX)) {

            $Grade = $Grade -replace $rGRADE, $OK
            $Grade = $Grade -replace '\s+', ' '
            $lockGrade = 1
    }
}

# Check for empty #3 wires and change to _OK_
if ($Grade -match "GRADE:\S{1,4}\s*?:\s*WIRE#\s*3") {
    $Grade = $Grade -replace $rGRADE, $PERFECT
}
# Check for empty #2 and #4 wires and switch to OK
if ($Grade -match "GRADE:\S{1,4}\s*?:\s*WIRE#\s*(2|4)") {
    $Grade = $Grade -replace $rGRADE, $OK
}

<# 
---------------------------------------------------------------------
                        END REGRADING
---------------------------------------------------------------------
#>


$Grade = $Grade -replace '\s+', ' '
$Grade = $Grade -replace "_", "\_"

#Strip the log message down to the pilot name

$Pilot = $landingEvent
$Pilot = $Pilot -replace "^.*(?:initiatorPilotName=)", ""
$Pilot = $Pilot -replace ",.*$", ""

if($Pilot -match "Saul") {
    $Pilot = "<@110154653630504960>"
}

if($Pilot -match "Black") {
    $Pilot = "<@138491556838506496>"
}

if($Pilot -match "Breezy") {
    $Pilot = "<@108401022606508032>"
}

if($Pilot -match "Essah") {
    $Pilot = "<@103280382849335296>"
}
if($Pilot -match "kevb") {
    $Pilot = "<@143778093343965184>"
}

if($Pilot -match "runny") {
    $Pilot = "<@286162987146936321>"
}

if($Pilot -match "Foogle") {
    $Pilot = "<@94828547272605696>"
}

if($Pilot -match "Heinz") {
    $Pilot = "<@123282968159584256>"
}


if($Pilot -match "intel") {
    $Pilot = "<@111233747516403712>"
}

if($Pilot -match "Kill") {
    $Pilot = "<@103981464349077504>"
}

if($Pilot -match "Heinz") {
    $Pilot = "<@123282968159584256>"
}

if($Pilot -match "Knub") {
    $Pilot = "<@110596267926618112>"
}

if($Pilot -match "Tri") {
    $Pilot = "<@162050207067013120>"
}

if($Pilot -match "Wrycu") {
    $Pilot = "<@108005836579696640>"
}

if($Pilot -match "Instinct") {
    $Pilot = "<@107301205222420480>"
}

if($Pilot -match "Spooky") {
    $Pilot = "<@150780675950116865>"
}

if($Pilot -match "Vega") {
    $Pilot = "<@106848076882292736>"
}

if($Pilot -match "Abso") {
    $Pilot = "<@100606220624216064>"
}

if($Pilot -match "Fracsid") {
    $Pilot = "<@631495942838812695>"
}


if($Pilot -match "Alphabet") {
    $Pilot = "<@108387557355601920>"
}

if($Pilot -match "GDR") {
    $Pilot = "<@135184282703364096>"
}

if($Pilot -match "Jive") {
    $Pilot = "<@107186659761631232>"
}

if($Pilot -match "Justi") {
    $Pilot = "<@134419342556135424>"
}

if($Pilot -match "ProTag") {
    $Pilot = "<@121700508879683584>"
}

if($Pilot -match "Racket") {
    $Pilot = "<@106852273824526336>"
}

if($Pilot -match "Rico") {
    $Pilot = "<@297495515866857474>"
}

if($Pilot -match "roll") {
    $Pilot = "<@318878626764554240>"
}

if($Pilot -match "Serral") {
    $Pilot = "<@108788985148493824>"
}

if($Pilot -match "Ohio") {
    $Pilot = "<@107235886218891264>"
}

#If the difference between the system time and log event time is greater than the time target, stop. 

if ($diff -gt $timeTarget) {

    Exit

    }

    #If the $Pilot or $Grade somehow turned up $null or blank, stop
    elseif (($Pilot -eq "System.Object[]") -or ($Grade -eq "System.Object[]")) {
        Write-EventLog -LogName "Application" -Source "LSO Bot" -EventId 400 -EntryType Warning -Message "A landing event was detected but the pilot name or grade was malformed. Discarding pass." -Category 1
        Exit

    }

    #If the $Pilot or $Grade has a date in the format of ####-##-##, stop. This will happen when AI land as the regex doesn't work correctly without a pilot field in the log event.
    elseif (($Pilot -match "^.*\d{4}\-\d{2}\-\d{2}.*$") -or ($Grade -match "^.*\d{4}\-\d{2}\-\d{2}.*$")) {
        Write-EventLog -LogName "Application" -Source "LSO Bot" -EventId 401 -EntryType Warning -Message "A landing event was detected but the name or grade contained a date in the format of 2020-01-01 after processing. This indicates that the pass was performed by an AI or the log message was malformed. Discarding pass." -Category 1
        Exit

    }
    #Create the webhook and send it
    else {
        #Message content
        $messageConcent = -join("**Pilot: **", $Pilot, " **Grade:** ", $Grade  )


        #json payload
        $payload = [PSCustomObject]@{
            content = $messageConcent
        }
        #The webhook
        try {
            Invoke-RestMethod -Uri $hookUrl -Method Post -Body ($payload | ConvertTo-Json) -ContentType 'application/json'  
        }
        #If the error was specifically a network exception or IO exception, write friendly log message
        catch [System.Net.WebException],[System.IO.IOException] {
            Write-EventLog -LogName "Application" -Source "LSO Bot" -EventId 403 -EntryType Warning -Message "Failed to establish connection to Discord webhook. Please check that the webhook URL is correct, and activated in Discord." -Category 1 -RawData $hookUrl
           
        }
        catch {
            Write-EventLog -LogName "Application" -Source "LSO Bot" -EventId 404 -EntryType Warning -Message "An unknown error occurred attempting to invoke the API request to Discord." -Category 1


        }
   
        Write-EventLog -LogName "Application" -Source "LSO Bot" -EventId 100 -EntryType Information -Message "A landing event was detected and sent successfully via Discord." -Category 1

}
