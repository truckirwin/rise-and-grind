# Job Seeker Companion - Security Implementation

## User Authentication System

### 1. Registration Flow

```swift
// iOS Implementation
struct RegistrationView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    
    private func registerUser() async {
        // Validate inputs
        guard validateEmail(email),
              validatePassword(password),
              password == confirmPassword,
              agreedToTerms else { return }
        
        // Hash password locally before sending
        let hashedPassword = hashPassword(password)
        
        // Send to backend
        do {
            let response = try await APIClient.shared.register(
                email: email,
                passwordHash: hashedPassword
            )
            
            // Store tokens securely
            KeychainManager.shared.saveTokens(response.tokens)
            
            // Enable biometric authentication
            await setupBiometrics()
        } catch {
            // Handle errors
        }
    }
}
```

### 2. Biometric Authentication

```swift
import LocalAuthentication

class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    
    func authenticateUser() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else {
            return false
        }
        
        // Perform authentication
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Access your job search companion"
            )
            return success
        } catch {
            return false
        }
    }
}
```

### 3. Keychain Storage

```swift
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.jobseeker.companion"
    
    func saveTokens(_ tokens: AuthTokens) throws {
        // Save access token
        try save(
            key: "access_token",
            value: tokens.accessToken.data(using: .utf8)!
        )
        
        // Save refresh token
        try save(
            key: "refresh_token",
            value: tokens.refreshToken.data(using: .utf8)!
        )
    }
    
    private func save(key: String, value: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
}
```

### 4. JWT Token Management

```javascript
// Backend Implementation (Node.js)
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

class AuthService {
    generateTokens(userId) {
        const accessToken = jwt.sign(
            { 
                userId, 
                type: 'access',
                jti: crypto.randomUUID()
            },
            process.env.JWT_SECRET,
            { 
                expiresIn: '15m',
                issuer: 'jobseeker-companion',
                audience: 'ios-app'
            }
        );
        
        const refreshToken = jwt.sign(
            { 
                userId, 
                type: 'refresh',
                jti: crypto.randomUUID()
            },
            process.env.JWT_REFRESH_SECRET,
            { 
                expiresIn: '30d',
                issuer: 'jobseeker-companion',
                audience: 'ios-app'
            }
        );
        
        return { accessToken, refreshToken };
    }
    
    async verifyToken(token, type = 'access') {
        const secret = type === 'access' 
            ? process.env.JWT_SECRET 
            : process.env.JWT_REFRESH_SECRET;
            
        try {
            const decoded = jwt.verify(token, secret, {
                issuer: 'jobseeker-companion',
                audience: 'ios-app'
            });
            
            // Check if token is blacklisted
            const isBlacklisted = await redis.exists(`blacklist:${decoded.jti}`);
            if (isBlacklisted) {
                throw new Error('Token has been revoked');
            }
            
            return decoded;
        } catch (error) {
            throw new Error('Invalid token');
        }
    }
}
```

### 5. Two-Factor Authentication

```swift
// iOS Implementation
import SwiftOTP

class TwoFactorAuthManager {
    static let shared = TwoFactorAuthManager()
    
    func generateSecret() -> String {
        // Generate random secret
        return base32Encode(randomData(length: 20))
    }
    
    func generateQRCode(for email: String, secret: String) -> UIImage? {
        let otpAuthURL = "otpauth://totp/JobSeeker:\(email)?secret=\(secret)&issuer=JobSeekerCompanion"
        
        guard let data = otpAuthURL.data(using: .utf8) else { return nil }
        
        let qrCode = CIFilter(name: "CIQRCodeGenerator")
        qrCode?.setValue(data, forKey: "inputMessage")
        
        if let outputImage = qrCode?.outputImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
    
    func verifyCode(_ code: String, secret: String) -> Bool {
        guard let totp = TOTP(secret: base32DecodeToData(secret)) else {
            return false
        }
        
        // Allow for time drift (30 seconds before and after)
        let now = Date()
        return totp.generate(time: now) == code ||
               totp.generate(time: now.addingTimeInterval(-30)) == code ||
               totp.generate(time: now.addingTimeInterval(30)) == code
    }
}
```

### 6. Session Management

```javascript
// Backend Session Management
class SessionManager {
    constructor(redisClient) {
        this.redis = redisClient;
        this.sessionTimeout = 30 * 60; // 30 minutes
    }
    
    async createSession(userId, deviceInfo) {
        const sessionId = crypto.randomUUID();
        const sessionData = {
            userId,
            deviceInfo,
            createdAt: new Date().toISOString(),
            lastActivity: new Date().toISOString()
        };
        
        await this.redis.setex(
            `session:${sessionId}`,
            this.sessionTimeout,
            JSON.stringify(sessionData)
        );
        
        // Track user sessions
        await this.redis.sadd(`user:${userId}:sessions`, sessionId);
        
        return sessionId;
    }
    
    async validateSession(sessionId) {
        const sessionData = await this.redis.get(`session:${sessionId}`);
        if (!sessionData) {
            throw new Error('Invalid session');
        }
        
        const session = JSON.parse(sessionData);
        
        // Update last activity
        session.lastActivity = new Date().toISOString();
        await this.redis.setex(
            `session:${sessionId}`,
            this.sessionTimeout,
            JSON.stringify(session)
        );
        
        return session;
    }
    
    async revokeAllSessions(userId) {
        const sessions = await this.redis.smembers(`user:${userId}:sessions`);
        
        for (const sessionId of sessions) {
            await this.redis.del(`session:${sessionId}`);
        }
        
        await this.redis.del(`user:${userId}:sessions`);
    }
}
```

### 7. Rate Limiting

```javascript
// Rate limiting middleware
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

const createRateLimiter = (options) => {
    return rateLimit({
        store: new RedisStore({
            client: redis,
            prefix: 'rate-limit:'
        }),
        windowMs: options.windowMs || 15 * 60 * 1000, // 15 minutes
        max: options.max || 100,
        message: 'Too many requests, please try again later',
        standardHeaders: true,
        legacyHeaders: false,
        handler: (req, res) => {
            res.status(429).json({
                error: 'Too many requests',
                retryAfter: res.getHeader('Retry-After')
            });
        }
    });
};

// Different limits for different endpoints
const authLimiter = createRateLimiter({ 
    windowMs: 15 * 60 * 1000, 
    max: 5 // 5 attempts per 15 minutes
});

const apiLimiter = createRateLimiter({ 
    windowMs: 1 * 60 * 1000, 
    max: 60 // 60 requests per minute
});
```

### 8. Data Encryption

```swift
// iOS Data Encryption
import CryptoKit

class DataEncryption {
    static let shared = DataEncryption()
    
    private let key: SymmetricKey
    
    init() {
        // Generate or retrieve encryption key from Keychain
        if let keyData = KeychainManager.shared.getEncryptionKey() {
            self.key = SymmetricKey(data: keyData)
        } else {
            self.key = SymmetricKey(size: .bits256)
            KeychainManager.shared.saveEncryptionKey(key.dataRepresentation)
        }
    }
    
    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(_ encryptedData: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func encryptString(_ string: String) throws -> String {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        
        let encrypted = try encrypt(data)
        return encrypted.base64EncodedString()
    }
    
    func decryptString(_ encryptedString: String) throws -> String {
        guard let data = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.invalidInput
        }
        
        let decrypted = try decrypt(data)
        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        return string
    }
}
```

### 9. Secure API Communication

```swift
// iOS API Client with Certificate Pinning
class SecureAPIClient {
    static let shared = SecureAPIClient()
    
    private let session: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        self.session = URLSession(
            configuration: configuration,
            delegate: PinningDelegate(),
            delegateQueue: nil
        )
    }
    
    func request<T: Decodable>(
        _ endpoint: APIEndpoint,
        type: T.Type
    ) async throws -> T {
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add authentication header
        if let token = KeychainManager.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add security headers
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        request.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "X-App-Bundle")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Certificate Pinning
class PinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Verify certificate
        let policies = [SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)]
        SecTrustSetPolicies(serverTrust, policies as CFArray)
        
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        
        guard isValid else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Pin certificate
        if let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {
            let serverCertificateData = SecCertificateCopyData(serverCertificate) as Data
            let pinnedCertificateData = loadPinnedCertificate()
            
            if serverCertificateData == pinnedCertificateData {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

### 10. Security Monitoring

```javascript
// Backend Security Monitoring
class SecurityMonitor {
    constructor(logger, alertService) {
        this.logger = logger;
        this.alertService = alertService;
    }
    
    async logSecurityEvent(event) {
        const enrichedEvent = {
            ...event,
            timestamp: new Date().toISOString(),
            eventId: crypto.randomUUID()
        };
        
        // Log to security audit trail
        await this.logger.security(enrichedEvent);
        
        // Check for suspicious patterns
        await this.analyzeThreat(enrichedEvent);
    }
    
    async analyzeThreat(event) {
        // Failed login attempts
        if (event.type === 'failed_login') {
            const attempts = await this.getRecentFailedAttempts(event.userId);
            if (attempts >= 5) {
                await this.alertService.send({
                    type: 'security_alert',
                    severity: 'high',
                    message: `Multiple failed login attempts for user ${event.userId}`,
                    action: 'account_locked'
                });
                
                await this.lockAccount(event.userId);
            }
        }
        
        // Suspicious location
        if (event.type === 'login' && event.location) {
            const isNewLocation = await this.isNewLocation(
                event.userId, 
                event.location
            );
            
            if (isNewLocation) {
                await this.alertService.send({
                    type: 'security_alert',
                    severity: 'medium',
                    message: `New login location detected for user ${event.userId}`,
                    location: event.location
                });
            }
        }
    }
}
```

## Security Best Practices Checklist

- [ ] All passwords hashed with bcrypt (cost factor 12+)
- [ ] JWT tokens expire after 15 minutes (access) / 30 days (refresh)
- [ ] Biometric authentication enabled by default
- [ ] Certificate pinning for API communications
- [ ] Rate limiting on all endpoints
- [ ] Security headers (HSTS, CSP, etc.) on all responses
- [ ] Regular security audits and penetration testing
- [ ] Encryption at rest for sensitive data
- [ ] Secure key storage using iOS Keychain
- [ ] Session timeout after 30 minutes of inactivity
- [ ] Two-factor authentication available
- [ ] Security event logging and monitoring
- [ ] GDPR compliance for data handling
- [ ] Regular dependency updates
- [ ] Input validation on all user inputs 