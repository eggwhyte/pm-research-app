from datetime import datetime
import json
import os
from pathlib import Path

out_dir = Path("/tmp/pm-research-job")
out_dir.mkdir(parents=True, exist_ok=True)

payload = {
    "job": "collect_once",
    "timestamp_utc": datetime.utcnow().isoformat() + "Z",
    "status": "ok"
}

outfile = out_dir / "last_run.json"
outfile.write_text(json.dumps(payload, indent=2))

print(json.dumps(payload))
