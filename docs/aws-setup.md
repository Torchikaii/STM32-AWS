# AWS IoT Core Setup Guide

This guide walks you through manually setting up AWS IoT Core for your STM32 device.

---

## Prerequisites

- AWS Account
- AWS CLI configured (`aws configure`)
- Device certificates generated locally

---

## Step 1: Create IoT Thing and Certificates

### Option A: AWS Console

1. Navigate to [AWS IoT Core Console](https://console.aws.amazon.com/iot/)
2. Go to **Manage** → **Things** → **Create** → **Create a single thing**
3. Enter device name: `stm32-device-001`
4. Click **Next**
5. Under **Certificate**, click **Create certificate**
6. Download:
   - Device certificate (`*.pem.crt`)
   - Private key (`*.pem.key`)
   - Root CA for AWS IoT (`AmazonRootCA1.pem`)
7. Click **Activate**
8. Attach the policy (see Step 2)

### Option B: AWS CLI

```bash
# Create IoT Thing
aws iot create-thing --thing-name "stm32-device-001"

# Create certificates
aws iot create-keys-and-certificate --set-as-active \
  --certificate-pem-outfile device.pem.crt \
  --public-key-outfile device.public.key \
  --private-key-outfile device.private.key

# Download root CA
curl -o AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
```

---

## Step 2: Create and Attach Policy

### Create Policy (CLI)

```bash
aws iot create-policy \
  --policy-name "stm32-aws-policy" \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["iot:Connect"],
        "Resource": ["arn:aws:iot:REGION:ACCOUNT_ID:client/stm32-device-001"]
      },
      {
        "Effect": "Allow",
        "Action": ["iot:Publish", "iot:Receive"],
        "Resource": ["arn:aws:iot:REGION:ACCOUNT_ID:topic/device/stm32-device-001/*"]
      },
      {
        "Effect": "Allow",
        "Action": ["iot:Subscribe"],
        "Resource": ["arn:aws:iot:REGION:ACCOUNT_ID:topicfilter/device/stm32-device-001/*"]
      }
    ]
  }'
```

Replace `REGION` and `ACCOUNT_ID` with your values.

### Attach Policy to Certificate

```bash
# Get certificate ARN from previous step output
CERTIFICATE_ARN="arn:aws:iot:REGION:ACCOUNT_ID:cert/xxxxxxxxxxxxx"

aws iot attach-policy \
  --policy-name "stm32-aws-policy" \
  --target "$CERTIFICATE_ARN"
```

---

## Step 3: Get IoT Endpoint

```bash
aws iot describe-endpoint --endpoint-type iot:Data-ATS
```

Save the endpoint URL - you'll need it for `aws_config.h`.

---

## Step 4: Organize Certificate Files

Create a secrets directory and organize your certificates:

```bash
mkdir -p /secrets
cp device.pem.crt /secrets/device.pem
cp device.private.key /secrets/device.key
cp AmazonRootCA1.pem /secrets/
```

---

## Step 5: Update Device Configuration

Edit `test439/Inc/aws_config.h`:

```c
#define AWS_IOT_ENDPOINT      "xxxxxxxxxxxxx-ats.iot.REGION.amazonaws.com"
#define AWS_DEVICE_ID         "stm32-device-001"
```

---

## MQTT Topics

| Topic | Direction | Purpose |
|-------|-----------|---------|
| `device/stm32-device-001/command` | Cloud → Device | Send commands |
| `device/stm32-device-001/response` | Device → Cloud | Command responses |
| `device/stm32-device-001/telemetry` | Device → Cloud | Periodic sensor data |
| `device/stm32-device-001/latency` | Device → Cloud | Timing metrics |

---

## Testing MQTT Connection

### Subscribe to Commands (AWS Console)

1. Go to **Test** → **MQTT test client**
2. Subscribe to: `device/stm32-device-001/command`
3. Click **Subscribe**

### Publish Test Message

```bash
aws iot-data publish \
  --topic "device/stm32-device-001/command" \
  --cli-unix-utc-timestamp-seconds $(date +%s) \
  --payload '{"command": "blink", "led": 1}'
```

---

## Troubleshooting

### Connection Refused

- Verify certificate is activated
- Check policy is attached to certificate
- Confirm endpoint URL is correct

### TLS Handshake Failed

- Verify device time is synchronized (NTP)
- Check root CA is correct (`AmazonRootCA1.pem`)

### Permission Denied

- Verify IAM permissions for IoT actions
- Check IoT policy Resource ARNs match your region/account

---

## Security Notes

- **Never commit certificates to version control**
- Store certificates outside the project directory
- Use file permissions `600` on private keys
- Consider AWS Secrets Manager for production deployments
