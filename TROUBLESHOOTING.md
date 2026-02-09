# Troubleshooting Guide

## Common Issues and Solutions

### 1. JSON Decode Error / Missing cmdoutput.json

**Problem**: Cowrie fails to start with error:
```
json.decoder.JSONDecodeError: Expecting value: line 1 column 3 (char 2)
```
or
```
FileNotFoundError: [Errno 2] No such file or directory: '/cowrie/cowrie-git/share/cowrie/cmdoutput.json'
```

**Root Cause**: 
- Cowrie version 2.6.0+ moved data files from `share/cowrie` to `src/cowrie/data`
- The configuration still references the old `share/cowrie` location
- Required files (`cmdoutput.json`, `fs.pickle`) need to be copied to `share/cowrie`

**Solution**:
This project includes an entrypoint script (`cowrie-entrypoint.sh`) that automatically copies required data files on startup. The script:
- Creates the `share/cowrie` directory structure
- Copies `cmdoutput.json` from `src/cowrie/data` to `share/cowrie`
- Copies `fs.pickle` for the filesystem
- Copies `txtcmds` directory with command outputs
- Only copies files if they don't exist or if the source is newer

**Verification**:
```bash
# Check if files were copied correctly
docker-compose exec cowrie ls -la /cowrie/cowrie-git/share/cowrie/

# You should see:
# - cmdoutput.json
# - fs.pickle
# - txtcmds/
# - arch/ (if available)

# Check entrypoint logs
docker-compose logs cowrie | grep -A 20 "Initialization"
```

**Manual Fix** (if entrypoint doesn't work):
```bash
# Enter the container
docker-compose exec cowrie bash

# Copy required files manually
mkdir -p /cowrie/cowrie-git/share/cowrie
cp /cowrie/cowrie-git/src/cowrie/data/cmdoutput.json /cowrie/cowrie-git/share/cowrie/
cp /cowrie/cowrie-git/src/cowrie/data/fs.pickle /cowrie/cowrie-git/share/cowrie/
cp -r /cowrie/cowrie-git/src/cowrie/data/txtcmds /cowrie/cowrie-git/share/cowrie/

# Restart container
exit
docker-compose restart cowrie
```

### 2. Services Not Starting

**Problem**: `docker-compose up` fails or services keep restarting

**Solutions**:

```bash
# Check service logs
docker-compose logs cowrie
docker-compose logs promtail
docker-compose logs victorialogs
docker-compose logs grafana

# Check if ports are already in use
netstat -tuln | grep -E '(2222|2223|3000|9428)'

# If ports are in use, either stop the conflicting service or modify docker-compose.yml
```

### 3. No Logs in Grafana

**Problem**: Grafana shows no data from Cowrie

**Troubleshooting Steps**:

```bash
# 1. Check if Cowrie is creating logs
docker-compose exec cowrie ls -la /cowrie/var/log/cowrie/
docker-compose exec cowrie tail -f /cowrie/var/log/cowrie/cowrie.json

# 2. Check if Promtail can see the logs
docker-compose logs promtail | grep -i error

# 3. Verify VictoriaLogs is receiving data
curl http://localhost:9428/select/logsql/query -d 'query={job="cowrie"}'

# 4. Check Grafana datasource connection
# Go to Grafana → Configuration → Data Sources → VictoriaLogs → Test
```

### 4. Cowrie Container Exits Immediately

**Problem**: Cowrie container starts but exits with error

**Solutions**:

```bash
# Check detailed logs
docker-compose logs cowrie --tail=100

# Common issues:
# - Configuration file syntax error
# - Missing directories
# - Permission issues

# Verify configuration
docker-compose exec cowrie cat /cowrie/cowrie.cfg

# Check if cowrie user has permissions
docker-compose exec cowrie ls -la /cowrie/var/log/
```

### 5. Cannot Connect to Honeypot (Ports 2222/2223)

**Problem**: SSH/Telnet connections to Cowrie fail

**Solutions**:

```bash
# Check if Cowrie is listening
docker-compose exec cowrie netstat -tuln | grep -E '(2222|2223)'

# Test connection from host
telnet localhost 2223
ssh -p 2222 root@localhost

# Check Docker port mappings
docker-compose ps

# Verify firewall rules (if running on server)
sudo ufw status
sudo iptables -L -n | grep -E '(2222|2223)'
```

### 6. Grafana Login Issues

**Problem**: Cannot log in to Grafana or forgot password

**Solutions**:

```bash
# Reset admin password
docker-compose exec grafana grafana-cli admin reset-admin-password newpassword

# Or, restart with environment variable
# Edit docker-compose.yml and change:
# GF_SECURITY_ADMIN_PASSWORD=yournewpassword

# Then restart
docker-compose restart grafana
```

### 7. VictoriaLogs Out of Disk Space

**Problem**: VictoriaLogs fills up disk space

**Solutions**:

```bash
# Check current disk usage
docker volume inspect victorialogs-data
du -sh /var/lib/docker/volumes/victorialogs-data

# Reduce retention period (edit docker-compose.yml)
# Under victorialogs service, change:
# '--retentionPeriod=30d'  # to lower value like 7d

# Restart service
docker-compose restart victorialogs

# Manual cleanup (⚠️ deletes old data)
docker-compose exec victorialogs rm -rf /victoria-logs-data/data
docker-compose restart victorialogs
```

### 8. Promtail Not Parsing Logs Correctly

**Problem**: Logs appear in VictoriaLogs but fields aren't extracted

**Solutions**:

```bash
# Test promtail configuration
docker-compose exec promtail cat /etc/promtail/config.yml

# Check for JSON parsing errors in logs
docker-compose logs promtail | grep -i error

# Verify Cowrie is writing valid JSON
docker-compose exec cowrie tail -1 /cowrie/var/log/cowrie/cowrie.json | python3 -m json.tool

# If not valid JSON, check Cowrie configuration
docker-compose exec cowrie cat /cowrie/cowrie.cfg | grep -A5 output_jsonlog
```

### 9. High CPU/Memory Usage

**Problem**: One or more containers using too many resources

**Solutions**:

```bash
# Check resource usage
docker stats

# Limit resources in docker-compose.yml (add under each service)
# Example:
#   deploy:
#     resources:
#       limits:
#         cpus: '0.5'
#         memory: 512M

# Restart with limits
docker-compose down && docker-compose up -d
```

### 10. Network Connectivity Issues Between Containers

**Problem**: Services can't communicate with each other

**Solutions**:

```bash
# Check network
docker network ls | grep honeypot
docker network inspect honeypot-monitoring

# Test connectivity
docker-compose exec promtail ping victorialogs
docker-compose exec grafana ping victorialogs

# Recreate network
docker-compose down
docker network rm honeypot-monitoring
docker-compose up -d
```

### 11. Permission Denied Errors

**Problem**: Permission errors in logs

**Solutions**:

```bash
# Check volume permissions
docker volume inspect cowrie-logs

# Fix permissions (run from host)
sudo chown -R 1000:1000 /var/lib/docker/volumes/cowrie-logs/_data

# Or recreate volumes
docker-compose down -v
docker-compose up -d
```

## Health Check Commands

Quick commands to verify everything is working:

```bash
# All services running?
docker-compose ps

# Any errors in logs?
docker-compose logs | grep -i error

# Cowrie logging?
docker-compose exec cowrie tail -f /cowrie/var/log/cowrie/cowrie.json

# Promtail sending logs?
docker-compose logs promtail | tail -20

# VictoriaLogs receiving data?
curl -s http://localhost:9428/select/logsql/query -d 'query={job="cowrie"}' | head -20

# Grafana healthy?
curl -s http://localhost:3000/api/health | python3 -m json.tool
```

## Getting More Help

If you're still experiencing issues:

1. **Check the full logs**: `docker-compose logs > debug.log`
2. **Check Docker status**: `docker info`
3. **Check system resources**: `df -h` and `free -m`
4. **Review configuration files** for typos or syntax errors
5. **Consult component documentation**:
   - [Cowrie Docs](https://cowrie.readthedocs.io/)
   - [VictoriaLogs Docs](https://docs.victoriametrics.com/VictoriaLogs/)
   - [Promtail Docs](https://grafana.com/docs/loki/latest/clients/promtail/)
   - [Grafana Docs](https://grafana.com/docs/grafana/latest/)

## Reporting Issues

When reporting issues, please include:
- Output of `docker-compose ps`
- Output of `docker-compose logs`
- Your OS and Docker version
- Contents of your configuration files
- Steps to reproduce the issue
