# TODO: Extend Channel System for Assignment Submissions

## Step 1: Create Assignment Model
- Create `lib/models/assignment.dart` with fields for assignment details (title, description, due date, etc.)
- Create `lib/models/submission.dart` with fields for submission details (user, file, status, grade, etc.)

## Step 2: Create Assignment Service
- Create `lib/services/assignment_service.dart` for managing assignments and submissions
- Implement methods for creating assignments, submitting work, grading, etc.

## Step 3: Update HubMessagingService for Assignment Channels
- Add support for 'assignment' channel type in `lib/services/chat/hub_messaging_service.dart`
- Modify createChannel to accept assignment-specific parameters

## Step 4: Update HubPage UI for Assignment Channels
- Modify `lib/pages/hub_page.dart` to display assignment channels differently (e.g., different icon)
- Add assignment creation dialog for moderators
- Add submission interface for students
- Add grading interface for moderators

## Step 5: Update Channel Creation Dialog
- Modify the channel creation dialog in HubPage to include 'assignment' type option
- Add fields for due date and description when creating assignment channels

## Step 6: Implement File Upload for Submissions
- Add file upload functionality in assignment service and UI
- Use Firebase Storage for file handling

## Step 7: Add Submission Status Tracking
- Implement status tracking (not submitted, submitted, graded) in submission model and service
- Update UI to show submission status

## Step 8: Testing and Integration
- Test all new features
- Ensure integration with existing messaging system
- Handle edge cases (e.g., late submissions, multiple submissions)
