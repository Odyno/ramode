#!/bin/bash

set +x

## LOAD CONFIG
fn_load_config(){
	configfile='./cfg/ramode.conf'
	configfile_secured='/tmp/ramode.cfg'

	# check if the file contains something we don't want
	if egrep -q -v '^#|^[^ ]*=[^;]*' "$configfile"; then
		echo "Config file is unclean, cleaning it..." >&2
		# filter the original to a new file
		egrep '^#|^[^ ]*=[^;&]*'  "$configfile" > "$configfile_secured"
		configfile="$configfile_secured"
	fi

	# now source it, either the original or the filtered variant
	source "$configfile"

}

fn_prepare_env(){
	echo "Prepare the SigInt "
	trap 'fn_terminate_script' SIGINT

	echo "Check directory"
	
	WORKSPACE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	tmp_img_dir=${IMG_TMP_DIR:-$WORKSPACE/img_temp}
        report_dir=${REPORT_DIR:-$WORKSPACE/report}
	tollerance=${TOLLERANCE:-100}
	capture_interval=${CAPTURE_INTERVAL:-1}
	one_iteration=${ONE_ITERATIOM:-true}
	
	if [ ! -d "$report_dir" ]; then
  		# Control will enter here if $DIRECTORY doesn't exist.
		echo "$report_dir doesn't exist."
		exit 1
	fi

	if [ ! -d "$tmp_img_dir" ]; then
		echo "$tmp_img_dir doesn't exist."
		exit 1
	fi

	ext='jpg'
	FFMPEG='ffmpeg'
	cfg_dir='./cfg'
	command -v $FFMPEG >/dev/null 2>&1 || { FFMPEG=avconv ; }

	
}

fn_terminate_script() {
	fn_cleanup
	echo "SIGINT caught."
	exit 0
}

fn_cleanup() {
  rm -rf $tmp_img_dir/*
}

fn_capture_frame(){
	if [[ "$OSTYPE" == "darwin"* ]]; then
		# Mac OSX
		$FFMPEG -loglevel fatal -f avfoundation -i "" -r 1 -t 0.0001 "$tmp_img_dir/$1.$ext"
	else
		# linux
        # $FFMPEG -loglevel fatal -f video4linux2 -i /dev/video0 -r 1 -t 0.0001 $FILENAME
		
		# raspberry pi
		source "$cfg_dir/fswebcam.conf"
 
		fswebcam -q \
			-d v4l2:/dev/video0 \
			-i 0 \
			-S 1 \
			-F 2 \
			-r 640x480 \
			--set brightness=$brightness \
			--set contrast=$contrast \
			--set saturation=$saturation \
			--set hue=$hue \
			--set gamma=$gamma \
			--set gain=$gain \
			"$tmp_img_dir/$1.$ext"
	fi

}

fn_compare_frame(){
	# $1 revius
	# $2 new file
	if [[ "$tmp_img_dir/$1.$ext" != "" ]]; then
		#echo "Comparing..."
		# For some reason, `compare` outputs the result to stderr so
		# it's not possibly to directly get the result. It needs to be
		# redirected to a temp file first.
		
		compare -fuzz 20% -metric ae $tmp_img_dir/$1.$ext $tmp_img_dir/$2.$ext "$tmp_img_dir/diff.png" 2> "$tmp_img_dir/diff.txt"
		
		DIFF="$(cat $tmp_img_dir/diff.txt)"
		
		
		if [ "$DIFF" -lt $tollerance ]; then
			fn_no_motion_detected $1 $2 $DIFF
		else
			file_a=$tmp_img_dir/$2A.$ext
			file_b=$tmp_img_dir/$2B.$ext
			cp $tmp_img_dir/$1.$ext  $file_a
			cp $tmp_img_dir/$2.$ext  $file_b
			fn_motion_detected $2 $file_a $file_b $DIFF &
		fi

		rm -f "$tmp_img_dir/diff.png"
		rm -f "$tmp_img_dir/diff.txt"

	fi	
}

fn_no_motion_detected(){
	echo "Diff = $3"
}

fn_motion_detected(){
	echo "Diff = $4 [***]"
	convert -delay 50 "$2" "$3" -loop 0 "$report_dir/$1_motion.gif"
	rm -f "$2"
	mv "$3" "$report_dir/$1.$ext"
}

fn_update_upstream(){
	cp "$tmp_img_dir/$1.$ext" "$tmp_img_dir/now.$ext"
}


fn_wait(){
	sleep "$1"
}

fn_main(){

	new_frame="$(date +"%Y%m%dT%H%M%S")"

	fn_capture_frame "$new_frame"

	fn_update_upstream "$new_frame"

	fn_compare_frame "$base_frame" "$new_frame" 
    
	rm -f "$tmp_img_dir/$base_frame.$ext"
	
	base_frame="$new_frame" 
	
	fn_wait "$capture_interval"
	
}


fn_load_config
fn_prepare_env
fn_cleanup
base_frame="$(date +"%Y%m%dT%H%M%S")"
fn_capture_frame "$base_frame"
fn_main
while [ false = $one_iteration ] ; do
   fn_main
done
