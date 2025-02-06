# Description
This script automatically updates the A records for a list of FQDNs in AWS Route53 with the current
public IP address of the machine running the script. It checks if the public IP has changed; if so,
it uses the AWS CLI to update the A records for the specified subdomains. It also sends an email
notification using an IFTTT webhook. The script is designed to be used in situations where a home
server or device has a dynamic public IP that may change periodically, and the DNS records need to
be updated accordingly to maintain accessibility.

# Prerequisites
[AWS CLI](https://aws.amazon.com/cli/) installed and configured with the necessary permissions to 
update Route53 records.

# Setup
Grant execute permissions with `sudo chmod +x run_ddns.sh`.

Copy the `config.sh.example` into a new `config.sh` file and configure the following:
1. FQDNS: The list of DNS records to be monitored and updated to the servers public IP
2. AWS_HOSTED_ZONE_ID: The Route53 hosted zone ID that contains the records you want to update
3. IFTTT_KEY: Your IFTTT webhook key from https://ifttt.com/maker_webhooks
4. IFTTT_EVENT: Your IFTTT event name, as specified when creating the webhook

> Note: For more information check 
> [the IFTTT webhooks documentation](https://ifttt.com/maker_webhooks). The IFTTT webhooks API
> endpoint looks like this `https://maker.ifttt.com/trigger/{IFTTT_EVENT}/json/with/key/{IFTTT_KEY}`

# Usage
* Run on-demand with `./run_ddns.sh`
* Check the logs with `tail -f log.csv`
* Schedule as a cronjob by adding a crontab command with `crontab -e`

Example crontab command that runs every 5 minutes:
```
# m h dom mon dow command
*/5 * * * * cd /path/to/ddns && ./run_ddns.sh
```
