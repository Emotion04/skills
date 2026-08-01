---
name: custom-voiceover
description: Custom voiceover (自定义口播) feature for video editing — transcribe speech, split video by subtitle segments, drag-and-drop timeline reordering, mix with background audio, batch output. Also covers random shuffle mix and AI-scored smart clip modes. Use when user mentions 自定义口播, voiceover, 口播, narration, TTS video, subtitle-based video editing, speech transcription video, 按字幕切分, 混剪口播, or multi-video clip merging.
---

# Custom Voiceover (自定义口播)

> **⚠️ Before implementing, read [references/REFERENCE.md](references/REFERENCE.md).** It contains FFmpeg commands, common pitfalls, implementation checklist, and testing strategy that this overview references.

Transcribe speech in videos → split by subtitle segments → drag to timeline → remix with background audio → output final video. Supports three editing modes.

## Editing Modes

| Tab | `edit_mode` | Input | Behavior |
|-----|-------------|-------|----------|
| **Random Mix** | `"random"` | Videos only | Chop into fixed-duration chunks → shuffle → merge to target duration |
| **AI Clip** | `"ai"` | Videos + text | Extract frames → AI scores each frame → select clips around top frames → merge |
| **Voiceover** | `"ordered"` | Videos (+ optional SRT) | Drag subtitle items to timeline → extract clips in exact order → merge (no duration limit) |

## Custom Voiceover Workflow

### Step 1: Upload
User drags/selects multiple `.mov`/`.mp4` files → `selectedFiles[]`.

### Step 2: Acquire Subtitles
**Path A — Upload SRT/TXT**: Parse external subtitle file → `POST /api/srt/parse` → `videoSubtitles[filename]`.
**Path B — Auto-transcribe (Whisper)**: Extract audio (16kHz mono) → local Whisper model → Traditional→Simplified Chinese → `POST /api/srt/transcribe` → `videoSubtitles[filename]`.
**Path C — Mixed**: Upload SRT for some videos, auto-transcribe others.

### Step 3: Subtitle Cards
Each video gets a collapsible card with numbered, draggable subtitle items carrying `data-video-name`, `data-start`, `data-end`, `data-text` attributes. Search box filters in real-time.

### Step 4: Drag-and-Drop Timeline
User drags subtitle items into the timeline. Supports reorder (drag within timeline) and remove (click ✕). `timelineItems[]` array updates on each change.

### Step 5: Submit & Process
`POST /api/process-video-stream` (SSE) with `ordered_clips_json`. Backend resolves `video_map`, extracts each clip via FFmpeg, concats in order, optionally burns subtitle overlay, returns video URL via SSE events.

### Step 6: Subtitle Overlay (optional)
When "烧录字幕" is checked: generate SRT from ordered clips → FFmpeg `subtitles` filter with Microsoft YaHei font, white text, black outline.

## Key Data Structures

```js
// Per-video subtitles
videoSubtitles = {
  "video1.mp4": {
    videoName: "video1.mp4",
    subtitles: [{index: 1, start: 0.0, end: 3.5, text: "大家好", duration: 3.5}, ...]
  }
}

// User's ordered clip sequence
timelineItems = [
  {id: "tl_xxx", videoName: "video1.mp4", text: "...", start: 7.2, end: 12.0, subtitleIndex: 3},
  ...
]
```

## API Design

```
POST /api/process-video-stream (SSE)
  FormData: query, edit_mode, ordered_clips_json, add_subtitles, files[]

SSE Events:
  step          → {agent, message, status}
  step_progress → {key, message}         // FFmpeg progress %
  result        → {status, video_url}
  done          → {status, message}
```

## Core Modules

| Module | File | Role |
|--------|------|------|
| STT | `hengline/tool/stt_tool.py` | Whisper transcription (faster-whisper → whisper → Google fallback) |
| SRT Parser | `hengline/tool/srt_parser.py` | SRT parsing, generation, short-segment merging |
| TTS | `hengline/tool/tts_tool.py` | Edge TTS (free) / GPT-SoVITS (voice cloning) |
| Video Route | `hengline/flask/video_route.py` | `_random_mix`, `_ordered_subtitle_mix`, `_ai_smart_mix` |
| Background Audio | `utils/background_audio_utils.py` | BGM at 30% volume, loop to match duration |

## Implementation Details

See [references/REFERENCE.md](references/REFERENCE.md) for:
- Complete FFmpeg commands (audio extraction, video splitting, concat two-tier strategy, background audio mixing, subtitle overlay)
- Step-by-step implementation with code snippets
- Word-density filtering, duration trimming, duplicate submit prevention
- 8 common pitfalls with fixes
- Full implementation checklist (19 items)
- Testing strategy (10 test cases)
- Frontend details (two-column layout, toast system, FFmpeg real-time progress, mode switching)
- Troubleshooting guide
