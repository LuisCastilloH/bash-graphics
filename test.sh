# error() {
#   local parent_lineno="$1"
#   local message="$2"
#   local code="${3:-1}"
#   if [[ -n "$message" ]] ; then
#     echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
#   else
#     echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
#   fi
#   exit "${code}"
# }
# trap 'error ${LINENO}' ERR

# cleanup
# trap 'echo -e "Something happened with the animation. Cleaning... \n'\
# 'Removing directory ${DIRs[*]}"; rm -rf "${DIRs[@]}"; '\
# '[[ -f FILE ]] && rm -f FILE; exit $ECODE' EXIT

# trap 'vverbose "Removing temporary directories ${TMPs[*]}"; rm -rf "${TMPs[@]}"; exit $ECODE' EXIT
# trap 'vverbose "Something happened with the animation. Cleaning. Removing dir ${DIRs[*]}"; rm -rf "${DIRs[@]}"; exit $ECODE' ERR
# trap 'echo "Something happened with the animation. Cleaning."; exit 0'

echo -e "This is the 1st test\n Bad one: Argument(s) missing"
sleep 1

./final.sh

echo -e "\nThis is the 2nd test\n Bad one: File contains invalid lines"
sleep 1

 ./final.sh /etc/passwd

echo -e "\nThis is the 3rd test\n Good one"
sleep 1

./final.sh data/chunk

echo -e "\nThis is the 4th test\n Good one"
sleep 1

./final.sh -v data/chunk

echo -e "\nThis is the 5th test\n Bad one: File contains invalid lines"
sleep 1

./final.sh -v -t "[%Y/%m/%d %H:%M:%S]" -X "[2009/05/12 07:30:00]" -x "[2009/05/11 07:20:00]" -Y 2 -y -1 -S 10 -F 15 -l "first test" -n dormirPrueba /etc/passwd

echo -e "\nThis is the 6th test\n Good one"
sleep 1

./final.sh -v -t "[%Y/%m/%d %H:%M:%S]" -X "[2009/05/12 07:30:00]" -x "[2009/05/11 07:20:00]" -Y 2 -y -1 -S 10 -F 15 -l "second test" -n dormirPrueba data/sin4

echo -e "\nThis is the 7th test\n Good one"
sleep 1

 ./final.sh -f example.conf data/sin.txt

echo -e "\nThis is the 8th test\n Good one"
sleep 1

./final.sh -v -t "[%Y/%m/%d %H:%M:%S]" data/sin1 data/sin2 data/sin3 data/sin4 data/sin5 data/sin6

echo -e "\nThis is the 8th test\n Bad one: Files are overlapped"
sleep 1

./final.sh -v -t "[%Y/%m/%d %H:%M:%S]" data/sin1 data/sin2 data/sin3 data/sin4 data/sin5 data/sin6 data/sin7

echo -e "\nThis is the 9th test\n Good one"
sleep 1

./final.sh -t "[%Y-%m-%d %H:%M:%S]"  data/chunk

echo -e "\nThis is the 10th test\n Bad one: timestamp of data does not match"
sleep 1

./final.sh -t "%Y-%m-%d %H:%M:%S"  data/chunk

echo -e "\nThis is the 10th test\n Good one"
sleep 1

./final.sh -t "[%Y-%m-%d %H:%M:%S]" -x min data/chunk

echo -e "\nThis is the 10th test\n Bad one: timestamp of data does not match"
sleep 1

./final.sh -t "[%Y-%m-%d]" data/chunk

echo -e "\nThis is the 11th test\n Good one"
sleep 1

./final.sh -v -X max -x min -y -1 -Y 1 data/chunk


