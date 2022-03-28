cd ~/ceph/build/bin
for f in *; do
  rm -rf "/usr/local/bin/$f"
  cp -r "$f" "/usr/local/bin"
done
cd ~/fio
rm -rf "/usr/local/bin/fio"
cp "fio" "/usr/local/bin"
