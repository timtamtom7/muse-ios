# Muse R11 — AI Music Intelligence

## Overview
R11 focuses on AI-powered music recommendations, playlist generation, and listening insights.

## Features

### 🎵 AI Music Recommendations
- **Smart Recommendations**: Analyze listening history and suggest new tracks
- **Mood-Based Playlists**: Generate playlists based on time of day, weather, activity
- **Similar Artists Discovery**: Find new artists similar to favorites
- **Rediscover Old Favorites**: Surface tracks from library not played recently

### 📝 Playlist Generator
- **Text-to-Playlist**: "Create a playlist for a road trip"
- **AI-Curated Themes**: Working out, studying, dinner party, etc.
- **Automatic Playlist Updates**: Add new songs to existing playlists based on taste
- **Playlist Cover Generation**: AI-generated artwork for playlists

### 📊 Listening Insights
- **Listening Stats Dashboard**: Total minutes, top genres, peak listening hours
- **Weekly/Monthly Reports**: Summary of listening habits
- **Genre Distribution**: Visual breakdown of music tastes
- **Discovery Rate**: How many new artists/songs per week

## Technical Approach

### AI Service Integration
```
- Use Apple Music API or Spotify Web API for catalog access
- Implement recommendation engine with CoreML or external AI service
- Store listening history in local SQLite database
- Privacy-first: all processing happens on-device when possible
```

### Data Models
- `ListeningHistory`: track_id, timestamp, play_duration, completion_rate
- `Recommendation`: track, score, reason, source_playlist
- `PlaylistTemplate`: name, description, seed_tracks, ai_generated_bool

## Implementation Phases

### Phase 1: Foundations
- [ ] Listening history tracking service
- [ ] Basic stats calculation engine
- [ ] Stats dashboard UI

### Phase 2: AI Integration  
- [ ] AI service abstraction layer
- [ ] Recommendation algorithm implementation
- [ ] Playlist generator with templates

### Phase 3: Polish
- [ ] Onboarding flow for insights
- [ ] Push notification for "Rediscover" suggestions
- [ ] Export stats as shareable image

## Success Metrics
- User opens insights 3+ times per week
- 50% of generated playlists have 3+ tracks added
- 80% recommendation acceptance rate
