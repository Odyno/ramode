#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPORT_DIR="$SCRIPT_DIR/images"
OUTPUT_DIR="/mnt/imgtmp"

CAPTURE_INTERVAL="2" # in seconds
FFMPEG=ffmpeg
command -v $FFMPEG >/dev/null 2>&1 || { FFMPEG=avconv ; }
DIFF_RESULT_FILE=$OUTPUT_DIR/diff_results.txt

fn_cleanup() {
	rm -f $OUTPUT_DIR/diff.png $DIFF_RESULT_FILE
}

fn_terminate_script() {
	fn_cleanup
	echo "SIGINT caught."
	exit 0
}
trap 'fn_terminate_script' SIGINT

mkdir -p $OUTPUT_DIR
PREVIOUS_FILENAME=""
while true ; do
	DNAME="$(date +"%Y%m%dT%H%M%S")"
	FILENAME="$OUTPUT_DIR/$DNAME.jpg"
#	echo "-----------------------------------------"
	#echo "Capturing $FILENAME"
		
	if [[ "$OSTYPE" == "darwin"* ]]; then
		# Mac OSX
		$FFMPEG -loglevel fatal -f avfoundation -i "" -r 1 -t 0.0001 $FILENAME
	else
                # $FFMPEG -loglevel fatal -f video4linux2 -i /dev/video0 -r 1 -t 0.0001 $FILENAME
		fswebcam -q -d v4l2:/dev/video0 -r 1280x1024 $FILENAME
	fi

        cp -f $FILENAME $OUTPUT_DIR/now.jpg

	if [[ "$PREVIOUS_FILENAME" != "" ]]; then
		#echo "Comparing..."
		# For some reason, `compare` outputs the result to stderr so
		# it's not possibly to directly get the result. It needs to be
		# redirected to a temp file first.
		
		compare -fuzz 20% -metric ae $PREVIOUS_FILENAME $FILENAME $OUTPUT_DIR/diff.png 2> $DIFF_RESULT_FILE
		DIFF="$(cat $DIFF_RESULT_FILE)"
		fn_cleanup
		
		if [ "$DIFF" -lt 100 ]; then
			echo "Diff = $DIFF"
		else
			echo "Diff = $DIFF [***]"

			convert -delay 50 $PREVIOUS_FILENAME $FILENAME -loop 0 $REPORT_DIR/${DNAME}_motion.gif
			cp "$FILENAME" "$REPORT_DIR/$DNAME.jpg"
		fi
		rm -f $PREVIOUS_FILENAME
	fi	
        PREVIOUS_FILENAME="$FILENAME"
	sleep $CAPTURE_INTERVAL
done
