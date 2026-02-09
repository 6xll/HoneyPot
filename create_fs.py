import os
import sys
import pickle

# Create minimal filesystem structure
filesystem_data = {
    '/': ['bin', 'etc', 'home', 'root', 'tmp', 'usr', 'var'],
    '/bin': ['ls', 'cat', 'echo', 'pwd', 'cd'],
    '/home': [],
    '/root': [],
    '/tmp': [],
    '/etc': ['passwd', 'shadow'],
    '/usr': ['bin'],
    '/var': ['log']
}

output_path = '/cowrie/cowrie-git/share/cowrie/fs.pickle'
with open(output_path, 'wb') as f:
    pickle.dump(filesystem_data, f, protocol=pickle.HIGHEST_PROTOCOL)
print(f"Created {output_path}")
