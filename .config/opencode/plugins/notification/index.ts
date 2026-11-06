import { Plugin } from "@opencode/plugin"
import os from "os"
import path from "path"

const home = os.homedir()
// Shared with the Claude Code notification hook: finished / error / attention.
const SOUNDS = path.join(home, ".claude/sounds")
// Fallback cue when the sound library is unavailable.
const TETO = path.join(home, ".opencode/plugins/teto.mp3")
const VOICE = path.join(home, ".opencode/plugins/en_US-amy-medium.onnx")
const POPUP = path.join(home, ".opencode/plugins/popup.sh")

type SoundCategory = "finished" | "error" | "attention"

// OpenCode 2 finishes a turn with `session.execution.*`. Other builds emit
// `session.idle` or a `session.status` of `idle`. Listen to all of them and
// de-duplicate per message so one turn only speaks once.
const TERMINAL_EVENTS: readonly string[] = [
	"session.execution.succeeded",
	"session.execution.failed",
	"session.execution.interrupted",
	"session.idle",
	"session.status",
]

// Sessions currently being announced, so a burst of events for the same
// session only speaks once.
const running = new Set<string>()
// Assistant message already spoken, per session.
const spoken = new Map<string, string>()

// OpenCode loads one plugin instance per location and every instance sees the
// same events, so in-process guards are not enough. The lock is taken with a
// real `mkdir` subprocess because `node:fs` writes are not reliable inside the
// plugin runtime, while spawning is.
async function claim(messageID: string): Promise<string | undefined> {
	const dir = path.join(os.tmpdir(), `opencode-notification-${messageID}`)
	const proc = Bun.spawn(["mkdir", dir], { stdout: "ignore", stderr: "ignore" })
	const code = await proc.exited
	return code === 0 ? dir : undefined
}

function release(dir: string | undefined): void {
	if (!dir) return
	Bun.spawn(["rm", "-rf", dir], { stdout: "ignore", stderr: "ignore" })
}

function splitSentences(text: string): string[] {
	const sections = text.split(/(?=^#{1,6}\s)|(?<=^[*]{2}[^*]+[*]{2}:$)|(?<=\d\.)\s+(?=- )|(?=^- )|(?=^\* )|(?=^\|)|\n\n+/m);
	const sentences: string[] = [];
	for (const section of sections) {
		const lines = section.split(/(?<=[.!?:](?![^"]*"))\s+|(?=^(?:[-*]|\d+\.)\s)/);
		for (const line of lines) {
			const trimmed = line.trim();
			const isOnlyHeader = /^(#{1,6}\s|[*]{2}[^*]+[*]{2}:)$/.test(trimmed);
			if (trimmed.length > 3 && !/^[-| ]+$/.test(trimmed) && !isOnlyHeader) {
				sentences.push(trimmed);
			}
		}
	}
	return sentences;
}

// Speak the thing a path points at, not every directory on the way there.
function pathName(match: string): string {
	const segments = match.replace(/[\\/]+$/, "").split(/[\\/]/).filter(Boolean)
	// Dates and version stubs like 2026/10/31 read better untouched.
	if (segments.length > 1 && segments.every((segment) => /^\d+$/.test(segment))) return match
	return segments.at(-1) ?? ""
}

// Turn machine-ish text (paths, URLs, generated ids, markdown noise) into
// something that sounds right when read aloud.
function humanize(sentence: string): string {
	// Inline code is usually a path or command: unwrap it before parsing paths.
	let text = sentence.replace(/`/g, " ")

	// Markdown links keep their label; the target is noise when spoken.
	text = text.replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
	text = text.replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
	text = text.replace(/\bhttps?:\/\/\S+/gi, " ")
	text = text.replace(/\bwww\.\S+/gi, " ")

	// `src/foo.ts:42` reads better as "foo.ts line 42".
	text = text.replace(/\b([\w.@+-]+\.[A-Za-z0-9]{1,8}):(\d+)\b/g, "$1 line $2")

	// Windows paths, then absolute / home / dot-relative paths.
	text = text.replace(/\b[A-Za-z]:\\[^\s"'`<>|]+/g, (match) => ` ${pathName(match)} `)
	text = text.replace(
		/(^|[\s([{"'=:,;])((?:~|\.{1,2})?\/[^\s"'`()<>|]*[^\s"'`()<>|.,;:!?])/g,
		(_match, lead: string, target: string) => `${lead}${pathName(target)}`,
	)
	// Relative paths with two or more separators (src/plugin/index.ts). Single
	// separators are left alone so "and/or" and "client/server" still read.
	text = text.replace(/\b(?:[\w.@+-]+\/){2,}[\w.@+-]+\b/g, (match) => pathName(match))

	// Generated identifiers and hashes are unreadable.
	text = text.replace(/\b(?:msg|ses|sh|tool|evt|part)_[A-Za-z0-9]{6,}\b/g, " ")
	text = text.replace(/\b[0-9a-f]{12,}\b/gi, " ")

	// Formatting punctuation and emphasis markers.
	text = text.replace(/[*_#>|…]/g, " ")
	text = text.replace(/[[\]{}]/g, " ")
	text = text.replace(/[-–—]/g, " ")
	text = text.replace(/["'“”‘’]/g, " ")
	// A bare "./" or "../" carries no meaning when spoken.
	text = text.replace(/(^|\s)\.{1,2}\/(?=\s|$)/g, " ")

	// Rejoin punctuation stranded by the substitutions above.
	return text
		.replace(/\s+([.,;:!?])(?![./~])/g, "$1")
		.replace(/\s+/g, " ")
		.trim()
}

const quiet = { stdout: "ignore", stderr: "ignore" } as const

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Child = any

// State for one spoken announcement. Everything spawned for it is tracked so a
// popup dismissal can kill the audio (and the caption) in flight instead of
// letting the sentence run to the end.
interface Announcement {
	stop: boolean
	interrupted: Promise<void>
	interrupt: () => void
	children: Set<Child>
}

function newAnnouncement(): Announcement {
	let resolve!: () => void
	const interrupted = new Promise<void>((r) => {
		resolve = r
	})
	const ann: Announcement = {
		stop: false,
		interrupted,
		children: new Set(),
		interrupt() {
			ann.stop = true
			resolve()
			for (const child of ann.children) {
				try {
					child.kill()
				} catch {}
			}
			ann.children.clear()
		},
	}
	return ann
}

function track(ann: Announcement, proc: Child): Child {
	ann.children.add(proc)
	const forget = () => ann.children.delete(proc)
	proc.exited.then(forget, forget)
	return proc
}

// Kill the child as soon as the announcement is interrupted, otherwise let it
// finish. Returns true when it ran to completion.
async function waitFor(ann: Announcement, proc: Child): Promise<boolean> {
	await Promise.race([proc.exited.catch(() => {}), ann.interrupted])
	if (!ann.stop) return true
	try {
		proc.kill()
	} catch {}
	await proc.exited.catch(() => {})
	return false
}

async function playFile(file: string, ann: Announcement): Promise<boolean> {
	const proc = track(ann, Bun.spawn(["ffplay", "-v", "error", "-nodisp", "-autoexit", file], quiet))
	return waitFor(ann, proc)
}

// Mirror the Claude Code hook: one random clip from the matching category, so
// the same cue doesn't play every time.
async function pickSound(category: SoundCategory): Promise<string> {
	const dir = JSON.stringify(path.join(SOUNDS, category))
	const proc = Bun.spawn(
		[
			"bash",
			"-c",
			`find ${dir} -maxdepth 1 -type f \\( -iname '*.mp3' -o -iname '*.ogg' -o -iname '*.oga' -o -iname '*.wav' -o -iname '*.flac' -o -iname '*.m4a' -o -iname '*.opus' \\) 2>/dev/null | shuf -n1`,
		],
		{ stdout: "pipe", stderr: "ignore" },
	)
	const picked = (await new Response(proc.stdout).text()).trim()
	await proc.exited.catch(() => {})
	return picked || TETO
}

function categoryFor(eventType: string): SoundCategory {
	if (eventType === "session.execution.failed") return "error"
	if (eventType === "session.execution.interrupted") return "attention"
	return "finished"
}

async function generateAudio(sentence: string, ann: Announcement, force = false): Promise<Uint8Array | undefined> {
	if (ann.stop && !force) return undefined
	const proc = track(
		ann,
		Bun.spawn(["piper", "-m", VOICE, "--output-raw"], {
			stdin: "pipe",
			stdout: "pipe",
			stderr: "ignore",
		}),
	)
	try {
		proc.stdin.write(sentence)
		await proc.stdin.end()
	} catch {}
	if (ann.stop && !force) {
		try {
			proc.kill()
		} catch {}
		return undefined
	}
	const audio = new Uint8Array(await new Response(proc.stdout).arrayBuffer())
	await proc.exited.catch(() => {})
	return ann.stop && !force ? undefined : audio
}

async function playAudio(
	sentence: string,
	audio: Uint8Array | undefined,
	ann: Announcement,
	force = false,
): Promise<void> {
	if (!audio) return
	if (ann.stop && !force) return

	const caption = track(
		ann,
		Bun.spawn(
			[
				"aosd_cat",
				"--font=Sans Bold 54",
				"--fore-color=white",
				"--back-color=black",
				"--position=7",
				"--x-offset=0",
				"--y-offset=-30",
				"--fade-in=100",
				"--fade-full=60000",
				"--fade-out=3000",
			],
			{ stdin: "pipe", stdout: "ignore", stderr: "ignore" },
		),
	)
	try {
		caption.stdin.write(sentence)
		await caption.stdin.end()
	} catch {}

	if (ann.stop && !force) {
		try {
			caption.kill()
		} catch {}
		return
	}

	const player = track(
		ann,
		Bun.spawn(
			["ffplay", "-af", "atempo=1.25", "-v", "error", "-nodisp", "-autoexit", "-f", "s16le", "-ar", "24000", "-i", "pipe:0"],
			{ stdin: audio, stdout: "ignore", stderr: "ignore" },
		),
	)

	if (force) {
		// The farewell phrase must be allowed to finish even though the
		// announcement is already marked as stopped.
		await player.exited.catch(() => {})
	} else {
		await Promise.race([player.exited.catch(() => {}), ann.interrupted])
		if (ann.stop) {
			try {
				player.kill()
			} catch {}
		}
		await player.exited.catch(() => {})
	}

	try {
		caption.kill()
	} catch {}
	Bun.spawn(["killall", "aosd_cat"], quiet).exited.catch(() => {})
}

function textOf(message: any): string {
	const parts: any[] = message?.content ?? message?.parts ?? []
	return parts
		.filter((part) => part?.type === "text" && typeof part.text === "string")
		.map((part) => part.text)
		.join("")
		.replace(/```[\s\S]*?```/g, "") // No code blocks
}

async function announce(ctx: any, sessionID: string, category: SoundCategory): Promise<void> {
	if (running.has(sessionID)) return

	let lock: string | undefined
	try {
		const session = await ctx.session.get({ sessionID })
		// Ignore subagents
		if (!session || session.parentID) return

		const messages = await ctx.session.context({ sessionID })
		// V2 appends a turn marker (an `idle` message with an outcome) as the newest
		// entry, so speak the most recent message that actually carries text.
		const last = [...(messages ?? [])].reverse().find((message: any) => textOf(message).trim().length > 0)
		if (!last?.id) return
		if (spoken.get(sessionID) === last.id) return

		const sentences = splitSentences(textOf(last))
			.map(humanize)
			.filter((sentence) => /[A-Za-z0-9]/.test(sentence))
		if (sentences.length === 0) return

		lock = await claim(last.id)
		if (!lock) return

		running.add(sessionID)
		spoken.set(sessionID, last.id)
		const title = session.title ?? ""

		const ann = newAnnouncement()
		const popup = Bun.spawn(["bash", POPUP, title], quiet)

		// Dismissing the popup silences the announcement immediately: kill the
		// tone/speech/caption in flight, then acknowledge with a short "oh.".
		popup.exited.then(
			async () => {
				if (ann.stop) return
				ann.interrupt()
				Bun.spawn(["killall", "aosd_cat"], quiet).exited.catch(() => {})
				const farewell = await generateAudio("oh.", ann, true)
				await playAudio("oh.", farewell, ann, true)
			},
			() => {},
		)

		const heardTone = await playFile(await pickSound(category), ann)
		if (heardTone) {
			let nextAudio = generateAudio(sentences[0], ann)
			for (let i = 0; i < sentences.length && !ann.stop; i++) {
				const audio = await nextAudio
				if (i + 1 < sentences.length) {
					nextAudio = generateAudio(sentences[i + 1], ann)
				}
				if (ann.stop) break
				await playAudio(sentences[i], audio, ann)
			}
		}

		if (!ann.stop) {
			// Only this popup: match on the parent bash PID so titles containing
			// regex characters can't misfire or miss.
			Bun.spawn(["pkill", "-P", String(popup.pid), "-x", "yad"], quiet).exited.catch(() => {})
		} else {
			try {
				popup.kill()
			} catch {}
		}
	} finally {
		release(lock)
		running.delete(sessionID)
	}
}

export default Plugin.define({
	id: "notification",
	async setup(ctx) {
		const controller = new AbortController()

		void (async () => {
			try {
				for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
					if (!TERMINAL_EVENTS.includes(event.type)) continue
					const data = (event as any).data ?? {}
					if (event.type === "session.status" && data.status?.type !== "idle") continue
					if (!data.sessionID) continue
					// Don't await: an announcement takes seconds of audio and must not
					// block the event stream for other sessions.
					void announce(ctx, data.sessionID, categoryFor(event.type)).catch((error) => {
						console.error("[notification]", error)
					})
				}
			} catch (error) {
				if (!controller.signal.aborted) console.error("[notification] subscription failed", error)
			}
		})()

		return () => controller.abort()
	},
})
