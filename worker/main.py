import os
import time

INTERVAL_SECONDS = int(os.getenv("WORKER_INTERVAL_SECONDS", "60"))

print("worker starting")

while True:
    print("worker heartbeat")
    time.sleep(INTERVAL_SECONDS)
