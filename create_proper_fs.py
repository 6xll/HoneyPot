import sys
sys.path.insert(0, '/cowrie/cowrie-git/src')
import pickle
from cowrie.shell import fs

# Create filesystem using Cowrie's class
filesystem = fs.HoneyPotFilesystem('/cowrie/cowrie-git/honeyfs', None, None)

# Save it
with open('/cowrie/cowrie-git/share/cowrie/fs.pickle', 'wb') as f:
    pickle.dump(filesystem, f)
print("Created proper fs.pickle")
