FROM sitkevij/ffmpeg:3.4.1-resin-rpi-raspbian 

RUN mkdir /mnt/imgtmp && mkdir /reports && mkdir /app

RUN apt-get update && apt-get install -y \
	fswebcam  \
	imagemagick \	
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app
ADD app /app

CMD ['sh','/app/ramode.sh']

ENTRYPOINT []
