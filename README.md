# ramode
Simple RAspberry MOtion DEtection made in bash scripts.

## What is it?
I love bash scripts and some times I'm doing scripts for fun like that. It's start for fun and now it's my home allarm system

Ramode is a shell script tha check the webcam and discover a motion on the room. If somthing change just save a photo, and 2 frame animated gif usefull to understand the difference found.

Ramode work with only 2 tools:
* fswebcam 
* converter ( it's from ImageMagic )

## Setup
Ramode can be run directly on the bash or can be run on Docker. I prefer Docker because i leave the Raspberry system totaly clean and I can perform all the change without break out other dependencies.

### Whith Docker
Please check the run.sh file. It contains my setup, you can update it with your path. The main config are:
* `device_dir` where is the webcam
* `reports_dir` where you want to save the immages/gif

thats the full command : 
``` 
docker run \
        --rm \
        -it \
        --device /dev/video0:/dev/video0 \
        --mount type=tmpfs,destination=/mnt/imgtmp \
        -v /reports_dir/reports:/reports \
        ramode /bin/bash /app/ramode.sh
```
### Classic mode
Install the dependecy:
* fswebcam
* ImageMagic

Enter on the directory `app/cfg/ramode.cfg` and setup the directory of reports and the temporaly directory used for the process of image.

Run the command `app/ramode.sh` 

# Enjoy 
