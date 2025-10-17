# Penggunaan Pgbouncer Connection Pool

Proyek ini menggunakan Pgbouncer sebagai connection pool untuk PostgreSQL/Citus. Berikut adalah dokumentasi cara menambah dan mengelola connection pool.

## Konfigurasi Pgbouncer

File konfigurasi utama:
- `pgbouncer/pgbouncer.ini` - Konfigurasi utama pgbouncer
- `pgbouncer/userlist.txt` - Daftar pengguna untuk autentikasi

## Parameter Connection Pool

Parameter-parameter penting dalam `pgbouncer.ini`:

- `max_client_conn`: Jumlah maksimum koneksi dari klien (default: 100)
- `default_pool_size`: Jumlah maksimum koneksi ke database backend per pool (default: 20)
- `min_pool_size`: Jumlah minimum koneksi dalam pool (default: 5)
- `reserve_pool_size`: Jumlah koneksi cadangan (default: 5)
- `pool_mode`: Mode pooling (transaction, session, statement)

## Cara Menambah Connection Pool

### 1. Mengubah jumlah maksimum koneksi klien

Untuk meningkatkan jumlah maksimum koneksi dari aplikasi klien:

```ini
max_client_conn = 200
```

### 2. Mengubah ukuran pool backend

Untuk meningkatkan jumlah maksimum koneksi ke database backend:

```ini
default_pool_size = 50
```

### 3. Mengubah ukuran pool minimum

Untuk mengatur jumlah minimum koneksi yang selalu dipertahankan:

```ini
min_pool_size = 10
```

### 4. Menambah koneksi cadangan

Untuk menambah jumlah koneksi cadangan:

```ini
reserve_pool_size = 10
```

## Mode Pooling

Pgbouncer mendukung tiga mode pooling:

- `session`: Satu koneksi backend per sesi klien (paling aman)
- `transaction`: Satu koneksi backend per transaksi klien
- `statement`: Satu koneksi backend per pernyataan SQL (paling efisien tapi terbatas)

## Menambah Koneksi Baru

### 1. Menambah Database Connection

Untuk menambah koneksi database baru, edit file `pgbouncer/pgbouncer.ini` dan tambahkan entri di bagian [databases]:

```ini
[databases]
citus_db = coor-hc:5432:postgres:postgres:ppgpass
# Contoh koneksi database baru
new_db = coor-hc:5432:newdatabase:postgres:ppgpass
```

### 2. Menyesuaikan Parameter Pool

Anda dapat menyesuaikan parameter untuk koneksi baru:

- `max_client_conn`: Jumlah maksimum koneksi dari klien
- `default_pool_size`: Jumlah maksimum koneksi ke database backend per pool
- `min_pool_size`: Jumlah minimum koneksi dalam pool
- `reserve_pool_size`: Jumlah koneksi cadangan

Contoh penyesuaian:
```ini
[pgbouncer]
max_client_conn = 200
default_pool_size = 50
min_pool_size = 10
reserve_pool_size = 10
```

### 3. Restart Pgbouncer

Setelah mengubah konfigurasi, restart pgbouncer:

```bash
docker-compose restart pgbouncer
```

Atau gunakan perintah reload jika pgbouncer mendukung:

```bash
docker-compose exec pgbouncer pgbouncer -R
```

## Monitoring

Untuk memonitor status pgbouncer, Anda bisa terhubung ke database admin:

```bash
psql -h localhost -p 6432 -U postgres pgbouncer
```

Kemudian gunakan perintah-perintah berikut:

- `SHOW POOLS;` - Menampilkan status pool
- `SHOW CLIENTS;` - Menampilkan koneksi klien
- `SHOW SERVERS;` - Menampilkan koneksi server
- `SHOW STATS;` - Menampilkan statistik