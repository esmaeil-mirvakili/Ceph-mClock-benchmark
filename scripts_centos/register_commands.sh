if [ -z "$1" ]; then
  HOME_LOC="${HOME}"
else
  HOME_LOC=$1
fi

cd "$HOME_LOC/ceph/build/bin"
for f in *; do
  sudo rm -rf "/usr/local/bin/$f"
  sudo cp -r "$f" "/usr/local/bin"
done
cd "$HOME_LOC/fio"
sudo rm -rf "/usr/local/bin/fio"
sudo cp "fio" "/usr/local/bin"
