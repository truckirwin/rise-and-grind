# Job Seeker Companion - Technical Architecture

## 1. Business Model Update

### Pricing Strategy
- **App Store**: One-time purchase ($9.99)
- **In-App Purchases** (via web portal):
  - Monthly subscription: $4.99/month
  - Annual subscription: $39.99/year (33% discount)
  - Premium content packs: $2.99 each
  - Online seminars: $19.99-$49.99
  - Tips & tricks guides: $4.99

### Revenue Streams
1. **Initial App Purchase**: Core features included
2. **Web Portal Subscriptions**: Premium features, unlimited messages, advanced analytics
3. **Educational Content**: Seminars, workshops, guides
4. **Corporate Packages**: B2B enterprise licensing

## 2. LinkedIn API Capabilities

### Current LinkedIn API Limitations
Based on my research, LinkedIn has **restricted** most third-party API access:

1. **No Direct Activity Analytics**: LinkedIn does not provide APIs for:
   - User engagement metrics
   - Post performance data
   - Connection growth tracking
   - Profile view statistics

2. **Available APIs** (Limited):
   - **Sign In with LinkedIn**: OAuth authentication only
   - **Share on LinkedIn**: Post content (limited)
   - **Member Profile API**: Basic profile data (restricted access)

3. **Analytics APIs**: Only available for:
   - LinkedIn Pages (company pages)
   - LinkedIn Ads
   - Sales Navigator (enterprise only)

### Alternative Approach
Since direct LinkedIn API integration is limited, we'll implement:

1. **Manual Tracking**: Users self-report LinkedIn activities
2. **Smart Reminders**: Prompt users to perform LinkedIn tasks
3. **Chrome Extension** (Future): Track LinkedIn activity client-side
4. **Screenshot Analysis** (Future): AI-powered activity detection

## 3. Security Architecture

### Authentication & Authorization
```
┌─────────────────────────────────────────┐
│           iOS App                       │
├─────────────────────────────────────────┤
│  - Biometric Authentication (Face ID)   │
│  - PIN Backup                          │
│  - Keychain Storage                    │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│         Auth Service (Backend)          │
├─────────────────────────────────────────┤
│  - JWT Token Generation                 │
│  - Refresh Token Management             │
│  - Multi-factor Authentication         │
│  - Session Management                   │
└─────────────────────────────────────────┘
```

### Data Security
- **Encryption at Rest**: AES-256 for local storage
- **Encryption in Transit**: TLS 1.3
- **Key Management**: iOS Keychain Services
- **Data Minimization**: Store only essential data
- **GDPR Compliance**: User data export/deletion

## 4. Payment Processing Architecture

### App Store Purchase
```swift
// StoreKit 2 Implementation
class PurchaseManager: ObservableObject {
    @Published var hasUnlockedApp = false
    
    func purchaseApp() async throws {
        let products = try await Product.products(for: ["com.jobseeker.companion.unlock"])
        guard let product = products.first else { return }
        
        let result = try await product.purchase()
        // Handle purchase result
    }
}
```

### Web Portal Subscription (Stripe Integration)
```javascript
// Backend API
app.post('/api/subscriptions/create', async (req, res) => {
    const { userId, planId } = req.body;
    
    const subscription = await stripe.subscriptions.create({
        customer: userId,
        items: [{ price: planId }],
        payment_settings: {
            payment_method_types: ['card'],
            save_default_payment_method: 'on_subscription'
        }
    });
    
    // Update user subscription in database
    await updateUserSubscription(userId, subscription);
});
```

## 5. iOS Development & Testing

### Development Testing Methods

#### 1. **Xcode Simulator**
- Test on various iPhone models
- Quick iteration during development
- Limited for hardware features (camera, biometrics simulation)

#### 2. **Physical Device Testing**
- Connect iPhone via USB
- Enable Developer Mode on device
- Real-world performance testing

#### 3. **TestFlight (Recommended)**
```
Process:
1. Archive app in Xcode
2. Upload to App Store Connect
3. Internal Testing: Up to 100 testers (90 days)
4. External Testing: Up to 10,000 testers (90 days)
5. Collect feedback and crash reports
```

#### 4. **Ad Hoc Distribution**
- For specific devices (up to 100)
- Requires device UDIDs
- Good for client demos

### Development Setup
```bash
# Install dependencies
brew install node
npm install -g react-native-cli

# iOS specific
sudo gem install cocoapods
cd ios && pod install

# Run on simulator
npx react-native run-ios

# Run on device
npx react-native run-ios --device "iPhone Name"
```

## 6. System Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────┐
│              iOS App                    │
│  ┌─────────────┬──────────────────┐    │
│  │   SwiftUI   │  Core Data        │    │
│  │   Views     │  (Local DB)       │    │
│  └─────┬───────┴──────────────────┘    │
│        │                                │
│  ┌─────▼────────────────────────────┐  │
│  │   Business Logic Layer           │  │
│  │   - Task Management              │  │
│  │   - Progress Tracking            │  │
│  │   - Notification Engine          │  │
│  └─────────────┬────────────────────┘  │
└────────────────┼───────────────────────┘
                 │
                 ▼ HTTPS/REST
┌─────────────────────────────────────────┐
│           Backend Services              │
├─────────────────────────────────────────┤
│  Node.js + Express                      │
│  ┌─────────────┬──────────────────┐    │
│  │   API       │  Auth Service     │    │
│  │   Gateway   │  (JWT)            │    │
│  └─────┬───────┴──────────────────┘    │
│        │                                │
│  ┌─────▼────────────────────────────┐  │
│  │   PostgreSQL Database            │  │
│  │   - Users, Tasks, Progress       │  │
│  │   - Messages, Analytics          │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │   Redis Cache                    │  │
│  │   - Session Management           │  │
│  │   - Rate Limiting                │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│         Web Portal (Admin + User)       │
├─────────────────────────────────────────┤
│  React.js + Next.js                     │
│  - Subscription Management              │
│  - Content Management                   │
│  - Analytics Dashboard                  │
└─────────────────────────────────────────┘
```

## 7. Database Schema (Updated)

### Users Table (Extended)
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Subscription fields
    app_purchased BOOLEAN DEFAULT FALSE,
    app_purchase_date TIMESTAMP,
    subscription_tier ENUM('free', 'premium', 'enterprise'),
    subscription_status ENUM('active', 'cancelled', 'expired'),
    subscription_expires_at TIMESTAMP,
    stripe_customer_id VARCHAR(255),
    
    -- Profile fields
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    timezone VARCHAR(50),
    notification_preferences JSONB,
    onboarding_completed BOOLEAN DEFAULT FALSE,
    
    -- Security
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    last_login_at TIMESTAMP,
    login_attempts INT DEFAULT 0
);
```

### LinkedIn Activities Table (Manual Tracking)
```sql
CREATE TABLE linkedin_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    activity_date DATE NOT NULL,
    
    -- LinkedIn metrics (self-reported)
    connections_sent INT DEFAULT 0,
    messages_sent INT DEFAULT 0,
    posts_created INT DEFAULT 0,
    comments_made INT DEFAULT 0,
    articles_shared INT DEFAULT 0,
    profile_views INT,
    post_impressions INT,
    
    -- Calculated metrics
    engagement_score DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Purchases Table
```sql
CREATE TABLE purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    product_type ENUM('app', 'subscription', 'content', 'seminar'),
    product_id VARCHAR(255),
    amount DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'USD',
    payment_method ENUM('app_store', 'stripe', 'paypal'),
    transaction_id VARCHAR(255),
    status ENUM('pending', 'completed', 'failed', 'refunded'),
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 8. API Endpoints (Extended)

### Authentication
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/auth/refresh
POST   /api/auth/verify-2fa
DELETE /api/auth/delete-account
```

### Subscription Management
```
GET    /api/subscriptions/status
POST   /api/subscriptions/create
PUT    /api/subscriptions/update
DELETE /api/subscriptions/cancel
POST   /api/subscriptions/webhook (Stripe webhook)
```

### LinkedIn Tracking (Manual)
```
POST   /api/linkedin/activities
GET    /api/linkedin/activities?date=
GET    /api/linkedin/analytics/weekly
GET    /api/linkedin/analytics/monthly
```

### Purchase Management
```
POST   /api/purchases/verify-app-store
GET    /api/purchases/history
POST   /api/purchases/content/:contentId
GET    /api/purchases/available-content
```

## 9. Implementation Timeline

### Phase 1: MVP (Months 1-3)
- ✅ Core iOS app with basic features
- ✅ User authentication
- ✅ Daily motivation system
- ✅ Task tracking
- ✅ Progress rings
- ✅ TestFlight beta

### Phase 2: Monetization (Months 4-5)
- 🔄 App Store listing ($9.99)
- 🔄 Web portal development
- 🔄 Stripe integration
- 🔄 Subscription management
- 🔄 Content delivery system

### Phase 3: Enhancement (Months 6-8)
- 📋 LinkedIn manual tracking
- 📋 Advanced analytics
- 📋 AI-powered insights
- 📋 Corporate packages
- 📋 Chrome extension planning

## 10. Testing Strategy

### Local Development
```bash
# iOS Simulator
xcrun simctl list devices
open -a Simulator

# Physical Device
# 1. Connect iPhone via USB
# 2. Trust computer on device
# 3. Select device in Xcode
# 4. Build and run
```

### TestFlight Setup
1. **App Store Connect**
   - Create app record
   - Set up TestFlight
   - Add test information

2. **Build Upload**
   ```bash
   # Archive in Xcode
   Product > Archive
   
   # Upload to App Store Connect
   Window > Organizer > Distribute App
   ```

3. **Tester Management**
   - Internal: Apple Developer team members
   - External: Email invitations
   - Feedback collection via TestFlight app

### Beta Testing Plan
- **Week 1-2**: Internal testing (5-10 testers)
- **Week 3-4**: Friends & family (20-30 testers)
- **Week 5-8**: Public beta (100-500 testers)
- **Week 9-12**: Final refinements

## Next Steps

1. **Immediate Actions**
   - Set up Apple Developer account ($99/year)
   - Create App Store Connect profile
   - Initialize Xcode project
   - Set up TestFlight

2. **Development Priorities**
   - Core motivation engine
   - Task management system
   - Progress tracking
   - Push notifications

3. **Business Setup**
   - Register business entity
   - Set up Stripe account
   - Create privacy policy
   - Prepare App Store assets

Would you like me to start creating the actual iOS app structure or focus on any specific component first? 