# Job Seeker Companion App - Technical Structure

## App Architecture Overview

```
JobSeekerCompanion/
├── iOS_App/
│   ├── Core/
│   │   ├── Models/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   ├── Services/
│   │   └── Utils/
│   ├── Features/
│   │   ├── Onboarding/
│   │   ├── Dashboard/
│   │   ├── Tasks/
│   │   ├── Progress/
│   │   ├── LearningPaths/
│   │   └── Settings/
│   └── Resources/
├── Backend/
│   ├── API/
│   ├── Database/
│   ├── Services/
│   └── Admin/
└── Shared/
    └── Constants/
```

## Database Schema

### Users Table
```sql
- id (UUID)
- email (string)
- created_at (timestamp)
- onboarding_completed (boolean)
- subscription_tier (enum: free, premium)
- notification_preferences (json)
- timezone (string)
```

### Daily_Messages Table
```sql
- id (UUID)
- message_text (text)
- category (enum: morning, midday, evening, task_complete)
- tone (enum: tough_love, encouraging, linkedin_focused, weekend)
- is_active (boolean)
- usage_count (integer)
```

### User_Tasks Table
```sql
- id (UUID)
- user_id (FK)
- task_template_id (FK)
- date (date)
- status (enum: pending, completed, skipped)
- completed_at (timestamp)
- category (enum: job_search, physical_health, mental_health)
```

### Task_Templates Table
```sql
- id (UUID)
- title (string)
- description (text)
- category (enum)
- estimated_time_minutes (integer)
- difficulty (enum: easy, medium, hard)
```

### Progress_Records Table
```sql
- id (UUID)
- user_id (FK)
- date (date)
- hustle_ring_value (integer 0-100)
- health_ring_value (integer 0-100)
- mind_ring_value (integer 0-100)
- streak_count (integer)
```

### Learning_Paths Table
```sql
- id (UUID)
- title (string)
- description (text)
- difficulty_level (enum: beginner, intermediate, advanced)
- estimated_duration_days (integer)
- price (decimal)
- subscription_tier_required (enum: free, premium, expert)
- is_active (boolean)
- created_at (timestamp)
```

### Learning_Modules Table
```sql
- id (UUID)
- learning_path_id (FK)
- title (string)
- description (text)
- order_index (integer)
- estimated_duration_minutes (integer)
```

### Learning_Lessons Table
```sql
- id (UUID)
- module_id (FK)
- title (string)
- content_type (enum: video, audio, text, interactive)
- content_url (string)
- content_text (text)
- order_index (integer)
- estimated_duration_minutes (integer)
- task_description (text)
- deliverables (json)
```

### User_Learning_Progress Table
```sql
- id (UUID)
- user_id (FK)
- learning_path_id (FK)
- current_lesson_id (FK)
- started_at (timestamp)
- completed_at (timestamp)
- completion_percentage (decimal)
- last_accessed_at (timestamp)
```

### Lesson_Completions Table
```sql
- id (UUID)
- user_id (FK)
- lesson_id (FK)
- completed_at (timestamp)
- task_completed (boolean)
- user_notes (text)
- rating (integer 1-5)
```

## Core Features Implementation

### 1. Morning Routine Flow
```
1. Alarm triggers → Show motivational message
2. User dismisses → Show daily dashboard
3. Display today's tasks (pre-populated)
4. User can modify/add tasks
5. Set one goal per category
6. Begin day tracking
```

### 2. Progress Rings Logic
```swift
// Ring completion calculation
Hustle Ring: (completed_job_tasks / total_job_tasks) * 100
Health Ring: (completed_health_tasks / total_health_tasks) * 100
Mind Ring: (completed_mind_tasks / total_mind_tasks) * 100

// Minimum daily targets
Hustle: 3 tasks
Health: 1 task
Mind: 1 task
```

### 3. Offline Sync Strategy
```
- Store 10 days of future tasks locally
- Cache last 30 days of progress
- Queue all user actions when offline
- Sync when connection restored
- Conflict resolution: Server wins for messages, Local wins for progress
```

## API Endpoints

### Authentication
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`

### User Data
- `GET /api/user/profile`
- `PUT /api/user/preferences`
- `GET /api/user/progress?start_date=&end_date=`

### Tasks
- `GET /api/tasks/daily?date=`
- `POST /api/tasks/complete`
- `PUT /api/tasks/update`
- `GET /api/tasks/templates`

### Messages
- `GET /api/messages/daily`
- `GET /api/messages/category/:category`

### Sync
- `POST /api/sync/upload`
- `GET /api/sync/download?last_sync=`

### Learning Paths
- `GET /api/learning-paths`
- `GET /api/learning-paths/:pathId`
- `POST /api/learning-paths/:pathId/enroll`
- `GET /api/learning-paths/:pathId/progress`
- `POST /api/lessons/:lessonId/complete`
- `GET /api/lessons/:lessonId/content`
- `PUT /api/learning-progress/:progressId`

## UI/UX Design Principles

### Screen Hierarchy
1. **Launch Screen** → Motivational message (2 seconds)
2. **Dashboard** → Three rings + Today's focus
3. **Task List** → Swipe to complete, tap to expand
4. **Progress History** → Calendar view with streaks
5. **Settings** → Minimal options, focus on essentials

### Visual Design
- **Color Palette:**
  - Primary: Deep Navy (#0A1628)
  - Accent: Energetic Orange (#FF6B35)
  - Success: Forest Green (#2D6A4F)
  - Background: Off-white (#FAFAFA)
  
- **Typography:**
  - Headers: SF Pro Display Bold
  - Body: SF Pro Text Regular
  - Motivational: SF Pro Display Black

### Animations
- Ring progress: Smooth circular animation
- Task completion: Satisfying check animation
- Screen transitions: Quick slide (200ms)
- No excessive animations or delays

## Notification Strategy

### Daily Schedule
- **6:00 AM - 9:00 AM:** Morning motivation (user set)
- **12:00 PM:** Lunch check-in
- **3:00 PM:** Afternoon boost
- **8:00 PM:** Evening reflection
- **10:00 PM:** Wind-down reminder

### Smart Notifications
- Detect user patterns and adjust timing
- Reduce frequency if user is active
- Increase support during inactive periods
- Weekend schedule differs from weekday

## Privacy & Security

### Data Collection
- Minimal: Only essential for app function
- Anonymous analytics
- No personal job search details stored
- Local-first approach

### Security Measures
- JWT tokens for API authentication
- SSL/TLS for all communications
- Biometric authentication option
- Data encryption at rest

## Performance Targets

- App launch: < 1.5 seconds
- Screen transitions: < 200ms
- Sync operation: < 3 seconds
- Offline capability: 10 days
- Battery impact: Minimal
- Storage: < 50MB

## Testing Strategy

### Unit Tests
- Business logic
- Data models
- Sync algorithms

### UI Tests
- User flows
- Accessibility
- Device compatibility

### Integration Tests
- API endpoints
- Database operations
- Offline/online transitions

## Deployment Plan

### Phase 1: MVP
- Basic features
- 10 beta testers
- 2-week testing period

### Phase 2: Soft Launch
- 100 users
- Gather feedback
- Fix critical issues

### Phase 3: Public Launch
- App Store release
- Marketing campaign
- Monitor metrics

## Success Metrics

### Technical
- Crash rate < 0.5%
- API response time < 500ms
- Sync success rate > 99%

### User Engagement
- DAU/MAU ratio > 50%
- Task completion rate > 60%
- 7-day retention > 40%

### Business
- Conversion to premium > 5%
- App Store rating > 4.5
- Monthly churn < 10% 