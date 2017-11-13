#!/bin/bash

################################################################################
# Programming in Shell 2 [BI-PS2], FIT, CVUT.                                  #
# Assessment Homework                                                          #
# author: Luis Castillo                                                        #
################################################################################

# global variables
ECODE=1
VERBOSE=0
oIFS=$IFS
IFS=$'\n'
DIRs=()
max=1
ti=0

# variables to avoid duplicity of switches
ftimef=0
fxmax=0
fxmin=0
fymax=0
fymin=0
fspeed=0
ftime=0
ffps=0
flegend=0
fgnu=0
feffe=0
fc_file=0
fname=0

# Array declaration to handle the order(timestamps) of the files
declare -A arr
declare -A arr2

# general functions, previously commented in the class. Their purpose is for
# display errors and run the script in verbose mode.
function err {
    printf "$0[error]: %s\n" "$@" >&2
    # echo "$USAGE"
    echo "ERROR!!"
    [[ -f FILE ]] && rm -f FILE
    [ -d $DIR ] && rm -rf $DIR
    exit 1
}
function verbose {
    ((VERBOSE)) && printf "$0[verbose]: %s\n" "$@" >&2
}

# functions
# function for make dirs, validates if the desired name exists, if it is the
# case assign the correspondent index
function name {
    numbers=$(ls | egrep "^${DIR}_[0-9]+$" | awk -F_ '{print $NF}')
    max=$(echo "${numbers[*]}" | sort -nr | head -n1)
    ####echo $max
    [ -d $DIR ] && ((max=$max+1)) && mkdir $DIR"_$max" && \
    DIR+="_$max" || mkdir $DIR 
}

function validate_config_file {
    if [ ! -z ${timeformat+x} ]
    then
        valid='^(\[|)(%y|%Y)([^%0-9]%m|)([^%0-9]%d|)(T| |)([^%0-9]%H|)([^%0-9]%M|)([^%0-9]%S|)(\]|)$'
        if [[ ! $timeformat =~ $valid ]]; then err "Config_file: timestamp format switch is invalid"; fi 
    fi
    valid=$REt2
    if [ ! -z ${xmax+x} ]
    then
        if [[ ! $xmax =~ $valid && $xmax != "max" && $xmax != "auto" ]]
        then 
            err "Config_file: Xmax format switch is invalid"
        else
            if [[ "$xmax" == "min" ]]
            then
                temp=$(cat $FILE | sed -n '$p' | sed 's/T/ /g')
                if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
                then
                    # this type is with date and hour
                    temp2=$(echo $temp | awk '{print $1}' | tr -d [ )
                    temp3=$(echo $temp | awk '{print $2}' | tr -d ] )
                    xmax="[$temp2 $temp3]"
                else
                    # this type is only with date
                    xmax="$(echo $temp | tr -d [] | awk '{print $1}')"
                    ####echo $Xmin
                fi
            elif [[ "$xmax" == "auto" ]]
            then
                xmax=""
            else
                xmax=$xmax
            fi
        fi
    fi
    if [ ! -z ${xmin+x} ]
    then
        if [[ ! $xmin =~ $valid && $xmin != "min" && $xmin != "auto" ]]
            then err "Config_file: Xmin format switch is invalid"
        else
            if [[ "$xmin" == "min" ]]
            then
                temp=$(cat $FILE | sed -n '1p' | sed 's/T/ /g')
                if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
                then
                    # this type is with date and hour
                    temp2=$(echo $temp | awk '{print $1}' | tr -d [ )
                    temp3=$(echo $temp | awk '{print $2}' | tr -d ] )
                    xmin="[$temp2 $temp3]"
                else
                    # this type is only with date
                    xmin="$(echo $temp | tr -d [] | awk '{print $1}')"
                    ####echo $Xmin
                fi
            elif [[ "$xmin" == "auto" ]]
            then
                xmin=""
            else
                xmin=$xmin
            fi    
        fi
    fi
    valid='^([-]|)([0-9]+|[0-9]*\.[0-9]+)$'
    if [ ! -z ${ymax+x} ]
    then
        if [[ ! $ymax =~ $valid && $ymax != "max" && $ymax != "auto" ]]
        then 
            err "Config_file: Ymax format switch is invalid"
        else
            if [[ "$ymax" == "max" ]]
            then
                ymax=$(cat $FILE | sed -n '$p' | awk '{print $NF}')
            elif [[ "$ymax" == "auto" ]]
            then
                ymax=""
            else
                ymax=$ymax
            fi
        fi 
    fi
    if [ ! -z ${ymin+x} ]
    then
        if [[ ! $ymin =~ $valid && $ymin != "min" && $ymin != "auto" ]]
        then 
            err "Config_file: Ymin format switch is invalid"
        else
            if [[ "$ymin" == "min" ]]
            then
                ymin=$(cat $FILE | sed -n '1p' | awk '{print $NF}')
            elif [[ "$ymin" == "auto" ]]
            then
                ymin=""
            else
                ymin=$ymin
            fi
        fi
    fi
    if [ ! -z ${speed+x} ]
    then
        valid='^([0-9]+)$'
        if [[ ! $speed =~ $valid ]]; then err "Config_file: Speed format switch is invalid"; fi 
    fi
    if [ ! -z ${time+x} ]
    then
        valid='^([0-9]+)$'
        if [[ ! $time =~ $valid ]]; then err "Config_file: Time format switch is invalid"; fi 
    fi
    if [ ! -z ${fps+x} ]
    then
        valid='^([0-9]+)$'
        if [[ ! $fps =~ $valid ]]; then err "Config_file: FPS format switch is invalid"; fi 
    fi
}

# function for the configuration file, reads every line ignoring the commented
# ones, blank lines and assigns the variables with their respectives values
# using the tool source
function config_file {
    LINES=$(cat $1 | sed 's/^[ \t]*//;s/[ \t]*$//' | grep "^[^#]" | \
    cut -d"#" -f1 | grep -v '^$')
    r="effectparams\|timeformat\|xmax\|xmin\|ymax\|ymin\|speed\|time\|fps\|legend\|gnuplotparams\|effectparams\|name"
    printf '%s\n' "$LINES" | while IFS= read -r line
    do
        echo "$line" | awk '{$1=tolower($1);printf "%s=\"", $1;}' | \
        grep $r | tr -d '\n' >> temp
        echo "$line" | cut -d' ' -f2- | sed -e 's/^[ \t]*//' | \
        sed 's/[ \t]*$//;s/$/"/' >> temp
    done
    #
    awk '/^effectparams=|^timeformat=|^xmax=|^xmin=|^ymax=|^ymin=|^speed=|^time=|^fps=|^legend=|^gnuplotparams=|^effectparams=|^name=/' temp > temp2 && mv temp2 temp
    temp="temp"
    [ -n "$temp" ] || err "Config file is not valid"
    [ -f "$temp" ] || err "Config file is not valid"
    [ -r "$temp" ] || err "Config file is not valid"
    [ -s "$temp" ] || err "Config file is not valid"

    while IFS= read -r line
    do
        echo $line >> tempY
        source tempY
        if [ -z ${gnuplotparams+x} ]
        then
            :
        else
            gtemp+=("$gnuplotparams");
        fi
        if [ -z ${effectparams+x} ]
        then
            :
        else
            etemp+=("$effectparams")
        fi
        rm tempY
    done < temp
    gnuplotparams=$gtemp
    effectparams=$etemp
    
    # rm temp
    # validate options of config file
    validate_config_file

    DIR=$name
    tDIR=$name
    name $DIR
}
#RE='^(\[|)([0-9]{2}|[0-9]{4})([^0-9][0-9]{2}|)([^0-9][0-9]{2}|)(T| |)([0-9]{2}|)([^0-9][0-9]{2}|)([^0-9][0-9]{2}|)(\]|) ([-]|)([0-9]+|[0-9]*\.[0-9]+)[[:space:]]*$'

function val_timestamp {
    # echo "timestamp data "$XXmin
    r=$(echo $timeformat | sed -r 's/\[/(\\\[)/g' | sed -r 's/\]/(\\\])/g' | \
    sed -r 's/[ymdHMS]/[0-9]{2}/g' | \
    sed -r 's/Y/[0-9]{4}/g' | sed -r 's/%//g')
    r="^$r$"
    # echo "time "$timeformat
    # echo "given "$r 
    # echo "file "$XXmin 
    if [[ ! $XXmin =~ $r ]] 
    then 
        err "timestamp of data does not match with the TimeFormat given"
    fi 
}

function process_files {
    ########################### data file processing
    # first line of each file is processed, first line is the minimum timestamp
    # of each file
    temp=$(cat $FILE | sed -n '1p' | sed 's/T/ /g')
    if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
    then
        # this type is with date and hour
        temp2=$(echo $temp | awk '{print $1}' | tr -d [ | sed 's/[^0-9]/-/g')
        temp3=$(echo $temp | awk '{print $2}' | tr -d ] | sed 's/[^0-9]/:/g')
        XXmin="$temp2 $temp3"
    else
        # this type is only with date
        XXmin="$(echo $temp | tr -d [] | awk '{print $1}')"
    fi
    # echo "minn de $FILE"
    # date -d "$XXmin" +"%s"

    # the minimum timestamp is transformed to an integer and stored in a
    # dictionary
    XXmin=$(date -d "$XXmin" +"%s")
    arr+=( ["$FILE"]=$XXmin)
#----------------------------------------------
    temp=$(cat $FILE | sed -n '$p' | sed 's/T/ /g')
    if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
    then
        # this type is with date and hour
        temp2=$(echo $temp | awk '{print $1}' | tr -d [ | sed 's/[^0-9]/-/g')
        temp3=$(echo $temp | awk '{print $2}' | tr -d ] | sed 's/[^0-9]/:/g')
        XXmax="$temp2 $temp3"
    else
        # this type is only with date
        XXmax="$(echo $temp | tr -d [] | awk '{print $1}')"
    fi
    # echo "max de $FILE"
    # date -d "$XXmax" +"%s"

    # the maximum timestamp is transformed to an integer and stored in a
    # dictionary
    XXmax=$(date -d "$XXmax" +"%s")
    arr2+=( ["$FILE"]=$XXmax)
}

function file_sorting {
    # Sorting
    # the dictionary of the minimum timestamps (converted to integers) are 
    # sorted according their values, and the keys (file names) are concatenated 
    # in one temporary file
    if [ ${#arr[@]} -gt 0 ]
    then
        for key in "${!arr[@]}"
        do
            echo ${key} ${arr[${key}]}
        done | sort -n -k2 | cut -d' ' -f1 > tempX
        readarray names < tempX
        for (( i=0; $i < ${#arr[@]}; i+=1 ))
        do
            # identify data overlapped and delete files overlapped
            keyMaxName=${names[$i]}
            keyMax=${arr2[$(echo $keyMaxName)]}
            # echo "kmax $keyMax"
            if [ ${#arr[@]} -gt $(($i+1)) ]
            then
                keyMinName="${names[$i+1]}"
                keyMin=${arr[$(echo $keyMinName)]}
                # echo "kmin $keyMin"
                if [ $keyMax -gt $keyMin ]
                then
                    rm tempX
                    err "Files $keyMaxName and $keyMinName are overlapped"
                fi
            fi
        done
        verbose "Your files are not overlapped"
        # the previous temporary file is used to get the sorted file names 
        # and now concatenate the contents of each file into the FILE
        for file in $(cat tempX)
        do
            cat $file >> FILE
            echo >> FILE
        done
    else
        cat $FILE >> FILE
    fi

    temp=$(cat $FILE | sed -n '1p' | sed 's/T/ /g')
    # echo "first line of file "$temp
    if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
    then
        # this type is with date and hour
        temp2=$(echo $temp | awk '{print $1}' | tr -d [ )
        temp3=$(echo $temp | awk '{print $2}' | tr -d ] )
        XXmin="[$temp2 $temp3]"
    else
        # this type is only with date
        XXmin="$(echo $temp | awk '{print $1}')"
    fi

    rm tempX
    FILE="FILE"
}

function validate_options {
    # validate options
    # The following validations are for assign the value to the options in case 
    # no directive was given
    if [ -z ${c_file+x} ]
    then
        :
    else
        if [ "$fc_file" -gt 1 ]
        then
            err "-f option is repeated in the switches."
        fi
        # sleep 5
        [ -n "$c_file" ] || err "Argument has empty value"
        [ -f "$c_file" ] || err "Argument '$c_file' is not a file"
        [ -r "$c_file" ] || err "File '$c_file' is not readable"
        [ -s "$c_file" ] || err "File '$c_file' is empty"
        config_file $c_file
    fi

    if [ -z ${TimeFormato+x} ]
    then
        if [ -z ${timeformat+x} ]
        then
            # validate that the timeformat corresponds to the default
            egrep -vq "$REt" "$FILE" && err "File '$FILE' does not contain default timestamp"
            timeformat="[%Y-%m-%d %H:%M:%S]"
        fi
    else
        if [ "$ftimef" -gt 1 ]
        then
            err "-t option is repeated in the switches."
        fi
        timeformat=$TimeFormato
    fi

    if [ -z ${DIRo+x} ]
    then
        if [ -z ${DIR+x} ]
        then
            DIR="final"
            name $DIR
        fi
    else
        if [ "$fname" -gt 1 ]
        then
            err "-n option is repeated in the switches."
        fi
        DIR=$DIRo
        if [ -d "$tDIR" ]; then rm -rf "$tDIR"; fi; name $DIR;
    fi

    if [ -z ${effectparams+x} ]
    then
        effectparams="lc rgb \"\#FFD700\"" 
    fi

    # validation of FPS, Speed and Time directives. The program will always
    # receive two of them, with that the others are obtained
    if [[ -z ${fps+x} && -z ${speed+x} ]]; then
        fps=25
    fi
    if [[ -z ${fps+x} && -z ${time+x} ]]; then
        fps=25
    fi
    if [[ -z ${time+x} && -z ${speed+x} ]]; then
        speed=1
    fi    
    if [ -z ${FPSo+x} ]
    then
        if [ -z ${fps+x} ]
        then
            fps=$(bc <<< "scale=6; ($LINES/$speed)")
            fps=$(bc <<< "scale=6; ($fps/$time)")
        fi
    else
        if [ "$ffps" -gt 1 ]
        then
            err "-F option is repeated in the switches."
        fi
        fps=$FPSo
    fi
    if [ -z ${Speedo+x} ]
    then
        if [ -z ${speed+x} ]
        then
            speed=$(bc <<< "scale=6; ($fps*$time)")
            speed=$(bc <<< "scale=6; ($LINES/$speed)")
        fi
    else
        if [ "$fspeed" -gt 1 ]
        then
            err "-S option is repeated in the switches."
        fi
        speed=$Speedo
    fi
    if [ -z ${Timeo+x} ]
    then
        if [ -z ${time+x} ]
        then
            :
        fi
    else
        if [ "$ftime" -gt 1 ]
        then
            err "-T option is repeated in the switches."
        fi
        time=$Timeo 
    fi    
    speed=$(bc <<< "scale=4; (1/$speed)")

    # The following validations are for assign the value to the options in 
    # case x's, y's directives were not given
    if [ -z ${Xmino+x} ]
    then
        if [ -z ${xmin+x} ]
        then
            temp=$(cat $FILE | sed -n '1p' | sed 's/T/ /g')
            if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
            then
                # this type is with date and hour
                temp2=$(echo $temp | awk '{print $1}' | tr -d [ )
                temp3=$(echo $temp | awk '{print $2}' | tr -d ] )
                xmin="[$temp2 $temp3]"
            else
                # this type is only with date
                xmin="$(echo $temp | tr -d [] | awk '{print $1}')"
                ####echo $Xmin
            fi
            # sleep 1
        fi
    else
        if [ "$fxmin" -gt 1 ]
        then
            err "-x option is repeated in the switches."
        fi
        if [[ "$Xmino" == "min" ]]
        then
            temp=$(cat $FILE | sed -n '1p' | sed 's/T/ /g')
            if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
            then
                # this type is with date and hour
                temp2=$(echo $temp | awk '{print $1}' | tr -d [ )
                temp3=$(echo $temp | awk '{print $2}' | tr -d ] )
                xmin="[$temp2 $temp3]"
            else
                # this type is only with date
                xmin="$(echo $temp | tr -d [] | awk '{print $1}')"
                ####echo $Xmin
            fi
        elif [[ "$Xmino" == "auto" ]]
        then
            xmin=""
        else
            xmin=$Xmino
        fi    
    fi

    if [ -z ${Xmaxo+x} ]
    then
        if [ -z ${xmax+x} ]
        then
            temp=$(cat $FILE | sed -n '$p' | sed 's/T/ /g')
            if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
            then
                # this type is with date and hour
                temp2=$(echo $temp | awk '{print $1}' | tr -d [ )
                temp3=$(echo $temp | awk '{print $2}' | tr -d ] )
                xmax="[$temp2 $temp3]"
            else
                # this type is only with date
                xmax="$(echo $temp | tr -d [] | awk '{print $1}')"
                ####echo $Xmax
            fi
            # sleep 1
        fi
    else
        if [ "$fxmax" -gt 1 ]
        then
            err "-X option is repeated in the switches."
        fi
        if [[ "$Xmaxo" == "max" ]]
        then
            temp=$(cat $FILE | sed -n '$p' | sed 's/T/ /g')
            if [ $(echo "$temp" | awk '{print $2}') != $(echo "$temp" | awk '{print $NF}') ]
            then
                # this type is with date and hour
                temp2=$(echo $temp | awk '{print $1}' | tr -d [ )
                temp3=$(echo $temp | awk '{print $2}' | tr -d ] )
                xmax="[$temp2 $temp3]"
            else
                # this type is only with date
                xmax="$(echo $temp | tr -d [] | awk '{print $1}')"
                ####echo $Xmin
            fi
        elif [[ "$Xmaxo" == "auto" ]]
        then
            xmax=""
        else
            xmax=$Xmaxo
        fi    
    fi

    if [ -z ${Ymino+x} ]
    then
        if [ -z ${ymin+x} ]
        then 
            ymin=""
        fi
    else
        if [ "$fymin" -gt 1 ]
        then
            err "-y option is repeated in the switches."
        fi
        if [[ "$Ymino" == "min" ]]
        then
            ymin=$(cat $FILE | sed -n '1p' | awk '{print $NF}')
        elif [[ "$Ymino" == "auto" ]]
        then
            ymin=""
        else
            ymin=$Ymino
        fi    
    fi

    if [ -z ${Ymaxo+x} ]
    then
        if [ -z ${ymax+x} ]
        then 
            ymax=""
        fi
    else
        if [ "$fymax" -gt 1 ]
        then
            err "-y option is repeated in the switches."
        fi
        if [[ "$Ymaxo" == "max" ]]
        then
            ymax=$(cat $FILE | sed -n '$p' | awk '{print $NF}')
        elif [[ "$Ymaxo" == "auto" ]]
        then
            ymax=""
        else
            ymax=$Ymaxo
        fi
    fi

    if [ -z ${Legendo+x} ]
    then
        if [ -z ${legend+x} ]
        then 
            legend=""
        fi
    else
        if [ "$flegend" -gt 1 ]
        then
            err "-l option is repeated in the switches."
        fi
        legend=$Legendo
    fi

    # validation of the data timestamp with the value of timestamp 
    val_timestamp
}

function mult_options {
    # These loops are for the options that allow multiple ocurrences. 
    # All the values are concatenated in one variable
    if [ ! -z "$gnuplotparams" ]
    then
        for val in "${gnuplotparams[@]}"
        do
            gnuparams+=$(echo "set $val")
            gnuparams+=$'\n'
            ####echo " $val"
        done
        ####echo $gnuparams
    fi
    
    if [ ! -z "$effectparams" ]
    then
        for val in "${effectparams[@]}"
        do
            effparams+=$(echo $val | sed 's/:/ /g' | sed 's/=/ /g')
            effparams+=" "   
        done
    fi
}

function create_animation {
# processing for the creation of the images (frames)
LINES=$(wc -l <"$FILE")
D=${#LINES}
columns=$(awk '{print NF}' "$FILE" | tail -n 1) 
DIRs+=("$DIR")
PNG="$DIR/%0${D}d.png"
####echo "esto es PNG $PNG"
verbose "Folder -> $DIR"

verbose "X range $xmin, $xmax"
verbose "Y range $ymin, $ymax"

# frames of animation
# Important part!!!!
# Here takes place the effect of the script plotting each frame with the
# help of gnuplot, it can also receive different options
# effect: Plot dissolves progressively and data is plotted according to a
# given function

[[ ! $xmax = "" ]] && xmax=\"$xmax\"
[[ ! $xmin = "" ]] && xmin=\"$xmin\"

for ((i=1;i<=LINES;i++))
do
{
    cat <<-GPLOT
    set terminal png
    set xdata time
    set timefmt "$timeformat"
    set output "$(printf "$PNG" $i)"
    set key outside top center title "$legend"
    ${gnuparams}
    plot [$xmin:$xmax][$ymin:$ymax] '-' using 1:( sqrt(\$${columns}) ) smooth bezier $effparams t ''
GPLOT
    head -n $i "$FILE"
} | gnuplot 2>&1 | grep -v 'Warning:'
done
    #set format x"%H:%M"
#plot ["$xmin":"$xmax"][$ymin:$ymax] '-' using 1:$columns smooth bezier lc rgb "#FFD700" t ''
#plot ["$xmin":"$xmax"][$ymin:$ymax] '-' using 1:$columns with linespoints lc rgb "#FFD700" t ''
#plot ["$xmin":"$xmax"][$ymin:$ymax] '-' using 1:( sqrt(\$${columns}) ) with linespoints lc rgb "#FFD700" t ''
####vverbose "$i"

[ -d "animations" ] || mkdir "animations"

# join frames into video file
# ffmpeg is used here, it can also receive different directives
IFS=$oIFS
((VERBOSE>1)) || LOG_LEVEL='-loglevel quiet'
ffmpeg $LOG_LEVEL -y -r $fps -i "$PNG" -vf "setpts=$speed*PTS,curves=vintage" "animations/$DIR".mp4
#ffmpeg $LOG_LEVEL -y -r $FPS -i "$PNG" -filter:v "setpts=$speed*PTS" "animations/$FILE".mp4
#ffmpeg $LOG_LEVEL -y -r 15 -i "$PNG" -filter:v "setpts=0.1*PTS" "animations/$FILE".mp4
temp1="animations/$DIR.mp4"
if [ ! -f "$temp1" ]
then
    rm -rf $DIR
    err "The animation was not created, verify the arguments for gnuplot"
fi
verbose "Animation succesfully created. Output file: $DIR.mp4"

ECODE=0
}

USAGE="Usage:  $0 [OPTION]... [FILE]... 
        $0 [-h]
        -v  verbose
        -h  this help
        -t timeformat, timestamp format 
        -X xmax, x-max
        -x xmin, x-min
        -Y ymax, y-max
        -y ymin, y-min
        -S speed, Speed
        -T time, time (duration)
        -F fps, fps
        -l legend, legend
        -g gnuplotparams, gnuplot params*
        -e effectparams, effect params*
        -f , config file
        -n name, name
        
        effectparams, \"lc rgb:[color]\"
"
# RE for matching valid timestamps and valid data
# [^0-9] is to assure that the pattern separates the numbers with other char 
# but number [^0-9] means match any character except numbers
RE='^(\[|)([0-9]{2}|[0-9]{4})([^0-9][0-9]{2}|)([^0-9][0-9]{2}|)(T| |)([0-9]{2}|)([^0-9][0-9]{2}|)([^0-9][0-9]{2}|)(\]|) ([-]|)([0-9]+|[0-9]*\.[0-9]+)[[:space:]]*$'
REt='^(\[)([0-9]{4})([-])([0-9]{2})([-])([0-9]{2})( )([0-9]{2})([:])([0-9]{2})([:])([0-9]{2})(\]) ([-]|)([0-9]+|[0-9]*\.[0-9]+)[[:space:]]*$'
REt2='^(\[|)([0-9]{2}|[0-9]{4})([^0-9][0-9]{2}|)([^0-9][0-9]{2}|)(T| |)([0-9]{2}|)([^0-9][0-9]{2}|)([^0-9][0-9]{2}|)(\]|)$'

# parse options
while getopts hvt:n:f:t:x:X:y:Y:l:g:e:S:T:F: opt
do
    case $opt in
        v) ((VERBOSE++));;
        t) TimeFormato=$OPTARG
            # validate if begins with no bracket but has an space is wrong
            valid='^(\[|)(%y|%Y)([^%0-9]%m|)([^%0-9]%d|)(T| |)([^%0-9]%H|)([^%0-9]%M|)([^%0-9]%S|)(\]|)$'
            if [[ ! $OPTARG =~ $valid ]]; then err "timestamp format switch is invalid"; fi 
            ftimef=$(($ftimef+1))
            ;;
        X) Xmaxo=$OPTARG
            valid=$REt2
            if [[ ! $OPTARG =~ $valid && $OPTARG != "max" && $OPTARG != "auto" ]]
            then err "Xmax format switch is invalid"; fi 
            fxmax=$(($fxmax+1))
            ;;
        x) Xmino=$OPTARG
            valid=$REt2
            if [[ ! $OPTARG =~ $valid && $OPTARG != "min" && $OPTARG != "auto" ]]
            then err "Xmin format switch is invalid"; fi 
            fxmin=$(($fxmin+1))
            ;;
        Y) Ymaxo=$OPTARG
            valid='^([-]|)([0-9]+|[0-9]*\.[0-9]+)$'
            if [[ ! $OPTARG =~ $valid && $OPTARG != "max" && $OPTARG != "auto" ]]
            then err "Ymax format switch is invalid"; fi 
            fymax=$(($fymax+1))
            ;;
        y) Ymino=$OPTARG
            valid='^([-]|)([0-9]+|[0-9]*\.[0-9]+)$'
            if [[ ! $OPTARG =~ $valid && $OPTARG != "min" && $OPTARG != "auto" ]]
            then err "Ymin format switch is invalid"; fi 
            fymin=$(($fymin+1))
            ;;
        S) Speedo=$OPTARG
            valid='^([0-9]+|[0-9]*\.[0-9]+)$'
            if [[ ! $OPTARG =~ $valid ]]; then err "Speed format switch is invalid"; fi 
            fspeed=$(($fspeed+1))
            ;;
        T) Timeo=$OPTARG
            valid='^([0-9]+|[0-9]*\.[0-9]+)$'
            if [[ ! $OPTARG =~ $valid ]]; then err "Time format switch is invalid"; fi 
            ftime=$(($ftime+1))
            ;;
        F) FPSo=$OPTARG
            valid='^([0-9]+|[0-9]*\.[0-9]+)$'
            if [[ ! $OPTARG =~ $valid ]]; then err "FPS format switch is invalid"; fi 
            ffps=$(($ffps+1))
            ;;
        l) Legendo=$OPTARG
            flegend=$(($flegend+1))
            ;;
        g) gnuplotparams+=("$OPTARG")
            fgnu=$(($fgnu+1))
            ;;
        e) effectparams+=("$OPTARG")
            feffe=$(($feffe+1))
            ;;
        f) c_file=$OPTARG
            fc_file=$(($fc_file+1))
            ;;
        n) DIRo=$OPTARG
            fname=$(($fname+1))
            ;;
        h) echo "$USAGE"; ECODE=0; exit;;
        \?) err $USAGE; exit;;
        : ) echo "Option -"$OPTARG" requires an argument." 1>&2
            exit 1;;
    esac
done
shift $((OPTIND-1))

# test args (one file or more)
[ $# -ge 1 ] || err "Argument(s) missing" $USAGE

for FILE
do
    # verbose "Processing file: '$FILE'"
    # test FILE
    [ -n "$FILE" ] || err "Argument has empty value"
    [ -f "$FILE" ] || err "Argument '$FILE' is not a file"
    [ -r "$FILE" ] || err "File '$FILE' is not readable"
    [ -s "$FILE" ] || err "File '$FILE' is empty"
    egrep -vq "$RE" "$FILE" && err "File '$FILE' contains invalid lines"
    verbose "The ($FILE) file has valid data"

    # data file processing
    process_files $FILE
done

# functions
file_sorting
LINES=$(wc -l <"$FILE")
validate_options
mult_options

# animation function
create_animation

verbose "End of the script"

trap 'verbose "Removing final file"; [[ -f FILE ]] && rm -f FILE; [[ -f temp ]] && rm temp; exit $ECODE' EXIT
