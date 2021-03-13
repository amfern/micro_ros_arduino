# docker builder build --tag microros/micro_ros_arduino_compiler .
FROM ubuntu:20.04

RUN apt update && \
    apt install -y git curl lib32z1 wget libfontconfig libxft2 xz-utils rsync

RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
ENV PATH=${PATH}:/root//bin

RUN arduino-cli core install OpenCR:OpenCR -v --additional-urls https://raw.githubusercontent.com/ROBOTIS-GIT/OpenCR/master/arduino/opencr_release/package_opencr_index.json
RUN arduino-cli core install arduino:samd -v
RUN arduino-cli core install arduino:sam -v
RUN arduino-cli core install arduino:mbed -v

# 
# INSTALLING TEENSY SUPPORT
RUN wget https://downloads.arduino.cc/arduino-1.8.13-linux64.tar.xz
RUN tar -xf arduino-1.8.13-linux64.tar.xz
RUN wget https://www.pjrc.com/teensy/td_153/TeensyduinoInstall.linux64
RUN chmod 755 TeensyduinoInstall.linux64
RUN ./TeensyduinoInstall.linux64 --dir=arduino-1.8.13


# teensy_loader_cli
RUN apt install -y build-essential libusb-dev
RUN git clone https://github.com/PaulStoffregen/teensy_loader_cli.git
RUN make -C ./teensy_loader_cli && cp ./teensy_loader_cli/teensy_loader_cli /usr/bin/teensy_loader_cli


# Faking Teensy loader
RUN rm -rf arduino-1.8.13/hardware/tools/teensy_post_compile
RUN cp /usr/bin/true arduino-1.8.13/hardware/tools/teensy_post_compile
RUN cp -R arduino-1.8.13/hardware/teensy/ /root/.arduino15/packages/
RUN rsync -a  arduino-1.8.13/hardware/tools/ /root/.arduino15/packages/tools/
RUN rm -rf arduino-1.8.13 arduino-1.8.13-linux64.tar.xz

# 
# PATCHING TEENSY AND SAM
ADD extras/patching_boards/platform_teensy.txt /root/.arduino15/packages/teensy/avr/platform.txt
ADD extras/patching_boards/platform_arduinocore_sam.txt /root/.arduino15/packages/arduino/hardware/sam/1.6.12/platform.txt

RUN arduino-cli core update-index
RUN arduino-cli lib update-index

RUN mkdir -p /root/Arduino/libraries/micro_ros_arduino-0.0.1

# docker run -it --rm \
#     --name=arduino-teensy \
#     --privileged \
#     --volume /dev:/dev \
#     --network host \
#     --workdir="/root/Arduino/libraries/micro_ros_arduino-0.0.1" \
#     --volume=$(pwd):"/root/Arduino/libraries/micro_ros_arduino-0.0.1":rw \
#     microros/micro_ros_arduino_compiler


# arduino-cli compile --fqbn teensy:avr:teensy31 /root/Arduino/libraries/micro_ros_arduino-0.0.1/examples/micro-ros_reconnection_example/ --output-dir /root/Arduino/libraries/micro_ros_arduino-0.0.1/examples/micro-ros_reconnection_example -v
# teensy_loader_cli --mcu=mk20dx256 -w /root/Arduino/libraries/micro_ros_arduino-0.0.1/examples/micro-ros_reconnection_example/micro-ros_reconnection_example.ino.hex -v
