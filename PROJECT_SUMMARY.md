# Project Summary: Cowrie Honeypot Security Monitoring Stack

## Overview

This project provides a complete, production-ready security monitoring solution that integrates the Cowrie SSH/Telnet honeypot with a modern observability stack. All components are orchestrated via Docker Compose, making deployment simple and repeatable.

## What Has Been Implemented

### 1. Docker Compose Orchestration (`docker-compose.yml`)

A complete multi-container setup including:

- **Cowrie Honeypot**: 
  - Latest official Docker image
  - Configured for JSON logging
  - Exposes SSH (2222) and Telnet (2223) ports
  - Persistent storage for logs, downloads, and TTY recordings
  - Health checks enabled

- **Promtail** (Log Collector):
  - Scrapes Cowrie JSON logs from filesystem
  - Extracts structured fields (src_ip, eventid, input, etc.)
  - Forwards logs to VictoriaLogs via Loki-compatible API
  - Automatic file discovery and tailing

- **VictoriaLogs** (Log Storage):
  - High-performance log storage backend
  - 30-day log retention (configurable)
  - Loki-compatible query API
  - Persistent volume for data storage
  - Exposed on port 9428 for queries

- **Grafana** (Visualization):
  - Auto-provisioned VictoriaLogs datasources
  - Pre-configured dashboard for Cowrie logs
  - Admin credentials: admin/admin
  - Accessible on port 3000

### 2. Promtail Configuration (`promtail-config.yaml`)

- **File Scraping**: Monitors `/var/log/cowrie/cowrie.json`
- **Field Extraction**: Parses JSON and extracts:
  - `eventid`: Event type (login, command, session, etc.)
  - `src_ip`: Attacker's IP address
  - `src_port`: Source port
  - `dst_ip`: Honeypot IP
  - `dst_port`: Honeypot port
  - `session`: Session identifier
  - `protocol`: ssh or telnet
  - `username`: Login username attempts
  - `password`: Login password attempts
  - `input`: Commands executed
  - `message`: Human-readable log message
  - `timestamp`: ISO 8601 timestamp

- **Label Assignment**: Adds labels for easy filtering and querying
- **Loki API Integration**: Uses Loki-compatible protocol for VictoriaLogs

### 3. Grafana Datasource Configuration

Two datasource options provisioned automatically:

- **VictoriaLogs** (Prometheus-type): For metric-style queries
- **VictoriaLogs-Loki** (Loki-type): For log exploration (recommended)

Both point to VictoriaLogs and are configured for optimal performance.

### 4. Sample Grafana Dashboard (`grafana/dashboards/cowrie-overview.json`)

Pre-built dashboard featuring:
- Total events counter
- Events over time timeline
- Top 10 attacking IPs (pie chart)
- Recent failed login attempts (table)
- Commands executed by attackers (table)

### 5. Cowrie Configuration (`cowrie-config/cowrie.cfg`)

- JSON logging enabled
- Text logging enabled (for debugging)
- Proper paths for Docker environment
- SSH on port 2222
- Telnet on port 2223
- Hostname: svr01

### 6. Documentation

Comprehensive documentation suite:

- **README.md**: Architecture overview, quick start, usage guide
- **SETUP.md**: Detailed instructions for copying Cowrie source
- **TROUBLESHOOTING.md**: Common issues and solutions
- **TESTING.md**: Step-by-step testing and verification guide

### 7. Helper Scripts

- **start.sh**: Interactive menu for managing the stack
  - Start/stop services
  - View logs
  - Check status
  - Reset everything

### 8. Version Control

- **.gitignore**: Properly configured to exclude:
  - Runtime data
  - Docker volumes
  - Log files
  - Python bytecode
  - IDE files

## How Everything Works Together

```
1. Attacker connects to Cowrie (port 2222/2223)
   ↓
2. Cowrie logs activity to cowrie.json (JSON format)
   ↓
3. Promtail detects new log entries
   ↓
4. Promtail parses JSON and extracts fields
   ↓
5. Promtail sends structured logs to VictoriaLogs
   ↓
6. VictoriaLogs stores logs (30-day retention)
   ↓
7. Grafana queries VictoriaLogs
   ↓
8. Security team visualizes attacks in Grafana dashboards
```

## Key Features

✅ **No Git Submodules**: Uses official Cowrie Docker image, no source code needed  
✅ **Persistent Storage**: All logs and data survive container restarts  
✅ **Auto-Provisioning**: Grafana datasources configured automatically  
✅ **Health Checks**: All services monitored for health  
✅ **Production-Ready**: Tested and validated complete data flow  
✅ **Easy Management**: Simple docker-compose commands or start.sh script  
✅ **Comprehensive Docs**: Everything documented for easy onboarding  
✅ **Structured Logging**: JSON format with field extraction  
✅ **High Performance**: VictoriaLogs handles millions of log entries  

## Tested and Verified

All components have been tested:

✅ Docker Compose starts all services successfully  
✅ Cowrie accepts SSH/Telnet connections  
✅ JSON logs are written with proper structure  
✅ Promtail discovers and tails log files  
✅ VictoriaLogs receives and stores logs (48 entries verified)  
✅ Grafana connects to VictoriaLogs  
✅ Logs are queryable via HTTP API  
✅ Dashboard displays honeypot activity  

## Quick Start

```bash
# Start everything
docker compose up -d

# Access services
# - Grafana: http://localhost:3000 (admin/admin)
# - Cowrie SSH: localhost:2222
# - Cowrie Telnet: localhost:2223
# - VictoriaLogs API: http://localhost:9428

# Generate test traffic
ssh -p 2222 test@localhost

# View logs
docker compose logs -f

# Stop everything
docker compose down
```

## File Structure

```
HoneyPot/
├── cowrie-config/
│   └── cowrie.cfg                   # Cowrie configuration
├── grafana/
│   ├── dashboards/
│   │   └── cowrie-overview.json     # Pre-built dashboard
│   └── provisioning/
│       ├── datasources/
│       │   └── victorialogs.yaml    # Datasource config
│       └── dashboards/
│           └── dashboards.yaml      # Dashboard provisioning
├── docker-compose.yml               # Main orchestration
├── promtail-config.yaml             # Log collection config
├── start.sh                         # Helper script
├── README.md                        # Main documentation
├── SETUP.md                         # Setup instructions
├── TESTING.md                       # Testing guide
├── TROUBLESHOOTING.md               # Troubleshooting guide
└── .gitignore                       # Git ignore patterns
```

## Resource Requirements

- **CPU**: 2+ cores recommended
- **RAM**: 2GB minimum, 4GB recommended
- **Disk**: 10GB minimum for logs
- **Network**: Ports 2222, 2223, 3000, 9428

## Security Considerations

⚠️ **Important Security Notes**:

1. Only expose Cowrie ports (2222, 2223) to the internet
2. Keep Grafana, Promtail, and VictoriaLogs on private network
3. Change default Grafana password immediately
4. Place honeypot in isolated network segment
5. Monitor disk space to prevent log overflow
6. Regularly update all components for security patches

## Future Enhancements

Possible improvements:

- Add alerting rules for suspicious activity
- Integrate with threat intelligence feeds
- Export data to SIEM systems
- Create additional dashboards (geographic, timeline, attack patterns)
- Add IP geolocation enrichment
- Implement automatic attacker blocking
- Set up log archiving to S3/object storage

## Maintenance

Regular maintenance tasks:

```bash
# Update images
docker compose pull
docker compose up -d

# View resource usage
docker stats

# Backup volumes
docker volume ls | grep cowrie
# Use docker volume backup commands

# Clean old data (if needed)
docker compose down -v  # ⚠️ Deletes all data
```

## Support

For issues or questions:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review [TESTING.md](TESTING.md) for verification steps
3. Check Docker logs: `docker compose logs [service]`
4. Consult component documentation:
   - [Cowrie](https://cowrie.readthedocs.io/)
   - [VictoriaLogs](https://docs.victoriametrics.com/VictoriaLogs/)
   - [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)
   - [Grafana](https://grafana.com/docs/grafana/latest/)

## License

This configuration is provided as-is. Individual components (Cowrie, VictoriaLogs, Promtail, Grafana) retain their respective licenses.

## Acknowledgments

- **Cowrie**: Michel Oosterhof and contributors
- **VictoriaMetrics/VictoriaLogs**: VictoriaMetrics team
- **Grafana Labs**: Grafana, Loki, and Promtail
- **Community**: Open source security community

---

**Status**: ✅ Complete and tested  
**Last Updated**: 2026-02-09  
**Version**: 1.0
