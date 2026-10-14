# The test root of the full cycle and the phone checklist
# (docs/stage2_android.md, 5.25): /storage/emulated/0/FileOrganizerTest,
# which a test build takes for the storage. Source it after setting ADB
# (array), ROOT and NOTES and defining say(); run from app/.
#   make_test_root   "a phone with duplicate photos" (camera photos with
#                    copies in Telegram and WhatsApp) and "a typical Download
#                    folder" (documents, an APK, a PDF, a screenshot, a video,
#                    music, an archive, unknown files, a project) plus NOTES
#                    small notes
#   snapshot         every file (path, modification time to the
#                    nanosecond, md5) and every folder of the test root, the
#                    quarantine left out. No size: md5 covers the content,
#                    and on a phone (API 33) stat through FUSE kept reporting
#                    size 0 for some files just written by the shell

#   wait_storage_writable  waits (up to 2 minutes) until adb can write
#                    files to the shared storage: right after boot (CI)
#                    it can list it but a push fails with "Operation not
#                    permitted". Probes in its own folder next to the test
#                    root and removes it.
wait_storage_writable() {
  local probe=$ROOT.probe
  for _ in $(seq 1 60); do
    if "${ADB[@]}" shell "mkdir -p '$probe'" >/dev/null 2>&1 &&
      "${ADB[@]}" push integration_test/native/fixtures/photo.jpg "$probe/p.jpg" >/dev/null 2>&1; then
      "${ADB[@]}" shell "rm -rf '$probe'"
      return 0
    fi
    sleep 2
  done
  "${ADB[@]}" shell "rm -rf '$probe'" || true
  say "the shared storage did not become writable"
  return 1
}

make_test_root() {
  say "the test root: duplicate photos, a typical Download folder, $NOTES notes"
  PHOTO=integration_test/native/fixtures/photo.jpg
  "${ADB[@]}" shell "mkdir -p '$ROOT/DCIM/Camera' '$ROOT/Telegram/Telegram Images' '$ROOT/WhatsApp/Media/WhatsApp Images' '$ROOT/Download/.cache' '$ROOT/Download/project/lib'"
  "${ADB[@]}" push "$PHOTO" "$ROOT/DCIM/Camera/IMG_20210506_070809.jpg" >/dev/null
  "${ADB[@]}" push "$PHOTO" "$ROOT/DCIM/Camera/IMG_20210507_100000.jpg" >/dev/null
  "${ADB[@]}" push "$PHOTO" "$ROOT/Download/photo.jpg" >/dev/null
  "${ADB[@]}" shell "cd '$ROOT' && \
    echo second >> DCIM/Camera/IMG_20210507_100000.jpg && \
    echo third >> Download/photo.jpg && \
    cp DCIM/Camera/IMG_20210506_070809.jpg 'Telegram/Telegram Images/photo_copy.jpg' && \
    cp DCIM/Camera/IMG_20210507_100000.jpg 'WhatsApp/Media/WhatsApp Images/IMG-20210507-WA0001.jpg' && \
    touch -d '2021-05-06 07:08:09' DCIM/Camera/*.jpg Download/photo.jpg && \
    cd Download && \
    echo 'invoice 2024: 1250.00 EUR' > invoice_2024.pdf && \
    touch -d '2024-01-15 12:00:00' invoice_2024.pdf && \
    cp invoice_2024.pdf 'invoice_2024 (1).pdf' && \
    echo report > Report.docx && echo table > table.xlsx && echo notes > notes.txt && \
    head -c 5000 /dev/urandom > song.mp3 && head -c 4000 /dev/urandom > backup.zip && \
    head -c 3000 /dev/urandom > app-release.apk && head -c 3000 /dev/urandom > setup.exe && \
    head -c 9000 /dev/urandom > holiday.mp4 && touch -d '2024-06-01 10:00:00' holiday.mp4 && \
    head -c 2000 /dev/urandom > Screenshot_20240301-120000.png && \
    touch -d '2024-03-01 12:00:00' Screenshot_20240301-120000.png && \
    echo '?' > data.xyz && echo readme > README && : > empty.txt && \
    echo cache > .cache/thumbs.db && echo 'name: p' > project/pubspec.yaml && \
    echo 'void main() {}' > project/lib/main.dart && \
    for i in \$(seq 1 $NOTES); do echo \"note \$i\" > \$(printf note_%04d.txt \$i); done"
  # A file just written through the storage's FUSE layer can report a
  # modification time one clock tick older than the one on disk until the
  # kernel drops its cached attributes (seen on API 34 with a full storage:
  # the tree "differed" after the undo without the app touching it). An
  # explicit time on every fresh file makes both agree.
  "${ADB[@]}" shell "cd '$ROOT' && find . -type f -mmin -60 -exec touch -d '2024-02-01 09:00:00' {} +"
  "${ADB[@]}" shell "content call --uri content://media/ --method scan_volume --arg external_primary" >/dev/null
}

snapshot() {
  "${ADB[@]}" shell "cd '$ROOT' && find . \( -path ./.FileOrganizer -prune \) -o -type f -exec stat -c '%n %y' {} + | sort; find . \( -path ./.FileOrganizer -prune \) -o -type f -exec md5sum {} + | sort; find . \( -path ./.FileOrganizer -prune \) -o -type d -print | sort" | tr -d '\r'
}
