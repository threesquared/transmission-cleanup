# transmission-cleanup

Scripts to automate cleaning up old [Couchpotato](https://couchpota.to/) and [Sickrage](https://sickrage.github.io/) [Transmission](https://transmissionbt.com/) torrent downloads and hard links.

## Usage

Edit the supplied scripts and modify the values at the top.

### ./couchpotato-cleanup.sh

This script looks in `COUCHPOTATO_DOWNLOAD_DIR` for `.renamed_already.ignore` files and then 
tries to find a hard linked mkv in the supplied `COUCHPOTATO_DESTINATION_FOLDER`. If one is found it then
tries to find an active torrent in Transmission and checks the seeding time. If the torrent has been seeding
for longer than `MIN_SEED_TIME` it removes and deletes the torrent.

### ./sickrage-cleanup.sh

Simmilarly this script checks all files in `SICKRAGE_DOWNLOAD_DIR` and if there is a hard link to
`SICKRAGE_DOWNLOAD_DIR` it will try and find a torrent in Transmission and remove it if it has been seeding
for longer than `MIN_SEED_TIME`.
