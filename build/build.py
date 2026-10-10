import subprocess
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))

if __name__ == "__main__":
    check = subprocess.run([sys.executable, os.path.join(HERE, "check.py")])
    if check.returncode != 0:
        print("build stopped: fix the problems above first")
        sys.exit(1)
    bundle = subprocess.run([sys.executable, os.path.join(HERE, "bundle.py")])
    sys.exit(bundle.returncode)
