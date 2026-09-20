"""Display each hex-encoded result as a JSON string, preserving empty fields."""
import json
import sys
for line in sys.stdin:
    print(json.dumps(bytes.fromhex(line.rstrip('\n')).decode('utf-8'), ensure_ascii=False))
