# Dragonfly registry mirror

Workflow menyalin image resmi `docker.dragonflydb.io/dragonflydb/dragonfly`
ke `registry.pauddasmen.id/dragonfly`. Hanya versi stabil terbaru dari setiap
major dan tag `latest` yang disinkronkan, termasuk seluruh arsitektur.
Contoh: jika major 1 terbaru adalah `v1.40.2` dan major 2 terbaru adalah
`v2.0.2`, hanya kedua tag versi tersebut yang disalin, beserta `latest`.
Tag versi lengkap (`vX.Y.Z` atau `X.Y.Z`) dan digest tetap sama dengan upstream.
Pemilihan versi menggunakan perbandingan angka major, minor, dan patch.
Tag prerelease dan varian seperti `ubuntu-*` tidak disalin.

Pemeriksaan berjalan setiap hari pukul **09:17 WIB**, saat perubahan workflow,
script, atau Dockerfile di-push ke `main`, dan melalui tombol **Run workflow**
di GitHub Actions. Jadwal GitHub dapat terlambat dan hanya berjalan dari default
branch. Setiap pemeriksaan memilih ulang versi terbaru per major, lalu hanya
menyalin tag yang belum ada atau digest-nya berubah. Tag lama yang sudah ada
di registry tujuan tidak dihapus.

Siapkan repository/organization Actions secrets dengan nama yang sama seperti
project lain, dan pastikan repository ini diberi akses jika menggunakan
organization secrets:

| Secret | Nilai |
| --- | --- |
| `PAUDDASMEN_HUB_REGISTRY` | `registry.pauddasmen.id` |
| `PAUDDASMEN_HUB_USERNAME` | Username dengan izin pull/push repository `dragonfly` |
| `PAUDDASMEN_HUB_PASSWORD` | Password/token registry |

Penggunaan:

```sh
docker pull registry.pauddasmen.id/dragonfly:latest
# Ganti vX.Y.Z dengan tag versi upstream yang ingin digunakan.
docker pull registry.pauddasmen.id/dragonfly:vX.Y.Z
```

Workflow menggunakan `crane copy` agar manifest dan digest tetap sama dengan
upstream. Dockerfile juga tersedia untuk build lokal versi tertentu:

```sh
docker build --build-arg DRAGONFLY_VERSION=vX.Y.Z -t dragonfly:vX.Y.Z .
```

Dockerfile tidak dipakai dalam workflow mirror; perubahan tambahan pada
Dockerfile tidak ikut disalin ke registry.
