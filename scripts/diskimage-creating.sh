!/bin/bash
while true; do
  case "$1" in
    -elements)
      elements=$2
      shift 2
      ;;
    -hadoop-version)
      export DIB_HADOOP_VERSION=$2
      shift 2
      ;;
    -java-url)
      export JAVA_DOWNLOAD_URL=$2
      shift 2
      ;;
    -ubuntu-image-name)
      ubuntu_image_name=$2
      shift 2
      ;;
    -fedora-image-name)
      fedora_image_name=$2
      shift 2
      ;;
    -image-size)
      export DIB_IMAGE_SIZE=$2
      break
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
  esac
done

if [ -z "$JAVA_DOWNLOAD_URL" ]; then
      echo "Java download url is not set"
      exit 1
fi
if [ -z "$DIB_HADOOP_VERSION" ]; then
   echo "Hadoop version is not set"
   exit 1
fi
if [ -z "$ubuntu_image_name" ]; then
   echo "Ubuntu image name is not set"
   exit 1
fi
if [ -z "$fedora_image_name" ]; then
   echo "Fedora image name is not set"
   exit 1
fi
if [ -z "$DIB_IMAGE_SIZE" ]; then
   echo "Image size is not set"
   exit 1
fi

echo -e "\n" | sudo apt-get update
echo -e "\n" | sudo apt-get install qemu
echo -e "\n" | sudo apt-get install kpartx
echo -e "\n" | sudo apt-get install git

if [ ! -d "DIB_work" ]; then
   mkdir DIB_work
fi
cd DIB_work
if [ -d "diskimage-builder" ]; then
   rm -r diskimage-builder
fi
git clone https://github.com/stackforge/diskimage-builder

export PATH=$PATH:/home/$USER/DIB_work/diskimage-builder/bin
export ELEMENTS_PATH=/home/$USER/DIB_work/diskimage-builder/elements

if [ -d "savanna-extra" ]; then
   rm -r savanna-extra
fi
git clone https://github.com/stackforge/savanna-extra

sudo cp /home/$USER/DIB_work/diskimage-builder/sudoers.d/img-build-sudoers /etc/sudoers.d/
sudo chown root:root /etc/sudoers.d/img-build-sudoers
sudo chmod 0440 /etc/sudoers.d/img-build-sudoers
cp -r /home/$USER/DIB_work/savanna-extra/elements/* /home/$USER/DIB_work/diskimage-builder/elements/

disk-image-create base vm fedora hadoop $elements -o $fedora_image_name
disk-image-create base vm hadoop ubuntu $elements -o $ubuntu_image_name

mv $fedora_image_name.qcow2 ../
mv $ubuntu_image_name.qcow2 ../
