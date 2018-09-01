PWD=$(pwd)

mkdir ${PWD}/reports

docker run \
	--rm \
	-it \
	--device /dev/video0:/dev/video0 \
        --mount type=tmpfs,destination=/mnt/imgtmp \
	-v ${PWD}/reports:/reports \
	ramode /bin/bash /app/ramode.sh 
