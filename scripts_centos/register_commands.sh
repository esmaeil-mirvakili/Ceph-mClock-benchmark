cd ~/ceph/build/bin
for f in *; do
  sudo rm -rf "/usr/local/bin/$f"
  sudo cp -r "$f" "/usr/local/bin"
done
cd ~/fio
sudo rm -rf "/usr/local/bin/fio"
sudo cp "fio" "/usr/local/bin"
