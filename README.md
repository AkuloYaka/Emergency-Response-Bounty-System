# Emergency Response Bounty System

> Blockchain-powered emergency response coordination with crypto-based incentives 🚁💰

## 🎯 Overview

The Emergency Response Bounty System is a decentralized platform that enables fast, coordinated emergency response through blockchain technology. Citizens can report incidents and create crypto bounties, while verified first responders can claim rewards for their assistance.

## ✨ Key Features

- 🌍 **Geo-located Incident Reporting** - Report emergencies with precise GPS coordinates
- 💎 **Token-based Rewards** - Responders earn crypto tokens for verified assistance
- 👨‍🚒 **Role-based Registry** - Separate registration for fire, ambulance, and security personnel
- 📜 **On-chain Audit Trail** - Complete response history stored on blockchain
- 🗳️ **Community Prioritization** - DAO voting system for incident priority
- 📍 **Dynamic Location Updates** - Responders can update their GPS coordinates in real-time

## 🚀 Quick Start

### For Citizens (Incident Reporters)

1. **Mint Tokens** (Contract Owner Required)
```clarity
(contract-call? .emergency-response-bounty-system mint-tokens 'SP1234... u1000)
```

2. **Report an Incident**
```clarity
(contract-call? .emergency-response-bounty-system report-incident 
  "house-fire" 
  40748817  ; latitude (NYC * 1M for precision)
  -73985428 ; longitude (NYC * 1M for precision)
  u4        ; severity (1-5)
  u100)     ; bounty amount
```

3. **Vote on Incident Priority**
```clarity
(contract-call? .emergency-response-bounty-system vote-incident-priority u1)
```

### For First Responders

1. **Register as Responder**
```clarity
(contract-call? .emergency-response-bounty-system register-responder 
  "fire"     ; role: "fire", "ambulance", or "security"
  40748817   ; your latitude
  -73985428) ; your longitude
```

2. **Get Verified** (Contract Owner Required)
```clarity
(contract-call? .emergency-response-bounty-system verify-responder 'SP1234...)
```

3. **Respond to Incident**
```clarity
(contract-call? .emergency-response-bounty-system respond-to-incident 
  u1                ; incident ID
  "dispatched")     ; response type
```

4. **Claim Reward** (After Verification)
```clarity
(contract-call? .emergency-response-bounty-system claim-reward u1)
```

5. **Update Location**
```clarity
(contract-call? .emergency-response-bounty-system update-responder-location
  40748817   ; new latitude
  -73985428) ; new longitude
```

### For Contract Administrators

1. **Verify Response**
```clarity
(contract-call? .emergency-response-bounty-system verify-response u1)
```

## 📊 Contract Functions

### 🔍 Read-Only Functions

- `get-responder` - Get responder details
- `get-incident` - Get incident information  
- `get-response` - Get response details
- `get-balance` - Check user token balance
- `get-contract-stats` - View contract statistics

### ✍️ Write Functions

- `register-responder` - Register as emergency responder
- `verify-responder` - Verify responder credentials (admin only)
- `report-incident` - Report new emergency incident
- `respond-to-incident` - Submit response to incident
- `verify-response` - Verify response validity (admin only)
- `claim-reward` - Claim bounty tokens for verified response
- `vote-incident-priority` - Vote to prioritize incident
- `mint-tokens` - Create new tokens (admin only)
- `transfer-tokens` - Transfer tokens between users
- `update-responder-location` - Update responder GPS coordinates

## 🗺️ Data Structures

### Responder Registry
- Role (fire/ambulance/security)
- GPS coordinates
- Reputation score
- Verification status
- Response history

### Incident Records
- Reporter information
- Incident type and severity
- GPS location
- Bounty amount
- Status and resolution
- Community priority votes

### Response Tracking
- Linked incident ID
- Responder details
- Response type
- Verification status
- Reward claim status

## 🔐 Security Features

- **Role-based Access Control** - Different permissions for responders, reporters, and admins
- **Geographic Validation** - Coordinates must be within valid Earth ranges
- **Double-spend Prevention** - Users cannot claim rewards twice
- **Verification Required** - Only verified responders can claim bounties
- **Balance Checking** - Prevents operations exceeding available funds

## 🏗️ Technical Details

- **Platform**: Stacks Blockchain
- **Language**: Clarity Smart Contract
- **Coordinate System**: Latitude/Longitude * 1,000,000 for precision
- **Token Standard**: Custom implementation with mint/burn capabilities
- **Storage**: On-chain maps for all data persistence

## 📈 Contract Stats

Track real-time contract metrics:
- Total incidents reported
- Total responses submitted  
- Token supply and distribution
- Contract balance

## 🤝 Contributing

This is an MVP implementation. Future enhancements could include:
- Multi-signature verification
- Reputation-based reward multipliers
- Integration with real emergency services
- Mobile app interface
- Cross-chain compatibility

## 📞 Emergency Note

⚠️ **This system is for demonstration purposes. In real emergencies, always call your local emergency services (911, 112, etc.) first!**

## 🆕 Incident Cancellation Feature

### Overview
The Incident Cancellation feature allows incident reporters to cancel their reported incidents if no responses have been submitted yet, enabling them to recover their bounty funds. This enhances flexibility and prevents funds from being locked in unresolved incidents.

### How It Works
- Reporters can call the `cancel-incident` function with the incident ID
- The system verifies the caller is the reporter, the incident is open, and no responses exist
- Upon successful cancellation, the incident status is set to "cancelled", and the bounty is refunded

### Usage Example
```clarity
(contract-call? .emergency-response-bounty-system cancel-incident u1)
```

### Benefits
- Provides reporters with control over their incidents
- Improves user experience by allowing retraction of false alarms
- Ensures efficient fund management within the system

### Updated Contract Functions
- Added `cancel-incident` to the list of write functions for cancelling incidents
