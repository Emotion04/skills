# Reference: Custom Voiceover — Implementation Details

## Full Voiceover Workflow (with code)

### Step 1: Upload Multiple Videos

```html
<input type="file" multiple accept=".mov,.mp4">
```
Files stored in `selectedFiles[]` array.

### Step 2A: Upload External SRT/TXT

```js
// User clicks "📄 上传SRT" → hidden file input → POST multipart
// Response: {success, count, subtitles: [{index,start,end,text,duration}], total_duration}
// Stored: videoSubtitles[file.name] = {videoPath:'', videoName:file.name, subtitles}
```

### Step 2B: Auto-transcribe with Whisper

```
POST /api/srt/transcribe (multipart: video=file, engine="faster-whisper", model="base", language="zh")
```

Backend per-video pipeline:
1. Extract audio: `ffmpeg -i video.mov -vn -acodec pcm_s16le -ar 16000 -ac 1 audio.wav`
2. Load local Whisper model from `data/models/faster-whisper-base/`
3. Transcribe → segments `[{start, end, text}, ...]`
4. Convert Traditional→Simplified Chinese (`opencc 't2s'`)
5. Return: `{success, subtitles, srt_path, txt_path, engine, model, language}`

### Step 3: Subtitle Cards Display

Each video gets a collapsible card. Each subtitle item has:
```
data-video-name="video1.mp4"
data-start="3.5"    data-end="7.2"
data-text="今天给大家推荐这条牛仔裤"
data-index="2"
```
Search filter: `item.style.display = text.includes(query) ? '' : 'none'`

### Step 4: Drag-and-Drop Timeline

- Native HTML5 DnD: `ondragstart="handleSubtitleDrag(event)"` → `JSON.parse` from `dataTransfer`
- Drop zone: `ondrop="handleTimelineDrop(event)"`
- Reorder within timeline: `handleTimelineReorderDrag/Drop`
- Remove: `removeTimelineItem(id)` → splice → re-render
- Total duration: `updateOrderedDuration()` called on every change

### Step 5: Submit and SSE Processing

```
FormData: query, edit_mode="ordered", ordered_clips_json, add_subtitles, files[]

Backend (_ordered_subtitle_mix):
  a. Parse ordered_clips_json
  b. Build video_map: {basename(vp): vp}
  c. For each clip: FFmpeg -ss start -i source -t dur → chunk (emit SSE progress)
  d. Concat all chunks → output.mp4
  e. If add_subtitles: generate SRT → ffmpeg subtitles filter
  f. Clean up temp chunks
```

### Step 6: Subtitle Overlay FFmpeg

```bash
ffmpeg -i merged.mp4 \
  -vf "subtitles='overlay.srt':force_style='FontName=Microsoft YaHei,FontSize=22,\
PrimaryColour=&H00FFFFFF,OutlineColour=&H80000000,Outline=2,Alignment=2,MarginV=30'" \
  -c:v libx264 -preset ultrafast -crf 23 -c:a copy output_subbed.mp4
```

---

## Critical FFmpeg Commands

### Audio Extraction for STT

```python
cmd = [ffmpeg, '-y', '-i', video_path,
    '-vn', '-acodec', 'pcm_s16le', '-ar', '16000', '-ac', '1', output_path]
```
16kHz mono PCM WAV — required by Whisper. Different sample rates degrade quality.

### Video Splitting by Subtitle Timestamps

```python
cmd = [ffmpeg, '-y',
    '-ss', str(start_t), '-i', video_path,  # -ss before -i = fast seek
    '-t', str(dur),
    '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '28',
    '-c:a', 'aac', '-b:a', '128k',
    '-pix_fmt', 'yuv420p', '-movflags', '+faststart', output_path]
```
Skip clips < 0.5s. `-ss` before `-i` uses keyframe-based fast seek.

### Concat: Two-Tier Strategy

**Tier 1 — Concat demuxer (fast, no re-encode):**
```python
with open(concat_list, 'w') as f:
    for clip in clips:
        f.write(f"file '{clip.replace(chr(92), '/')}'\n")
cmd = [ffmpeg, '-y', '-f', 'concat', '-safe', '0', '-i', concat_list,
    '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '23',
    '-c:a', 'aac', '-b:a', '128k', '-pix_fmt', 'yuv420p', output_path]
```

**Tier 2 — Pairwise concat filter (handles mismatched codecs):**
```python
cmd = [ffmpeg, '-y', '-i', temp_merged, '-i', next_clip,
    '-filter_complex', '[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[outv][outa]',
    '-map', '[outv]', '-map', '[outa]',
    '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '28', output_path]
```

### Duration Trimming

```python
if target_duration > 0 and actual_dur > target_duration + 2:
    cmd = [ffmpeg, '-y', '-i', output, '-t', str(target_duration), '-c', 'copy', trimmed]
```
Only trim if overshoot > 2s. Uses `-c copy` (no re-encode).

### Background Audio Mixing

```python
cmd = [ffmpeg, "-y",
    "-i", video_path,
    "-stream_loop", "-1", "-i", bgm_path,  # loop infinitely
    "-filter_complex", f"[1:a]atrim=duration={dur}[bg];[bg]volume=0.3[out]",
    "-map", "0:v", "-map", "[out]",
    "-c:v", "copy", "-c:a", "aac", "-ar", "44100", "-ac", "2", "-b:a", "128k",
    "-shortest", output_path]
```
BGM at 30% volume. `-stream_loop -1` loops audio. `-shortest` stops at video end.

---

## Whisper Word-Density Filtering

```python
for seg in stt_result.get('segments', []):
    dur = seg['end'] - seg['start']
    words = len(seg.get('text', ''))
    density = words / max(dur, 0.5)
    if density >= 1.0:
        clip_points[video_path].append((seg['start'], seg['end']))
```
Filters out pauses, filler words ("嗯", "啊"), and silent gaps.

---

## Common Pitfalls

### 1. Silent Fake Data on Tool Failure
```python
# BAD: returns fake data
except: return [(0.0, 5.0), (5.0, 10.0)]
# GOOD: raise exception
except Exception as e: raise RuntimeError(f"Failed: {e}")
```

### 2. Shell Command for Timestamp
```python
# BAD: blocks, Windows-only
timestamp = os.popen('echo %time%').read().strip()
# GOOD: pure Python
from datetime import datetime
timestamp = datetime.now().isoformat()
```

### 3. Shallow State Copy in LangGraph
```python
# BAD: shared nested references
updated_state = state.copy()
# GOOD: deep copy
import copy; updated_state = copy.deepcopy(state)
```

### 4. MemorySaver for Production
```python
# BAD: lost on restart
self.checkpointer = MemorySaver()
# GOOD: persistent
from langgraph.checkpoint.sqlite import SqliteSaver
self.checkpointer = SqliteSaver.from_conn_string("checkpoints.db")
```

### 5. No Concurrency for Independent Tools
Scene detection, object detection, emotion analysis, and STT are all independent I/O. Run concurrently with `asyncio.gather` + `asyncio.to_thread`.

### 6. Blocking Flask for Long Tasks
Video processing takes minutes. Use SSE streaming (as shown) or task queue (RQ/Celery).

### 7. Concat Demuxer Silent Failure
Always check return code. On failure, immediately fall back to pairwise concat filter — don't return partial results.

### 8. Global Singleton at Import Time
```python
# BAD: fails if config not loaded
global_ai_client = AIClient()
# GOOD: lazy init
_global_ai_client = None
def get_ai_client():
    global _global_ai_client
    if _global_ai_client is None: _global_ai_client = AIClient()
    return _global_ai_client
```

---

## Implementation Checklist

- [ ] FFmpeg installed and `find_ffmpeg()` resolves correctly
- [ ] Audio extraction produces 16kHz mono WAV for STT
- [ ] Whisper model loads (local or downloads)
- [ ] SRT parsing handles BOM, empty lines, multi-line subtitles
- [ ] Video splitting uses `-ss` before `-i` for fast seek
- [ ] Chunk duration >= 0.5s filter applied
- [ ] Concat list file uses forward slashes (replace `\` with `/`)
- [ ] Concat demuxer failure triggers pairwise concat filter fallback
- [ ] Target duration trim uses `-c copy` (no re-encode)
- [ ] Background audio uses `-stream_loop -1` for infinite looping
- [ ] Background audio volume reduced to ~30%
- [ ] `-shortest` flag used when merging video+audio of different lengths
- [ ] All temp files cleaned up after processing
- [ ] Word-density filter applied to Whisper segments (>= 1.0 words/sec)
- [ ] Error handling raises exceptions instead of returning fake data
- [ ] Long-running tasks use SSE streaming or async task queue
- [ ] `_prepare_initial_state()` fills all GraphState fields with defaults
- [ ] State copies use `deepcopy` between LangGraph nodes
- [ ] Duplicate form submit prevention: exactly ONE `addEventListener('submit')`

---

## Testing Strategy

1. Unit test STT pipeline: feed video with known speech, verify segments
2. Unit test SRT parser: parse hand-written SRT, verify timestamps
3. Unit test video splitting: extract 10s clip from 60s video, verify duration
4. Unit test concat: merge 2 short clips, verify output duration
5. Integration: upload video → process → verify output exists and plays
6. Edge case: no audio in video → add BGM, don't crash
7. Edge case: empty subtitles → fall back to fixed-duration chopping
8. Edge case: clips < 0.5s → skip, don't error
9. Edge case: video 10+ min → complete within timeout
10. Edge case: mismatched codecs → concat demuxer falls back to filter

---

## Dependencies & Config

### Core Dependencies
```
flask>=3.0, flask-cors>=3.0, python-dotenv>=1.0
faster-whisper>=1.0 (preferred), openai-whisper (fallback)
SpeechRecognition>=3.10 (Google STT fallback)
pydub>=0.25, edge-tts (free TTS)
ffmpeg (system, must be in PATH)
openai>=1.0, requests>=2.30 (AI mode optional)
opencc (Traditional→Simplified), opencv-python (AI mode)
```

### Key Config

```json
{
  "video_processing": {
    "upload_dir": "uploads", "temp_dir": "data/temp",
    "output_dir": "data/output", "model_dir": "data/models",
    "default_transition_duration": 0.5, "max_concurrent_processes": 2
  },
  "video_rendering": {
    "width": 1920, "height": 1080, "codec": "libx264",
    "preset": "ultrafast", "crf": 23, "framerate": 30, "audio_bitrate": "128k"
  }
}
```

---

## Frontend Details

### Two-Column Layout

Left (40%): mode tabs, file upload, params, submit, progress. Right (60%, ordered mode only): subtitle cards + timeline. Right column is `display:none` in random/ai modes. "片段长度" input hidden in ordered mode.

### Duplicate Submit Prevention

**Critical**: Exactly ONE `uploadForm.addEventListener('submit', ...)` handler. Search for existing bindings before adding any.

### Total Duration Display

```js
function updateOrderedDuration() {
    var total = 0;
    timelineItems.forEach(item => total += (item.end || 0) - (item.start || 0));
    document.getElementById('ordered-total-duration').textContent = total.toFixed(1);
}
```

### Toast Notification System

```js
showToast('message', 'error');  // Types: info, error, success, warning
// Auto-dismiss: error=8s, others=4s. Fixed top-right, z-index 100.
// Hooks into: window.onerror, unhandledrejection, SSE errors, fetch failures
```

### Submit Button Lock/Unlock

```js
// Lock: submitBtn.disabled = true; submitBtn.classList.add('opacity-50', 'cursor-not-allowed');
// Unlock: called in SSE 'result', 'done', and catch handlers
function enableSubmitButton() { /* reverse lock */ }
```

### FFmpeg Real-Time Progress

```python
def _run_ffmpeg_with_progress(cmd, emit, label, timeout=300):
    # Parse time=HH:MM:SS.ms from stderr → emit 'step_progress' SSE events
    proc = Popen(cmd, stdout=PIPE, stderr=PIPE, text=True)
    # ... threading.Thread reads stderr, emits pct via emit()
```

### Troubleshooting

**Subtitle cards don't appear**: Check `selectedFiles` populated, Whisper model exists at `data/models/faster-whisper-base/model.bin`, Flask log for "加载本地 Whisper 模型", browser console for fetch errors.

**FFmpeg timeout**: Use `-ss` before `-i` for fast keyframe seek. Increase timeout for 4K HEVC.

**Frozen video output**: Always re-encode clips (`libx264`), never `-c copy` for segments under 5s.

**Button stays gray**: Missing `enableSubmitButton()` call in SSE handler path. Ensure called in `result`, `done` (error), and `catch`.

**Junk files in output**: `shutil.rmtree(temp_dir)` after successful merge.
