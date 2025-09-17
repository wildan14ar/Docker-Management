1\. 🚀 Setup Qdrant (Docker Compose)
------------------------------------

**docker-compose.yaml**
```yaml
services:
  qdrant:
    image: qdrant/qdrant
    container_name: qdrant
    environment:
      - QDRANT__SERVICE__API_KEY=qdrant123
      - QDRANT__SERVICE__JWT_RBAC=true
    ports:
      - "6333:6333"   # REST API
      - "6334:6334"   # gRPC
    volumes:
      - qdrant_data:/qdrant/storage
      - ./rbac.json:/qdrant/config/rbac.json:ro
    restart: always

volumes:
  qdrant_data:
```

Jalankan:

```bash
docker compose up -d
```

* * * * *

2\. 📂 Membuat Collection
-------------------------

REST API:
```bash
curl -X PUT "http://localhost:6333/collections/my_collection"\
     -H "api-key: qdrant123"\
     -H "Content-Type: application/json"\
     -d '{
           "vectors": { "size": 4, "distance": "Cosine" }
         }'
```

Python SDK:
```python
from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance

client = QdrantClient("localhost", port=6333, api_key="qdrant123")

client.recreate_collection(
    collection_name="my_collection",
    vectors_config=VectorParams(size=4, distance=Distance.COSINE)
)
```

* * * * *

3\. ➕ Menambahkan Data (Points)
-------------------------------
```bash
curl -X PUT "http://localhost:6333/collections/my_collection/points?wait=true"\
     -H "api-key: qdrant123"\
     -H "Content-Type: application/json"\
     -d '{
           "points": [
             {"id": 1, "vector": [0.1, 0.2, 0.3, 0.4], "payload": {"category": "tech"}},
             {"id": 2, "vector": [0.2, 0.1, 0.4, 0.3], "payload": {"category": "sport"}}
           ]
         }'
```

* * * * *

4\. 🔍 Melakukan Search
-----------------------

Query vector `[0.1, 0.2, 0.3, 0.4]`:

```bash
curl -X POST "http://localhost:6333/collections/my_collection/points/search"\
     -H "api-key: qdrant123"\
     -H "Content-Type: application/json"\
     -d '{
           "vector": [0.1, 0.2, 0.3, 0.4],
           "limit": 2
         }'
```

* * * * *

5\. 🔑 RBAC (Role-Based Access Control)
---------------------------------------

### `rbac.json`
```json
{
  "roles": {
    "admin": {
      "permissions": [
        {"collection": "*", "operation": "read"},
        {"collection": "*", "operation": "write"},
        {"collection": "*", "operation": "delete"}
      ]
    },
    "reader": {
      "permissions": [
        {"collection": "*", "operation": "read"}
      ]
    }
  }
}
```

### Generate JWT (Python)
```python
import jwt, datetime

API_KEY = "qdrant123"

token_admin = jwt.encode(
    {"role": "admin", "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=12)},
    API_KEY,
    algorithm="HS256"
)

token_reader = jwt.encode(
    {"role": "reader", "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=12)},
    API_KEY,
    algorithm="HS256"
)

print("Admin Token:", token_admin)
print("Reader Token:", token_reader)
```

### Gunakan Token
```bash
curl -X GET "http://localhost:6333/collections"\
     -H "Authorization: Bearer <reader_token>"
```

👉 Kalau `reader` coba insert data, Qdrant akan **tolak**.

* * * * *

6\. 💾 Snapshot & Restore
-------------------------

### Membuat Snapshot
```bash
curl -X POST "http://localhost:6333/collections/my_collection/snapshots"\
     -H "api-key: qdrant123"
```

### Download Snapshot
```bash
curl -O "http://localhost:6333/collections/my_collection/snapshots/<snapshot_name>"
```

### Restore Snapshot
```
curl -X PUT "http://localhost:6333/collections/my_collection/snapshots/upload"\
     -H "api-key: qdrant123"\
     -F "snapshot=@snapshot_file.snapshot"
```

* * * * *

📌 Ringkasan
============

-   **Docker Compose** → jalanin Qdrant + RBAC.

-   **Collection** → bikin wadah vector.

-   **Insert + Search** → simpan & cari vector.

-   **RBAC** → role-based dengan JWT, bukan user langsung.

-   **Snapshot** → backup & restore data.