# Blood Donation App - Donation Tracking System

## Overview

The donation tracking system allows users to record and monitor their blood donation history. This feature helps users keep track of their donations, view statistics, and know when they are eligible to donate again.

## Features

### 1. Donation Tracker

The Donation Tracker screen allows users to:

- **Add new donations**: Record the date and location of each blood donation
- **View donation history**: See a chronological list of all past donations
- **Delete donations**: Remove incorrect or duplicate donation records
- **Track eligibility**: The system automatically updates the user's eligibility status based on their donation history

### 2. Donation Statistics

The Statistics screen provides users with insights about their donation history:

- **Summary statistics**: Total donations, first donation date, yearly average, and potential lives saved
- **Yearly breakdown**: Visual chart showing donations by year
- **Favorite locations**: List of most frequently visited donation centers
- **Impact metrics**: Information about the total volume of blood donated and lives potentially saved

### 3. Profile Integration

The user's profile page displays:

- **Eligibility status**: Clear indication of whether the user is eligible to donate
- **Last donation date**: Date of the most recent donation
- **Days until eligible**: For users who have donated recently, the number of days until they can donate again
- **Quick access**: Button to access the donation tracking system

## Technical Implementation

The donation tracking system is implemented using:

- **Firebase Firestore**: Stores donation records in a subcollection under each user document
- **Flutter UI**: Modern, user-friendly interface with charts and statistics
- **Date calculations**: Automatically determines eligibility based on the 3-month waiting period between donations

## Usage

1. From the profile page, tap "Manage Donation History"
2. To add a donation:
   - Select the date of your donation
   - Enter the location (hospital or blood bank)
   - Tap "Add Donation Record"
3. To view statistics, tap the chart icon in the top-right corner of the Donation Tracker screen
4. To delete a donation, swipe left on the donation record or tap the delete icon

## Future Enhancements

Potential future improvements to the donation tracking system:

- Reminders for when the user becomes eligible to donate again
- Integration with blood bank systems for automatic donation recording
- Social sharing features to encourage others to donate
- Gamification elements like badges and achievements for donation milestones
