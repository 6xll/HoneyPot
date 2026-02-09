# HoneyPot Security Monitoring Project

A comprehensive security monitoring solution integrating Cowrie honeypot with a modern observability stack.

## Architecture Overview

This project uses Docker Compose to orchestrate a complete security monitoring stack:

```
┌─────────────┐
│   Cowrie    │ - SSH/Telnet honeypot
│  Honeypot   │ - Logs to JSON format
└──────┬──────┘
       │
       │ JSON logs (cowrie.json)
       │
       ▼
┌─────────────┐
│  Promtail   │ - Log collector
│             │ - Extracts fields (src_ip, eventid, input)
└──────┬──────┘
       │
       │ Structured logs
       │
       ▼
┌─────────────┐
│ VictoriaLogs│ - High-performance log storage
│             │ - Query engine
└──────┬──────┘
       │
       │ LogQL queries
       │
       ▼
┌─────────────┐
│   Grafana   │ - Visualization & dashboards
│             │ - Alerting
└─────────────┘
```

## Components

- **Cowrie**: SSH/Telnet honeypot that logs attacker activities in JSON format
- **Promtail**: Log scraper that collects and forwards Cowrie logs
- **VictoriaLogs**: Fast, cost-effective log storage backend
- **Grafana**: Visualization and dashboarding platform

## Prerequisites

- Docker Engine (20.10+)
- Docker Compose (2.0+)
- At least 2GB of free RAM
- 10GB of free disk space

## Quick Start

### Step 1: Copy Cowrie Source Code

Instead of using Cowrie as a git submodule, we'll copy it directly into our repository:

```bash
# Clone Cowrie repository temporarily
git clone https://github.com/cowrie/cowrie.git /tmp/cowrie-temp

# Copy Cowrie source into your project
cp -r /tmp/cowrie-temp/* ./cowrie/

# Clean up temporary clone
rm -rf /tmp/cowrie-temp

# Add Cowrie to your repository
git add cowrie/
git commit -m "Add Cowrie honeypot source code"
```

**Note**: This approach gives you full control over Cowrie's version in your repository. You can update it manually when needed without dealing with submodule complexities.

### Step 2: Start the Stack

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check service health
docker-compose ps
```

**Note**: The first time you start Cowrie, the entrypoint script will automatically copy required data files (`cmdoutput.json`, `fs.pickle`, etc.) from the source directory to the share directory. This process is necessary for Cowrie to function properly.

You can verify the initialization by checking the logs:
```bash
docker-compose logs cowrie | grep "Initialization"
```

### Step 3: Access Services

- **Grafana**: http://localhost:3000 (default credentials: admin/admin)
- **Cowrie SSH**: Port 2222 (honeypot endpoint)
- **Cowrie Telnet**: Port 2223 (honeypot endpoint)
- **VictoriaLogs**: http://localhost:9428

### Step 4: Configure Grafana

1. Log in to Grafana at http://localhost:3000
2. The VictoriaLogs datasource is automatically provisioned
3. Navigate to "Explore" to query logs
4. Create dashboards to visualize attack patterns

## Configuration

### Cowrie Configuration

Cowrie is configured via `cowrie/cowrie.cfg`:
- JSON logging enabled
- Logs stored in `/cowrie/var/log/cowrie/cowrie.json`
- SSH on port 2222, Telnet on port 2223

### Promtail Configuration

Promtail is configured to:
- Monitor `/var/log/cowrie/cowrie.json`
- Extract fields: `src_ip`, `eventid`, `input`
- Add labels for easy querying
- Forward logs to VictoriaLogs

### VictoriaLogs Configuration

VictoriaLogs runs with:
- Data stored in Docker volume
- Retention: 30 days (configurable)
- HTTP API on port 9428

## Example Queries

Once data is flowing, you can use these LogQL queries in Grafana:

### View all SSH login attempts
```
{job="cowrie"} | json | eventid="cowrie.login.failed"
```

### Track commands executed by attackers
```
{job="cowrie"} | json | eventid="cowrie.command.input" | line_format "{{.src_ip}}: {{.input}}"
```

### Top attacking IPs
```
sum by (src_ip) (count_over_time({job="cowrie"} | json [5m]))
```

## Maintenance

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f cowrie
docker-compose logs -f promtail
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart cowrie
```

### Stop and Clean Up
```bash
# Stop services
docker-compose down

# Stop and remove volumes (⚠️ deletes all logs)
docker-compose down -v
```

## Security Considerations

1. **Isolation**: Run this stack in an isolated network segment
2. **Firewall**: Only expose Cowrie ports (2222, 2223) to the internet
3. **Monitoring**: Keep Grafana and VictoriaLogs on private network
4. **Updates**: Regularly update Cowrie and other components for security patches
5. **Logs**: Monitor and rotate logs to prevent disk space issues

## Troubleshooting

### Cowrie not starting
```bash
# Check Cowrie logs
docker-compose logs cowrie

# Verify configuration
docker-compose exec cowrie cat /cowrie/cowrie.cfg
```

### No logs in Grafana
```bash
# Check Promtail is running
docker-compose logs promtail

# Verify log file exists
docker-compose exec cowrie ls -la /cowrie/var/log/cowrie/

# Check VictoriaLogs
curl http://localhost:9428/select/logsql/query -d 'query={job="cowrie"}'
```

### Container resource issues
```bash
# Check resource usage
docker stats

# Increase Docker resource limits if needed
```

## Customization

### Adding Custom Cowrie Plugins
Place custom plugins in `./cowrie/src/cowrie/plugins/`

### Custom Grafana Dashboards
Save dashboards as JSON in `./grafana/dashboards/` for version control

### Adjusting Log Retention
Edit `docker-compose.yml` and modify VictoriaLogs retention settings

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This project configuration is provided as-is. Cowrie and other components retain their respective licenses.

## Resources

- [Cowrie Documentation](https://cowrie.readthedocs.io/)
- [VictoriaLogs Documentation](https://docs.victoriametrics.com/VictoriaLogs/)
- [Promtail Documentation](https://grafana.com/docs/loki/latest/clients/promtail/)
- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
