# Testing Guide for HoneyPot Monitoring Stack

This guide demonstrates how to test and verify the complete monitoring stack.

## Prerequisites

Ensure the stack is running:
```bash
docker compose ps
```

All services should be in "Up" or "healthy" status.

## Test 1: Verify Services are Running

```bash
# Check all containers are healthy
docker compose ps

# Expected output: All services running and healthy
# - cowrie (ports 2222, 2223)
# - promtail
# - victorialogs (port 9428)
# - grafana (port 3000)
```

## Test 2: Test Cowrie Honeypot

Generate honeypot activity:

```bash
# Test SSH connection (will fail authentication, which is expected)
ssh -p 2222 root@localhost

# Or with password attempt
timeout 3 ssh -p 2222 test@localhost

# Check Cowrie logs
docker compose logs cowrie --tail=20
```

You should see log entries for connection attempts, such as:
- `New connection`
- `login attempt`
- `Remote SSH version`

## Test 3: Verify JSON Logs are Created

```bash
# List log files
sudo ls -lh /var/lib/docker/volumes/cowrie-logs/_data/

# View JSON logs
sudo tail -5 /var/lib/docker/volumes/cowrie-logs/_data/cowrie.json | jq
```

Expected fields in JSON logs:
- `eventid`: Event type (e.g., `cowrie.session.connect`, `cowrie.login.failed`)
- `src_ip`: Source IP address
- `src_port`: Source port
- `dst_ip`: Destination IP
- `dst_port`: Destination port
- `session`: Session ID
- `protocol`: Protocol used (ssh/telnet)
- `message`: Human-readable message
- `timestamp`: ISO 8601 timestamp

## Test 4: Verify Promtail is Collecting Logs

```bash
# Check Promtail logs
docker compose logs promtail --tail=30

# Look for messages like:
# - "Adding target" - Promtail found the log files
# - "tail routine: started" - Promtail is tailing files
```

## Test 5: Verify VictoriaLogs is Receiving Data

```bash
# Check ingestion metrics
curl -s 'http://localhost:9428/metrics' | grep vl_rows_ingested_total

# Should show non-zero values for loki protobuf format:
# vl_rows_ingested_total{type="loki",format="protobuf"} > 0
```

## Test 6: Query Logs from VictoriaLogs

```bash
# Query all Cowrie logs
curl -s 'http://localhost:9428/select/logsql/query' \
  --data-urlencode 'query=job:cowrie' \
  -d 'limit=10'

# Query specific event types
curl -s 'http://localhost:9428/select/logsql/query' \
  --data-urlencode 'query=job:cowrie _msg:~"login"' \
  -d 'limit=5'

# Query by time range (last 5 minutes)
curl -s 'http://localhost:9428/select/logsql/query' \
  --data-urlencode 'query=job:cowrie _time:5m' \
  -d 'limit=10'
```

## Test 7: Access Grafana

1. Open browser to http://localhost:3000
2. Login with credentials: `admin` / `admin`
3. Navigate to **Explore** (compass icon in left sidebar)
4. Select **VictoriaLogs-Loki** as the datasource
5. Enter a LogQL query: `{job="cowrie"}`
6. Click **Run query**

You should see logs appear in the Explore view.

## Test 8: Test the Sample Dashboard

1. In Grafana, go to **Dashboards** (four squares icon)
2. Look for folder **Honeypot**
3. Open **Cowrie Honeypot Overview** dashboard
4. The dashboard should show:
   - Total events count
   - Events over time graph
   - Top source IPs
   - Recent failed logins
   - Commands executed by attackers

## Test 9: Generate More Activity for Testing

Use this script to generate varied honeypot activity:

```bash
#!/bin/bash
# Generate test honeypot activity

echo "Generating honeypot test traffic..."

# Failed login attempts with various usernames
for user in admin root test guest ubuntu; do
  echo "Testing with user: $user"
  timeout 2 ssh -p 2222 -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null $user@localhost 2>&1 | head -2
  sleep 1
done

# Wait for logs to be processed
echo "Waiting 10 seconds for log processing..."
sleep 10

# Check how many events were logged
echo ""
echo "Events in VictoriaLogs:"
curl -s 'http://localhost:9428/select/logsql/query' \
  --data-urlencode 'query=job:cowrie _time:1m' \
  -d 'limit=1' | wc -l

echo ""
echo "Check Grafana to see the activity!"
```

## Test 10: Verify Log Field Extraction

Check that Promtail is extracting the right fields:

```bash
# Query and display structured fields
curl -s 'http://localhost:9428/select/logsql/query' \
  --data-urlencode 'query=job:cowrie' \
  -d 'limit=3' | jq .
```

Expected fields in VictoriaLogs:
- `_msg`: The log message
- `_time`: Timestamp
- `_stream`: Stream identifier
- `job`: Job label (should be "cowrie")
- Additional labels extracted by Promtail

## Expected Results

After running these tests, you should have:

✅ Cowrie honeypot accepting SSH/Telnet connections  
✅ JSON logs being written to shared volume  
✅ Promtail reading and forwarding logs  
✅ VictoriaLogs storing logs  
✅ Grafana able to query and display logs  
✅ Pre-built dashboard showing honeypot activity  

## Troubleshooting

If any test fails, check:

1. **Services not starting**: `docker compose logs [service-name]`
2. **No logs in VictoriaLogs**: Check Promtail logs for errors
3. **Grafana can't connect**: Verify datasource URL in Grafana settings
4. **No dashboard data**: Wait a few minutes and refresh; query time range in Grafana

For more help, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Performance Notes

- **Log retention**: Currently set to 30 days in VictoriaLogs
- **Log volume**: Expect ~1-10 KB per honeypot connection
- **Query performance**: VictoriaLogs can handle millions of log entries efficiently
- **Resource usage**: Entire stack uses ~500MB RAM under light load

## Next Steps

1. **Expose Cowrie to Internet**: Configure firewall to allow external traffic to ports 2222/2223
2. **Create custom dashboards**: Build dashboards specific to your monitoring needs
3. **Setup alerts**: Configure Grafana alerts for suspicious activity
4. **Integrate with other tools**: Export data to SIEM or threat intelligence platforms
5. **Analyze attack patterns**: Use the collected data to identify attack trends

## Security Reminder

⚠️ **Important**: 
- Only expose Cowrie ports (2222, 2223) to the internet
- Keep Grafana, VictoriaLogs, and Promtail on internal network
- Change default Grafana password immediately
- Regularly backup your logs and configuration
- Monitor disk space usage to prevent log volume overflow
