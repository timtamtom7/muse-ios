# Muse R12 — Social & Collaborative Features

## Overview
R12 adds social listening features, friend activity feeds, and collaborative playlist capabilities.

## Features

### 👥 Friend Activity
- **Live Listening Status**: See what friends are playing in real-time
- **Activity Feed**: Recent plays, new playlists, milestones
- **Reaction System**: Quick reactions to what friends are playing
- **Private Listening Mode**: Opt-out of sharing individual plays

### 🎸 Collaborative Playlists
- **Invite Friends to Playlist**: Multi-user shared playlists
- **Contribution Permissions**: Owner can set who can add/remove tracks
- **Chat in Playlist**: Comment on tracks in the playlist
- **Voting on Tracks**: Upvote/downvote suggestions in party mode

### 📍 Location Features
- **See Friends Nearby**: Find friends listening to music nearby
- **Location-Based Playlists**: "Music from this city" recommendations
- **Share Current Vibe**: Broadcast what you're listening to publicly

## Technical Approach

### Architecture
```
- WebSocket connection for real-time friend activity
- CloudKit or Firebase for cross-device sync
- End-to-end encryption for private data
- Push notifications for social events
```

### Data Models
- `User`: id, display_name, avatar_url, is_private
- `FriendConnection`: user_id, friend_id, status (pending/accepted)
- `ActivityItem`: user_id, track_id, activity_type, timestamp
- `CollaborativePlaylist`: playlist_id, owner_id, collaborator_ids[], permissions

## Implementation Phases

### Phase 1: Friend System
- [ ] User profile creation and management
- [ ] Friend request and acceptance flow
- [ ] Block/report functionality

### Phase 2: Activity Feed
- [ ] Activity service with WebSocket
- [ ] Activity feed UI with real-time updates
- [ ] Reaction quick-actions

### Phase 3: Collaboration
- [ ] Collaborative playlist data model
- [ ] Real-time sync with CloudKit
- [ ] Contribution permission system

## Privacy Controls
- Granular privacy settings per feature
- Block list management
- Activity visibility controls
- Data export and deletion

## Success Metrics
- 30% of users make at least one friend connection
- Collaborative playlists have 2+ contributors on average
- 25% weekly active rate for social features
