cd ~/ceph/build/bin
for f in *; do
  rm -rf "/usr/local/bin/$f"
  ln -s "$f" "/usr/local/bin"
done
cd ~/fio
rm -rf "/usr/local/bin/fio"
ln -s "fio" "/usr/local/bin"
